///|
/// OPC UA ExpandedNodeId with optional NamespaceUri and ServerIndex.
pub(all) struct ExpandedNodeId {
  node_id : NodeId
  namespace_uri : String?
  server_index : UInt32?
}

///|
/// Construct an ExpandedNodeId without a URI or server index.
pub fn ExpandedNodeId::new(node_id : NodeId) -> ExpandedNodeId {
  { node_id, namespace_uri: None, server_index: None, }
}

///|
/// Add a NamespaceUri.
pub fn ExpandedNodeId::with_namespace_uri(
  self : ExpandedNodeId,
  namespace_uri : String,
) -> ExpandedNodeId {
  { ..self, namespace_uri: Some(namespace_uri), }
}

///|
/// Add a ServerIndex.
pub fn ExpandedNodeId::with_server_index(
  self : ExpandedNodeId,
  server_index : UInt32,
) -> ExpandedNodeId {
  { ..self, server_index: Some(server_index), }
}

///|
/// Render an ExpandedNodeId for diagnostics.
pub fn ExpandedNodeId::to_string(self : ExpandedNodeId) -> String {
  let base = self.node_id.to_string()
  let uri = match self.namespace_uri {
    Some(value) => if value == "" { "" } else { "?uri=" + value }
    None => ""
  }
  let server = match self.server_index {
    Some(value) => if value == 0U { "" } else { "?server=" + value.to_string() }
    None => ""
  }
  base + uri + server
}

///|
fn expanded_flags(
  namespace_uri : String?,
  server_index : UInt32?,
) -> (UInt32, Bool, Bool) {
  let has_uri = match namespace_uri {
    Some(value) => value != ""
    None => false
  }
  let has_server = match server_index {
    Some(value) => value != 0U
    None => false
  }
  let flags = (if has_uri { 0x80U } else { 0U }) |
    (if has_server { 0x40U } else { 0U })
  (flags, has_uri, has_server)
}

///|
/// Encode an ExpandedNodeId.
pub fn UaWriter::write_expanded_node_id(
  self : UaWriter,
  value : ExpandedNodeId,
) -> Unit raise UaError {
  let (flags, has_uri, has_server) = expanded_flags(
    value.namespace_uri,
    value.server_index,
  )
  let namespace_index = if has_uri {
    0U.to_uint16()
  } else {
    value.node_id.namespace_index
  }
  match value.node_id.identifier {
    Numeric(identifier) =>
      if namespace_index.to_uint() <= 255U && identifier <= 255U {
        self.write_u8(flags)
        self.write_u8(namespace_index.to_uint())
        self.write_u8(identifier)
      } else if namespace_index.to_uint() <= 255U && identifier <= 65535U {
        self.write_u8(flags | 0x01U)
        self.write_u8(namespace_index.to_uint())
        self.write_uint16(identifier.to_uint16())
      } else {
        self.write_u8(flags | 0x02U)
        self.write_uint16(namespace_index)
        self.write_uint32(identifier)
      }
    String(identifier) => {
      self.write_u8(flags | 0x03U)
      self.write_uint16(namespace_index)
      self.write_string(identifier)
    }
    Guid(identifier) => {
      if identifier.length() != 16 {
        raise InvalidGuidLength(identifier.length())
      }
      self.write_u8(flags | 0x04U)
      self.write_uint16(namespace_index)
      self.buffer.write_bytes(identifier.exact_view())
    }
    Opaque(identifier) => {
      self.write_u8(flags | 0x05U)
      self.write_uint16(namespace_index)
      self.write_bytes(identifier)
    }
  }
  if has_uri {
    match value.namespace_uri {
      Some(uri) => self.write_string(uri)
      None => ()
    }
  }
  if has_server {
    match value.server_index {
      Some(index) => self.write_uint32(index)
      None => ()
    }
  }
}

///|
/// Decode an ExpandedNodeId.
pub fn UaReader::read_expanded_node_id(
  self : UaReader,
) -> ExpandedNodeId raise UaError {
  let encoding = self.read_u8()
  let has_uri = (encoding & 0x80U) != 0U
  let has_server = (encoding & 0x40U) != 0U
  let node_encoding = encoding & 0x3FU
  let namespace_index = match node_encoding {
    0 | 1 => self.read_u8().to_uint16()
    2 | 3 | 4 | 5 => self.read_uint16()
    other => raise InvalidNodeIdEncoding(other)
  }
  let identifier = match node_encoding {
    0 => Numeric(self.read_u8())
    1 => Numeric(self.read_uint16().to_uint())
    2 => Numeric(self.read_uint32())
    3 => String(self.read_required_string())
    4 => Guid(self.take(16).to_owned())
    5 => Opaque(self.read_required_bytes())
    other => raise InvalidNodeIdEncoding(other)
  }
  let namespace_uri = if has_uri {
    let uri = self.read_required_string()
    if uri == "" {
      raise InvalidValue("ExpandedNodeId NamespaceUri must not be empty")
    }
    Some(uri)
  } else {
    None
  }
  let server_index = if has_server {
    let index = self.read_uint32()
    if index == 0U {
      raise InvalidValue("ExpandedNodeId ServerIndex must not be zero")
    }
    Some(index)
  } else {
    None
  }
  let effective_namespace = if has_uri {
    0U.to_uint16()
  } else {
    namespace_index
  }
  {
    node_id: { namespace_index: effective_namespace, identifier, },
    namespace_uri,
    server_index,
  }
}
