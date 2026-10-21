# MoonUA

MoonUA 是一个纯 MoonBit 的 OPC UA Binary Encoding 基础库，面向工业设备、边缘网关、协议测试工具和数字孪生应用。

## 当前功能

- 小端序 Boolean、SByte、Byte、Int16、UInt16
- Int32、UInt32、Int64、UInt64、Float、Double
- OPC UA String 和 ByteString，包含 null、长度和 UTF-8 检查
- NodeId 的 TwoByte、FourByte、Numeric、String、Guid、Opaque 编码
- QualifiedName 的 namespace index 和名称编码
- LocalizedText 的 locale/text 掩码组合
- 类型化错误、边界检查、已知字节向量测试和可运行示例

## 快速开始

```moonbit
import {
  "oilleelssq-wq/moonua" @moonua,
}

let writer = @moonua.UaWriter::new()
writer.write_node_id(@moonua.NodeId::numeric(1, 1000))
writer.write_qualified_name(@moonua.QualifiedName::new(1, "Device"))
let bytes = writer.to_bytes()
```

当前范围不包含网络传输、SecureChannel、Session、Variant、DataValue 或 ExtensionObject。这些能力会在后续阶段逐步加入。

## 验证

```bash
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon test --target wasm
moon info
moon run examples/nodeid_demo --target wasm-gc
```

## 许可

Apache License 2.0。
