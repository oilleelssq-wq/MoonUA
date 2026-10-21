///|
/// A deterministic writer for OPC UA Binary Encoding.
pub(all) struct UaWriter {
  buffer : Buffer
}

///|
/// Create an empty writer.
pub fn UaWriter::new() -> UaWriter {
  { buffer: Buffer::Buffer(size_hint=32), }
}

///|
/// Return the encoded bytes.
pub fn UaWriter::to_bytes(self : UaWriter) -> Bytes {
  self.buffer.to_bytes()
}

///|
/// Write one unsigned byte.
pub fn UaWriter::write_u8(self : UaWriter, value : UInt32) -> Unit {
  self.buffer.write_byte(value.to_byte())
}

///|
/// Write one signed byte.
pub fn UaWriter::write_sbyte(
  self : UaWriter,
  value : Int32,
) -> Unit raise UaError {
  if value < -128 || value > 127 {
    raise InvalidValue("SByte is out of range")
  }
  self.buffer.write_byte(value.to_byte())
}

///|
/// Write a Boolean.
pub fn UaWriter::write_bool(self : UaWriter, value : Bool) -> Unit {
  self.buffer.write_byte(if value { 1 } else { 0 })
}

///|
/// Write a little-endian Int16.
pub fn UaWriter::write_int16(
  self : UaWriter,
  value : Int32,
) -> Unit raise UaError {
  if value < -32768 || value > 32767 {
    raise InvalidValue("Int16 is out of range")
  }
  self.buffer.write_int16_le(Int16::from_int(value))
}

///|
/// Write a little-endian UInt16.
pub fn UaWriter::write_uint16(self : UaWriter, value : UInt16) -> Unit {
  self.buffer.write_uint16_le(value)
}

///|
/// Write a little-endian Int32.
pub fn UaWriter::write_int32(self : UaWriter, value : Int32) -> Unit {
  self.buffer.write_uint_le(value.reinterpret_as_uint())
}

///|
/// Write a little-endian UInt32.
pub fn UaWriter::write_uint32(self : UaWriter, value : UInt32) -> Unit {
  self.buffer.write_uint_le(value)
}

///|
/// Write a little-endian Int64.
pub fn UaWriter::write_int64(self : UaWriter, value : Int64) -> Unit {
  self.buffer.write_int64_le(value)
}

///|
/// Write a little-endian UInt64.
pub fn UaWriter::write_uint64(self : UaWriter, value : UInt64) -> Unit {
  self.buffer.write_uint64_le(value)
}

///|
/// Write a little-endian Float.
pub fn UaWriter::write_float(self : UaWriter, value : Float) -> Unit {
  self.buffer.write_float_le(value)
}

///|
/// Write a little-endian Double.
pub fn UaWriter::write_double(self : UaWriter, value : Double) -> Unit {
  self.buffer.write_double_le(value)
}

///|
/// Write a non-null OPC UA String.
pub fn UaWriter::write_string(
  self : UaWriter,
  value : String,
) -> Unit raise UaError {
  let encoded = @utf8.encode(value)
  if encoded.length() > 0x7FFFFFFF {
    raise InvalidLength(encoded.length())
  }
  self.buffer.write_uint_le(encoded.length().reinterpret_as_uint())
  self.buffer.write_bytes(encoded.exact_view())
}

///|
/// Write a nullable OPC UA String.
pub fn UaWriter::write_nullable_string(
  self : UaWriter,
  value : String?,
) -> Unit raise UaError {
  match value {
    Some(text) => self.write_string(text)
    None => self.buffer.write_uint_le(0xFFFFFFFFU)
  }
}

///|
/// Write a non-null ByteString.
pub fn UaWriter::write_bytes(
  self : UaWriter,
  value : Bytes,
) -> Unit raise UaError {
  if value.length() > 0x7FFFFFFF {
    raise InvalidLength(value.length())
  }
  self.buffer.write_uint_le(value.length().reinterpret_as_uint())
  self.buffer.write_bytes(value.exact_view())
}

///|
/// Write a nullable ByteString.
pub fn UaWriter::write_nullable_bytes(
  self : UaWriter,
  value : Bytes?,
) -> Unit raise UaError {
  match value {
    Some(bytes) => self.write_bytes(bytes)
    None => self.buffer.write_uint_le(0xFFFFFFFFU)
  }
}
