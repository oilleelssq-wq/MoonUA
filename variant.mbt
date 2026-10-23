///|
/// A practical scalar subset of an OPC UA Variant.
///
/// Array variants and recursive built-in types are rejected explicitly until
/// their bounded codecs are implemented.
pub(all) enum VariantValue {
  Null
  BoolValue(Bool)
  SByteValue(Int32)
  ByteValue(UInt32)
  Int16Value(Int32)
  UInt16Value(UInt16)
  Int32Value(Int32)
  UInt32Value(UInt32)
  Int64Value(Int64)
  UInt64Value(UInt64)
  FloatValue(Float)
  DoubleValue(Double)
  StringValue(String?)
  DateTimeValue(UaDateTime)
  GuidValue(Bytes)
  ByteStringValue(Bytes?)
  XmlElementValue(String?)
  NodeIdValue(NodeId)
  StatusCodeValue(StatusCode)
  QualifiedNameValue(QualifiedName)
  LocalizedTextValue(LocalizedText)
  ExtensionObjectValue(ExtensionObject)
}

///|
/// OPC UA built-in type id for this Variant value.
pub fn VariantValue::type_id(self : VariantValue) -> UInt32 {
  match self {
    Null => 0
    BoolValue(_) => 1
    SByteValue(_) => 2
    ByteValue(_) => 3
    Int16Value(_) => 4
    UInt16Value(_) => 5
    Int32Value(_) => 6
    UInt32Value(_) => 7
    Int64Value(_) => 8
    UInt64Value(_) => 9
    FloatValue(_) => 10
    DoubleValue(_) => 11
    StringValue(_) => 12
    DateTimeValue(_) => 13
    GuidValue(_) => 14
    ByteStringValue(_) => 15
    XmlElementValue(_) => 16
    NodeIdValue(_) => 17
    StatusCodeValue(_) => 19
    QualifiedNameValue(_) => 20
    LocalizedTextValue(_) => 21
    ExtensionObjectValue(_) => 22
  }
}

///|
/// Human-readable built-in type name.
pub fn VariantValue::type_name(self : VariantValue) -> String {
  match self {
    Null => "Null"
    BoolValue(_) => "Boolean"
    SByteValue(_) => "SByte"
    ByteValue(_) => "Byte"
    Int16Value(_) => "Int16"
    UInt16Value(_) => "UInt16"
    Int32Value(_) => "Int32"
    UInt32Value(_) => "UInt32"
    Int64Value(_) => "Int64"
    UInt64Value(_) => "UInt64"
    FloatValue(_) => "Float"
    DoubleValue(_) => "Double"
    StringValue(_) => "String"
    DateTimeValue(_) => "DateTime"
    GuidValue(_) => "Guid"
    ByteStringValue(_) => "ByteString"
    XmlElementValue(_) => "XmlElement"
    NodeIdValue(_) => "NodeId"
    StatusCodeValue(_) => "StatusCode"
    QualifiedNameValue(_) => "QualifiedName"
    LocalizedTextValue(_) => "LocalizedText"
    ExtensionObjectValue(_) => "ExtensionObject"
  }
}

///|
/// Encode a scalar Variant with its built-in type id.
pub fn UaWriter::write_variant(
  self : UaWriter,
  value : VariantValue,
) -> Unit raise UaError {
  self.write_u8(value.type_id())
  match value {
    Null => ()
    BoolValue(item) => self.write_bool(item)
    SByteValue(item) => self.write_sbyte(item)
    ByteValue(item) => self.write_u8(item)
    Int16Value(item) => self.write_int16(item)
    UInt16Value(item) => self.write_uint16(item)
    Int32Value(item) => self.write_int32(item)
    UInt32Value(item) => self.write_uint32(item)
    Int64Value(item) => self.write_int64(item)
    UInt64Value(item) => self.write_uint64(item)
    FloatValue(item) => self.write_float(item)
    DoubleValue(item) => self.write_double(item)
    StringValue(item) => self.write_nullable_string(item)
    DateTimeValue(item) => self.write_datetime(item)
    GuidValue(item) => {
      if item.length() != 16 {
        raise InvalidGuidLength(item.length())
      }
      self.buffer.write_bytes(item.exact_view())
    }
    ByteStringValue(item) => self.write_nullable_bytes(item)
    XmlElementValue(item) => self.write_nullable_string(item)
    NodeIdValue(item) => self.write_node_id(item)
    StatusCodeValue(item) => self.write_status_code(item)
    QualifiedNameValue(item) => self.write_qualified_name(item)
    LocalizedTextValue(item) => self.write_localized_text(item)
    ExtensionObjectValue(item) => self.write_extension_object(item)
  }
}

///|
/// Decode a scalar Variant. Array variants are rejected explicitly.
pub fn UaReader::read_variant(self : UaReader) -> VariantValue raise UaError {
  let type_id = self.read_u8()
  if (type_id & 0x80U) != 0U {
    raise UnsupportedType(type_id)
  }
  match type_id {
    0 => Null
    1 => BoolValue(self.read_bool())
    2 => SByteValue(self.read_sbyte())
    3 => ByteValue(self.read_u8())
    4 => Int16Value(self.read_int16())
    5 => UInt16Value(self.read_uint16())
    6 => Int32Value(self.read_int32())
    7 => UInt32Value(self.read_uint32())
    8 => Int64Value(self.read_int64())
    9 => UInt64Value(self.read_uint64())
    10 => FloatValue(self.read_float())
    11 => DoubleValue(self.read_double())
    12 => StringValue(self.read_string())
    13 => DateTimeValue(self.read_datetime())
    14 => GuidValue(self.take(16).to_owned())
    15 => ByteStringValue(self.read_bytes())
    16 => XmlElementValue(self.read_string())
    17 => NodeIdValue(self.read_node_id())
    19 => StatusCodeValue(self.read_status_code())
    20 => QualifiedNameValue(self.read_qualified_name())
    21 => LocalizedTextValue(self.read_localized_text())
    22 => ExtensionObjectValue(self.read_extension_object())
    other => raise UnsupportedType(other)
  }
}
