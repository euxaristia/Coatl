# Coatl Language Specification (Draft v0.1)

## Goals
- Be a systems language that is **safer than C**, while preserving **predictable performance**.
- Provide **explicit control** over memory and layout with **compiler-verified ownership**.
- Stay **portable** with a **standalone compiler** (no LLVM dependency).
- Support **x86_64** and **AArch64** as first-class targets.

## Core Design Decisions
- **Syntax:** C-like, expression-oriented with blocks.
- **Memory model:** Ownership + borrowing (no GC). Move-by-default, explicit `&` borrow.
- **Error handling:** `Result[T, E]` and `Option[T]`; no exceptions in v0.x.
- **Modules:** File-based modules with explicit `import`.
- **Interop:** C FFI supported via `extern` blocks.

## Lexical Structure
- Identifiers: ASCII letters, digits, `_`, not starting with digit.
- Keywords: `fn`, `let`, `mut`, `return`, `if`, `else`, `while`, `struct`, `enum`, `import`, `extern`, `true`, `false`.
- Type keywords: `i32`, `i64`, `f32`, `f64`, `bool`, `str`.
- Integers: decimal literals, with optional type suffix (`42i64`).
- Floats: decimal with dot (`3.14`), optional suffix (`3.14f64`).

## Types
- Primitive: `i32`, `i64`, `f32`, `f64`, `bool`.
- String: `str` (fat pointer: `{ptr: i32, len: i32}` header).
- Arrays: `[T N]` fixed-size arrays (heap-allocated via bump allocator).
- Structs (passed by value, flattened to scalar fields).
- Pointers: `*T` (raw, unsafe) and `&T` (borrowed, safe) are planned.
- Enums: planned for future versions.

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
- `let` bindings: `let x: i32 = 42`
- `return`.

## Ownership + Borrowing (v0.1 rules)
- Values move by default.
- `&T` is an immutable borrow; `&mut T` is a mutable borrow.
- Borrow rules: many readers or one writer, not both.

## Unsafe
- Raw pointers `*T` are allowed in `unsafe` blocks (future).

## Codegen Targets
- **x86_64 SysV** and **AArch64** are the primary targets.

## CLI (compiler)
- `coatl build <file>`
- `coatl build <file> --emit=asm` (x86_64 SysV)

## Runtime Intrinsics (Current)
- Memory: `__mem_load`, `__mem_store`, `__mem_load8`, `__mem_store8`
- Terminal mode (POSIX/Linux x86_64 native bin lane):
  - `__tty_get_mode(fd: i32, out_ptr: i32) -> i32`
  - `__tty_set_raw(fd: i32, mode_ptr: i32, vmin: i32, vtime: i32) -> i32`
  - `__tty_restore(fd: i32, mode_ptr: i32) -> i32`
  - `__tty_get_size(fd: i32, out_ptr: i32) -> i32`

Notes:
- TTY intrinsics return `0` on success, nonzero errno on failure.

## Status
- This is a draft; features will be staged via ROADMAP.md.
