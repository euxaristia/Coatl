# Mee

Mee is a draft systems language that aims to be safer than C while staying predictable and portable. This repo contains:
- A Rust compiler that emits WAT (WebAssembly text) and x86_64 SysV assembly.
- A self-hosting bootstrap compiler written in Mee (`selfhost/bootstrap.mee`).
- A growing test suite and roadmap toward full self-hosting.

## Status (High Level)
- Parser, AST, and basic type checker (i32/bool/char, plus string literals as pointer values).
- WAT codegen with WASI I/O intrinsics (`fd_write`, `fd_read`, `path_open`, `fd_close`).
- x86_64 backend for scalar arithmetic and function calls (no WASI).
- Struct codegen: local struct values, field read/write, struct params, and struct returns.
- Bootstrap compiler can parse, compile to WAT, and verify output; self-hosting convergence is documented.

## Quick Start

Build WAT:
```bash
cd compiler
cargo run --quiet -- build ../examples/hello.mee --emit=wat
```

Run the WAT with wasmtime:
```bash
wasmtime --invoke main /tmp/hello.wat
```

Build x86_64 assembly:
```bash
cargo run --quiet -- build ../examples/hello.mee --emit=asm
```

Write output to a file:
```bash
cargo run --quiet -- build ../examples/hello.mee --emit=wat -o /tmp/hello.wat
```

## Hello World (Mee)

```mee
fn main() -> i32 {
  let msg: i32 = "Hello, world!\n";
  let iov: i32 = 64;
  let nwritten: i32 = 72;

  __mem_store(iov, msg);
  __mem_store(iov + 4, 14);
  __mem_store(nwritten, 0);

  __fd_write(1, iov, 1, nwritten);
  return 0;
}
```

## WASI Notes

The WAT output uses WASI imports for I/O. If your program calls `__path_open` or any file I/O, you must preopen a directory:
```bash
wasmtime --dir . --invoke main /tmp/hello.wat
```

## Repository Layout

- `compiler/`: Rust compiler (parser, type checker, WAT/x86_64 codegen).
- `examples/`: Sample programs (`hello.mee`).
- `selfhost/`: Bootstrap compiler and self-hosting documentation.
- `ROADMAP.md`: High-level milestones.
- `SPEC.md`: Language notes/spec.

## Limitations (Current)

- No binary WASM emitter yet (WAT only).
- x86_64 backend has no WASI/file I/O support.
- No ownership/borrow checker, enums, or pattern matching yet.
- Minimal type system (i32/bool/char + string literals as pointers).
- Bootstrap (Mee-in-Mee) compiler does not yet implement structs.

## Self-Hosting

The bootstrap compiler lives in `selfhost/bootstrap.mee`. Self-hosting progress and verification steps are tracked in `selfhost/SELFHOSTING.md`.

## Roadmap

See `ROADMAP.md` for the full plan. Near-term focus:
- Stage 6: bootstrap type checking and error reporting.
- WASM binary emitter.
- AArch64 backend.
