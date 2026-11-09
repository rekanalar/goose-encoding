// encoding - the base32, base32hex, Crockford base32, hex, ASCII85, base85
// and Z85 codecs for Goose, and the streams that run them.
//
// The package writes bytes as text and reads text back to bytes.
// The decoders are strict. They give a code and the position of the
// first fault. A decoder never returns wrong bytes without an error.
//
// The rules of a codec stand in the options. The strict options read
// the canonical text of RFC 4648. The text options read the text that
// a person typed.
//
// The repository is goose-encoding. The import name is "encoding".
namespace encoding;

import std;
import errors;
import common;
import base32;
import hex;
import base85;
import stream;
