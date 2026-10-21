///|
fn main {
  let nodes = [
    @moonua.NodeId::numeric(0, 225),
    @moonua.NodeId::numeric(1, 1000),
    @moonua.NodeId::string(2, "Device"),
  ]
  for node in nodes {
    let writer = @moonua.UaWriter::new()
    writer.write_node_id(node) catch {
      error => {
        println("encode failed: " + error.message())
        continue
      }
    }
    println(
      node.to_string() +
      " -> " +
      writer.to_bytes().length().to_string() +
      " bytes",
    )
  }
  let qualified_name = @moonua.QualifiedName::new(1, "Device")
  let name_writer = @moonua.UaWriter::new()
  name_writer.write_qualified_name(qualified_name) catch {
    error => {
      println("encode failed: " + error.message())
      return
    }
  }
  println(
    "QualifiedName " +
    qualified_name.to_string() +
    " -> " +
    name_writer.to_bytes().length().to_string() +
    " bytes",
  )
  let localized_text = @moonua.LocalizedText::new(Some("en-US"), Some("Device"))
  let text_writer = @moonua.UaWriter::new()
  text_writer.write_localized_text(localized_text) catch {
    error => {
      println("encode failed: " + error.message())
      return
    }
  }
  println(
    "LocalizedText " +
    localized_text.to_string() +
    " -> " +
    text_writer.to_bytes().length().to_string() +
    " bytes",
  )
}
