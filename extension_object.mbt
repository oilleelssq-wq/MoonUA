///|
/// The encoded body of an OPC UA ExtensionObject.
pub(all) enum ExtensionObjectBody {
  NoBody
  ByteString(Bytes)
  XmlElement(String)
}

///|
/// OPC UA ExtensionObject.
pub(all) struct ExtensionObject {
  type_id : NodeId
  body : ExtensionObjectBody
}

///|
/// Construct an empty ExtensionObject.
pub fn ExtensionObject::empty(type_id : NodeId) -> ExtensionObject {
  { type_id, body: NoBody, }
}

///|
/// Construct an ExtensionObject with a binary body.
pub fn ExtensionObject::binary(
  type_id : NodeId,
  body : Bytes,
) -> ExtensionObject {
  { type_id, body: ByteString(body), }
}

///|
/// Construct an ExtensionObject with an XML body.
pub fn ExtensionObject::xml(type_id : NodeId, body : String) -> ExtensionObject {
  { type_id, body: XmlElement(body), }
}

///|
/// Encode an ExtensionObject.
pub fn UaWriter::write_extension_object(
  self : UaWriter,
  value : ExtensionObject,
) -> Unit raise UaError {
  self.write_node_id(value.type_id)
  match value.body {
    NoBody => self.write_u8(0)
    ByteString(bytes) => {
      self.write_u8(1)
      self.write_bytes(bytes)
    }
    XmlElement(xml) => {
      self.write_u8(2)
      self.write_string(xml)
    }
  }
}

///|
/// Decode an ExtensionObject.
pub fn UaReader::read_extension_object(
  self : UaReader,
) -> ExtensionObject raise UaError {
  let type_id = self.read_node_id()
  let encoding = self.read_u8()
  let body = match encoding {
    0 => NoBody
    1 => ByteString(self.read_required_bytes())
    2 => XmlElement(self.read_required_string())
    other => raise InvalidExtensionObjectEncoding(other)
  }
  { type_id, body, }
}
