// The tests of the group streams.
namespace streams_tests;

import std;
import os;
import encoding from "..";
import common;

const MEGABYTE: i64 = 1000000;

// test_streams proves that a stream gives the result of one call, for
// every codec, every length and several chunk sizes.
fn test_streams() {
    let strict = encoding::strict_options();
    var codec: i64 = 0;
    while codec <= encoding::STREAM_Z85 {
        if codec == encoding::STREAM_CUSTOM32 { codec = codec + 1; continue; }
        var n: i64 = 0;
        while n <= 60 {
            var src: u8[>..] = [];
            var k: i64 = 0;
            while k < n { src.push(((k * 71 + 5) % 256) as u8); k = k + 1; }
            if n > 8 { src[3] = 0; src[4] = 0; src[5] = 0; src[6] = 0; }
            var chunk: i64 = 1;
            while chunk <= 13 {
                var want: u8[>..] = [];
                let wc = common::one_encode(codec, src, strict, want);
                var got: u8[>..] = [];
                let gc, gp = common::stream_encode(codec, src, chunk, strict, got);
                if wc == encoding::ERR_OK {
                    assert(gc == encoding::ERR_OK);
                    assert(got == want);
                    // The text reads back through a stream too.
                    var back: u8[>..] = [];
                    let dc, dp = common::stream_decode(codec, want, chunk, strict, back);
                    assert(dc == encoding::ERR_OK);
                    assert(back == src);
                } else {
                    // Z85 refuses a length that is not a multiple of 4.
                    assert(gc == wc);
                    assert(got.len == (src.len / 4) * 5);
                }
                chunk = chunk + 3;
            }
            n = n + 1;
        }
        codec = codec + 1;
    }

    // A fault gives the place of the one-shot call and keeps the buffer.
    var out: u8[>..] = [9];
    let c1, p1 = common::stream_decode(encoding::STREAM_BASE32, "MZXW6YTBOI======MZXW", 3, strict, out);
    var o2: u8[>..] = [9];
    let c2, p2 = encoding::base32_decode(o2, "MZXW6YTBOI======MZXW", strict);
    assert(c1 == c2 && p1 == p2);
    assert(c1 == encoding::ERR_BAD_PADDING);
    var o3: u8[>..] = [];
    let c3, p3 = common::stream_decode(encoding::STREAM_Z85, "HelloWorld%nSc0##", 4, strict, o3);
    assert(c3 == encoding::ERR_BAD_LENGTH && p3 == 15);
    var o4: u8[>..] = [];
    let c4, p4 = common::stream_decode(encoding::STREAM_Z85, "HelloWorld#####%nSc0", 2, strict, o4);
    assert(c4 == encoding::ERR_OVERFLOW && p4 == 10);
    assert(o4.len == 8);
    var o5: u8[>..] = [];
    let c5, p5 = common::stream_decode(encoding::STREAM_ASCII85, "zz!!!!!zA", 1, strict, o5);
    assert(c5 == encoding::ERR_BAD_LENGTH);

    // A bad byte inside a group gives the fault of one call.
    var o13: u8[>..] = [];
    let c13a, p13a = common::stream_decode(encoding::STREAM_ASCII85, "azzzzbcde", 9, strict, o13);
    var o14: u8[>..] = [];
    let c13b, p13b = encoding::ascii85_decode(o14, "azzzzbcde", strict);
    assert(c13a == c13b && p13a == p13b && c13a == encoding::ERR_INVALID_CHAR && p13a == 1);
    let c13c, p13c = common::stream_decode(encoding::STREAM_BASE85, "a,,,,bcde", 1, strict, o13);
    assert(c13c == encoding::ERR_INVALID_CHAR && p13c == 1);
    // A long padding gives the fault of one call.
    var eq: u8[>..] = [];
    eq.resize(300, '=');
    let c13d, p13d = common::stream_decode(encoding::STREAM_BASE32, eq, 40, strict, o13);
    assert(c13d == encoding::ERR_BAD_PADDING && p13d == 0);

    // Hostile texts give the code and the position of one call, for every
    // chunk size.
    let bad_texts: const u8[:][10] = ["azzzzbcde", "a,,,,bcde", "uuuuu", "#####abcd", "Ac", "A", "MZXW6YTB=", "MZXW6YTBOI======X", "0g", "abcde~"];
    var bt: i64 = 0;
    while bt < 10 {
        var cdc: i64 = 0;
        while cdc <= encoding::STREAM_Z85 {
            if cdc != encoding::STREAM_CUSTOM32 {
                var ch: i64 = 1;
                while ch <= 7 {
                    var ref: u8[>..] = [];
                    let rc, rp = common::one_decode(cdc, bad_texts[bt], strict, ref);
                    var got: u8[>..] = [];
                    let gc, gp = common::stream_decode(cdc, bad_texts[bt], ch, strict, got);
                    assert(gc == rc && gp == rp);
                    ch = ch + 2;
                }
            }
            cdc = cdc + 1;
        }
        bt = bt + 1;
    }

    // The fault is sticky.
    var s = encoding::decoder_new(encoding::STREAM_HEX, strict);
    var o6: u8[>..] = [];
    let c6, p6 = encoding::stream_write(s, o6, "0g");
    assert(c6 == encoding::ERR_INVALID_CHAR && p6 == 1);
    let c7, p7 = encoding::stream_write(s, o6, "00");
    assert(c7 == encoding::ERR_INVALID_CHAR && p7 == 1 && o6.len == 0);

    // The white space and the padding across chunks.
    let text = encoding::text_options();
    var o8: u8[>..] = [];
    let c8, p8 = common::stream_decode(encoding::STREAM_BASE32, "MZXW 6YTB OI== ====", 1, text, o8);
    assert(c8 == encoding::ERR_OK && o8 == "foobar");

    // A custom alphabet.
    var cs = encoding::custom32_encoder_new("0123456789abcdefghijklmnopqrstuv", strict);
    var o9: u8[>..] = [];
    encoding::stream_write(cs, o9, "foo");
    encoding::stream_write(cs, o9, "bar");
    let c9, p9 = encoding::stream_finish(cs, o9);
    var o10: u8[>..] = [];
    encoding::custom32_encode(o10, "foobar", "0123456789abcdefghijklmnopqrstuv", strict);
    assert(c9 == encoding::ERR_OK && o9 == o10);
    var bad = encoding::custom32_decoder_new("aaaa", strict);
    let c10, p10 = encoding::stream_write(bad, o9, "abc");
    assert(c10 == encoding::ERR_BAD_ALPHABET && p10 == 0);

    // A stream is reusable after finish.
    var rs = encoding::encoder_new(encoding::STREAM_HEX, strict);
    var o11: u8[>..] = [];
    encoding::stream_write(rs, o11, "ab");
    encoding::stream_finish(rs, o11);
    encoding::stream_write(rs, o11, "cd");
    encoding::stream_finish(rs, o11);
    assert(o11 == "61626364");

    // A group with more white space than the carry holds is a fault.
    var many: u8[>..] = [];
    many.push('A');
    many.resize(300, ' ');
    var o12: u8[>..] = [];
    let c12, p12 = common::stream_decode(encoding::STREAM_BASE32, many, 50, text, o12);
    assert(c12 == encoding::ERR_BAD_LENGTH && o12.len == 0);

    // A megabyte in chunks of 1000 bytes.
    var big: u8[>..] = [];
    big.resize(MEGABYTE, 'A');
    var enc: u8[>..] = [];
    let start = clock();
    let c13, p13 = common::stream_encode(encoding::STREAM_BASE85, big, 1000, strict, enc);
    var dec: u8[>..] = [];
    let c14, p14 = common::stream_decode(encoding::STREAM_BASE85, enc, 1000, strict, dec);
    assert(c13 == encoding::ERR_OK && c14 == encoding::ERR_OK && dec == big);
    assert(clock() - start < 5.0);
}
