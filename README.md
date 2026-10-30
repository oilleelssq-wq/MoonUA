# MoonUA

MoonUA 是一个纯 MoonBit 的 OPC UA Binary Encoding 基础库，面向工业设备、
边缘网关、协议测试工具和数字孪生应用。

## 标准基线

项目依据 OPC 10000-6《OPC Unified Architecture - Part 6: Mappings》
1.05.07 的 OPC UA Binary 第 5.2 节独立实现。兼容目标限定为二进制数据
编码；XML/JSON 映射、SecureChannel、Session、证书和网络传输不在库的
编解码边界内。

完整交付矩阵、可选字段结构和 `Variant[]` 编解码流程见
[ENCODING_FLOW.md](docs/ENCODING_FLOW.md)。

## 当前 0.3.0 功能

- 小端序 Boolean、SByte、Byte、Int16、UInt16、Int32、UInt32、Int64、UInt64、Float、Double
- OPC UA String 和 ByteString，包括 null、长度和 UTF-8 检查
- TwoByte、FourByte、Numeric、String、Guid、Opaque NodeId
- ExpandedNodeId 的 NamespaceUri 和 ServerIndex
- QualifiedName、LocalizedText、DateTime、StatusCode
- DataValue 可选字段掩码
- 标量 Variant、一维和多维 Variant 数组
- ExtensionObject 的空、二进制和 XML body
- 类型化错误、边界检查、已知字节向量测试和可运行示例

当前版本尚不支持通用 optional-field 结构 schema、Union、`Variant[]`、
DiagnosticInfo、Decimal 或完整 ExtensionObject 类型注册。遇到未支持类型时
会返回 `UaError`，不会静默改变字节语义。

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
