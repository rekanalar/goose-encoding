// An example for the encoding package: bytes as hex.
//
// Run with: goose run examples/digest.goose
import std;
import encoding from "..";

fn main() {
    // The bytes of a digest.
    let bytes = "the quick brown fox";

    // The text that the package writes.
    var upper: u8[>..] = [];
    encoding::hex_encode(upper, bytes, encoding::strict_options());
    print("upper : ", upper[..], "\n");

    // The lower case form.
    var lower: u8[>..] = [];
    let low = encoding::strict_options();
    low.lower = true;
    encoding::hex_encode(lower, bytes, low);
    print("lower : ", lower[..], "\n");

    // The bytes come back.
    var back: u8[>..] = [];
    let code, pos = encoding::hex_decode(back, upper, encoding::strict_options());
    print("read  : ", back[..], "\n");
    print("code  : ", encoding::error_text(code), " at ", pos, "\n");

    // The text of a person holds a space.
    var spaced: u8[>..] = [];
    let code2, pos2 = encoding::hex_decode(spaced, "74 68 65", encoding::text_options());
    print("spaced: ", encoding::error_text(code2), " at ", pos2, "\n");
    print("text  : ", spaced[..], "\n");

    // A text of an odd count of characters is a fault.
    var odd: u8[>..] = [];
    let code3, pos3 = encoding::hex_decode(odd, "746", encoding::strict_options());
    print("odd   : ", encoding::error_text(code3), " at ", pos3, "\n");
    return 0;
}
