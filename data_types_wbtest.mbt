///|
test "DateTime converts between Unix milliseconds and OPC UA ticks" {
  let epoch = UaDateTime::from_unix_ms(0L)
  assert_eq(epoch.ticks, UA_UNIX_EPOCH_TICKS)
  assert_eq(epoch.to_unix_ms(), 0L)
  let sample = UaDateTime::from_unix_ms(1_700_000_000_000L)
  assert_eq(sample.to_unix_ms(), 1_700_000_000_000L)
}

///|
test "DateTime uses little-endian Int64 encoding" {
  let value = UaDateTime::from_ticks(0x0102030405060708L)
  let writer = UaWriter::new()
  writer.write_datetime(value)
  assert_eq(writer.to_bytes(), b"\x08\x07\x06\x05\x04\x03\x02\x01")
  let reader = UaReader::from_bytes(b"\x08\x07\x06\x05\x04\x03\x02\x01")
  assert_eq(reader.read_datetime().ticks, value.ticks)
}

///|
test "DateTime rejects Unix milliseconds outside its representable range" {
  try UaDateTime::from_unix_ms(910_692_730_085_478L) catch {
    InvalidValue(_) => ()
    _ => fail("unexpected upper-range error")
  } noraise {
    _ => fail("expected upper-range DateTime failure")
  }
}

///|
test "StatusCode uses top bits for severity" {
  assert_eq(StatusCode::new(0).severity_name(), "Good")
  assert_eq(StatusCode::new(0x40000000).severity_name(), "Uncertain")
  assert_eq(StatusCode::new(0x80000000).severity_name(), "Bad")
  assert_eq(StatusCode::new(0x80000000).is_good(), false)
  assert_eq(StatusCode::new(0).is_good(), true)
}

///|
test "StatusCode roundtrips through UInt32 wire encoding" {
  let writer = UaWriter::new()
  writer.write_status_code(StatusCode::new(0x80150000))
  assert_eq(writer.to_bytes(), b"\x00\x00\x15\x80")
  let reader = UaReader::from_bytes(b"\x00\x00\x15\x80")
  assert_eq(reader.read_status_code().raw(), 0x80150000)
}
