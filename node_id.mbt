///|
/// The identifier portion of an OPC UA NodeId.
pub(all) enum NodeIdIdentifier {
  Numeric(UInt32)
  String(String)
  Guid(Bytes)
  Opaque(Bytes)
}

///|
/// An OPC UA NodeId.
pub(all) struct NodeId {
  namespace_index : UInt16
  identifier : NodeIdIdentifier
}

///|
/// Construct a numeric NodeId.
pub fn NodeId::numeric(namespace_index : UInt16, identifier : UInt32) -> NodeId {
  { namespace_index, identifier: Numeric(identifier), }
}

///|
/// Construct a string NodeId.
pub fn NodeId::string(namespace_index : UInt16, identifier : String) -> NodeId {
  { namespace_index, identifier: String(identifier), }
}

///|
/// Construct a Guid NodeId.
pub fn NodeId::guid(namespace_index : UInt16, identifier : Bytes) -> NodeId {
  { namespace_index, identifier: Guid(identifier), }
}

///|
/// Construct an opaque NodeId.
pub fn NodeId::bytes(namespace_index : UInt16, identifier : Bytes) -> NodeId {
  { namespace_index, identifier: Opaque(identifier), }
}

///|
/// Render a NodeId for diagnostics.
pub fn NodeId::to_string(self : NodeId) -> String {
  match self.identifier {
    Numeric(value) => "ns=\{self.namespace_index};i=\{value}"
    String(value) => "ns=\{self.namespace_index};s=\{value}"
    Guid(_) => "ns=\{self.namespace_index};g=<16-byte-guid>"
    Opaque(_) => "ns=\{self.namespace_index};b=<opaque>"
  }
}

///|
/// Decode a NodeId.
pub fn UaReader::read_node_id(self : UaReader) -> NodeId raise UaError {
  let encoding = self.read_u8()
  if encoding > 5 {
    raise InvalidNodeIdEncoding(encoding)
  }
  let namespace_index : UInt16 = match encoding {
    0 => {
      let value = self.read_u8()
      if value > 255 {
        raise InvalidNodeIdEncoding(encoding)
      }
      value.to_uint16()
    }
    1 => {
      let value = self.read_u8()
      if value > 255 {
        raise InvalidNodeIdEncoding(encoding)
      }
      value.to_uint16()
    }
    _ => self.read_uint16()
  }
  let identifier = match encoding {
    0 => {
      let value = self.read_u8()
      if value > 255 {
        raise InvalidNodeIdEncoding(encoding)
      }
      Numeric(value)
    }
    1 => Numeric(self.read_uint16().to_uint())
    2 => Numeric(self.read_uint32())
    3 => String(self.read_required_string())
    4 => {
      let guid = self.take(16).to_owned()
      Guid(guid)
    }
    5 => Opaque(self.read_required_bytes())
    other => raise InvalidNodeIdEncoding(other)
  }
  { namespace_index, identifier, }
}

///|
/// Encode a NodeId using the most compact numeric representation.
pub fn UaWriter::write_node_id(
  self : UaWriter,
  value : NodeId,
) -> Unit raise UaError {
  match value.identifier {
    Numeric(identifier) =>
      if value.namespace_index.to_uint() <= 255U && identifier <= 255U {
        self.write_u8(0)
        self.write_u8(value.namespace_index.to_uint())
        self.write_u8(identifier)
      } else if value.namespace_index.to_uint() <= 255U && identifier <= 65535U {
        self.write_u8(1)
        self.write_u8(value.namespace_index.to_uint())
        self.write_uint16(identifier.to_uint16())
      } else {
        self.write_u8(2)
        self.write_uint16(value.namespace_index)
        self.write_uint32(identifier)
      }
    String(identifier) => {
      self.write_u8(3)
      self.write_uint16(value.namespace_index)
      self.write_string(identifier)
    }
    Guid(identifier) => {
      if identifier.length() != 16 {
        raise InvalidGuidLength(identifier.length())
      }
      self.write_u8(4)
      self.write_uint16(value.namespace_index)
      self.buffer.write_bytes(identifier.exact_view())
    }
    Opaque(identifier) => {
      self.write_u8(5)
      self.write_uint16(value.namespace_index)
      self.write_bytes(identifier)
    }
  }
}
