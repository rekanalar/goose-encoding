# goose-encoding

[![ci](https://github.com/rekanalar/goose-encoding/actions/workflows/ci.yml/badge.svg)](https://github.com/rekanalar/goose-encoding/actions/workflows/ci.yml)

The base32, base32hex, Crockford base32, hex, ASCII85, base85 and Z85 codecs for the [Goose](https://github.com/aardappel/goose) programming language. It also holds a base32 codec for an alphabet that you give.

## Install

Put this line in the root file of your program:

```goose
import encoding from "rekanalar/goose-encoding@v0.4.0";
```

The CI runs the gate on Linux, macOS and Windows. It uses Goose v2026.4 and v2026.3 on each.
The package is pure Goose. It depends on the standard library only.

## Reference libraries

| Area | Reference |
|---|---|
| Base32 and hex | Go `encoding/base32`, `encoding/hex` |
| Base32 and hex | Python `base64`, `binascii` |
| Base32 and hex | Java `java.util.HexFormat`, Apache Commons Codec, Guava `BaseEncoding` |
| Base32 and hex | Rust `data-encoding`, `base64`, `hex` |
| Base32 | Perl `Convert::Base32`, `MIME::Base32` |
| Base64 and hex | C++ `cppcodec`, OpenSSL, Boost, Abseil |
| ASCII85 | Go `encoding/ascii85` |
| ASCII85 and base85 | Python `base64` (`a85encode`, `a85decode`, `b85encode`, `b85decode`) |
| ASCII85 and base85 | Rust `ascii85`, `base85`, `base85rs`, `base85-simd` |
| ASCII85 and base85 | Node npm `base85`, npm `ascii85` |
| ASCII85 | Java `com.github.fzakaria:ascii85` |
| base85 | Perl `MIME::Base85`, `Convert::Base85`, `Math::Base85` |
| ASCII85 and base85 | C# `SimpleBase` |
| Crockford base32 | C++ `cppcodec` (`base32_crockford`) |
| Custom alphabet | Rust `data-encoding` (`Specification`), Go `encoding/base32` (`NewEncoding`) |
| `map01` | Python `base64` (`b32decode`) |
| Z85 | Python `base64` (`z85encode`, `z85decode`), Rust `z85`, Node npm `z85` |

## Features

- **Base32 and base32hex.** The alphabets of RFC 4648 §6 and §7. Encode and decode, with the padding or without it.
- **Hex.** Two characters for each byte. Encode and decode, in either case.
- **ASCII85 and base85.** Five characters for every four bytes. The alphabet of Adobe and the alphabet of RFC 1924. Encode and decode.
- **Crockford base32.** The alphabet without `I`, `L`, `O` and `U`. No padding. The decoder reads `O` as 0 and `I` and `L` as 1.
- **A custom alphabet.** Your own 32 symbols for the base32 codec. The package checks the alphabet.
- **The `map01` option.** The base32 decoder can read 0 as `O` and 1 as `I` or `L`. RFC 4648 section 2.4 allows it.
- **Z85.** The codec of ZeroMQ RFC 32. Five characters for every four bytes, with its own alphabet. The input holds whole groups only. Encode and decode.
- **Strict decoders.** Every decoder refuses a byte outside the alphabet. It refuses a wrong padding. It refuses the leftover bits that are not zero. It refuses a base85 or Z85 group that holds more than 32 bits.
- **The place of the fault.** Every decoder gives the position of the first fault in the text.
- **The rules of the codec.** The caller chooses the padding, the case and the white space.

## API

| Name | What it does |
|---|---|
| `base32_encode(out, src, opts)` | Write the base32 text of the bytes |
| `base32_decode(out, src, opts)` | Read the base32 text. It gives a code and a position |
| `base32hex_encode(out, src, opts)` | Write the base32hex text of the bytes |
| `base32hex_decode(out, src, opts)` | Read the base32hex text. It gives a code and a position |
| `hex_encode(out, src, opts)` | Write the hex text of the bytes |
| `hex_decode(out, src, opts)` | Read the hex text. It gives a code and a position |
| `ascii85_encode(out, src, opts)` | Write the ASCII85 text of the bytes |
| `ascii85_decode(out, src, opts)` | Read the ASCII85 text. It gives a code and a position |
| `base85_encode(out, src, opts)` | Write the base85 text of RFC 1924 of the bytes |
| `base85_decode(out, src, opts)` | Read the base85 text of RFC 1924. It gives a code and a position |
| `base32crockford_encode(out, src, opts)` | Write the Crockford base32 text of the bytes |
| `base32crockford_decode(out, src, opts)` | Read the Crockford base32 text. It gives a code and a position |
| `custom32_encode(out, src, alphabet, opts)` | Write the base32 text with an alphabet of 32 symbols. It gives a code and a position |
| `custom32_decode(out, src, alphabet, opts)` | Read the text of an alphabet of 32 symbols. It gives a code and a position |
| `z85_encode(out, src, opts)` | Write the Z85 text of the bytes. It gives a code and a position. The length of the bytes is a multiple of 4 |
| `z85_decode(out, src, opts)` | Read the Z85 text. It gives a code and a position. The length of the text is a multiple of 5 |
| `strict_options()` | The rules of RFC 4648 |
| `text_options()` | The rules of the text that a person typed |
| `error_text(code)` | The name of a code |

The buffer `out` is a growable buffer of the caller. The codec adds its bytes to the bytes that the buffer holds.
A decoder that finds a fault leaves the buffer as it was.

The slice `src` is a view of the bytes of the caller. The codec never writes to it.

### The options

| Field | The encoder | The decoder |
|---|---|---|
| `padding` | Writes the `=` padding | Requires the padding. It takes a text with no padding when the field is false |
| `lower` | Writes the lower case letters | Takes either case |
| `skip_space` | Does nothing | Skips the spaces, the tabs, the carriage returns and the line feeds. The Crockford decoder also skips `-` |
| `map01` | Does nothing | The letter `I` or `L` makes the base32 decoder read 0 as `O` and 1 as that letter. Any other value turns it off |

The hex codec has no padding. The field `padding` changes nothing for it.
The ASCII85, base85 and Z85 codecs have no padding and no case. The fields `padding` and `lower` change nothing for them.

### The codes

| Code | The fault | The place |
|---|---|---|
| `ERR_OK` | The text holds no fault | -1 |
| `ERR_INVALID_CHAR` | A byte is not in the alphabet of the codec | The index of the byte |
| `ERR_BAD_LENGTH` | The text holds a length that no group of the codec can hold | The index of the first byte of the group. For hex it is the index just after the last character |
| `ERR_BAD_PADDING` | The padding is missing, too short, too long or stands in the middle of the text | The index of the first `=` |
| `ERR_NON_CANONICAL` | The last group of a base32 text holds bits that are not zero. The last group of a base85 text is not the tail of its own bytes | The index of the last character of the last group |
| `ERR_OVERFLOW` | A group of a base85 text holds a value that is larger than 2 to the power of 32 | The index of the first character of the group |
| `ERR_BAD_ALPHABET` | The alphabet of a custom codec has not 32 symbols, repeats a symbol, or holds `=` or a byte that is not printable | The index of the first bad symbol. For a wrong count it is 0 |

The decoder reports the fault with the smallest place.
A fault that stands later in the text never hides a fault that stands earlier in it.

## Example

```goose
import std;
import encoding from "rekanalar/goose-encoding@v0.4.0";

fn main() {
    var text: u8[>..] = [];
    encoding::base32_encode(text, "hello", encoding::strict_options());
    print(text[..], "\n");

    var bytes: u8[>..] = [];
    let code, pos = encoding::base32_decode(bytes, "NBSWY3DP", encoding::strict_options());
    print(code, " ", pos, " ", bytes[..], "\n");
    return 0;
}
```

The text is `NBSWY3DP`. The decode gives the code `ERR_OK`, the place `-1` and the bytes `hello`.

## Security

The package reads text from people you do not know. It adds these protections beyond the reference libraries.

- **A bad byte never becomes a good byte.** The decoder refuses a byte that is not in the alphabet. The Apache Commons Codec and the Perl library `MIME::Base32` skip such a byte with no error. The Node library `Buffer` cuts a hex text at the first bad pair. The package refuses.
- **The leftover bits stay zero.** The last group of a base32 text may hold bits that no byte uses. The Go, the Python, the Java and the Perl libraries accept these bits. The package refuses them. One text then has one spelling.
- **The buffer of the caller keeps its bytes.** A decoder that finds a fault leaves the buffer as it was. The check for the leftover bits runs before the write. A text that holds them leaves no byte in the buffer.
- **A short tail is a fault.** A tail of 1, 3 or 6 characters is refused. The Go library drops such a tail in its no-padding mode and gives no error.
- **The padding stays complete.** The decoder refuses a padding that is missing, too short or too long. It refuses a padding that stands in the middle of the text. The Apache Commons Codec ends the text at the padding and drops the rest.
- **The white space never stands for a byte.** The decoder skips the four white space bytes on request. It refuses every other byte. The MIME decoder of the JDK skips every byte that is not in the alphabet. A control byte goes with it.
- **The place of the fault is known.** Every decoder gives the index of the first fault in the text. The caller can show it and cut the text there.
- **A group that holds too much is a fault.** Five characters of base85 hold 85 to the power of 5. That number is larger than 2 to the power of 32. A group can then hold a value that no four bytes hold.

  The Go library `encoding/ascii85` wraps that value. It gives wrong bytes and no error. The Rust library `base85` 2.0.0, the Java library of fzakaria and the C# library `SimpleBase` do the same. The Python library and the Rust library `base85-simd` refuse the group. The package refuses it.
- **The tail of a base85 text has one spelling.** Its characters hold more digits than its bytes need. The Go, the Python, the Rust and the C# libraries take any tail. The Go decoder gives the bytes `66` for the text `Ac` and for the text `Ad`. The package takes the tail of its own bytes only. One text then has one spelling.
- **A hyphen or a digit never slips in.** The Crockford decoder skips `-` only on request. The base32 decoder maps 0 and 1 only when the caller sets `map01`. The Crockford `=` is a bad byte.
- **A bad alphabet is a fault.** The custom codec checks the alphabet before it writes. It refuses a repeated symbol, `=` and a byte that is not printable. A repeated symbol gives two values one text.
- **Z85 takes no wrapped group and no stray byte.** The Node library `z85` wraps a group that holds too much. It also takes a space inside the text. Both give wrong bytes. The package refuses both, and skips white space only under the text options.
- **The output never grows past the input.** At most 5 bytes come from 8 characters of a base32 text. At most 1 byte comes from 2 characters of a hex text. At most 4 bytes come from 5 characters of a base85 text. The shortcut `z` gives 4 bytes from 1 character. The output buffer is sized before the write.

Risks that stay: the package never opens a file and never opens a socket. The caller reads the bytes and holds the text. A text that passes the validation may still be a business mistake. The base32 text of a secret is not a secret. It is shorter than the key, and a person with the text can find the key.

## Limits

These are the places where this package does less than a reference library.

- **No base64.** The standard library holds the base64 codec. The package holds base32, base32hex and hex.
- **Z85 holds whole groups only.** RFC 32 asks for a multiple of 4 bytes and a multiple of 5 characters. The Python library `base64` pads on encode and takes a tail on decode. The package refuses both with `ERR_BAD_LENGTH`. The Rust library `z85` refuses them too.
- **Z85 has no shortcut.** The character `z` is a digit of the value 35. The encoder gives a code, because it can fail.
- **No frame of Adobe.** The package neither reads nor writes `<~` and `~>`. The Go library leaves the frame to the caller. The Rust library `ascii85` writes it always. The C# library and the Java library remove it when it stands. The npm package `base85` writes it in its variant `ascii85`. The caller removes the frame.
- **No shortcut `y`.** The package refuses the `y` of btoa. It stands for four spaces. The C# library takes it and writes it. The Python library takes it under the argument `foldspaces=True`. It is not a part of the Adobe format.
- **The white space is skipped only on request.** The Go library and the Python library skip the white space always. The Rust library `base85` and the Python library `b85decode` refuse it. The package skips it under the text options.
- **A group that holds too much is a fault.** The Go library `encoding/ascii85` gives wrong bytes for such a group. The Rust library `base85` 2.0.0, the Java library of fzakaria and the C# library `SimpleBase` do the same. The package refuses the group.
- **A tail of one character is a fault.** The Go library and the Rust libraries refuse such a tail. The Python, the Java and the C# libraries give no bytes and no error. The package refuses it.
- **The encoder writes the shortcut `z`.** The Rust library `ascii85` writes no `z` for a group of four zero bytes. The Go library and the Python library write it. The package writes it.
- **No streaming.** The Go library `encoding/base32` holds `NewEncoder` and `NewDecoder`. The Guava library `BaseEncoding` holds `encodingStream`. The Apache Commons Codec holds streams. The Rust library `data-encoding`, the Python library `base64` and the Perl modules hold no stream. The package works on a buffer that the caller holds.
- **A custom alphabet has 32 symbols.** The Rust library `data-encoding` builds alphabets of 2 to 64 symbols. The Go library `encoding/base32` takes 32. The Python and Java libraries take none. The package takes 32 for base32. The standard library holds base64. Hex and base85 have fixed alphabets.
- **No check symbol for Crockford.** The format allows a check symbol, modulo 37. The C++ library `cppcodec` builds none. The package builds none.
- **`map01` takes a letter.** The Python library `base64` takes the letter as an argument and `casefold` as a second one. The package takes either case at all times, so it holds no `casefold`.
- **The options hold a new field.** The field `map01` is new. A program that builds `Options` with a literal must set it. A program that calls `strict_options` or `text_options` needs no change.
- **No base58 and no varint.**
- **The decoder has one rule for the case.** It takes a letter in either case. The Go library `encoding/base32` and the Guava library `base32` refuse a lower case letter. The Apache Commons Codec and the Perl library `Convert::Base32` take it.
- **The decoder has one rule for the padding.** It requires the padding under the strict options. It takes the padding as optional under the text options. The JDK library `java.util.Base64` always takes it as optional. The Apache Commons Codec takes a padding that stands in the middle of the text.
- **The decoder has no lenient mode.** It never skips a byte that is not in the alphabet. The Apache Commons Codec skips every such byte under its default policy. The Java library `java.util.Base64` in its MIME mode skips every byte that is not in the alphabet.
- **The encoder writes no line break.** The Python library `base64.encodebytes` writes a line of 76 characters. The Perl library `MIME::Base64` writes such a line. The OpenSSL library writes one too. The package writes the text in one line.
