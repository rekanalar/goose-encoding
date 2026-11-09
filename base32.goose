// The base32 and the base32hex codecs.
//
// A group holds 8 characters for 5 bytes. A tail holds 2, 4, 5 or 7
// characters. The bits that a tail leaves over must be zero.
//
// The decoder reads the text in two passes. The first pass counts the
// characters and finds the faults. The second pass writes the bytes.
// The decoder reports the fault with the smallest position. The
// leftover bits are checked only when the text holds no other fault.
namespace encoding;

// The kind of the alphabet of RFC 4648 section 6.
const ALPHA_BASE32: i64 = 0;

// The kind of the alphabet of RFC 4648 section 7.
const ALPHA_BASE32HEX: i64 = 1;

// The count of the characters of a group.
const GROUP_CHARS: i64 = 8;

// The count of the bytes of a group.
const GROUP_BYTES: i64 = 5;

// b32_symbol gives the character of a value of 5 bits.
fn b32_symbol(kind: i64, v: u8, lower: bool) -> u8 {
    var c: u8 = 'A';
    if kind == ALPHA_BASE32HEX {
        if v < 10 { c = '0' + v; } else { c = 'A' + (v - 10); }
    } else {
        if v < 26 { c = 'A' + v; } else { c = '2' + (v - 26); }
    }
    if lower && c >= 'A' && c <= 'Z' { c = c + 32; }
    return c;
}

// b32_value gives the value of a character of the alphabet. It gives
// INVALID for a byte that is not in the alphabet.
fn b32_value(kind: i64, c: u8) -> u32 {
    if kind == ALPHA_BASE32HEX {
        if c - '0' < 10 { return c - '0'; }
        if c - 'A' < 22 { return 10 + (c - 'A'); }
        if c - 'a' < 22 { return 10 + (c - 'a'); }
        return INVALID;
    }
    if c - 'A' < 26 { return c - 'A'; }
    if c - 'a' < 26 { return c - 'a'; }
    if c - '2' < 6 { return 26 + (c - '2'); }
    return INVALID;
}

// base32_encode writes the base32 text of the bytes into the buffer of
// the caller.
fn base32_encode(out: u8[>..]&, src: const u8[:], opts: Options) {
    encode_b32(out, src, opts, ALPHA_BASE32);
}

// base32hex_encode writes the base32hex text of the bytes into the
// buffer of the caller.
fn base32hex_encode(out: u8[>..]&, src: const u8[:], opts: Options) {
    encode_b32(out, src, opts, ALPHA_BASE32HEX);
}

// encode_b32 writes the text of the bytes into the buffer of the
// caller. It adds its text to the bytes that the buffer holds.
fn encode_b32(out: u8[>..]&, src: const u8[:], opts: Options, kind: i64) {
    let start = out.len;
    // The text of n bytes holds n * 8 / 5 characters.
    let chars = (src.len * 8 + 4) / 5;
    var need = chars;
    if opts.padding {
        need = ((chars + GROUP_CHARS - 1) / GROUP_CHARS) * GROUP_CHARS;
    }
    out.resize(start + need, 0);
    let dst = out[start..];
    var d: i64 = 0;
    // The buffer holds the bits that no character has used yet.
    var buf: u32 = 0;
    var bits: i64 = 0;
    var i: i64 = 0;
    while i < src.len {
        buf = (buf << 8) | src[i];
        bits = bits + 8;
        while bits >= 5 {
            bits = bits - 5;
            dst[d] = b32_symbol(kind, ((buf >> bits) & 31) as u8, opts.lower);
            buf = buf & ((1 << bits) - 1);
            d = d + 1;
        }
        i = i + 1;
    }
    if bits > 0 {
        // The last character holds the bits that no byte uses. They are
        // zero, so the text has one spelling.
        dst[d] = b32_symbol(kind, ((buf << (5 - bits)) & 31) as u8, opts.lower);
        d = d + 1;
    }
    while d < need {
        dst[d] = '=';
        d = d + 1;
    }
}

// What the first pass of the decoder finds.
struct Scan {
    count: i64,       // the count of the characters of the data
    first_bad: i64,   // the index of the first byte outside the alphabet
    first_pad: i64,   // the index of the first '='
    pad_count: i64,   // the count of the '='
    after_pad: i64,   // the index of the first byte after the padding
    group_start: i64, // the index of the first character of the last group
    last_data: i64,   // the index of the last character of the data
}

// base32_decode reads the base32 text into the buffer of the caller. It
// gives a code and a position.
fn base32_decode(out: u8[>..]&, src: const u8[:], opts: Options) -> i64, i64 {
    return decode_b32(out, src, opts, ALPHA_BASE32);
}

// base32hex_decode reads the base32hex text into the buffer of the
// caller. It gives a code and a position.
fn base32hex_decode(out: u8[>..]&, src: const u8[:], opts: Options) -> i64, i64 {
    return decode_b32(out, src, opts, ALPHA_BASE32HEX);
}

// decode_b32 reads the text into the buffer of the caller. It gives a
// code and a position. It leaves the buffer as it was when it finds a
// fault.
fn decode_b32(out: u8[>..]&, src: const u8[:], opts: Options, kind: i64) -> i64, i64 {
    let start = out.len;
    let s = scan_b32(src, opts, kind);

    var code: i64 = ERR_OK;
    var pos: i64 = -1;

    // A byte outside the alphabet.
    if s.first_bad >= 0 {
        code = ERR_INVALID_CHAR;
        pos = s.first_bad;
    }

    // A length that no group of the codec can hold.
    let tail = s.count % GROUP_CHARS;
    if tail != 0 && tail != 2 && tail != 4 && tail != 5 && tail != 7 {
        if pos < 0 || s.group_start < pos {
            code = ERR_BAD_LENGTH;
            pos = s.group_start;
        }
    }

    // A padding that is wrong.
    let pad_pos = padding_fault(s, opts);
    if pad_pos >= 0 && (pos < 0 || pad_pos < pos) {
        code = ERR_BAD_PADDING;
        pos = pad_pos;
    }

    if code != ERR_OK {
        return code, pos;
    }

    // The bits that no byte uses must be zero. The check runs before
    // the write, so a fault leaves the buffer of the caller as it was.
    // The check runs only when the text holds no other fault, because
    // the bits of a broken text mean nothing.
    let extra = (tail * 5) % 8;
    if extra > 0 {
        let last = b32_value(kind, src[s.last_data]) as i64;
        if (last & ((1 << extra) - 1)) != 0 {
            return ERR_NON_CANONICAL, s.last_data;
        }
    }

    // The second pass writes the bytes.
    var bytes = (s.count / GROUP_CHARS) * GROUP_BYTES;
    if tail != 0 { bytes = bytes + (tail * 5) / 8; }
    out.resize(start + bytes, 0);
    let dst = out[start..];
    var d: i64 = 0;
    var buf: u32 = 0;
    var bits: i64 = 0;
    var i: i64 = 0;
    while i < src.len {
        let c = src[i];
        if opts.skip_space && is_space(c) {
            i = i + 1;
            continue;
        }
        if c == '=' { break; }
        buf = (buf << 5) | b32_value(kind, c);
        bits = bits + 5;
        while bits >= 8 {
            bits = bits - 8;
            dst[d] = ((buf >> bits) & 255) as u8;
            buf = buf & ((1 << bits) - 1);
            d = d + 1;
        }
        i = i + 1;
    }
    return ERR_OK, -1;
}

// scan_b32 counts the characters of the text and finds the faults that
// the counts give.
fn scan_b32(src: const u8[:], opts: Options, kind: i64) -> Scan {
    var s = Scan { count: 0, first_bad: -1, first_pad: -1, pad_count: 0,
                   after_pad: -1, group_start: -1, last_data: -1 };
    var i: i64 = 0;
    while i < src.len {
        let c = src[i];
        if opts.skip_space && is_space(c) {
            i = i + 1;
            continue;
        }
        if c == '=' {
            if s.first_pad < 0 { s.first_pad = i; }
            s.pad_count = s.pad_count + 1;
            i = i + 1;
            continue;
        }
        if s.first_pad >= 0 {
            // A byte stands after the padding. The padding ends the text.
            if s.after_pad < 0 { s.after_pad = i; }
            i = i + 1;
            continue;
        }
        if s.count % GROUP_CHARS == 0 {
            // The character starts a group.
            s.group_start = i;
        }
        s.count = s.count + 1;
        s.last_data = i;
        if s.first_bad < 0 && b32_value(kind, c) == INVALID {
            s.first_bad = i;
        }
        i = i + 1;
    }
    return s;
}

// padding_fault gives the place of the fault of the padding. It gives
// -1 when the padding is right.
fn padding_fault(s: Scan, opts: Options) -> i64 {
    let tail = s.count % GROUP_CHARS;
    var required: i64 = 0;
    if tail != 0 { required = GROUP_CHARS - tail; }
    if s.after_pad >= 0 {
        // A byte stands after the padding.
        return s.after_pad;
    }
    if s.first_pad >= 0 {
        if s.pad_count != required { return s.first_pad; }
        return -1;
    }
    if opts.padding && required > 0 {
        // The padding is required and the text holds none.
        return s.last_data + 1;
    }
    return -1;
}
