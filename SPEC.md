# Coatl Language Specification (Draft v0.1)

## Goals
- Be a systems language that is **safer than C**, while preserving **predictable performance**.
- Provide **explicit control** over memory and layout with **compiler-verified ownership**.
- Stay **portable** with a **standalone compiler** (no LLVM dependency).
- Support **x86_64**, **AArch64**, and **WASM** as first-class targets.

## Core Design Decisions
- **Syntax:** C-like, expression-oriented with blocks.
- **Memory model:** Ownership + borrowing (no GC). Move-by-default, explicit `&` borrow.
- **Error handling:** `Result[T, E]` and `Option[T]`; no exceptions in v0.x.
- **Modules:** File-based modules with explicit `import`.
- **Interop:** C FFI supported via `extern` blocks.

## Lexical Structure
- Identifiers: ASCII letters, digits, `_`, not starting with digit.
- Keywords: `fn`, `let`, `mut`, `return`, `if`, `else`, `while`, `struct`, `enum`, `import`, `extern`, `true`, `false`.
- Integers: decimal literals only in v0.1.

## Types
- Primitive: `i32`, `i64`, `u32`, `u64`, `bool`, `void`.
- Pointers: `*T` (raw, unsafe) and `&T` (borrowed, safe).
- Structs/enums (declared but minimal support in v0.1).

## Functions
```
fn add(a: i32, b: i32) -> i32 {
  return a + b;
}
```
- Functions are pure by default; `mut` allows mutation.
- `main` is the entry point.

## Expressions (v0.1 subset)
- Integer literals, identifiers, binary `+ - * /`, function calls.
- Blocks are expressions; last expression is the block value.

## Statements (v0.1 subset)
- `let` bindings: `let x: i32 = 42;`
- `return`.

## Ownership + Borrowing (v0.1 rules)
- Values move by default.
- `&T` is an immutable borrow; `&mut T` is a mutable borrow.
- Borrow rules: many readers or one writer, not both.

## Unsafe
- Raw pointers `*T` are allowed in `unsafe` blocks (future).

## Codegen Targets
- **WASM** (baseline target for v0.1).
- **x86_64 SysV** and **AArch64** are planned for v0.2+.

## CLI (compiler)
- `coatl build <file>`
- `coatl build <file> --emit=wat` (default)
- `coatl build <file> --emit=asm` (x86_64 SysV)
- `coatl build <file> --emit=wasm` (planned)

## Status
- This is a draft; features will be staged via ROADMAP.md.
