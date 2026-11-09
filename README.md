# goose-encoding

[![ci](https://github.com/rekanalar/goose-encoding/actions/workflows/ci.yml/badge.svg)](https://github.com/rekanalar/goose-encoding/actions/workflows/ci.yml)

The base32, base32hex and hex codecs for the [Goose](https://github.com/aardappel/goose) programming language.

## Install

Put this line in the root file of your program:

```goose
import encoding from "rekanalar/goose-encoding@v0.1.0";
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

## Features

- **Base32 and base32hex.** The alphabets of RFC 4648 §6 and §7. Encode and decode, with the padding or without it.
- **Hex.** Two characters for each byte. Encode and decode, in either case.
- **Strict decoders.** Every decoder refuses a byte outside the alphabet. It refuses a wrong padding. It refuses the leftover bits that are not zero.
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
| `skip_space` | Does nothing | Skips the spaces, the tabs, the carriage returns and the line feeds |

The hex codec has no padding. The field `padding` changes nothing for it.

### The codes

| Code | The fault | The place |
|---|---|---|
| `ERR_OK` | The text holds no fault | -1 |
| `ERR_INVALID_CHAR` | A byte is not in the alphabet of the codec | The index of the byte |
| `ERR_BAD_LENGTH` | The text holds a length that no group of the codec can hold | The index of the first byte of the group. For hex it is the index just after the last character |
| `ERR_BAD_PADDING` | The padding is missing, too short, too long or stands in the middle of the text | The index of the first `=` |
| `ERR_NON_CANONICAL` | The last group of a base32 text holds bits that are not zero | The index of the last character of the last group |

The decoder reports the fault with the smallest place.
A fault that stands later in the text never hides a fault that stands earlier in it.

## Example

```goose
import std;
import encoding from "rekanalar/goose-encoding@v0.1.0";

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
- **The output never grows past the input.** At most 5 bytes come from 8 characters of a base32 text. At most 1 byte comes from 2 characters of a hex text. The output buffer is sized before the write.

Risks that stay: the package never opens a file and never opens a socket. The caller reads the bytes and holds the text. A text that passes the validation may still be a business mistake. The base32 text of a secret is not a secret. It is shorter than the key, and a person with the text can find the key.

## Limits

These are the places where this package does less than a reference library.

- **No base64.** The standard library holds the base64 codec. The package holds base32, base32hex and hex.
- **No ASCII85 and no base85.** They come in the next release.
- **No base58 and no varint.**
- **No Crockford base32.** The Go library `x/crypto` and the C++ library `cppcodec` hold it. The package holds the two alphabets of RFC 4648.
- **The decoder has one rule for the case.** It takes a letter in either case. The Go library `encoding/base32` and the Guava library `base32` refuse a lower case letter. The Apache Commons Codec and the Perl library `Convert::Base32` take it.
- **The decoder has one rule for the padding.** It requires the padding under the strict options. It takes the padding as optional under the text options. The JDK library `java.util.Base64` always takes it as optional. The Apache Commons Codec takes a padding that stands in the middle of the text.
- **The decoder has no lenient mode.** It never skips a byte that is not in the alphabet. The Apache Commons Codec skips every such byte under its default policy. The Java library `java.util.Base64` in its MIME mode skips every byte that is not in the alphabet.
- **The encoder writes no line break.** The Python library `base64.encodebytes` writes a line of 76 characters. The Perl library `MIME::Base64` writes such a line. The OpenSSL library writes one too. The package writes the text in one line.
