// The values that every codec of the package uses.
//
// The options hold the rules of a codec. The caller holds one value
// and gives it to every call.
//
// The hex codec has no padding. The field padding changes nothing for
// it.
namespace encoding;

// The value of a byte that is not in the alphabet of a codec.
const INVALID: u32 = 255;

// The rules of a codec.
struct Options {
    // The encoder writes the '=' padding. The decoder requires it.
    // The decoder also takes a text with no padding when the field is
    // false.
    padding: bool,
    // The encoder writes the lower case letters.
    lower: bool,
    // The decoder skips the spaces, the tabs, the carriage returns and
    // the line feeds.
    skip_space: bool,
    // The base32 decoder reads 0 as O and 1 as this letter, which is I
    // or L (RFC 4648 section 2.4). Any other value turns the mapping off.
    map01: u8,
}

// strict_options gives the rules of RFC 4648. The padding is there, the
// letters are upper case and no byte is skipped.
fn strict_options() -> Options {
    return Options { padding: true, lower: false, skip_space: false, map01: 0 };
}

// text_options gives the rules of the text that a person typed. The
// padding may be missing and the white space is skipped.
fn text_options() -> Options {
    return Options { padding: false, lower: false, skip_space: true, map01: 0 };
}

// is_space tells whether a byte is one of the four white space bytes.
fn is_space(c: u8) -> bool {
    return c == ' ' || c == '\t' || c == '\r' || c == '\n';
}
