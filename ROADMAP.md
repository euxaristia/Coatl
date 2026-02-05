# Mee Roadmap

Last updated: 2026-02-05

## Completed (through current head)

### Core compiler
- Lexer, parser, AST, and basic type checker (`i32`/`bool`/`char` + string pointers)
- WAT (WASM text) backend
- x86_64 SysV backend for scalar arithmetic + calls
- Memory intrinsics in both backends (`__mem_load`, `__mem_store`, `__mem_load8`, `__mem_store8`)
- WASI intrinsics wired (`__fd_write`, `__fd_read`, `__path_open`, `__fd_close`)
- Struct codegen for local values, field read/write, struct params/returns

### Self-host bootstrap
- Stages 0, 1, 1.5, 1.6, 1.7 complete
- Stage 3 complete (dynamic input from memory)
- Stage 4 complete (multi-function + params + args + assignments)
- Stage 5 nearly complete (WAT text output and file output path)
- Stage 6 partially complete:
  - Self-compile convergence checks automated
  - Round-trip suite automated
  - Struct-aware semantic checks in bootstrap compiler (including call argument typing)
  - Top-level `./mee` driver now defaults WAT builds to selfhost (`auto` toolchain mode)
  - Strict no-Rust mode available via `MEE_NO_RUST=1` for enforcing Rust-free compile paths

## Current Focus (next roadmap slice)

### v0.2
- Complete Stage 6 construct coverage audit for `selfhost/bootstrap.mee` (done)
- Strengthen bootstrap diagnostics (semantic/type errors with precise spans)
- Stabilize self-hosted behavior on full test corpus by default
- Add more negative tests (expected failures) for parser/type checker
- Continue closing remaining selfhost struct support gaps (field-level typing and diagnostics)

### v0.3
- WASM binary emitter (in addition to WAT)
- AArch64 backend
- Improve x86_64 backend coverage (feature parity where feasible; struct ABI runtime coverage now in suite)
- Grow `--emit=ir` into a stable non-Rust backend interface (current extraction seam in place)
- External non-Rust `lower-ir` -> WAT lane established (subset), expand coverage incrementally
- `./mee --toolchain=ir` now exercises Rust frontend + non-Rust WAT backend path for supported programs
- `./mee --toolchain=ir` can run in strict no-Rust mode via a non-Rust subset frontend (currently limited coverage)
- Strict no-Rust subset `toolchain=ir` currently covers `hello`, `mem_test`, `byte_test`, `array_sim`, control-flow subset tests, and `__fd_read` / `__path_open` / `__fd_write` / `__fd_close` probes
- `--toolchain=auto` now attempts non-Rust IR pipeline fallback before Rust backend fallback
- `--emit=ir --toolchain=auto` now attempts subset non-Rust frontend before Rust fallback
- Strict suite now verifies auto-mode no-Rust fallback across multiple runtime cases (not just hello)
- `--toolchain=ir` now tries subset non-Rust frontend first and falls back to Rust frontend only when needed
- Strict no-Rust subset frontend now also supports `./mee build --emit=ir --toolchain=ir` for supported programs
- `--emit=asm --toolchain=ir` now has a non-Rust subset lane (`tools/ir_to_x86_64_asm.py`) with Rust fallback when allowed
- Strict no-Rust asm smoke coverage now includes scalar/memory/control-flow, struct subset paths, and Linux I/O intrinsics via `tests/run_ir_x86_subset_asm_smoke.sh`
- Strict no-Rust now also verifies the same asm subset matrix through `--toolchain=auto` via `tests/run_auto_no_rust_asm_suite.sh`
- Strict no-Rust subset coverage now includes basic struct params/locals/returns paths in `--toolchain=ir` (`tests/struct_param_pass.mee`, `tests/struct_return_basic.mee`, `tests/struct_chain_calls.mee`)
- Strict no-Rust subset coverage now includes struct field mutation lowering (`tests/struct_field_mutation_subset.mee`)
- Strict no-Rust subset coverage now includes nested struct-return calls in arg position (`tests/struct_nested_arg_subset.mee`)
- Strict no-Rust subset coverage now includes control-flow/local-let struct-return bodies (`tests/struct_return_if_subset.mee`)
- Strict no-Rust subset coverage now includes loop-based struct-return body lowering (`tests/struct_return_while_subset.mee`)
- Strict no-Rust auto-fallback suite now exercises the same struct set through forced selfhost-failure -> IR pipeline fallback

### v0.4 (self-hosting)
- Make Mee-in-Mee compiler the default development compiler
- Keep Rust compiler as reference/fallback during transition
- Document and enforce deterministic self-compile in CI

### v1.0
- Stable standard library
- Package manager
- Debug info + developer tooling

---

## Self-Hosting Dependency Graph

```
Stage 5 (WAT text output + file output)
        │
        ▼
Stage 6 completion (full construct coverage + diagnostics)
        │
        ▼
Mee-in-Mee as default compiler (v0.4)
        │
        ▼
Binary/backend/tooling maturity (v1.0 track)
```

For stage-by-stage bootstrap detail, see `selfhost/SELFHOSTING.md`.
