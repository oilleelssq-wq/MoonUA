# MoonUA 项目申报书（2026 十月黑客松）

**项目名称与方向**：MoonUA，纯 MoonBit OPC UA Binary Encoding 基础库；服务工业设备、边缘网关、协议测试与 MoonBit 可复用数据模型生态。

**参赛者**：oilleelssq-wq　　**联系邮箱**：2321130582@qq.com

**GitHub 仓库**：https://github.com/oilleelssq-wq/MoonUA

**标准基线**：OPC 10000-6《OPC Unified Architecture – Part 6: Mappings》1.05.07 的 OPC UA Binary 第 5.2 节；本文“完整兼容”指该节的数据编码语义，不含 XML/JSON 映射、安全握手或网络传输。

**最终交付目标**：完成 Built-in Types、Arrays、Structures、Structures with optional fields、Unions、Variant、Variant[]、DataValue、ExtensionObject、DiagnosticInfo 与 Decimal 的确定性编解码，并提供结构 schema、ExtensionObject 类型注册和递归/长度预算；技术路线为 schema/类型表、掩码与字段编解码、官方向量双向验证。非法掩码、截断、越界或尺寸不一致均返回 `UaError`。

**当前 0.3.0 已交付**：标量、Nullable String/ByteString、六种 NodeId、ExpandedNodeId、QualifiedName、LocalizedText、DateTime、StatusCode、DataValue 可选字段掩码、ExtensionObject，以及标量/一维/多维 Variant；已知字节向量、边界与跨 wasm 测试共 45 项通过。

**暂未实现（仅属最终目标）**：通用 optional-field 结构 schema、Union、`Variant[]`、DiagnosticInfo、Decimal、完整 ExtensionObject 类型注册；SecureChannel、Session 和网络传输不属于本项目交付。

**可选字段案例**：`SensorReading { sensor_id: UInt32, value: Variant?, samples: Variant[]? }`，编码掩码 `0x00000003`；先写 UInt32 掩码，再按声明顺序写必填字段和已置位的可选字段，解码端拒绝保留位。

**嵌套 Variant 案例**：规范禁止标量 Variant 直接包含标量 Variant，但允许 `Variant[]`；数组编码掩码使用类型号 23 加数组位（`0x97`），先写元素数，再逐个写完整 Variant。完整字节示例见 `docs/ENCODING_FLOW.md`。

**调用方职责**：提供合法字段值、结构 schema 和 ExtensionObject 编码 NodeId，设置递归与长度上限，并按 `UaError` 终止解析；库负责小端序、字段顺序、掩码校验、边界检查和耗尽检测。

**兼容验收**：官方编码器和 MoonUA 对同一值产生相同字节；MoonUA 对官方样例及自产字节双向解码一致；畸形输入不得猜测或静默降级。

**工程验收**：`moon fmt --check`、`moon check --deny-warn`、`moon test --deny-warn`、wasm 测试、可运行示例、CI、Apache-2.0 许可证和 MoonCakes 发布均可复现。

**生态定位**：MoonCakes 检索未发现 OPC UA 数据模型库；项目独立依据规范实现 MoonBit API，不复制现有代码，也不与 MQTT、Modbus、CoAP、ROS 2 等协议包重叠。
