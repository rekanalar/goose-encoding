// The streaming encoders and decoders.
//
// A stream takes the bytes or the text in chunks of any size. It holds
// the part of a group that a chunk leaves open. It encodes or decodes
// each whole group with the codec of the package, so a stream gives the
// same result as one call on the joined chunks.
//
// The stream holds a carry of 256 bytes. The carry holds the open group
// of a text, with its white space and its padding. A group that needs
// more than 256 bytes of text is a fault.
namespace encoding;

// The codecs that a stream knows.
const STREAM_BASE32: i64 = 0;
const STREAM_BASE32HEX: i64 = 1;
const STREAM_CROCKFORD: i64 = 2;
const STREAM_CUSTOM32: i64 = 3;
const STREAM_HEX: i64 = 4;
const STREAM_ASCII85: i64 = 5;
const STREAM_BASE85: i64 = 6;
const STREAM_Z85: i64 = 7;

// The size of the carry.
const STREAM_CARRY: i64 = 256;

// The state of an encoder or a decoder.
struct Stream {
    codec: i64,
    opts: Options,
    decoding: bool,
    n: i64,          // the count of the bytes in the carry
    consumed: i64,   // the count of the bytes that the stream finished
    failed: i64,     // the code of the first fault, or ERR_OK
    fail_pos: i64,   // the place of the first fault
    carry: u8[256],
    alphabet: u8[32],
}

// stream_new builds a stream. The caller gives the codec.
fn stream_new(codec: i64, opts: Options, decoding: bool) -> Stream {
    return Stream { codec: codec, opts: opts, decoding: decoding, n: 0,
                    consumed: 0, failed: ERR_OK, fail_pos: -1, .. };
}

// encoder_new builds an encoder for a codec other than the custom one.
fn encoder_new(codec: i64, opts: Options) -> Stream {
    return stream_new(codec, opts, false);
}

// decoder_new builds a decoder for a codec other than the custom one.
fn decoder_new(codec: i64, opts: Options) -> Stream {
    return stream_new(codec, opts, true);
}

// custom32_encoder_new builds an encoder for an alphabet of 32 symbols.
// A bad alphabet makes every later call give ERR_BAD_ALPHABET.
fn custom32_encoder_new(alphabet: const u8[:], opts: Options) -> Stream {
    return custom_stream(alphabet, opts, false);
}

// custom32_decoder_new builds a decoder for an alphabet of 32 symbols.
fn custom32_decoder_new(alphabet: const u8[:], opts: Options) -> Stream {
    return custom_stream(alphabet, opts, true);
}

fn custom_stream(alphabet: const u8[:], opts: Options, decoding: bool) -> Stream {
    var s = stream_new(STREAM_CUSTOM32, opts, decoding);
    let code, pos = alphabet_fault(alphabet);
    if code != ERR_OK {
        s.failed = code;
        s.fail_pos = pos;
        return s;
    }
    var i: i64 = 0;
    while i < 32 {
        s.alphabet[i] = alphabet[i];
        i = i + 1;
    }
    return s;
}

// stream_group_bytes gives the count of the bytes of a group.
fn stream_group_bytes(codec: i64) -> i64 {
    if codec == STREAM_HEX { return 1; }
    if codec >= STREAM_ASCII85 { return B85_GROUP_BYTES; }
    return GROUP_BYTES;
}

// stream_group_chars gives the count of the characters of a group.
fn stream_group_chars(codec: i64) -> i64 {
    if codec == STREAM_HEX { return 2; }
    if codec >= STREAM_ASCII85 { return B85_GROUP_CHARS; }
    return GROUP_CHARS;
}

// stream_one_encode encodes bytes with the codec of the stream.
fn stream_one_encode(s: Stream, out: u8[>..]&, src: const u8[:]) -> i64, i64 {
    let c = s.codec;
    if c == STREAM_BASE32 { base32_encode(out, src, s.opts); }
    else if c == STREAM_BASE32HEX { base32hex_encode(out, src, s.opts); }
    else if c == STREAM_CROCKFORD { base32crockford_encode(out, src, s.opts); }
    else if c == STREAM_CUSTOM32 { return custom32_encode(out, src, s.alphabet[..], s.opts); }
    else if c == STREAM_HEX { hex_encode(out, src, s.opts); }
    else if c == STREAM_ASCII85 { ascii85_encode(out, src, s.opts); }
    else if c == STREAM_BASE85 { base85_encode(out, src, s.opts); }
    else { return z85_encode(out, src, s.opts); }
    return ERR_OK, -1;
}

// stream_one_decode decodes text with the codec of the stream.
fn stream_one_decode(s: Stream, out: u8[>..]&, src: const u8[:]) -> i64, i64 {
    let c = s.codec;
    if c == STREAM_BASE32 { return base32_decode(out, src, s.opts); }
    if c == STREAM_BASE32HEX { return base32hex_decode(out, src, s.opts); }
    if c == STREAM_CROCKFORD { return base32crockford_decode(out, src, s.opts); }
    if c == STREAM_CUSTOM32 { return custom32_decode(out, src, s.alphabet[..], s.opts); }
    if c == STREAM_HEX { return hex_decode(out, src, s.opts); }
    if c == STREAM_ASCII85 { return ascii85_decode(out, src, s.opts); }
    if c == STREAM_BASE85 { return base85_decode(out, src, s.opts); }
    return z85_decode(out, src, s.opts);
}

// stream_fail keeps the first fault of the stream and gives it.
fn stream_fail(s: Stream&, code: i64, pos: i64) -> i64, i64 {
    s.failed = code;
    s.fail_pos = pos;
    return code, pos;
}

// b85_digit tells whether a byte is a digit of the base85 family codec.
fn b85_digit(s: Stream, c: u8) -> bool {
    var kind: i64 = ALPHA_ASCII85;
    if s.codec == STREAM_BASE85 { kind = ALPHA_BASE85; }
    if s.codec == STREAM_Z85 { kind = ALPHA_Z85; }
    return b85_value(kind, c) != INVALID;
}

// stream_cut gives the length of the longest prefix of the text that
// holds whole groups. It stops at the padding. White space that follows
// a whole group belongs to the prefix.
fn stream_cut(s: Stream, text: const u8[:]) -> i64 {
    let chars = stream_group_chars(s.codec);
    let padded = s.codec <= STREAM_CUSTOM32 && s.codec != STREAM_CROCKFORD;
    var skip_kind: i64 = ALPHA_BASE32;
    if s.codec == STREAM_CROCKFORD { skip_kind = ALPHA_CROCKFORD; }
    var in_group: i64 = 0;
    var cut: i64 = 0;
    var i: i64 = 0;
    while i < text.len {
        let c = text[i];
        if padded && c == '=' { break; }
        if b32_skips(skip_kind, s.opts, c) {
            i = i + 1;
            if in_group == 0 { cut = i; }
            continue;
        }
        i = i + 1;
        if s.codec == STREAM_ASCII85 && c == 'z' {
            // The shortcut is a whole group. In the middle of a group it
            // is a bad byte, which the decoder does not count.
            if in_group == 0 { cut = i; }
            continue;
        }
        if s.codec >= STREAM_ASCII85 && !b85_digit(s, c) {
            // The base85 decoder does not count a byte that is not a digit.
            continue;
        }
        in_group = in_group + 1;
        if in_group == chars {
            in_group = 0;
            cut = i;
        }
    }
    return cut;
}

// stream_has_pad tells whether the carry holds the padding.
fn stream_has_pad(s: Stream) -> bool {
    var i: i64 = 0;
    while i < s.n {
        if s.carry[i] == '=' { return true; }
        i = i + 1;
    }
    return false;
}

// stream_write gives a chunk to the stream. It writes the bytes or the
// text of the whole groups into the buffer of the caller. It gives a code
// and a position. The position counts the bytes of the text from the
// start of the stream. A fault leaves the buffer as it was before the
// call, and every later call gives the same fault.
fn stream_write(s: Stream&, out: u8[>..]&, chunk: const u8[:]) -> i64, i64 {
    if s.failed != ERR_OK { return s.failed, s.fail_pos; }
    if s.decoding { return stream_write_text(s, out, chunk); }
    let g = stream_group_bytes(s.codec);
    let start = out.len;
    var off: i64 = 0;
    // Close the open group first.
    while s.n > 0 && s.n < g && off < chunk.len {
        s.carry[s.n] = chunk[off];
        s.n = s.n + 1;
        off = off + 1;
    }
    if s.n == g {
        let code, pos = stream_one_encode(s, out, s.carry[..g]);
        if code != ERR_OK { out.resize(start); return stream_fail(s, code, s.consumed + pos); }
        s.consumed = s.consumed + g;
        s.n = 0;
    }
    // Encode the whole groups of the chunk.
    let whole = ((chunk.len - off) / g) * g;
    if whole > 0 {
        let code, pos = stream_one_encode(s, out, chunk[off..off + whole]);
        if code != ERR_OK { out.resize(start); return stream_fail(s, code, s.consumed + pos); }
        s.consumed = s.consumed + whole;
        off = off + whole;
    }
    // Keep the open group.
    while off < chunk.len {
        s.carry[s.n] = chunk[off];
        s.n = s.n + 1;
        off = off + 1;
    }
    return ERR_OK, -1;
}

fn stream_write_text(s: Stream&, out: u8[>..]&, chunk: const u8[:]) -> i64, i64 {
    let start = out.len;
    var off: i64 = 0;
    while off < chunk.len {
        var take = STREAM_CARRY - s.n;
        if take > chunk.len - off { take = chunk.len - off; }
        var k: i64 = 0;
        while k < take {
            s.carry[s.n + k] = chunk[off + k];
            k = k + 1;
        }
        s.n = s.n + take;
        off = off + take;
        let cut = stream_cut(s, s.carry[..s.n]);
        if cut > 0 {
            let code, pos = stream_one_decode(s, out, s.carry[..cut]);
            if code != ERR_OK { out.resize(start); return stream_fail(s, code, s.consumed + pos); }
            s.consumed = s.consumed + cut;
            var j: i64 = 0;
            while j < s.n - cut {
                s.carry[j] = s.carry[cut + j];
                j = j + 1;
            }
            s.n = s.n - cut;
        } else if s.n == STREAM_CARRY {
            // One group needs more text than the carry holds. A bad byte or
            // a bad padding in the carry is the fault. Otherwise the
            // group is too long.
            let code, pos = stream_one_decode(s, out, s.carry[..s.n]);
            out.resize(start);
            if code == ERR_INVALID_CHAR || (code == ERR_BAD_PADDING && stream_has_pad(s)) {
                return stream_fail(s, code, s.consumed + pos);
            }
            return stream_fail(s, ERR_BAD_LENGTH, s.consumed);
        }
    }
    return ERR_OK, -1;
}

// stream_finish ends the stream. It handles the open group: the tail of
// the bytes, or the last group of the text with its padding. It gives a
// code and a position. After the call the stream is empty and the caller
// can use it again.
fn stream_finish(s: Stream&, out: u8[>..]&) -> i64, i64 {
    if s.failed != ERR_OK { return s.failed, s.fail_pos; }
    var code: i64 = ERR_OK;
    var pos: i64 = -1;
    if s.n > 0 {
        let start = out.len;
        if s.decoding {
            code, pos = stream_one_decode(s, out, s.carry[..s.n]);
        } else {
            code, pos = stream_one_encode(s, out, s.carry[..s.n]);
        }
        if code != ERR_OK {
            out.resize(start);
            return stream_fail(s, code, s.consumed + pos);
        }
    }
    s.n = 0;
    s.consumed = 0;
    return ERR_OK, -1;
}
