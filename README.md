# Mee

Mee is a draft systems language that aims to be safer than C while staying predictable and portable. This repo contains:
- A self-hosting bootstrap compiler written in Mee (`selfhost/bootstrap.mee`).
- A growing test suite and roadmap toward full self-hosting.
- Non-Rust IR lowerers for WAT and x86_64 assembly.

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

Build x86_64 assembly (Rust backend):
```bash
./mee build ./examples/hello.mee --emit=asm --toolchain=rust -o /tmp/hello.s
```

Build x86_64 assembly via non-Rust IR subset backend:
```bash
./mee build ./examples/hello.mee --emit=asm --toolchain=ir -o /tmp/hello-ir.s
```

Install `mee` to your `PATH`:
```bash
make install
```
By default this installs to `/usr/local/bin/mee`. Override prefix if needed:
```bash
make install PREFIX="$HOME/.local"
```

Emit backend-neutral IR (S-expression form, currently Rust-backed):
```bash
./mee build ./examples/hello.mee --emit=ir --toolchain=rust -o /tmp/hello.ir
```

Run the x86_64 runtime suite (Linux):
```bash
./tests/run_x86_runtime_suite.sh
```
Run the same x86_64 runtime suite through strict no-Rust `toolchain=ir`:
```bash
./tests/run_x86_runtime_suite_ir_no_rust.sh
```
Run the same x86_64 runtime suite through strict no-Rust `toolchain=auto`:
```bash
./tests/run_x86_runtime_suite_auto_no_rust.sh
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
Run no-Rust subset x86_64 asm smoke suite:
```bash
./tests/run_ir_x86_subset_asm_smoke.sh
```
This suite currently covers scalar/memory/control-flow, struct flows, and Linux I/O intrinsics (`__fd_read`, `__path_open`, `__fd_write`, `__fd_close`).
Run no-Rust auto-mode x86_64 asm suite:
```bash
./tests/run_auto_no_rust_asm_suite.sh
```
Run no-Rust backend parity suite (WAT vs ASM) for subset corpus:
```bash
./tests/run_no_rust_backend_parity_suite.sh
```
Run no-Rust bootstrap compile check through `toolchain=ir`:
```bash
./tests/run_no_rust_bootstrap_ir_compile.sh
```
Run full no-Rust `toolchain=ir` compile coverage (`tests/`, `examples/`, `selfhost/`):
```bash
./tests/run_no_rust_ir_full_compile_coverage.sh
```
Run full no-Rust `--emit=ir --toolchain=ir` coverage (`tests/`, `examples/`, `selfhost/`):
```bash
./tests/run_no_rust_ir_emit_full_coverage.sh
```
Run full no-Rust `--emit=asm --toolchain=ir` compile coverage (`tests/`, `examples/`, `selfhost/`):
```bash
./tests/run_no_rust_ir_full_asm_compile_coverage.sh
```
Run full no-Rust `--toolchain=auto` WAT compile coverage (`tests/`, `examples/`, `selfhost/`):
```bash
./tests/run_no_rust_auto_full_wat_compile_coverage.sh
```
Run full no-Rust `--toolchain=auto` WAT compile coverage with default seed/selfhost attempt path:
```bash
./tests/run_no_rust_auto_full_wat_compile_default_seed_coverage.sh
```
Run full no-Rust `--emit=ir --toolchain=auto` coverage:
```bash
./tests/run_no_rust_auto_full_ir_emit_coverage.sh
```
Run full no-Rust `--emit=asm --toolchain=auto` coverage:
```bash
./tests/run_no_rust_auto_full_asm_compile_coverage.sh
```
Run no-Rust guard that fails if any path invokes `cargo`:
```bash
./tests/run_no_rust_no_cargo_guard.sh
```
Run branch-mode no-Rust full coverage (uses `MEE_NO_RUST_BUILD=1` + cargo shadow guard):
```bash
./tests/run_no_rust_build_mode_full_coverage.sh
```
Run branch-mode check that `auto` prefers IR pipeline (skips selfhost-first attempt):
```bash
./tests/run_no_rust_build_mode_prefers_ir.sh
```
Run branch-mode check that temporarily disables `compiler/` and verifies no-rust-build still works:
```bash
./tests/run_no_rust_build_without_compiler_dir.sh
```
Run strongest pre-delete gate: strict no-rust suite with `compiler/` temporarily removed:
```bash
./tests/run_no_rust_build_strict_without_compiler_dir.sh
```
Run smoke test for expected rust-toolchain failure message when `compiler/` is missing:
```bash
./tests/run_missing_compiler_rust_lane_smoke.sh
```
Rust-legacy helper suites now gracefully fall back/skip when Rust lane is unavailable (`compiler/` missing or `MEE_NO_RUST_BUILD=1`), including `selfhost/check_self_compile.sh --with-rust`, `selfhost/run_roundtrip_suite.sh --with-rust`, and `tests/run_ir_smoke.sh`.
Run full no-Rust default CLI coverage (no explicit `--toolchain`) for WAT/IR/ASM:
```bash
./tests/run_no_rust_default_cli_full_wat_compile_coverage.sh
./tests/run_no_rust_default_cli_full_ir_emit_coverage.sh
./tests/run_no_rust_default_cli_full_asm_compile_coverage.sh
```
Run default-CLI no-Rust backend parity suite (WAT vs ASM):
```bash
./tests/run_no_rust_default_cli_backend_parity_suite.sh
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
Run no-Rust auto-fallback suite (forces selfhost failure, expects IR fallback):
```bash
./tests/run_auto_no_rust_fallback_suite.sh
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
For `--toolchain=ir`, `./mee` now prefers the subset non-Rust frontend and uses Rust frontend only as a fallback for unsupported programs.
The strict subset frontend now includes struct params/locals, field assignment (`p.x = ...`), nested struct-return calls in argument position, and struct-return body lowering with local `let` + `if`/`else`/`while` by flattening struct values into i32 field lanes (`tests/struct_param_pass.mee`, `tests/struct_return_basic.mee`, `tests/struct_chain_calls.mee`, `tests/struct_field_mutation_subset.mee`, `tests/struct_nested_arg_subset.mee`, `tests/struct_return_if_subset.mee`, `tests/struct_return_while_subset.mee`).
The non-Rust WAT lowerer now handles nested-block `let` locals correctly (covered by `tests/nested_let_scope_subset.mee`), and strict no-Rust also guards that `selfhost/bootstrap.mee` compiles through `--toolchain=ir` via `tests/run_no_rust_bootstrap_ir_compile.sh`.
Strict no-Rust also guards full `--toolchain=ir` compile coverage across `tests/`, `examples/`, and `selfhost/` via `tests/run_no_rust_ir_full_compile_coverage.sh`.
Strict no-Rust also guards full `--emit=ir --toolchain=ir` coverage across `tests/`, `examples/`, and `selfhost/` via `tests/run_no_rust_ir_emit_full_coverage.sh`.
Strict no-Rust also guards full `--emit=asm --toolchain=ir` compile coverage across `tests/`, `examples/`, and `selfhost/` via `tests/run_no_rust_ir_full_asm_compile_coverage.sh`.
Strict no-Rust also guards full `--toolchain=auto` compile/emission coverage for WAT/IR/ASM via `tests/run_no_rust_auto_full_wat_compile_coverage.sh`, `tests/run_no_rust_auto_full_ir_emit_coverage.sh`, and `tests/run_no_rust_auto_full_asm_compile_coverage.sh`.
Strict no-Rust also guards full `--toolchain=auto` WAT compile coverage through the default seed/selfhost-attempt path via `tests/run_no_rust_auto_full_wat_compile_default_seed_coverage.sh`.
Strict no-Rust also guards against accidental Cargo invocation in no-Rust paths via `tests/run_no_rust_no_cargo_guard.sh`.
Strict no-Rust also guards full default CLI (`./mee build ...` without explicit `--toolchain`) no-Rust coverage for WAT/IR/ASM via `tests/run_no_rust_default_cli_full_wat_compile_coverage.sh`, `tests/run_no_rust_default_cli_full_ir_emit_coverage.sh`, and `tests/run_no_rust_default_cli_full_asm_compile_coverage.sh`.
Strict no-Rust also guards default-CLI no-Rust runtime parity between WAT and ASM via `tests/run_no_rust_default_cli_backend_parity_suite.sh`.
Strict no-Rust also includes branch-mode coverage via `tests/run_no_rust_build_mode_full_coverage.sh`, which validates full default CLI corpus coverage under `MEE_NO_RUST_BUILD=1` and fails on any accidental Cargo invocation.
In `MEE_NO_RUST_BUILD=1` mode, `auto` now skips selfhost-first WAT attempt and prefers the IR pipeline directly (checked by `tests/run_no_rust_build_mode_prefers_ir.sh`).
Strict no-Rust also verifies `MEE_NO_RUST_BUILD=1` operation with `compiler/` temporarily removed via `tests/run_no_rust_build_without_compiler_dir.sh`.
In `--toolchain=auto` WAT mode, `./mee` now validates selfhost output as a compilable module (`wasmtime compile`) and falls back to the IR pipeline if selfhost emits invalid WAT.
The forced auto no-Rust fallback suite also includes these struct cases, so struct coverage is validated through fallback-to-IR, not only direct `--toolchain=ir`.

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

- `examples/`: Sample programs (`hello.mee`).
- `selfhost/`: Bootstrap compiler and self-hosting documentation.
- `tools/`: Non-Rust frontend/lowerer utilities for IR/WAT/ASM lanes.
- `ROADMAP.md`: High-level milestones.
- `SPEC.md`: Language notes/spec.

## Limitations (Current)

- No binary WASM emitter yet (WAT only).
- `--emit=ir` is a typed AST/IR seam intended for external (non-Rust) backend work; native backend production flow is still Rust-owned today.
- `MEE_NO_RUST=1` forbids Rust compiler usage/fallback in `./mee`; `--emit=asm --toolchain=ir` and `--emit=ir --toolchain=ir` work for the current subset coverage.
- `--toolchain=rust` is currently unavailable unless an external Rust compiler lane is reintroduced.
- Strict no-Rust `--toolchain=ir` coverage now includes scalar/control-flow/I/O plus basic struct params/locals/returns paths.
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
