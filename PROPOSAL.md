# MoonUA 项目申报书

**项目名称**：MoonUA：MoonBit 原生 OPC UA Binary Encoding 基础库

**参赛者**：oilleelssq-wq

**联系邮箱**：2321130582@qq.com

**GitHub 仓库**：https://github.com/oilleelssq-wq/MoonUA

**项目方向**：工业互联网数据交换；MoonBit 可复用协议与数据模型库。

## 项目简介

MoonUA 用纯 MoonBit 实现 OPC UA Binary Encoding，为工业设备、边缘网关、测试工具和数字孪生应用提供可复用的二进制数据编解码层。当前阶段完成基础标量、字符串、字节串、NodeId、ExpandedNodeId、QualifiedName、LocalizedText、DateTime、StatusCode、Variant、DataValue 和 ExtensionObject，并覆盖 OPC UA 的六种 NodeId 编码形式。后续阶段加入 SecureChannel 和客户端会话。

## 可复现案例

1. 工业边缘网关读取 PLC 或传感器数据，将 OPC UA 值编码为稳定的二进制消息，并在上位机中解码验证。
2. 设备模拟器和协议测试工具构造 NodeId、名称和本地化文本，为 OPC UA 服务端互操作测试提供不依赖 C 运行时的 MoonBit 实现。
3. CI 对比已知 OPC UA 字节向量，检查不同后端上的编码结果一致，避免工业数据在小端序、长度和边界处理上出现静默偏差。

## 核心功能与边界

- Boolean、整数、浮点、字符串和 ByteString 的小端序编解码。
- NodeId 的 TwoByte、FourByte、Numeric、String、Guid、Opaque 形式。
- ExpandedNodeId 的可选 NamespaceUri 和 ServerIndex。
- QualifiedName 和 LocalizedText 的编码掩码与可空字段。
- 长度限制、截断检测、非法编码和非法 UTF-8 诊断。
- 后续加入 SecureChannel 和客户端会话。
- 当前不做网络传输、证书、安全通道和完整服务端。

## 原创性与生态定位

项目为原创实现，不复制或移植现有代码；依据 OPC UA Part 6 Binary Encoding 规范独立设计 MoonBit 类型和 API。MoonCakes 检索未发现 OPC UA 数据模型实现，现有协议包集中在 MQTT、NATS、Kafka、AMQP、Modbus、CoAP 和 ROS 2，MoonUA 补充的是 OPC UA 数据编码这一独立生态位。

## 技术路线

先实现无 I/O 的二进制 Reader/Writer、NodeId 和常用名称模型，再以已知字节向量验证编码；随后建立 Variant、DataValue 的可组合数据模型；最后将 codec 接入 ExtensionObject、SecureChannel 和客户端会话。每个阶段都保持独立可测的 API。

## 交付与验收

- 可复用的 MoonCakes 包和清晰的公开 API。
- README、申报书、路线图、变更记录和可运行示例。
- 已知字节向量、边界条件、畸形输入和跨后端测试。
- GitHub Actions 覆盖 check、test、fmt 和 wasm/wasm-gc。
- 已知限制、规范来源和第三方依赖说明。
