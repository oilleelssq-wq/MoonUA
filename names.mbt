///|
/// An OPC UA QualifiedName: a namespace index plus a name.
pub(all) struct QualifiedName {
  namespace_index : UInt16
  name : String
}

///|
/// Construct a QualifiedName.
pub fn QualifiedName::new(
  namespace_index : UInt16,
  name : String,
) -> QualifiedName {
  { namespace_index, name, }
}

///|
/// Render a QualifiedName for diagnostics.
pub fn QualifiedName::to_string(self : QualifiedName) -> String {
  "\{self.namespace_index}:\{self.name}"
}

///|
/// Decode a QualifiedName.
pub fn UaReader::read_qualified_name(
  self : UaReader,
) -> QualifiedName raise UaError {
  { namespace_index: self.read_uint16(), name: self.read_required_string(), }
}

///|
/// Encode a QualifiedName.
pub fn UaWriter::write_qualified_name(
  self : UaWriter,
  value : QualifiedName,
) -> Unit raise UaError {
  self.write_uint16(value.namespace_index)
  self.write_string(value.name)
}

///|
/// An OPC UA LocalizedText.
pub(all) struct LocalizedText {
  locale : String?
  text : String?
}

///|
/// Construct a LocalizedText.
pub fn LocalizedText::new(locale : String?, text : String?) -> LocalizedText {
  { locale, text, }
}

///|
/// Construct a text-only LocalizedText.
pub fn LocalizedText::text_only(text : String) -> LocalizedText {
  { locale: None, text: Some(text), }
}

///|
/// Render a LocalizedText for diagnostics.
pub fn LocalizedText::to_string(self : LocalizedText) -> String {
  let locale = match self.locale {
    Some(value) => value
    None => ""
  }
  let text = match self.text {
    Some(value) => value
    None => ""
  }
  if locale == "" {
    text
  } else {
    "[" + locale + "] " + text
  }
}

///|
/// Decode a LocalizedText.
pub fn UaReader::read_localized_text(
  self : UaReader,
) -> LocalizedText raise UaError {
  let mask = self.read_u8()
  if (mask & 0xFCU) != 0U {
    raise InvalidValue("LocalizedText encoding mask has reserved bits set")
  }
  let locale = if (mask & 0x01U) != 0U { self.read_string() } else { None }
  let text = if (mask & 0x02U) != 0U { self.read_string() } else { None }
  { locale, text, }
}

///|
/// Encode a LocalizedText.
pub fn UaWriter::write_localized_text(
  self : UaWriter,
  value : LocalizedText,
) -> Unit raise UaError {
  let mut mask = 0U
  if value.locale is Some(_) {
    mask = mask | 0x01U
  }
  if value.text is Some(_) {
    mask = mask | 0x02U
  }
  self.write_u8(mask)
  match value.locale {
    Some(locale) => self.write_string(locale)
    None => ()
  }
  match value.text {
    Some(text) => self.write_string(text)
    None => ()
  }
}
