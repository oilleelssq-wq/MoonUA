# MoonUA

MoonUA 是一个纯 MoonBit 的 OPC UA Binary Encoding 基础库。

当前第一个功能完成 OPC UA 二进制标量编码和 `NodeId` 编解码：

- 小端序 `Boolean`、`SByte`、`Byte`、`Int16`、`UInt16`
- `Int32`、`UInt32`、`Int64`、`UInt64`、`Float`、`Double`
- OPC UA `String` 和 `ByteString`，包含 null 与长度边界检查
- `NodeId` 的 TwoByte、FourByte、Numeric、String、Guid、Opaque 编码
- 数字 NodeId 自动选择最紧凑的编码形式
- 类型化 `UaError` 诊断和测试中的已知字节向量

## 快速开始

```moonbit
import {
  "oilleelssq-wq/moonua" @moonua,
}

let writer = @moonua.UaWriter::new()
writer.write_node_id(@moonua.NodeId::numeric(1, 1000))
let bytes = writer.to_bytes()
```

当前范围不包含网络传输、SecureChannel、Session、`Variant`、`DataValue` 或
`ExtensionObject`。这些能力会在后续阶段按功能逐步加入。

## 验证

```bash
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon test --target wasm
moon info
```

## 许可

Apache License 2.0。
