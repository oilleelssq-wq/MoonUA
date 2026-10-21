# MoonUA Project Instructions

MoonUA is a pure MoonBit implementation of OPC UA Binary Encoding primitives
and reusable data-model codecs. The first milestone covers scalar codecs and
`NodeId`; future work may add `Variant`, `DataValue`, `ExtensionObject`,
`SecureChannel`, and client/session layers.

## Working rules

- Use `apply_patch` for source and documentation edits.
- Keep every change focused on one user-visible capability.
- Run `moon fmt`, `moon check --deny-warn`, and `moon test --deny-warn`
  before committing.
- Add known-byte-vector tests for every encoding rule.
- Do not copy code or specifications without recording provenance and license.
- Do not push or publish without explicit approval from the repository owner.

## Architecture

- `moonua` root package: public binary codec and data model.
- Keep network transport, secure channels, and session state out of the codec.
- All decoders must be bounds checked and return typed `UaError` values.
- Encoding must be deterministic and preserve the selected numeric NodeId form.
