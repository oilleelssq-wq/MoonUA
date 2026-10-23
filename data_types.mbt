///|
/// OPC UA DateTime stored as 100-nanosecond intervals since 1601-01-01 UTC.
pub(all) struct UaDateTime {
  ticks : Int64
}

///|
/// Ticks between 1601-01-01 and 1970-01-01.
pub const UA_UNIX_EPOCH_TICKS : Int64 = 116_444_736_000_000_000L

///|
/// Construct a DateTime from raw OPC UA ticks.
pub fn UaDateTime::from_ticks(ticks : Int64) -> UaDateTime {
  { ticks, }
}

///|
/// Convert Unix milliseconds to OPC UA ticks.
pub fn UaDateTime::from_unix_ms(unix_ms : Int64) -> UaDateTime raise UaError {
  if unix_ms > 910_692_730_085_477L || unix_ms < -11_644_473_600_000L {
    raise InvalidValue(
      "Unix milliseconds are outside the OPC UA DateTime range",
    )
  }
  { ticks: unix_ms * 10_000L + UA_UNIX_EPOCH_TICKS, }
}

///|
/// Convert OPC UA ticks to Unix milliseconds, truncating sub-millisecond values.
pub fn UaDateTime::to_unix_ms(self : UaDateTime) -> Int64 {
  (self.ticks - UA_UNIX_EPOCH_TICKS) / 10_000L
}

///|
/// Decode a DateTime.
pub fn UaReader::read_datetime(self : UaReader) -> UaDateTime raise UaError {
  { ticks: self.read_int64(), }
}

///|
/// Encode a DateTime.
pub fn UaWriter::write_datetime(self : UaWriter, value : UaDateTime) -> Unit {
  self.write_int64(value.ticks)
}

///|
/// OPC UA StatusCode severity is encoded in the two most significant bits.
pub(all) enum StatusSeverity {
  Good
  Uncertain
  Bad
}

///|
/// OPC UA StatusCode.
pub(all) struct StatusCode {
  value : UInt32
}

///|
/// Construct a StatusCode from its raw wire value.
pub fn StatusCode::new(value : UInt32) -> StatusCode {
  { value, }
}

///|
/// Raw wire value.
pub fn StatusCode::raw(self : StatusCode) -> UInt32 {
  self.value
}

///|
/// Decode the severity from the top two bits.
pub fn StatusCode::severity(self : StatusCode) -> StatusSeverity {
  match self.value >> 30 {
    0 => Good
    1 => Uncertain
    _ => Bad
  }
}

///|
/// Whether the status severity is Good.
pub fn StatusCode::is_good(self : StatusCode) -> Bool {
  match self.severity() {
    Good => true
    Uncertain | Bad => false
  }
}

///|
/// Human-readable status severity.
pub fn StatusCode::severity_name(self : StatusCode) -> String {
  match self.severity() {
    Good => "Good"
    Uncertain => "Uncertain"
    Bad => "Bad"
  }
}

///|
/// Decode a StatusCode.
pub fn UaReader::read_status_code(self : UaReader) -> StatusCode raise UaError {
  { value: self.read_uint32(), }
}

///|
/// Encode a StatusCode.
pub fn UaWriter::write_status_code(self : UaWriter, value : StatusCode) -> Unit {
  self.write_uint32(value.value)
}
