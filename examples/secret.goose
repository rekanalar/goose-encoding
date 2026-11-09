// An example for the encoding package: a secret in base32.
//
// Run with: goose run examples/secret.goose
import std;
import encoding from "..";

fn main() {
    // The secret of a person. It is a text of base32.
    let secret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ";

    // The bytes of the secret.
    var bytes: u8[>..] = [];
    let code, pos = encoding::base32_decode(bytes, secret, encoding::strict_options());
    print("code   : ", encoding::error_text(code), " at ", pos, "\n");

    // The same bytes as hex, so that they can be read.
    var shown: u8[>..] = [];
    encoding::hex_encode(shown, bytes, encoding::strict_options());
    print("bytes  : ", shown[..], "\n");

    // The text that the package writes for the same bytes.
    var text: u8[>..] = [];
    encoding::base32_encode(text, bytes, encoding::strict_options());
    print("base32 : ", text[..], "\n");

    // The same bytes in the other alphabet.
    var hexed: u8[>..] = [];
    encoding::base32hex_encode(hexed, bytes, encoding::strict_options());
    print("hex    : ", hexed[..], "\n");

    // The person typed the secret in lower case and with a space in it.
    let typed = "gezd gnbv gy3t qojq gezd gnbv gy3t qojq";
    var typed_back: u8[>..] = [];
    let code2, pos2 = encoding::base32_decode(typed_back, typed, encoding::text_options());
    print("typed  : ", encoding::error_text(code2), " at ", pos2, "\n");
    print("same   : ", typed_back == bytes, "\n");

    // The strict options refuse the text of the person.
    var strict_back: u8[>..] = [];
    let code3, pos3 = encoding::base32_decode(strict_back, typed, encoding::strict_options());
    print("strict : ", encoding::error_text(code3), " at ", pos3, "\n");

    // A text with a byte that is not in the alphabet.
    var bad: u8[>..] = [];
    let code4, pos4 = encoding::base32_decode(bad, "NBSWY3D!", encoding::strict_options());
    print("bad    : ", encoding::error_text(code4), " at ", pos4, "\n");

    // The same bytes as ASCII85 and as base85.
    var a85: u8[>..] = [];
    encoding::ascii85_encode(a85, bytes, encoding::strict_options());
    print("ascii85: ", a85[..], "\n");
    var b85: u8[>..] = [];
    encoding::base85_encode(b85, bytes, encoding::strict_options());
    print("base85 : ", b85[..], "\n");

    // The bytes come back from the ASCII85 text.
    var back: u8[>..] = [];
    let code5, pos5 = encoding::ascii85_decode(back, a85, encoding::strict_options());
    print("read   : ", encoding::error_text(code5), " at ", pos5, "\n");
    print("same   : ", back == bytes, "\n");

    // Z85 needs a length that is a multiple of 4 bytes.
    var z85: u8[>..] = [];
    let key: u8[8] = [0x86, 0x4F, 0xD2, 0x6F, 0xB5, 0x59, 0xF7, 0x5B];
    let code7, pos7 = encoding::z85_encode(z85, key[..], encoding::strict_options());
    print("z85    : ", z85[..], " ", encoding::error_text(code7), "\n");
    var odd: u8[>..] = [];
    let code8, pos8 = encoding::z85_encode(odd, "abc", encoding::strict_options());
    print("z85 odd: ", encoding::error_text(code8), " at ", pos8, "\n");

    // Crockford base32 has no padding. A person can read it aloud.
    var crock: u8[>..] = [];
    encoding::base32crockford_encode(crock, bytes, encoding::strict_options());
    print("crock  : ", crock[..], "\n");
    var mine: u8[>..] = [];
    let code9, pos9 = encoding::custom32_encode(mine, bytes, "0123456789abcdefghijklmnopqrstuv", encoding::strict_options());
    print("custom : ", mine[..], " ", encoding::error_text(code9), "\n");
    let code10, pos10 = encoding::custom32_encode(mine, bytes, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", encoding::strict_options());
    print("alpha  : ", encoding::error_text(code10), " at ", pos10, "\n");

    // A group of five characters can hold a value that no four bytes
    // hold. The decoder refuses such a text.
    var over: u8[>..] = [];
    let code6, pos6 = encoding::ascii85_decode(over, "uuuuu", encoding::strict_options());
    print("over   : ", encoding::error_text(code6), " at ", pos6, "\n");
    return 0;
}
