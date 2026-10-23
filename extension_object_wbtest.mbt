///|
fn encode_extension_object(value : ExtensionObject) -> Bytes raise UaError {
  let writer = UaWriter::new()
  writer.write_extension_object(value)
  writer.to_bytes()
}

///|
fn decode_extension_object(bytes : Bytes) -> ExtensionObject raise UaError {
  let reader = UaReader::from_bytes(bytes)
  reader.read_extension_object()
}

///|
test "ExtensionObject encodes type id and binary body" {
  let object = ExtensionObject::binary(NodeId::numeric(0, 100), b"\x01\x02")
  assert_eq(
    encode_extension_object(object),
    b"\x00\x00\x64\x01\x02\x00\x00\x00\x01\x02",
  )
  let decoded = decode_extension_object(
    b"\x00\x00\x64\x01\x02\x00\x00\x00\x01\x02",
  )
  assert_eq(decoded.type_id.to_string(), "ns=0;i=100")
  match decoded.body {
    ByteString(body) => assert_eq(body, b"\x01\x02")
    _ => fail("expected binary ExtensionObject body")
  }
}

///|
test "ExtensionObject supports empty and XML bodies" {
  let empty = ExtensionObject::empty(NodeId::numeric(1, 5))
  assert_eq(encode_extension_object(empty), b"\x00\x01\x05\x00")
  let xml = ExtensionObject::xml(NodeId::numeric(1, 5), "<A/>")
  assert_eq(
    encode_extension_object(xml),
    b"\x00\x01\x05\x02\x04\x00\x00\x00<A/>",
  )
  let decoded = decode_extension_object(b"\x00\x01\x05\x02\x04\x00\x00\x00<A/>")
  match decoded.body {
    XmlElement(body) => assert_eq(body, "<A/>")
    _ => fail("expected XML ExtensionObject body")
  }
}

///|
test "Variant carries ExtensionObject values with type id 22" {
  let object = ExtensionObject::binary(NodeId::numeric(0, 100), b"\x01\x02")
  let writer = UaWriter::new()
  writer.write_variant(ExtensionObjectValue(object))
  let bytes = writer.to_bytes()
  assert_eq(bytes[0], b'\x16')
  let reader = UaReader::from_bytes(bytes)
  match reader.read_variant() {
    ExtensionObjectValue(decoded) => {
      assert_eq(decoded.type_id.to_string(), "ns=0;i=100")
      match decoded.body {
        ByteString(body) => assert_eq(body, b"\x01\x02")
        _ => fail("expected binary body from Variant")
      }
    }
    _ => fail("expected ExtensionObject Variant")
  }
}

///|
test "ExtensionObject rejects unknown encodings and truncated bodies" {
  let unknown = UaReader::from_bytes(b"\x00\x00\x64\x03")
  try unknown.read_extension_object() catch {
    InvalidExtensionObjectEncoding(value) => assert_eq(value, 3U)
    _ => fail("unexpected ExtensionObject encoding error")
  } noraise {
    _ => fail("expected unknown ExtensionObject encoding")
  }
  let truncated = UaReader::from_bytes(b"\x00\x00\x64\x01\x08\x00\x00\x00")
  try truncated.read_extension_object() catch {
    Truncated(8, 0) => ()
    _ => fail("unexpected truncated ExtensionObject error")
  } noraise {
    _ => fail("expected truncated ExtensionObject body")
  }
}
