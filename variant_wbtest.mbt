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
test "Variant one-dimensional arrays use the array flag and length" {
  let ints = VariantArray::from_values([Int32Value(1), Int32Value(2)])
  assert_eq(
    encode_variant(ArrayValue(ints)),
    b"\x86\x02\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00",
  )
  let strings = VariantArray::from_values([
    StringValue(Some("A")),
    StringValue(Some("BC")),
  ])
  assert_eq(
    encode_variant(ArrayValue(strings)),
    b"\x8C\x02\x00\x00\x00\x01\x00\x00\x00A\x02\x00\x00\x00BC",
  )
  let decoded = decode_variant(
    b"\x86\x02\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00",
  )
  match decoded {
    ArrayValue(array) => {
      assert_eq(array.element_type, 6U)
      assert_eq(array.length(), 2)
      match array.values[1] {
        Int32Value(item) => assert_eq(item, 2)
        _ => fail("expected Int32 array element")
      }
    }
    _ => fail("expected Int32 array Variant")
  }
}

///|
test "Variant arrays support empty arrays with an explicit type" {
  let empty = VariantArray::empty(7)
  assert_eq(encode_variant(ArrayValue(empty)), b"\x87\x00\x00\x00\x00")
}

///|
test "Variant arrays enforce homogeneous non-null elements" {
  try VariantArray::from_values([Int32Value(1), DoubleValue(2.0)]) catch {
    InvalidValue(_) => ()
    _ => fail("unexpected heterogeneous-array error")
  } noraise {
    _ => fail("expected heterogeneous Variant array rejection")
  }
  try VariantArray::from_values([Null]) catch {
    InvalidValue(_) => ()
    _ => fail("unexpected null-array error")
  } noraise {
    _ => fail("expected null Variant array rejection")
  }
}

///|
test "Variant rejects dimensions limits and unsupported built-in types" {
  let dimensions = UaReader::from_bytes(b"\x46")
  try dimensions.read_variant() catch {
    UnsupportedType(value) => assert_eq(value, 0x46U)
    _ => fail("unexpected dimension-array error")
  } noraise {
    _ => fail("expected multi-dimensional Variant rejection")
  }
  let limits = { ..UaLimits::default(), max_array_length: 2, }
  let oversized = UaReader::with_limits(
    b"\x86\x03\x00\x00\x00".exact_view(),
    limits,
  )
  try oversized.read_variant() catch {
    LimitExceeded(3, 2) => ()
    _ => fail("unexpected array limit error")
  } noraise {
    _ => fail("expected Variant array limit")
  }
  let data_value = UaReader::from_bytes(b"\x17")
  try data_value.read_variant() catch {
    UnsupportedType(value) => assert_eq(value, 23U)
    _ => fail("unexpected unsupported-type error")
  } noraise {
    _ => fail("expected unsupported DataValue Variant rejection")
  }
}
