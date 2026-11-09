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
    // The hex encoder writes this byte between two bytes. The hex decoder
    // requires it there and nowhere else. The byte is printable and is
    // not a hex digit. Any other value turns the separator off.
    sep: u8,
    // The encoder breaks the text with a line feed after this many
    // characters. Zero or less writes one line.
    wrap: i64,
    // The ASCII85 encoder writes the frame of Adobe. The ASCII85 decoder
    // requires it.
    adobe: bool,
    // The decoder takes only the case that the field lower selects.
    exact_case: bool,
}

// strict_options gives the rules of RFC 4648. The padding is there, the
// letters are upper case and no byte is skipped.
fn strict_options() -> Options {
    return Options { padding: true, lower: false, skip_space: false, map01: 0, sep: 0, wrap: 0, adobe: false, exact_case: false };
}

// text_options gives the rules of the text that a person typed. The
// padding may be missing and the white space is skipped.
fn text_options() -> Options {
    return Options { padding: false, lower: false, skip_space: true, map01: 0, sep: 0, wrap: 0, adobe: false, exact_case: false };
}

// is_space tells whether a byte is one of the four white space bytes.
fn is_space(c: u8) -> bool {
    return c == ' ' || c == '\t' || c == '\r' || c == '\n';
}

// wrap_lines breaks the text that starts at the index start in the buffer
// into lines of at most width characters. It writes a line feed between
// two lines and none at the end. A width of zero or less changes nothing.
fn wrap_lines(out: u8[>..]&, start: i64, width: i64) {
    if width <= 0 { return; }
    let n = out.len - start;
    if n <= width { return; }
    let lines = (n - 1) / width;
    out.resize(out.len + lines, 0);
    var r = start + n;
    var w = out.len;
    while r > start {
        var take = (r - start) % width;
        if take == 0 { take = width; }
        var k: i64 = 0;
        while k < take {
            out[w - 1 - k] = out[r - 1 - k];
            k = k + 1;
        }
        r = r - take;
        w = w - take;
        if r > start {
            w = w - 1;
            out[w] = '\n';
        }
    }
}

// case_ok tells whether a letter has the case that the options ask for.
// The check runs only when the options ask for an exact case.
fn case_ok(opts: Options, c: u8) -> bool {
    if !opts.exact_case { return true; }
    if c - 'A' < 26 { return !opts.lower; }
    if c - 'a' < 26 { return opts.lower; }
    return true;
}
