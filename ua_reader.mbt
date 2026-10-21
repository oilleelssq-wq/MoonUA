///|
/// A bounds-checked reader for OPC UA Binary Encoding.
pub(all) struct UaReader {
  data : BytesView
  mut offset : Int32
  limits : UaLimits
}

///|
/// Create a reader with default limits.
pub fn UaReader::new(data : BytesView) -> UaReader {
  { data, offset: 0, limits: UaLimits::default(), }
}

///|
/// Create a reader from owned bytes.
pub fn UaReader::from_bytes(data : Bytes) -> UaReader {
  UaReader::new(data.exact_view())
}

///|
/// Create a reader with explicit limits.
pub fn UaReader::with_limits(data : BytesView, limits : UaLimits) -> UaReader {
  { data, offset: 0, limits, }
}

///|
/// Current byte offset.
pub fn UaReader::position(self : UaReader) -> Int32 {
  self.offset
}

///|
/// Remaining bytes.
pub fn UaReader::remaining(self : UaReader) -> Int32 {
  self.data.length() - self.offset
}

///|
fn UaReader::take(self : UaReader, count : Int32) -> BytesView raise UaError {
  let remaining = self.remaining()
  if count < 0 || count > remaining {
    raise Truncated(count, remaining)
  }
  let start = self.offset
  self.offset = self.offset + count
  self.data[start:self.offset]
}

///|
/// Read an unsigned byte.
pub fn UaReader::read_u8(self : UaReader) -> UInt32 raise UaError {
  self.take(1)[0].to_uint()
}

///|
/// Read a signed byte.
pub fn UaReader::read_sbyte(self : UaReader) -> Int32 raise UaError {
  let value = self.read_u8().reinterpret_as_int()
  if value >= 0x80 {
    value - 0x100
  } else {
    value
  }
}

///|
/// Read a Boolean. OPC UA accepts zero and one only.
pub fn UaReader::read_bool(self : UaReader) -> Bool raise UaError {
  match self.read_u8() {
    0 => false
    1 => true
    value => raise InvalidValue("Boolean must be 0 or 1, got \{value}")
  }
}

///|
/// Read a little-endian Int16.
pub fn UaReader::read_int16(self : UaReader) -> Int32 raise UaError {
  let value = self.take(2).unsafe_read_uint16_le(0).to_int()
  if value >= 0x8000 {
    value - 0x10000
  } else {
    value
  }
}

///|
/// Read a little-endian UInt16.
pub fn UaReader::read_uint16(self : UaReader) -> UInt16 raise UaError {
  self.take(2).unsafe_read_uint16_le(0)
}

///|
/// Read a little-endian Int32.
pub fn UaReader::read_int32(self : UaReader) -> Int32 raise UaError {
  self.take(4).unsafe_read_uint32_le(0).reinterpret_as_int()
}

///|
/// Read a little-endian UInt32.
pub fn UaReader::read_uint32(self : UaReader) -> UInt32 raise UaError {
  self.take(4).unsafe_read_uint32_le(0)
}

///|
/// Read a little-endian Int64.
pub fn UaReader::read_int64(self : UaReader) -> Int64 raise UaError {
  self.take(8).unsafe_read_uint64_le(0).reinterpret_as_int64()
}

///|
/// Read a little-endian UInt64.
pub fn UaReader::read_uint64(self : UaReader) -> UInt64 raise UaError {
  self.take(8).unsafe_read_uint64_le(0)
}

///|
/// Read a little-endian Float.
pub fn UaReader::read_float(self : UaReader) -> Float raise UaError {
  Float::reinterpret_from_uint(self.read_uint32())
}

///|
/// Read a little-endian Double.
pub fn UaReader::read_double(self : UaReader) -> Double raise UaError {
  self.read_uint64().reinterpret_as_double()
}

///|
/// Read a nullable OPC UA String.
pub fn UaReader::read_string(self : UaReader) -> String? raise UaError {
  let length = self.read_int32()
  if length == -1 {
    return None
  }
  if length < -1 {
    raise InvalidLength(length)
  }
  if length > self.limits.max_byte_length {
    raise LimitExceeded(length, self.limits.max_byte_length)
  }
  let payload = self.take(length)
  Some(@utf8.decode(payload) catch { _ => raise InvalidUtf8 })
}

///|
/// Read a String and reject null.
pub fn UaReader::read_required_string(self : UaReader) -> String raise UaError {
  match self.read_string() {
    Some(value) => value
    None => raise InvalidValue("String must not be null")
  }
}

///|
/// Read a nullable ByteString.
pub fn UaReader::read_bytes(self : UaReader) -> Bytes? raise UaError {
  let length = self.read_int32()
  if length == -1 {
    return None
  }
  if length < -1 {
    raise InvalidLength(length)
  }
  if length > self.limits.max_byte_length {
    raise LimitExceeded(length, self.limits.max_byte_length)
  }
  Some(self.take(length).to_owned())
}

///|
/// Read a ByteString and reject null.
pub fn UaReader::read_required_bytes(self : UaReader) -> Bytes raise UaError {
  match self.read_bytes() {
    Some(value) => value
    None => raise InvalidValue("ByteString must not be null")
  }
}
