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

Build WAT (default path prefers selfhost, no Rust required):
```bash
./mee build ./examples/hello.mee --emit=wat -o /tmp/hello.wat
```

Run the WAT with wasmtime:
```bash
wasmtime --invoke main /tmp/hello.wat
```

Build x86_64 assembly (currently Rust-backed):
```bash
./mee build ./examples/hello.mee --emit=asm --toolchain=rust -o /tmp/hello.s
```

Emit backend-neutral IR (S-expression form, currently Rust-backed):
```bash
./mee build ./examples/hello.mee --emit=ir --toolchain=rust -o /tmp/hello.ir
```

Run the x86_64 runtime suite (Linux):
```bash
./tests/run_x86_runtime_suite.sh
```

Run the IR seam smoke suite:
```bash
./tests/run_ir_smoke.sh
```

Run the no-Rust CLI smoke suite:
```bash
./tests/run_cli_no_rust_smoke.sh
```

Run strict no-Rust mode checks:
```bash
./tests/run_strict_no_rust_suite.sh
```

Run Rust-frontend + external-backend (`toolchain=ir`) smoke suite:
```bash
./tests/run_ir_backend_smoke.sh
```

Run no-Rust subset frontend + external backend suite:
```bash
./tests/run_ir_subset_backend_suite.sh
```
Run no-Rust subset I/O smoke (`__fd_read`):
```bash
./tests/run_ir_subset_io_smoke.sh
```
Run no-Rust subset `__path_open` probe smoke:
```bash
./tests/run_ir_subset_path_open_smoke.sh
```
Run no-Rust subset write/close smoke (`__path_open + __fd_write + __fd_close`):
```bash
./tests/run_ir_subset_path_open_write_close_smoke.sh
```

Run no-Rust subset frontend IR emission smoke:
```bash
./tests/run_ir_subset_frontend_smoke.sh
```

Check Rust compile-entrypoint centralization:
```bash
./tests/check_rust_entrypoint_centralization.sh
```

Lower IR to WAT via external (non-Rust) backend lane:
```bash
./mee lower-ir /tmp/prog.ir -o /tmp/prog.wat
```

Compile Mee source with Rust frontend + external non-Rust WAT backend:
```bash
./mee build ./examples/hello.mee --emit=wat --toolchain=ir -o /tmp/hello-ir-backend.wat
```

In strict no-Rust mode, `--toolchain=ir` uses a non-Rust subset frontend for supported programs:
```bash
MEE_NO_RUST=1 ./mee build ./examples/hello.mee --emit=wat --toolchain=ir -o /tmp/hello-ir-norust.wat
```
And for IR output itself:
```bash
MEE_NO_RUST=1 ./mee build ./examples/hello.mee --emit=ir --toolchain=ir -o /tmp/hello.ir
```
In `--toolchain=auto`, `--emit=ir` now also prefers the subset frontend before any Rust fallback.
Current strict subset coverage includes `hello`, `mem_test`, `byte_test`, and `array_sim` via `./tests/run_ir_subset_backend_suite.sh`.
It also includes control flow (`if`/`while`) and boolean/comparison operators via `tests/ir_subset_control_flow.mee`, plus `__fd_read` and `__path_open` probes via `tests/run_ir_subset_io_smoke.sh` and `tests/run_ir_subset_path_open_smoke.sh`, and write/close flow via `tests/run_ir_subset_path_open_write_close_smoke.sh`.
In `--toolchain=auto`, if selfhost WAT compilation fails, `./mee` now tries the non-Rust IR pipeline before any Rust fallback.

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
- `--emit=ir` is a typed AST/IR seam intended for external (non-Rust) backend work; native backend production flow is still Rust-owned today.
- `MEE_NO_RUST=1` forbids Rust compiler usage/fallback in `./mee`; `--emit=asm` and `--emit=ir` currently fail in this mode.
- x86_64 backend supports Mee I/O intrinsics (`__fd_write`, `__fd_read`, `__path_open`, `__fd_close`) via Linux syscalls.
- x86_64 runtime suite covers scalar, memory, I/O, and struct ABI cases.
- x86_64 runtime helper path is Linux-oriented today; AArch64 backend is not implemented yet.
- No ownership/borrow checker, enums, or pattern matching yet.
- Minimal type system (i32/bool/char + string literals as pointers).
- Bootstrap (Mee-in-Mee) compiler now parses struct declarations/types/field access/literals natively for the selfhost WASM path, including stricter struct-aware call typing checks.

## Self-Hosting

The bootstrap compiler lives in `selfhost/bootstrap.mee`. Self-hosting progress and verification steps are tracked in `selfhost/SELFHOSTING.md`.

Rust-free (seeded) compile path:
```bash
./selfhost/build_with_selfhost.sh build ./examples/hello.mee -o /tmp/hello-self.wat
wasmtime --invoke main /tmp/hello-self.wat
```

Rust-free convergence + runtime checks:
```bash
./selfhost/check_self_compile.sh
./selfhost/check_self_compile_seed.sh
./selfhost/run_selfhost_runtime_suite.sh
./selfhost/run_roundtrip_suite_seed.sh
./selfhost/run_no_rust_ci.sh
```

Refresh the committed seed (default: no Rust):
```bash
./selfhost/update_seed.sh
```

Refresh seed using Rust-assisted trust chain (optional):
```bash
./selfhost/update_seed.sh --with-rust
```

## Roadmap

See `ROADMAP.md` for the full plan. Near-term focus:
- Stage 6: bootstrap type checking and error reporting.
- WASM binary emitter.
- AArch64 backend.
