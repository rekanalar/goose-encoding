// The hex codec.
//
// Two characters hold one byte. The letters of the alphabet are upper
// case unless the options ask for the lower case. The decoder takes
// either case.
//
// The hex codec has no padding. A text of an odd count of characters
// is a fault of the length.
namespace encoding;

// hex_symbol gives the character of a value of 4 bits.
fn hex_symbol(v: u8, lower: bool) -> u8 {
    var c: u8 = '0';
    if v >= 10 {
        c = 'A' + (v - 10);
        if lower { c = c + 32; }
    } else {
        c = '0' + v;
    }
    return c;
}

// hex_value gives the value of a character of the alphabet. It gives
// INVALID for a byte that is not in the alphabet.
fn hex_value(c: u8) -> u32 {
    if c - '0' < 10 { return c - '0'; }
    if c - 'A' < 6 { return 10 + (c - 'A'); }
    if c - 'a' < 6 { return 10 + (c - 'a'); }
    return INVALID;
}

// hex_encode writes the hex text of the bytes into the buffer of the
// caller.
fn hex_encode(out: u8[>..]&, src: const u8[:], opts: Options) {
    let start = out.len;
    out.resize(start + src.len * 2, 0);
    let dst = out[start..];
    var d: i64 = 0;
    var i: i64 = 0;
    while i < src.len {
        dst[d] = hex_symbol(src[i] >> 4, opts.lower);
        dst[d + 1] = hex_symbol(src[i] & 15, opts.lower);
        d = d + 2;
        i = i + 1;
    }
}

// hex_decode reads the hex text into the buffer of the caller. It gives
// a code and a position. It leaves the buffer as it was when it finds a
// fault.
fn hex_decode(out: u8[>..]&, src: const u8[:], opts: Options) -> i64, i64 {
    let start = out.len;

    // The first pass counts the characters and finds the faults.
    var count: i64 = 0;
    var end: i64 = 0;
    var first_bad: i64 = -1;
    var i: i64 = 0;
    while i < src.len {
        let c = src[i];
        if opts.skip_space && is_space(c) {
            i = i + 1;
            continue;
        }
        if first_bad < 0 && hex_value(c) == INVALID {
            first_bad = i;
        }
        count = count + 1;
        end = i + 1;
        i = i + 1;
    }

    var code: i64 = ERR_OK;
    var pos: i64 = -1;
    if first_bad >= 0 {
        code = ERR_INVALID_CHAR;
        pos = first_bad;
    }
    if count % 2 != 0 {
        // The place stands just after the last character of the data.
        if pos < 0 || end < pos {
            code = ERR_BAD_LENGTH;
            pos = end;
        }
    }
    if code != ERR_OK {
        return code, pos;
    }

    // The second pass writes the bytes.
    out.resize(start + count / 2, 0);
    let dst = out[start..];
    var d: i64 = 0;
    var high: u32 = 0;
    var odd = false;
    i = 0;
    while i < src.len {
        let c = src[i];
        if opts.skip_space && is_space(c) {
            i = i + 1;
            continue;
        }
        if odd {
            dst[d] = ((high << 4) | hex_value(c)) as u8;
            d = d + 1;
            odd = false;
        } else {
            high = hex_value(c);
            odd = true;
        }
        i = i + 1;
    }
    return ERR_OK, -1;
}
