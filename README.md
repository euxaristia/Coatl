# Coatl

Coatl follows an ancient, sleek serpent aesthetic: fluid paths, precise control, and minimal friction.

Coatl is a systems language project with a self-hosting compiler path and an IR-driven native backend path.

## Quick Start

Build WAT (default `auto` path prefers selfhost):
```bash
./coatl build ./examples/hello.coatl --emit=wat -o /tmp/hello.wat
wasmtime --invoke main /tmp/hello.wat
```

Build x86_64 assembly via the IR pipeline:
```bash
./coatl build ./examples/hello.coatl --emit=asm --toolchain=ir -o /tmp/hello.s
```

Build x86_64 ELF object:
```bash
./coatl build ./examples/hello.coatl --emit=obj --toolchain=ir -o /tmp/hello.o
```

Build native x86_64 Linux binary:
```bash
./coatl build ./examples/hello.coatl --emit=bin --toolchain=ir -o /tmp/hello.bin
/tmp/hello.bin
```

Emit textual IR:
```bash
./coatl build ./examples/hello.coatl --emit=ir --toolchain=ir -o /tmp/hello.ir
```

## Core Tooling

- `./coatl build ... --emit=wat|ir|asm|obj|bin`
- `./coatl lower-ir input.ir -o output.wat`
- `./coatl --version`

Environment flags:
- `COATL_TOOLCHAIN=auto|selfhost|ir`
- `COATL_IR_FIRST_BUILD=1` to force auto mode to skip selfhost-first attempt

## Validation

Primary strict suite:
```bash
./tests/run_strict_no_rust_suite.sh
```

IR seam smoke:
```bash
./tests/run_ir_smoke.sh
```

x86_64 runtime suite:
```bash
./tests/run_x86_runtime_suite.sh
```

## Self-Hosting

Seeded selfhost build:
```bash
./selfhost/build_with_selfhost.sh build ./examples/hello.coatl -o /tmp/hello-self.wat
wasmtime --invoke main /tmp/hello-self.wat
```

Convergence/runtime checks:
```bash
./selfhost/check_self_compile.sh
./selfhost/check_self_compile_seed.sh
./selfhost/run_roundtrip_suite_seed.sh
./selfhost/run_selfhost_runtime_suite.sh
./selfhost/run_no_rust_ci.sh
```

Refresh committed seed:
```bash
./selfhost/update_seed.sh
```

## Repository Layout

- `examples/` sample programs
- `tests/` integration and smoke suites
- `selfhost/` bootstrap compiler and docs
- `tools/` IR frontend/lowerer/linker utilities
- `ROADMAP.md` near-term milestones
- `SPEC.md` language notes
