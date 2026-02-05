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
- Strict no-Rust subset `toolchain=ir` currently covers `hello`, `mem_test`, and `byte_test`

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
