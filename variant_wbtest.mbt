///|
fn encode_variant(value : VariantValue) -> Bytes raise UaError {
  let writer = UaWriter::new()
  writer.write_variant(value)
  writer.to_bytes()
}

///|
fn decode_variant(bytes : Bytes) -> VariantValue raise UaError {
  let reader = UaReader::from_bytes(bytes)
  reader.read_variant()
}

///|
test "Variant scalar values use OPC UA built-in type ids" {
  assert_eq(encode_variant(Null), b"\x00")
  assert_eq(encode_variant(BoolValue(true)), b"\x01\x01")
  assert_eq(encode_variant(Int32Value(-3)), b"\x06\xFD\xFF\xFF\xFF")
  assert_eq(encode_variant(StringValue(Some("UA"))), b"\x0C\x02\x00\x00\x00UA")
  assert_eq(
    encode_variant(DateTimeValue(UaDateTime::from_ticks(1L))),
    b"\x0D\x01\x00\x00\x00\x00\x00\x00\x00",
  )
}

///|
test "Variant common OPC UA models use ids 17 through 21" {
  assert_eq(
    encode_variant(NodeIdValue(NodeId::numeric(1, 1000))),
    b"\x11\x01\x01\xE8\x03",
  )
  assert_eq(
    encode_variant(StatusCodeValue(StatusCode::new(0x80000000))),
    b"\x13\x00\x00\x00\x80",
  )
  assert_eq(
    encode_variant(QualifiedNameValue(QualifiedName::new(1, "A"))),
    b"\x14\x01\x00\x01\x00\x00\x00A",
  )
  assert_eq(
    encode_variant(LocalizedTextValue(LocalizedText::text_only("A"))),
    b"\x15\x02\x01\x00\x00\x00A",
  )
}

///|
test "Variant scalar values roundtrip" {
  let values = [
    Null,
    BoolValue(false),
    SByteValue(-7),
    ByteValue(250),
    Int16Value(-32000),
    UInt16Value(65000U.to_uint16()),
    Int32Value(-2000000),
    UInt32Value(4_000_000_000U),
    Int64Value(-9_000_000_000L),
    UInt64Value(18_000_000_000UL),
    FloatValue(1.5),
    DoubleValue(-2.25),
    StringValue(Some("hello")),
    DateTimeValue(UaDateTime::from_ticks(1234L)),
    ByteStringValue(Some(b"\x01\x02")),
    XmlElementValue(Some("<A/>")),
  ]
  for value in values {
    let encoded = encode_variant(value)
    let decoded = decode_variant(encoded)
    assert_eq(decoded.type_id(), value.type_id())
  }
}

///|
test "Variant rejects arrays and unsupported built-in types" {
  let array = UaReader::from_bytes(b"\x81\x00\x00\x00\x00")
  try array.read_variant() catch {
    UnsupportedType(value) => assert_eq(value, 0x81U)
    _ => fail("unexpected array-variant error")
  } noraise {
    _ => fail("expected array Variant rejection")
  }
  let data_value = UaReader::from_bytes(b"\x17")
  try data_value.read_variant() catch {
    UnsupportedType(value) => assert_eq(value, 23U)
    _ => fail("unexpected unsupported-type error")
  } noraise {
    _ => fail("expected unsupported DataValue Variant rejection")
  }
}
