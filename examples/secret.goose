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
    return 0;
}
