///|
/// A practical subset of an OPC UA Variant.
///
/// One- and multi-dimensional arrays are supported. Recursive built-in types
/// and nested arrays are rejected explicitly.
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
  ArrayValue(VariantArray)
}

///|
/// A homogeneous Variant array with optional dimensions.
pub(all) struct VariantArray {
  element_type : UInt32
  values : Array[VariantValue]
  dimensions : Array[Int32]?
}

///|
/// Construct an array and infer its element type from the first value.
pub fn VariantArray::from_values(
  values : Array[VariantValue],
) -> VariantArray raise UaError {
  if values.is_empty() {
    raise InvalidValue("empty VariantArray requires an explicit element type")
  }
  let element_type = values[0].type_id()
  if element_type == 0U {
    raise InvalidValue("Variant arrays cannot contain Null values")
  }
  for value in values {
    match value {
      ArrayValue(_) =>
        raise InvalidValue("nested Variant arrays are not supported")
      Null => raise InvalidValue("Variant arrays cannot contain Null values")
      _ => ()
    }
    if value.type_id() != element_type {
      raise InvalidValue("Variant array elements must have the same type")
    }
  }
  { element_type, values, dimensions: None, }
}

///|
/// Construct an empty array with an explicit built-in element type.
pub fn VariantArray::empty(element_type : UInt32) -> VariantArray raise UaError {
  if element_type == 0U || element_type > 22U {
    raise UnsupportedType(element_type)
  }
  { element_type, values: [], dimensions: None, }
}

///|
/// Construct a multi-dimensional array from flattened values and dimensions.
pub fn VariantArray::from_dimensions(
  values : Array[VariantValue],
  dimensions : Array[Int32],
) -> VariantArray raise UaError {
  let array = VariantArray::from_values(values)
  validate_variant_dimensions(array.values.length(), dimensions)
  { ..array, dimensions: Some(dimensions), }
}

///|
/// Number of elements.
pub fn VariantArray::length(self : VariantArray) -> Int32 {
  self.values.length()
}

///|
/// Whether this array declares multiple dimensions.
pub fn VariantArray::is_multidimensional(self : VariantArray) -> Bool {
  match self.dimensions {
    Some(_) => true
    None => false
  }
}

///|
fn validate_variant_dimensions(
  value_count : Int32,
  dimensions : Array[Int32],
) -> Unit raise UaError {
  if dimensions.length() < 2 {
    raise InvalidValue("ArrayDimensions requires at least two dimensions")
  }
  let mut product = 1L
  for dimension in dimensions {
    if dimension <= 0 {
      raise InvalidValue("ArrayDimensions entries must be greater than zero")
    }
    product = product * dimension.to_int64()
    if product > value_count.to_int64() {
      raise InvalidValue("ArrayDimensions exceed the encoded value count")
    }
  }
  if product != value_count.to_int64() {
    raise InvalidValue("ArrayDimensions do not match the encoded value count")
  }
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
    ArrayValue(value) => value.element_type
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
    ArrayValue(value) => "Array[\{value.element_type}]"
  }
}

///|
/// Encode a Variant with its built-in type id.
pub fn UaWriter::write_variant(
  self : UaWriter,
  value : VariantValue,
) -> Unit raise UaError {
  match value {
    ArrayValue(array) => {
      let dimensions_flag = match array.dimensions {
        Some(_) => 0x40U
        None => 0U
      }
      self.write_u8(array.element_type | 0x80U | dimensions_flag)
      self.write_int32(array.length())
      for item in array.values {
        self.write_variant_scalar_payload(item)
      }
      match array.dimensions {
        Some(dimensions) => {
          self.write_int32(dimensions.length())
          for dimension in dimensions {
            self.write_int32(dimension)
          }
        }
        None => ()
      }
    }
    _ => {
      self.write_u8(value.type_id())
      self.write_variant_scalar_payload(value)
    }
  }
}

///|
fn UaWriter::write_variant_scalar_payload(
  self : UaWriter,
  value : VariantValue,
) -> Unit raise UaError {
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
    ArrayValue(_) =>
      raise InvalidValue("nested Variant arrays are not supported")
  }
}

///|
/// Decode a scalar Variant or a one-/multi-dimensional Variant array.
pub fn UaReader::read_variant(self : UaReader) -> VariantValue raise UaError {
  let encoding_mask = self.read_u8()
  let has_dimensions = (encoding_mask & 0x40U) != 0U
  let is_array = (encoding_mask & 0x80U) != 0U
  let type_id = encoding_mask & 0x3FU
  if has_dimensions && !is_array {
    raise UnsupportedType(encoding_mask)
  }
  if !is_array {
    return self.read_variant_scalar(type_id)
  }
  if type_id == 0U {
    raise UnsupportedType(encoding_mask)
  }
  let length = self.read_int32()
  if length < 0 {
    raise InvalidLength(length)
  }
  if length > self.limits.max_array_length {
    raise LimitExceeded(length, self.limits.max_array_length)
  }
  let values : Array[VariantValue] = []
  for _ in 0..<length {
    values.push(self.read_variant_scalar(type_id))
  }
  let dimensions = if has_dimensions {
    let dimension_count = self.read_int32()
    if dimension_count < 2 {
      raise InvalidValue("ArrayDimensions requires at least two dimensions")
    }
    if dimension_count > self.limits.max_array_length {
      raise LimitExceeded(dimension_count, self.limits.max_array_length)
    }
    let dimensions : Array[Int32] = []
    for _ in 0..<dimension_count {
      dimensions.push(self.read_int32())
    }
    validate_variant_dimensions(length, dimensions)
    Some(dimensions)
  } else {
    None
  }
  ArrayValue({ element_type: type_id, values, dimensions, })
}

///|
fn UaReader::read_variant_scalar(
  self : UaReader,
  type_id : UInt32,
) -> VariantValue raise UaError {
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
