# MoonUA Binary Encoding Scope and Caller Contract

## Normative baseline

MoonUA targets the OPC UA Binary data encoding in OPC 10000-6
*OPC Unified Architecture - Part 6: Mappings*, version 1.05.07, section 5.2.
The reference used for this document was checked on 2026-10-30:

- https://reference.opcfoundation.org/Core/Part6/v105/docs/5.2
- https://reference.opcfoundation.org/Core/Part6/v105/docs/5.2.2.16
- https://reference.opcfoundation.org/Core/Part6/v105/docs/5.2.7

Compatibility means byte-for-byte interoperability for the section 5.2 data
encoding rules covered by the delivery matrix below. It does not claim
compatibility with the XML or JSON mappings, security handshakes in section 6,
transport protocols in section 7, or a complete OPC UA client/server stack.

## Delivery matrix

| Capability | 0.3.0 | Final delivery target |
| --- | --- | --- |
| Built-in scalar values | Implemented except DiagnosticInfo and Decimal | All section 5.2.2 built-ins plus Decimal |
| Arrays | Implemented for Variant values | Bounds-checked scalar and structured arrays |
| NodeId and ExpandedNodeId | Implemented | Preserve all standard encoding forms and flags |
| QualifiedName and LocalizedText | Implemented | Keep binary and encoding masks conformant |
| ExtensionObject | Untyped binary/XML body implemented | Schema/type-id registry for application bodies |
| Variant | Scalar, one-dimensional, and multidimensional arrays | Add type-id 23 `Variant[]` and complete recursive budgets |
| DataValue | Fixed optional-field mask implemented | Keep mask validation and optional-field tests |
| Structures | Fixed application structures only | Schema-driven mandatory and optional fields |
| Optional fields | DataValue implemented | Generic Structures with optional fields, maximum 32 fields |
| Unions | Not implemented | Union selector and selected-field codec |
| DiagnosticInfo | Not implemented | Full optional and recursive fields |
| SecureChannel, Session, networking | Not in scope | Not in scope |
| OPC UA XML and JSON mappings | Not in scope | Not in scope |

The 0.3.0 implementation deliberately rejects nested `VariantArray` values and
the unsupported Variant type id instead of silently changing the wire value.
The `Variant[]` case below is an acceptance target, not a claim that 0.3.0
already supports it.

## Optional-field structure

Consider this application structure:

```moonbit
struct SensorReading {
  sensor_id : UInt32,
  value : Variant?,
  samples : Array[Variant]?,
}
```

`sensor_id` is mandatory. `value` and `samples` are optional fields and receive
bits 0 and 1 of the 32-bit EncodingMask. The mask precedes the fields; mandatory
fields and present optional fields are then written in declaration order.

For the instance `sensor_id = 42`, `value = Double(3.5)`, and
`samples = [Int32(7), String("ok")]`, the binary payload is:

```text
03 00 00 00                         # EncodingMask: value + samples
2A 00 00 00                         # sensor_id = 42
0B 00 00 00 00 00 00 0C 40          # Variant(Double 3.5)
97 02 00 00 00                      # Variant[] type id 23, two elements
06 07 00 00 00                      # Variant(Int32 7)
0C 02 00 00 00 6F 6B                # Variant(String "ok")
```

This example encodes the structure payload itself. Wrapping it in an
ExtensionObject additionally requires the application's binary encoding NodeId,
encoding byte `0x01`, and the body length.

## Encode flow

1. The caller supplies a fully typed structure and its schema, including field
   order, optionality, data types, and ExtensionObject encoding NodeId.
2. The library validates required fields, bitmap width (at most 32 optional
   fields), configured length limits, and application-specific constraints.
3. The writer builds the optional-field mask and writes it before the fields.
4. Mandatory fields are always written. Optional fields are written only when
   their bit is set. Arrays write their element count before their elements.
5. A `Variant[]` uses Variant type id 23 with the array bit set; every element
   is encoded as a complete Variant according to its own type id.
6. The writer returns bytes only after every nested value, length, and
   dimension has passed validation.

## Decode flow

1. The caller provides the expected schema and resource limits.
2. The reader reads the field mask and rejects nonzero unassigned bits.
3. Fields are decoded in declaration order. Absent optional fields remain
   `None`; present fields are decoded according to their declared type.
4. Every length, count, dimension product, string size, and recursion depth is
   checked against configured limits before allocation or traversal.
5. `Variant[]` elements are decoded by their individual type masks. A scalar
   Variant whose type id is Variant is rejected because the specification does
   not allow a scalar Variant to contain another scalar Variant.
6. The caller must propagate `UaError`; it must not return partial values or
   continue as if malformed data were valid.

## Responsibility boundary

MoonUA owns deterministic little-endian encoding, field order, masks, length
and bounds checks, typed errors, and decoding resource budgets.

The caller owns application schemas, required-field policy, ExtensionObject
type registration, configured limits, security/session state, and deciding how
to handle a failed decode. SecureChannel, Session, certificates, and network
transport remain outside MoonUA's codec boundary.

## Current evidence

The 0.3.0 release includes 45 tests on the default target and 45 tests on wasm,
known-byte-vector coverage, optional DataValue masks, array dimensions, typed
errors, a runnable wasm-gc example, GitHub CI, and a MoonCakes package.
