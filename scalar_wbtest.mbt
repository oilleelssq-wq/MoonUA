///|
test "scalar encoder follows little-endian OPC UA layout" {
  let writer = UaWriter::new()
  writer.write_bool(true)
  writer.write_sbyte(-1)
  writer.write_u8(0xFE)
  writer.write_int16(-2)
  writer.write_uint16(0xFFFE)
  writer.write_int32(-3)
  writer.write_uint32(0xFFFFFFFD)
  writer.write_int64(-4L)
  writer.write_uint64(0xFFFFFFFFFFFFFFFCUL)
  writer.write_float(1.5)
  writer.write_double(-2.25)
  assert_eq(
    writer.to_bytes(),
    b"\x01\xFF\xFE\xFE\xFF\xFE\xFF\xFD\xFF\xFF\xFF\xFD\xFF\xFF\xFF\xFC\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFC\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x00\x00\xC0\x3F\x00\x00\x00\x00\x00\x00\x02\xC0",
  )
}

///|
test "scalar reader decodes the same values" {
  let bytes = b"\x01\xFF\xFE\xFE\xFF\xFE\xFF\xFD\xFF\xFF\xFF\xFD\xFF\xFF\xFF\xFC\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFC\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x00\x00\xC0\x3F\x00\x00\x00\x00\x00\x00\x02\xC0"
  let reader = UaReader::from_bytes(bytes)
  assert_eq(reader.read_bool(), true)
  assert_eq(reader.read_sbyte(), -1)
  assert_eq(reader.read_u8(), 0xFEU)
  assert_eq(reader.read_int16(), -2)
  assert_eq(reader.read_uint16().to_uint(), 0xFFFEU)
  assert_eq(reader.read_int32(), -3)
  assert_eq(reader.read_uint32(), 0xFFFFFFFDU)
  assert_eq(reader.read_int64(), -4L)
  assert_eq(reader.read_uint64(), 0xFFFFFFFFFFFFFFFCUL)
  assert_eq(reader.read_float(), 1.5)
  assert_eq(reader.read_double(), -2.25)
}

///|
test "nullable strings and byte strings roundtrip" {
  let writer = UaWriter::new()
  writer.write_string("UA")
  writer.write_nullable_string(None)
  writer.write_bytes(b"\x01\x02")
  writer.write_nullable_bytes(None)
  assert_eq(
    writer.to_bytes(),
    b"\x02\x00\x00\x00UA\xFF\xFF\xFF\xFF\x02\x00\x00\x00\x01\x02\xFF\xFF\xFF\xFF",
  )
  let reader = UaReader::from_bytes(
    b"\x02\x00\x00\x00UA\xFF\xFF\xFF\xFF\x02\x00\x00\x00\x01\x02\xFF\xFF\xFF\xFF",
  )
  match reader.read_string() {
    Some(value) => assert_eq(value, "UA")
    None => fail("expected string")
  }
  match reader.read_string() {
    None => ()
    Some(_) => fail("expected null string")
  }
  match reader.read_bytes() {
    Some(value) => assert_eq(value, b"\x01\x02")
    None => fail("expected bytes")
  }
  match reader.read_bytes() {
    None => ()
    Some(_) => fail("expected null bytes")
  }
}

///|
test "unicode strings and limits are enforced" {
  let writer = UaWriter::new()
  writer.write_string("设备")
  let encoded = writer.to_bytes()
  let reader = UaReader::from_bytes(encoded)
  assert_eq(reader.read_required_string(), "设备")
  let limits = { ..UaLimits::default(), max_byte_length: 2, }
  let oversized = UaReader::with_limits(
    b"\x03\x00\x00\x00abc".exact_view(),
    limits,
  )
  try oversized.read_string() catch {
    LimitExceeded(3, 2) => ()
    _ => fail("unexpected limit error")
  } noraise {
    _ => fail("expected length limit")
  }
}

///|
test "invalid UTF-8 bool and range values are rejected" {
  let invalid_utf8 = UaReader::from_bytes(b"\x01\x00\x00\x00\xFF")
  try invalid_utf8.read_string() catch {
    InvalidUtf8 => ()
    _ => fail("unexpected UTF-8 error")
  } noraise {
    _ => fail("expected invalid UTF-8")
  }
  let invalid_bool = UaReader::from_bytes(b"\x02")
  try invalid_bool.read_bool() catch {
    InvalidValue(_) => ()
    _ => fail("unexpected Boolean error")
  } noraise {
    _ => fail("expected invalid Boolean")
  }
  let writer = UaWriter::new()
  try writer.write_sbyte(200) catch {
    InvalidValue(_) => ()
    _ => fail("unexpected SByte range error")
  } noraise {
    _ => fail("expected SByte range error")
  }
  try writer.write_int16(40000) catch {
    InvalidValue(_) => ()
    _ => fail("unexpected Int16 range error")
  } noraise {
    _ => fail("expected Int16 range error")
  }
}
