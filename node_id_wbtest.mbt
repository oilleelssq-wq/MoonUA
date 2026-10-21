///|
fn encode_node_id(value : NodeId) -> Bytes raise UaError {
  let writer = UaWriter::new()
  writer.write_node_id(value)
  writer.to_bytes()
}

///|
fn decode_node_id(bytes : Bytes) -> NodeId raise UaError {
  let reader = UaReader::from_bytes(bytes)
  reader.read_node_id()
}

///|
test "numeric NodeId chooses the compact encoding byte" {
  assert_eq(encode_node_id(NodeId::numeric(0, 225)), b"\x00\x00\xE1")
  assert_eq(encode_node_id(NodeId::numeric(1, 1000)), b"\x01\x01\xE8\x03")
  assert_eq(
    encode_node_id(NodeId::numeric(2, 70000)),
    b"\x02\x02\x00\x70\x11\x01\x00",
  )
}

///|
test "numeric NodeId roundtrips all numeric forms" {
  let two = decode_node_id(b"\x00\x00\xE1")
  assert_eq(two.namespace_index, 0)
  match two.identifier {
    Numeric(value) => assert_eq(value, 225U)
    _ => fail("expected numeric NodeId")
  }
  let four = decode_node_id(b"\x01\x01\xE8\x03")
  assert_eq(four.namespace_index, 1)
  match four.identifier {
    Numeric(value) => assert_eq(value, 1000U)
    _ => fail("expected numeric NodeId")
  }
  let full = decode_node_id(b"\x02\x02\x00\x70\x11\x01\x00")
  assert_eq(full.namespace_index, 2)
  match full.identifier {
    Numeric(value) => assert_eq(value, 70000U)
    _ => fail("expected numeric NodeId")
  }
}

///|
test "string NodeId uses the OPC UA length-prefixed encoding" {
  let value = NodeId::string(1, "Device")
  assert_eq(encode_node_id(value), b"\x03\x01\x00\x06\x00\x00\x00Device")
  let decoded = decode_node_id(b"\x03\x01\x00\x06\x00\x00\x00Device")
  assert_eq(decoded.namespace_index, 1)
  match decoded.identifier {
    String(text) => assert_eq(text, "Device")
    _ => fail("expected string NodeId")
  }
  assert_eq(value.to_string(), "ns=1;s=Device")
}

///|
test "Guid and opaque NodeIds roundtrip" {
  let guid_bytes = b"\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F"
  let guid = NodeId::guid(1, guid_bytes)
  assert_eq(
    encode_node_id(guid),
    b"\x04\x01\x00\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F",
  )
  let decoded_guid = decode_node_id(
    b"\x04\x01\x00\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F",
  )
  match decoded_guid.identifier {
    Guid(value) => assert_eq(value, guid_bytes)
    _ => fail("expected Guid NodeId")
  }
  let opaque_node = NodeId::bytes(2, b"\x01\x02\x03")
  assert_eq(
    encode_node_id(opaque_node),
    b"\x05\x02\x00\x03\x00\x00\x00\x01\x02\x03",
  )
  let decoded_opaque = decode_node_id(
    b"\x05\x02\x00\x03\x00\x00\x00\x01\x02\x03",
  )
  match decoded_opaque.identifier {
    Opaque(value) => assert_eq(value, b"\x01\x02\x03")
    _ => fail("expected opaque NodeId")
  }
}

///|
test "invalid and truncated NodeIds are rejected" {
  let reader = UaReader::from_bytes(b"\x06")
  try reader.read_node_id() catch {
    InvalidNodeIdEncoding(6) => ()
    _ => fail("unexpected invalid NodeId error")
  } noraise {
    _ => fail("expected invalid NodeId encoding")
  }
  let truncated = UaReader::from_bytes(b"\x01\x01")
  try truncated.read_node_id() catch {
    Truncated(_, _) => ()
    _ => fail("unexpected truncation error")
  } noraise {
    _ => fail("expected truncated NodeId")
  }
  let invalid_guid = UaReader::from_bytes(b"\x04\x01\x00short")
  try invalid_guid.read_node_id() catch {
    Truncated(16, _) => ()
    _ => fail("unexpected Guid truncation error")
  } noraise {
    _ => fail("expected short Guid to fail")
  }
}

///|
test "writer rejects invalid Guid lengths" {
  let writer = UaWriter::new()
  try writer.write_node_id(NodeId::guid(1, b"short")) catch {
    InvalidGuidLength(5) => ()
    _ => fail("unexpected Guid length error")
  } noraise {
    _ => fail("expected invalid Guid length")
  }
}
