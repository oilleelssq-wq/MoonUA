///|
fn encode_data_value(value : DataValue) -> Bytes raise UaError {
  let writer = UaWriter::new()
  writer.write_data_value(value)
  writer.to_bytes()
}

///|
fn decode_data_value(bytes : Bytes) -> DataValue raise UaError {
  let reader = UaReader::from_bytes(bytes)
  reader.read_data_value()
}

///|
test "empty and value-only DataValues use compact masks" {
  assert_eq(DataValue::empty().is_empty(), true)
  assert_eq(encode_data_value(DataValue::empty()), b"\x00")
  assert_eq(encode_data_value(DataValue::of(BoolValue(true))), b"\x01\x01\x01")
}

///|
test "DataValue status and source timestamp mask fields" {
  let value = {
    ..DataValue::empty(),
    status: Some(StatusCode::new(0x80000000)),
  }
  assert_eq(encode_data_value(value), b"\x02\x00\x00\x00\x80")
  let source_value = {
    ..DataValue::empty(),
    source_timestamp: Some(UaDateTime::from_ticks(1L)),
  }
  assert_eq(
    encode_data_value(source_value),
    b"\x04\x01\x00\x00\x00\x00\x00\x00\x00",
  )
}

///|
test "DataValue full mask roundtrips all optional fields" {
  let value = {
    value: Some(Int32Value(-3)),
    status: Some(StatusCode::new(0)),
    source_timestamp: Some(UaDateTime::from_ticks(1L)),
    server_timestamp: Some(UaDateTime::from_ticks(2L)),
    source_picoseconds: Some(100U.to_uint16()),
    server_picoseconds: Some(200U.to_uint16()),
  }
  let encoded = encode_data_value(value)
  assert_eq(encoded[0], b'\x3F')
  let decoded = decode_data_value(encoded)
  match decoded.value {
    Some(Int32Value(item)) => assert_eq(item, -3)
    _ => fail("expected Int32 DataValue")
  }
  match decoded.status {
    Some(item) => assert_eq(item.is_good(), true)
    None => fail("expected status")
  }
  match decoded.source_timestamp {
    Some(item) => assert_eq(item.ticks, 1L)
    None => fail("expected source timestamp")
  }
  match decoded.server_timestamp {
    Some(item) => assert_eq(item.ticks, 2L)
    None => fail("expected server timestamp")
  }
  match decoded.source_picoseconds {
    Some(item) => assert_eq(item.to_uint(), 100U)
    None => fail("expected source picoseconds")
  }
  match decoded.server_picoseconds {
    Some(item) => assert_eq(item.to_uint(), 200U)
    None => fail("expected server picoseconds")
  }
}

///|
test "DataValue rejects invalid timestamps and picoseconds" {
  let missing_timestamp = {
    ..DataValue::empty(),
    source_picoseconds: Some(1U.to_uint16()),
  }
  try encode_data_value(missing_timestamp) catch {
    InvalidValue(_) => ()
    _ => fail("unexpected missing timestamp error")
  } noraise {
    _ => fail("expected picoseconds without timestamp to fail")
  }
  let excessive = {
    ..DataValue::empty(),
    source_timestamp: Some(UaDateTime::from_ticks(0L)),
    source_picoseconds: Some(10000U.to_uint16()),
  }
  try encode_data_value(excessive) catch {
    InvalidValue(_) => ()
    _ => fail("unexpected picosecond range error")
  } noraise {
    _ => fail("expected picoseconds above 9999 to fail")
  }
}

///|
test "DataValue rejects reserved mask bits" {
  let reader = UaReader::from_bytes(b"\x40")
  try reader.read_data_value() catch {
    InvalidMask(kind, mask) => {
      assert_eq(kind, "DataValue")
      assert_eq(mask, 0x40U)
    }
    _ => fail("unexpected reserved-mask error")
  } noraise {
    _ => fail("expected reserved mask failure")
  }
}
