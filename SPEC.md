# Coatl Language Specification (Draft v0.1)

## Goals

- Be a systems language that is **safer than C**, while preserving **predictable performance**.
- Provide **explicit control** over memory and layout.
- Stay **portable** with a **standalone Python-based compiler** (no LLVM dependency).
- Support **x86_64** and **AArch64** as first-class native targets.

## Core Design Decisions

- **Syntax:** C-like, expression-oriented with blocks.
- **Memory model:** Manual memory access via intrinsics; ownership tracking planned.
- **Modules:** File-based modules (initial implementation).
- **Interop:** C FFI supported via assembly templates.

## Lexical Structure

- Identifiers: ASCII letters, digits, `_`, not starting with digit.
- Keywords: `fn`, `let`, `mut`, `return`, `if`, `else`, `while`, `struct`, `enum`, `import`, `extern`, `true`, `false`.
- Type keywords: `i32`, `i64`, `f32`, `f64`, `bool`, `str`.
- Integers: decimal literals, with optional type suffix (`42i64`).
- Floats: decimal with dot (`3.14`), optional suffix (`3.14f64`).
- Strings: Double-quoted, supports hex escapes (e.g., `\x1b`).

## Types

- Primitive: `i32`, `i64`, `f32`, `f64`, `bool`.
- String: `str` (fat pointer: `{ptr: i32, len: i32}` header).
- Arrays: `[T N]` fixed-size arrays.
- Structs: Flattened to fields in memory.

## Functions

```coatl
fn add(a: i32, b: i32) returns i32 {
  return a + b;
}
```

- `main` is the entry point.

## Expressions (v0.1 subset)

- Integer literals, identifiers, binary `+ - * /`, function calls.
- Blocks are expressions; last expression is the block value.

## Statements (v0.1 subset)

- `let` bindings: `let x: i32 = 42`

- `return`.

## Codegen Targets

- **x86_64 Linux** (System V AMD64 ABI).
- **AArch64 Linux**.

## CLI (compiler)

- `coatl build <file>`: Compile to native binary.
- `coatl build <file> -o out.s`: Emit assembly.
- `coatl build <file> -o out.ir`: Emit IR.

## Runtime Intrinsics

- Memory: `__mem_load`, `__mem_store`, `__mem_load8`, `__mem_store8`.
- Terminal mode:
  - `__tty_get_mode(fd: i32, out_ptr: i32) returns i32`
  - `__tty_set_raw(fd: i32, mode_ptr: i32, vmin: i32, vtime: i32) returns i32`
  - `__tty_restore(fd: i32, mode_ptr: i32) returns i32`
  - `__tty_get_size(fd: i32, out_ptr: i32) returns i32`

## Status

- This is a draft; features are being incrementally implemented in the Python toolchain.
