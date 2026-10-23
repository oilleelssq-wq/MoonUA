///|
/// Errors raised while decoding OPC UA Binary Encoding data.
pub(all) suberror UaError {
  Truncated(Int32, Int32)
  InvalidLength(Int32)
  LimitExceeded(Int32, Int32)
  InvalidUtf8
  InvalidNodeIdEncoding(UInt32)
  InvalidGuidLength(Int32)
  InvalidValue(String)
  UnsupportedType(UInt32)
  InvalidMask(String, UInt32)
}

///|
/// Decoder resource limits.
pub(all) struct UaLimits {
  max_byte_length : Int32
}

///|
/// Conservative defaults for untrusted binary input.
pub fn UaLimits::default() -> UaLimits {
  { max_byte_length: 16 * 1024 * 1024, }
}

///|
/// Human-readable error message.
pub fn UaError::message(self : UaError) -> String {
  match self {
    Truncated(required, remaining) =>
      "truncated input: need \{required} bytes, have \{remaining}"
    InvalidLength(length) => "invalid length prefix \{length}"
    LimitExceeded(length, limit) =>
      "length \{length} exceeds configured limit \{limit}"
    InvalidUtf8 => "String is not valid UTF-8"
    InvalidNodeIdEncoding(value) =>
      "unsupported NodeId encoding 0x\{value.to_string(radix=16)}"
    InvalidGuidLength(length) => "Guid must contain 16 bytes, got \{length}"
    InvalidValue(reason) => "invalid value: \{reason}"
    UnsupportedType(value) => "unsupported OPC UA built-in type id \{value}"
    InvalidMask(kind, mask) =>
      "\{kind} encoding mask has reserved bits set: 0x\{mask.to_string(radix=16)}"
  }
}
