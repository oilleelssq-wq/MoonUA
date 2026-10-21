///|
test "QualifiedName encodes namespace index and UTF-8 name" {
  let value = QualifiedName::new(1, "Device")
  let writer = UaWriter::new()
  writer.write_qualified_name(value)
  assert_eq(writer.to_bytes(), b"\x01\x00\x06\x00\x00\x00Device")
  let reader = UaReader::from_bytes(b"\x01\x00\x06\x00\x00\x00Device")
  let decoded = reader.read_qualified_name()
  assert_eq(decoded.namespace_index, 1)
  assert_eq(decoded.name, "Device")
  assert_eq(decoded.to_string(), "1:Device")
}

///|
test "empty QualifiedName names are valid" {
  let writer = UaWriter::new()
  writer.write_qualified_name(QualifiedName::new(2, ""))
  assert_eq(writer.to_bytes(), b"\x02\x00\x00\x00\x00\x00")
  let reader = UaReader::from_bytes(b"\x02\x00\x00\x00\x00\x00")
  let decoded = reader.read_qualified_name()
  assert_eq(decoded.namespace_index, 2)
  assert_eq(decoded.name, "")
}

///|
test "LocalizedText encoding mask covers all combinations" {
  let empty = UaWriter::new()
  empty.write_localized_text(LocalizedText::new(None, None))
  assert_eq(empty.to_bytes(), b"\x00")
  let locale_only = UaWriter::new()
  locale_only.write_localized_text(LocalizedText::new(Some("en-US"), None))
  assert_eq(locale_only.to_bytes(), b"\x01\x05\x00\x00\x00en-US")
  let text_only = UaWriter::new()
  text_only.write_localized_text(LocalizedText::text_only("Hello"))
  assert_eq(text_only.to_bytes(), b"\x02\x05\x00\x00\x00Hello")
  let both = UaWriter::new()
  both.write_localized_text(LocalizedText::new(Some("en-US"), Some("Hello")))
  assert_eq(both.to_bytes(), b"\x03\x05\x00\x00\x00en-US\x05\x00\x00\x00Hello")
}

///|
test "LocalizedText decodes locale and text in mask order" {
  let reader = UaReader::from_bytes(
    b"\x03\x05\x00\x00\x00en-US\x05\x00\x00\x00Hello",
  )
  let value = reader.read_localized_text()
  match value.locale {
    Some(locale) => assert_eq(locale, "en-US")
    None => fail("expected locale")
  }
  match value.text {
    Some(text) => assert_eq(text, "Hello")
    None => fail("expected text")
  }
  assert_eq(value.to_string(), "[en-US] Hello")
  let text_only = UaReader::from_bytes(b"\x02\x05\x00\x00\x00Hello")
  let decoded = text_only.read_localized_text()
  assert_eq(decoded.to_string(), "Hello")
}

///|
test "LocalizedText rejects reserved bits and truncation" {
  let reserved = UaReader::from_bytes(b"\x04")
  try reserved.read_localized_text() catch {
    InvalidValue(_) => ()
    _ => fail("unexpected reserved-mask error")
  } noraise {
    _ => fail("expected reserved mask to fail")
  }
  let truncated = UaReader::from_bytes(b"\x02")
  try truncated.read_localized_text() catch {
    Truncated(_, _) => ()
    _ => fail("unexpected LocalizedText truncation error")
  } noraise {
    _ => fail("expected truncated LocalizedText")
  }
}
