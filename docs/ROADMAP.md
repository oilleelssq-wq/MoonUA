# Roadmap

The delivery baseline is OPC UA Part 6: Mappings 1.05.07, section 5.2
(OPC UA Binary data encoding). XML/JSON mappings, security handshakes, sessions,
and network transports are outside the project boundary.

## 0.1 Binary primitives

- Little-endian scalar readers and writers
- Nullable String and ByteString
- Six NodeId encodings
- ExpandedNodeId URI and server flags
- Bounds, limits, UTF-8, and invalid-value diagnostics
- Known-byte-vector tests

## 0.2 Common data model

- QualifiedName
- LocalizedText
- DateTime and StatusCode helpers
- DataValue and scalar Variant codecs

## 0.3 Structured values

- ExtensionObject
- Variant one- and multi-dimensional arrays
- Bounded recursive decoding
- Encoding roundtrip fixtures

## Final binary compatibility target

- Complete section 5.2 built-in scalar coverage, including DiagnosticInfo and Decimal
- Schema-driven Structures and Structures with optional fields
- Union selector codecs
- `Variant[]` and explicit recursive decode budgets
- ExtensionObject application type registry
- Official byte-vector interoperability fixtures

## Explicit non-goals

- SecureChannel and message security
- Client/server Sessions
- OPC UA TCP, HTTPS, WebSockets, or other network transports
- OPC UA XML and JSON mappings
