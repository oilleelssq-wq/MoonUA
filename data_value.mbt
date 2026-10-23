///|
/// OPC UA DataValue with optional value, status, timestamps, and picoseconds.
pub(all) struct DataValue {
  value : VariantValue?
  status : StatusCode?
  source_timestamp : UaDateTime?
  server_timestamp : UaDateTime?
  source_picoseconds : UInt16?
  server_picoseconds : UInt16?
}

///|
/// Construct an empty DataValue.
pub fn DataValue::empty() -> DataValue {
  {
    value: None,
    status: None,
    source_timestamp: None,
    server_timestamp: None,
    source_picoseconds: None,
    server_picoseconds: None,
  }
}

///|
/// Construct a DataValue carrying only a Variant value.
pub fn DataValue::of(value : VariantValue) -> DataValue {
  {
    value: Some(value),
    status: None,
    source_timestamp: None,
    server_timestamp: None,
    source_picoseconds: None,
    server_picoseconds: None,
  }
}

///|
/// Whether the DataValue has no optional fields.
pub fn DataValue::is_empty(self : DataValue) -> Bool {
  match self.value {
    Some(_) => false
    None =>
      match self.status {
        Some(_) => false
        None =>
          match self.source_timestamp {
            Some(_) => false
            None =>
              match self.server_timestamp {
                Some(_) => false
                None =>
                  match self.source_picoseconds {
                    Some(_) => false
                    None =>
                      match self.server_picoseconds {
                        Some(_) => false
                        None => true
                      }
                  }
              }
          }
      }
  }
}

///|
fn validate_data_value(value : DataValue) -> Unit raise UaError {
  match value.source_picoseconds {
    Some(ps) => {
      if ps > 9999U.to_uint16() {
        raise InvalidValue("SourcePicoseconds must be between 0 and 9999")
      }
      match value.source_timestamp {
        None => raise InvalidValue("SourcePicoseconds requires SourceTimestamp")
        Some(_) => ()
      }
    }
    None => ()
  }
  match value.server_picoseconds {
    Some(ps) => {
      if ps > 9999U.to_uint16() {
        raise InvalidValue("ServerPicoseconds must be between 0 and 9999")
      }
      match value.server_timestamp {
        None => raise InvalidValue("ServerPicoseconds requires ServerTimestamp")
        Some(_) => ()
      }
    }
    None => ()
  }
}

///|
fn data_value_mask(value : DataValue) -> UInt32 {
  let mask = 0U
  let mut mask = mask
  match value.value {
    Some(_) => mask = mask | 0x01U
    None => ()
  }
  match value.status {
    Some(_) => mask = mask | 0x02U
    None => ()
  }
  match value.source_timestamp {
    Some(_) => mask = mask | 0x04U
    None => ()
  }
  match value.server_timestamp {
    Some(_) => mask = mask | 0x08U
    None => ()
  }
  match value.source_picoseconds {
    Some(_) => mask = mask | 0x10U
    None => ()
  }
  match value.server_picoseconds {
    Some(_) => mask = mask | 0x20U
    None => ()
  }
  mask
}

///|
/// Encode a DataValue and its optional-field mask.
pub fn UaWriter::write_data_value(
  self : UaWriter,
  value : DataValue,
) -> Unit raise UaError {
  validate_data_value(value)
  self.write_u8(data_value_mask(value))
  match value.value {
    Some(item) => self.write_variant(item)
    None => ()
  }
  match value.status {
    Some(item) => self.write_status_code(item)
    None => ()
  }
  match value.source_timestamp {
    Some(item) => self.write_datetime(item)
    None => ()
  }
  match value.server_timestamp {
    Some(item) => self.write_datetime(item)
    None => ()
  }
  match value.source_picoseconds {
    Some(item) => self.write_uint16(item)
    None => ()
  }
  match value.server_picoseconds {
    Some(item) => self.write_uint16(item)
    None => ()
  }
}

///|
/// Decode a DataValue and validate its optional-field mask.
pub fn UaReader::read_data_value(self : UaReader) -> DataValue raise UaError {
  let mask = self.read_u8()
  if (mask & 0xC0U) != 0U {
    raise InvalidMask("DataValue", mask)
  }
  let value = if (mask & 0x01U) != 0U {
    Some(self.read_variant())
  } else {
    None
  }
  let status = if (mask & 0x02U) != 0U {
    Some(self.read_status_code())
  } else {
    None
  }
  let source_timestamp = if (mask & 0x04U) != 0U {
    Some(self.read_datetime())
  } else {
    None
  }
  let server_timestamp = if (mask & 0x08U) != 0U {
    Some(self.read_datetime())
  } else {
    None
  }
  let source_picoseconds = if (mask & 0x10U) != 0U {
    Some(self.read_uint16())
  } else {
    None
  }
  let server_picoseconds = if (mask & 0x20U) != 0U {
    Some(self.read_uint16())
  } else {
    None
  }
  let decoded = {
    value,
    status,
    source_timestamp,
    server_timestamp,
    source_picoseconds,
    server_picoseconds,
  }
  validate_data_value(decoded)
  decoded
}
