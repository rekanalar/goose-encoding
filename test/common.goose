// The helpers that the tests of more than one group share.
namespace common;

import std;
import os;
import encoding from "..";

// check_b32 holds the base32 text of the bytes.
fn check_b32(src: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    encoding::base32_encode(out, src, encoding::strict_options());
    assert(out == want);
}

// check_b32hex holds the base32hex text of the bytes.
fn check_b32hex(src: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    encoding::base32hex_encode(out, src, encoding::strict_options());
    assert(out == want);
}

// check_hex holds the hex text of the bytes.
fn check_hex(src: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    encoding::hex_encode(out, src, encoding::strict_options());
    assert(out == want);
}

// check_a85 holds the ASCII85 text of the bytes.
fn check_a85(src: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    encoding::ascii85_encode(out, src, encoding::strict_options());
    assert(out == want);
}

// check_b85 holds the base85 text of the bytes.
fn check_b85(src: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    encoding::base85_encode(out, src, encoding::strict_options());
    assert(out == want);
}

// check_read_a85 holds the bytes of the ASCII85 text.
fn check_read_a85(text: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    let code, pos = encoding::ascii85_decode(out, text, encoding::strict_options());
    assert(code == encoding::ERR_OK);
    assert(pos == -1);
    assert(out == want);
}

// check_read_b85 holds the bytes of the base85 text.
fn check_read_b85(text: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    let code, pos = encoding::base85_decode(out, text, encoding::strict_options());
    assert(code == encoding::ERR_OK);
    assert(pos == -1);
    assert(out == want);
}

// check_read holds the bytes of the base32 text.
fn check_read(text: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    let code, pos = encoding::base32_decode(out, text, encoding::strict_options());
    assert(code == encoding::ERR_OK);
    assert(pos == -1);
    assert(out == want);
}

// probe_symbol gives the character of a value of 5 bits in the
// alphabet of base32.
fn probe_symbol(v: i64) -> u8 {
    if v < 26 { return ('A' + v) as u8; }
    return ('2' + (v - 26)) as u8;
}

// stream_encode runs an encoder over the bytes in chunks of a given size.
fn stream_encode(codec: i64, src: const u8[:], chunk: i64, opts: encoding::Options, out: u8[>..]&) -> i64, i64 {
    var s = encoding::encoder_new(codec, opts);
    var off: i64 = 0;
    while off < src.len {
        var end = off + chunk;
        if end > src.len { end = src.len; }
        let code, pos = encoding::stream_write(s, out, src[off..end]);
        if code != encoding::ERR_OK { return code, pos; }
        off = end;
    }
    return encoding::stream_finish(s, out);
}

// stream_decode runs a decoder over the text in chunks of a given size.
fn stream_decode(codec: i64, src: const u8[:], chunk: i64, opts: encoding::Options, out: u8[>..]&) -> i64, i64 {
    var s = encoding::decoder_new(codec, opts);
    var off: i64 = 0;
    while off < src.len {
        var end = off + chunk;
        if end > src.len { end = src.len; }
        let code, pos = encoding::stream_write(s, out, src[off..end]);
        if code != encoding::ERR_OK { return code, pos; }
        off = end;
    }
    return encoding::stream_finish(s, out);
}

// one_encode runs the call of the package that matches a stream codec.
fn one_encode(codec: i64, src: const u8[:], opts: encoding::Options, out: u8[>..]&) -> i64 {
    if codec == encoding::STREAM_BASE32 { encoding::base32_encode(out, src, opts); }
    else if codec == encoding::STREAM_BASE32HEX { encoding::base32hex_encode(out, src, opts); }
    else if codec == encoding::STREAM_CROCKFORD { encoding::base32crockford_encode(out, src, opts); }
    else if codec == encoding::STREAM_HEX { encoding::hex_encode(out, src, opts); }
    else if codec == encoding::STREAM_ASCII85 { encoding::ascii85_encode(out, src, opts); }
    else if codec == encoding::STREAM_BASE85 { encoding::base85_encode(out, src, opts); }
    else {
        let code, pos = encoding::z85_encode(out, src, opts);
        return code;
    }
    return encoding::ERR_OK;
}

// one_decode runs the call of the package that matches a stream codec.
fn one_decode(codec: i64, src: const u8[:], opts: encoding::Options, out: u8[>..]&) -> i64, i64 {
    if codec == encoding::STREAM_BASE32 { return encoding::base32_decode(out, src, opts); }
    if codec == encoding::STREAM_BASE32HEX { return encoding::base32hex_decode(out, src, opts); }
    if codec == encoding::STREAM_CROCKFORD { return encoding::base32crockford_decode(out, src, opts); }
    if codec == encoding::STREAM_HEX { return encoding::hex_decode(out, src, opts); }
    if codec == encoding::STREAM_ASCII85 { return encoding::ascii85_decode(out, src, opts); }
    if codec == encoding::STREAM_BASE85 { return encoding::base85_decode(out, src, opts); }
    return encoding::z85_decode(out, src, opts);
}

// test_options_more pins the separator, the line width, the frame of
// Adobe and the exact case.
fn ad_opts(width: i64) -> encoding::Options {
    var o = encoding::strict_options();
    o.adobe = true;
    o.wrap = width;
    return o;
}
