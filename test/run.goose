// Tests of the package. Run them all with: goose run test/run.goose
// The program must start in the package directory.

import std;
import encoding from "..";
import base_tests;
import ascii85_tests;
import z85_tests;
import alphabets_tests;
import streams_tests;
import options_more_tests;
import encoding_checks;
import os;

fn main() {
    base_tests::test_encode();
    base_tests::test_decode();
    base_tests::test_round_trip();
    base_tests::test_faults();
    base_tests::test_options();
    base_tests::test_hostile();
    ascii85_tests::test_encode85();
    ascii85_tests::test_decode85();
    ascii85_tests::test_faults85();
    ascii85_tests::test_options85();
    ascii85_tests::test_round_trip85();
    ascii85_tests::test_hostile85();
    z85_tests::test_z85();
    alphabets_tests::test_alphabets();
    streams_tests::test_streams();
    options_more_tests::test_options_more();
    print("all tests passed");
    return 0;
}
