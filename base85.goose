// The ASCII85 codec and the base85 codec of RFC 1924.
//
// A group holds 5 characters for 4 bytes. A tail holds 2, 3 or 4
// characters for 1, 2 or 3 bytes.
//
// The value of a group is held in 64 bits. Five characters of base85
// hold 85 to the power of 5. That number is larger than 2 to the power
// of 32, so a group can hold a value that no four bytes hold. The
// decoder refuses such a group.
//
// The tail of a text must be the tail of the bytes it decodes to. The
// libraries of the references take any tail. One payload then has many
// spellings. This package takes one.
//
// The decoder reads the text in two passes. The first pass counts the
// characters and finds the faults. The second pass writes the bytes.
// The decoder reports the fault with the smallest position. The tail is
// checked only when the text holds no other fault.
namespace encoding;

// The kind of the alphabet of ASCII85.
const ALPHA_ASCII85: i64 = 0;

// The kind of the alphabet of RFC 1924.
const ALPHA_BASE85: i64 = 1;

// The count of the characters of a group.
const B85_GROUP_CHARS: i64 = 5;

// The count of the bytes of a group.
const B85_GROUP_BYTES: i64 = 4;

// The value of a group must stay under this limit. It is 2 to the power
// of 32.
const B85_LIMIT: i64 = 4294967296;

// The powers of 85.
const B85_P1: i64 = 85;
const B85_P2: i64 = 7225;
const B85_P3: i64 = 614125;
const B85_P4: i64 = 52200625;

// The 23 characters of RFC 1924 that no range holds. The value of such
// a character is 62 plus its place in this list.
const B85_PUNCT: const u8[:] = "!#$%&()*+-;<=>?@^_`{|}~";

// b85_pow gives 85 to the power of n. The power runs from 0 to 5.
fn b85_pow(n: i64) -> i64 {
    if n <= 0 { return 1; }
    if n == 1 { return B85_P1; }
    if n == 2 { return B85_P2; }
    if n == 3 { return B85_P3; }
    if n == 4 { return B85_P4; }
    return 4437053125;
}

// b85_has_shortcut tells whether the codec holds the shortcut z. Only
// ASCII85 holds it. The shortcut stands for four zero bytes.
fn b85_has_shortcut(kind: i64) -> bool {
    return kind == ALPHA_ASCII85;
}

// b85_is_shortcut tells whether the character is the shortcut of the
// codec.
fn b85_is_shortcut(kind: i64, c: u8) -> bool {
    return b85_has_shortcut(kind) && c == 'z';
}

// b85_symbol gives the character of a value of 0 to 84.
fn b85_symbol(kind: i64, v: u8) -> u8 {
    if kind == ALPHA_BASE85 {
        if v < 10 { return '0' + v; }
        if v < 36 { return 'A' + (v - 10); }
        if v < 62 { return 'a' + (v - 36); }
        return B85_PUNCT[v - 62];
    }
    return '!' + v;
}

// b85_value gives the value of a character of the alphabet. It gives
// INVALID for a byte that is not in the alphabet.
fn b85_value(kind: i64, c: u8) -> u32 {
    if kind == ALPHA_BASE85 {
        if c - '0' < 10 { return c - '0'; }
        if c - 'A' < 26 { return 10 + (c - 'A'); }
        if c - 'a' < 26 { return 36 + (c - 'a'); }
        var i: i64 = 0;
        while i < B85_PUNCT.len {
            if B85_PUNCT[i] == c { return (62 + i) as u32; }
            i = i + 1;
        }
        return INVALID;
    }
    if c - '!' < 85 { return c - '!'; }
    return INVALID;
}

// ascii85_encode writes the ASCII85 text of the bytes into the buffer of
// the caller.
fn ascii85_encode(out: u8[>..]&, src: const u8[:], opts: Options) {
    encode_b85(out, src, opts, ALPHA_ASCII85);
}

// base85_encode writes the base85 text of RFC 1924 of the bytes into the
// buffer of the caller.
fn base85_encode(out: u8[>..]&, src: const u8[:], opts: Options) {
    encode_b85(out, src, opts, ALPHA_BASE85);
}

// encode_b85 writes the text of the bytes into the buffer of the caller.
// It adds its text to the bytes that the buffer holds.
//
// A group holds 4 bytes. The bytes stand at the top of the value of the
// group and the rest of the value holds zeros. The text of a group holds
// 5 characters. The text of a tail holds 1 more character than the tail
// holds bytes.
//
// The shortcut z stands for four zero bytes. It holds 1 character where
// a group holds 5. The size of the text depends on the bytes, so the
// encoder counts the groups of zero bytes before it writes.
fn encode_b85(out: u8[>..]&, src: const u8[:], opts: Options, kind: i64) {
    let start = out.len;
    let full = src.len / B85_GROUP_BYTES;
    let rest = src.len % B85_GROUP_BYTES;
    var zeros: i64 = 0;
    if b85_has_shortcut(kind) {
        var z: i64 = 0;
        while z + B85_GROUP_BYTES <= src.len {
            if b85_word(src, z, B85_GROUP_BYTES) == 0 { zeros = zeros + 1; }
            z = z + B85_GROUP_BYTES;
        }
    }
    var chars = (full - zeros) * B85_GROUP_CHARS + zeros;
    if rest > 0 { chars = chars + rest + 1; }
    out.resize(start + chars, 0);
    let dst = out[start..];
    var d: i64 = 0;
    var i: i64 = 0;
    while i < src.len {
        var n = src.len - i;
        if n > B85_GROUP_BYTES { n = B85_GROUP_BYTES; }
        let v = b85_word(src, i, n);
        if n == B85_GROUP_BYTES && v == 0 && b85_has_shortcut(kind) {
            dst[d] = 'z';
            d = d + 1;
        } else {
            var p: i64 = B85_P4;
            var j: i64 = 0;
            while j < n + 1 {
                dst[d] = b85_symbol(kind, ((v / p) % 85) as u8);
                p = p / 85;
                d = d + 1;
                j = j + 1;
            }
        }
        i = i + n;
    }
}

// b85_word gives the value of n bytes of the source. The bytes stand at
// the top of the value and the rest of the value holds zeros.
fn b85_word(src: const u8[:], i: i64, n: i64) -> i64 {
    var v: i64 = 0;
    var j: i64 = 0;
    while j < n {
        v = (v << 8) + src[i + j];
        j = j + 1;
    }
    var k: i64 = n;
    while k < B85_GROUP_BYTES {
        v = v << 8;
        k = k + 1;
    }
    return v;
}

// What the first pass of the decoder finds.
struct Scan85 {
    digits: i64,     // the count of the characters of the data
    zeros: i64,      // the count of the shortcut z
    first_bad: i64,  // the index of the first byte outside the alphabet
    group_start: i64,// the index of the first character of the last group
    tail_len: i64,   // the count of the characters of the last group
    last_data: i64,  // the index of the last character of the data
    overflow: i64,   // the index of the first character of a group that overflows
    value: i64,      // the value of the characters of the last group
}

// ascii85_decode reads the ASCII85 text into the buffer of the caller.
// It gives a code and a position.
fn ascii85_decode(out: u8[>..]&, src: const u8[:], opts: Options) -> i64, i64 {
    return decode_b85(out, src, opts, ALPHA_ASCII85);
}

// base85_decode reads the base85 text of RFC 1924 into the buffer of the
// caller. It gives a code and a position.
fn base85_decode(out: u8[>..]&, src: const u8[:], opts: Options) -> i64, i64 {
    return decode_b85(out, src, opts, ALPHA_BASE85);
}

// decode_b85 reads the text into the buffer of the caller. It gives a
// code and a position. It leaves the buffer as it was when it finds a
// fault.
fn decode_b85(out: u8[>..]&, src: const u8[:], opts: Options, kind: i64) -> i64, i64 {
    let start = out.len;
    let s = scan_b85(src, opts, kind);

    var code: i64 = ERR_OK;
    var pos: i64 = -1;

    // A byte outside the alphabet.
    if s.first_bad >= 0 {
        code = ERR_INVALID_CHAR;
        pos = s.first_bad;
    }

    // A tail of 1 character holds no byte. The check of the length runs
    // before the check of the overflow. A tail of 1 character can carry
    // both faults at the same position.
    if s.tail_len == 1 {
        if pos < 0 || s.group_start < pos {
            code = ERR_BAD_LENGTH;
            pos = s.group_start;
        }
    }

    // A group whose value is 2 to the power of 32 or more holds no four
    // bytes.
    if s.overflow >= 0 {
        if pos < 0 || s.overflow < pos {
            code = ERR_OVERFLOW;
            pos = s.overflow;
        }
    }

    if code != ERR_OK {
        return code, pos;
    }

    // The tail must be the tail of the bytes it decodes to. The check
    // runs before the write, so a fault leaves the buffer of the caller
    // as it was. The check runs only when the text holds no other fault,
    // because the tail of a broken text means nothing.
    var word: i64 = 0;
    if s.tail_len > 0 {
        word = b85_tail_word(s.value, s.tail_len);
        if word / b85_pow(5 - s.tail_len) != s.value {
            return ERR_NON_CANONICAL, s.last_data;
        }
    }

    // The second pass writes the bytes.
    let groups = (s.digits - s.tail_len) / B85_GROUP_CHARS;
    var bytes = (groups + s.zeros) * B85_GROUP_BYTES;
    if s.tail_len > 0 { bytes = bytes + s.tail_len - 1; }
    out.resize(start + bytes, 0);
    let dst = out[start..];
    var d: i64 = 0;
    var i: i64 = 0;
    var in_group: i64 = 0;
    var value: i64 = 0;
    while i < src.len {
        let c = src[i];
        if opts.skip_space && is_space(c) {
            i = i + 1;
            continue;
        }
        if b85_is_shortcut(kind, c) {
            // The shortcut z stands for four zero bytes.
            dst[d] = 0;
            dst[d + 1] = 0;
            dst[d + 2] = 0;
            dst[d + 3] = 0;
            d = d + B85_GROUP_BYTES;
            in_group = 0;
            value = 0;
            i = i + 1;
            continue;
        }
        value = value * 85 + b85_value(kind, c);
        in_group = in_group + 1;
        if in_group == B85_GROUP_CHARS {
            dst[d] = ((value >> 24) & 255) as u8;
            dst[d + 1] = ((value >> 16) & 255) as u8;
            dst[d + 2] = ((value >> 8) & 255) as u8;
            dst[d + 3] = (value & 255) as u8;
            d = d + B85_GROUP_BYTES;
            in_group = 0;
            value = 0;
        }
        i = i + 1;
    }
    if s.tail_len > 0 {
        // The bytes of the tail stand at the top of the word.
        var j: i64 = 0;
        while j < s.tail_len - 1 {
            dst[d] = ((word >> (24 - 8 * j)) & 255) as u8;
            d = d + 1;
            j = j + 1;
        }
    }
    return ERR_OK, -1;
}

// b85_tail_full gives the value of the tail. The missing digits of the
// group take the largest digit.
fn b85_tail_full(value: i64, len: i64) -> i64 {
    let span = b85_pow(5 - len);
    return value * span + (span - 1);
}

// b85_tail_word gives the word of the tail. The bytes of the tail stand
// at the top of the word.
fn b85_tail_word(value: i64, len: i64) -> i64 {
    let full = b85_tail_full(value, len);
    let shift = 8 * (5 - len);
    return (full >> shift) << shift;
}

// scan_b85 counts the characters of the text and finds the faults that
// the counts give.
fn scan_b85(src: const u8[:], opts: Options, kind: i64) -> Scan85 {
    var s = Scan85 { digits: 0, zeros: 0, first_bad: -1, group_start: -1,
                     tail_len: 0, last_data: -1, overflow: -1, value: 0 };
    var i: i64 = 0;
    var in_group: i64 = 0;
    var value: i64 = 0;
    var start: i64 = -1;
    while i < src.len {
        let c = src[i];
        if opts.skip_space && is_space(c) {
            i = i + 1;
            continue;
        }
        if b85_is_shortcut(kind, c) {
            if in_group != 0 {
                // The shortcut z stands in the middle of a group.
                if s.first_bad < 0 { s.first_bad = i; }
                i = i + 1;
                continue;
            }
            // The shortcut z stands for four zero bytes. It is a whole
            // group.
            s.zeros = s.zeros + 1;
            s.last_data = i;
            start = i;
            i = i + 1;
            continue;
        }
        let v = b85_value(kind, c);
        if v == INVALID {
            if s.first_bad < 0 { s.first_bad = i; }
            i = i + 1;
            continue;
        }
        if in_group == 0 { start = i; }
        value = value * 85 + v;
        in_group = in_group + 1;
        s.digits = s.digits + 1;
        s.last_data = i;
        if in_group == B85_GROUP_CHARS {
            if value >= B85_LIMIT && s.overflow < 0 { s.overflow = start; }
            in_group = 0;
            value = 0;
        }
        i = i + 1;
    }
    // The last group is a tail. Its value takes the missing digits to be
    // the largest digit.
    s.group_start = start;
    s.tail_len = in_group;
    s.value = value;
    if in_group > 0 {
        if b85_tail_full(value, in_group) >= B85_LIMIT && s.overflow < 0 {
            s.overflow = start;
        }
    }
    return s;
}
