# Coatl Roadmap

Last updated: 2026-02-05

## Completed

- Lexer/parser/AST/type-checking baseline (`i32`/`bool`/`char`, string pointer literals)
- WAT backend with WASI-style I/O intrinsics
- x86_64 backend and direct IR->ASM lane
- IR->OBJ and IR->BIN outputs on Linux
- Internal minimal ELF linker for direct `--emit=bin` fallback path
- Selfhost bootstrap convergence checks and seed refresh flow
- Struct support across active compile/test lanes
- **Type-directed codegen**: `bool`, `i64`, `f32`, `f64`, `str`, `[T; N]` arrays with correct WASM opcode selection
- **IR v1 format** with type annotations on params, locals, returns, and binary operations
- **Selfhost type system expansion**: lexer, parser, and type checker updated for all new types

## Current Focus

- Increase subset frontend coverage so more programs compile through the IR-only lane
- Strengthen diagnostics and error spans in selfhost compiler
- Expand x86_64 runtime parity checks between WAT and native paths
- Keep strict suite green under constrained toolchains (`cc/gcc/clang/ld` blocked)
- Extend x86_64 backend for typed codegen (i64, f32, f64 registers)

## Next Milestones

### v0.3
- WASM binary emitter
- AArch64 backend
- Broader backend coverage for structs and control-flow heavy programs
- More negative tests for parser/type-checker behavior

### v0.4
- Promote Coatl-in-Coatl workflow as the default development path
- Deterministic self-compile + seed refresh checks in CI

### v1.0
- Stable standard library surface
- Package/dependency workflow
- Debug info and better developer tooling
