// The error codes of the encoding package.
//
// Every call that can fail gives a code. The code ERR_OK means that
// the call succeeded. The other codes name the fault.
//
// The decoder of a text gives a code and a position. The position
// counts the bytes of the text from zero.
namespace encoding;

// The code of a call that succeeded.
const ERR_OK: i64 = 0;

// A byte is not in the alphabet of the codec.
const ERR_INVALID_CHAR: i64 = 1;

// The text holds a length that no group of the codec can hold.
const ERR_BAD_LENGTH: i64 = 2;

// The padding is missing, too short, too long or stands in the middle
// of the text.
const ERR_BAD_PADDING: i64 = 3;

// The last group of a base32 text holds bits that are not zero. The last
// group of a base85 text is not the tail of its own bytes.
const ERR_NON_CANONICAL: i64 = 4;

// A group of a base85 text holds a value that is larger than 2 to the
// power of 32. No four bytes hold that value.
const ERR_OVERFLOW: i64 = 5;

// error_text gives the name of an error code. It gives the name of
// ERR_OK for a code that the package does not hold.
fn error_text(code: i64) -> u8[:] {
    if code == ERR_OK { return "ERR_OK"; }
    if code == ERR_INVALID_CHAR { return "ERR_INVALID_CHAR"; }
    if code == ERR_BAD_LENGTH { return "ERR_BAD_LENGTH"; }
    if code == ERR_BAD_PADDING { return "ERR_BAD_PADDING"; }
    if code == ERR_NON_CANONICAL { return "ERR_NON_CANONICAL"; }
    if code == ERR_OVERFLOW { return "ERR_OVERFLOW"; }
    return "ERR_OK";
}
