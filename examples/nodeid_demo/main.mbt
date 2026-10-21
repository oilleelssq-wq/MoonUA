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
}
