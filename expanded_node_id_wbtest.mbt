///|
fn encode_expanded_node_id(value : ExpandedNodeId) -> Bytes raise UaError {
  let writer = UaWriter::new()
  writer.write_expanded_node_id(value)
  writer.to_bytes()
}

///|
fn decode_expanded_node_id(bytes : Bytes) -> ExpandedNodeId raise UaError {
  let reader = UaReader::from_bytes(bytes)
  reader.read_expanded_node_id()
}

///|
test "ExpandedNodeId without flags matches NodeId wire layout" {
  let value = ExpandedNodeId::new(NodeId::numeric(1, 5))
  assert_eq(encode_expanded_node_id(value), b"\x00\x01\x05")
  let decoded = decode_expanded_node_id(b"\x00\x01\x05")
  assert_eq(decoded.node_id.to_string(), "ns=1;i=5")
  match decoded.namespace_uri {
    None => ()
    Some(_) => fail("unexpected NamespaceUri")
  }
}

///|
test "ExpandedNodeId encodes NamespaceUri and ServerIndex after NodeId" {
  let value = ExpandedNodeId::new(NodeId::numeric(2, 5))
    .with_namespace_uri("urn:x")
    .with_server_index(7U)
  assert_eq(
    encode_expanded_node_id(value),
    b"\xC0\x00\x05\x05\x00\x00\x00urn:x\x07\x00\x00\x00",
  )
  let decoded = decode_expanded_node_id(
    b"\xC0\x00\x05\x05\x00\x00\x00urn:x\x07\x00\x00\x00",
  )
  assert_eq(decoded.node_id.to_string(), "ns=0;i=5")
  match decoded.namespace_uri {
    Some(uri) => assert_eq(uri, "urn:x")
    None => fail("expected NamespaceUri")
  }
  match decoded.server_index {
    Some(index) => assert_eq(index, 7U)
    None => fail("expected ServerIndex")
  }
  assert_eq(decoded.to_string(), "ns=0;i=5?uri=urn:x?server=7")
}

///|
test "ExpandedNodeId supports URI-only and server-only flags" {
  let uri_only = ExpandedNodeId::new(NodeId::numeric(0, 5)).with_namespace_uri(
    "urn:x",
  )
  assert_eq(
    encode_expanded_node_id(uri_only),
    b"\x80\x00\x05\x05\x00\x00\x00urn:x",
  )
  let server_only = ExpandedNodeId::new(NodeId::numeric(1, 5)).with_server_index(
    7U,
  )
  assert_eq(
    encode_expanded_node_id(server_only),
    b"\x40\x01\x05\x07\x00\x00\x00",
  )
}

///|
test "ExpandedNodeId omits empty URI and zero server index" {
  let value = ExpandedNodeId::new(NodeId::numeric(1, 5))
    .with_namespace_uri("")
    .with_server_index(0U)
  assert_eq(encode_expanded_node_id(value), b"\x00\x01\x05")
}

///|
test "ExpandedNodeId rejects inconsistent and truncated flag fields" {
  let empty_uri = UaReader::from_bytes(b"\x80\x00\x05\x00\x00\x00\x00")
  try empty_uri.read_expanded_node_id() catch {
    InvalidValue(_) => ()
    _ => fail("unexpected empty URI error")
  } noraise {
    _ => fail("expected empty NamespaceUri to fail")
  }
  let zero_server = UaReader::from_bytes(b"\x40\x01\x05\x00\x00\x00\x00")
  try zero_server.read_expanded_node_id() catch {
    InvalidValue(_) => ()
    _ => fail("unexpected zero ServerIndex error")
  } noraise {
    _ => fail("expected zero ServerIndex to fail")
  }
  let truncated = UaReader::from_bytes(b"\x40\x01\x05\x07\x00")
  try truncated.read_expanded_node_id() catch {
    Truncated(_, _) => ()
    _ => fail("unexpected truncated ServerIndex error")
  } noraise {
    _ => fail("expected truncated ServerIndex")
  }
}

///|
test "Variant uses built-in type id 18 for ExpandedNodeId" {
  let value = ExpandedNodeId::new(NodeId::numeric(1, 5)).with_server_index(7U)
  let writer = UaWriter::new()
  writer.write_variant(ExpandedNodeIdValue(value))
  let bytes = writer.to_bytes()
  assert_eq(bytes[0], b'\x12')
  let reader = UaReader::from_bytes(bytes)
  match reader.read_variant() {
    ExpandedNodeIdValue(decoded) =>
      match decoded.server_index {
        Some(index) => assert_eq(index, 7U)
        None => fail("expected ServerIndex from Variant")
      }
    _ => fail("expected ExpandedNodeId Variant")
  }
}
