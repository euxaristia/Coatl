# Coatl

Coatl follows an ancient, sleek serpent aesthetic: fluid paths, precise control, and minimal friction.

Coatl is a native systems language focusing on x86_64 and AArch64 Linux backends.

## Documentation

- Wiki: https://github.com/euxaristia/Coatl/wiki
- Language draft/spec: `SPEC.md`

## Quick Start

Build native x86_64 Linux binary:
```bash
./coatl build ./examples/hello.coatl -o /tmp/hello
/tmp/hello
```

Build x86_64 assembly:
```bash
./coatl build ./examples/hello.coatl -o /tmp/hello.s
```

Build ELF object:
```bash
./coatl build ./examples/hello.coatl -o /tmp/hello.o
```

Emit textual IR:
```bash
./coatl build ./examples/hello.coatl -o /tmp/hello.ir
```

## Core Tooling

- `./coatl build ...`
- `./coatl run-cbyte <input.cbyte>`
- `./coatl --version`

Environment flags:
- `COATL_ARCH=x86_64|aarch64` (auto-detects by default)
- `COATL_HOME` to a Coatl repo root if tools are not found

## Terminal Raw Mode Intrinsics

For terminal games on Linux, Coatl exposes:
- `__tty_get_mode(fd: i32, out_ptr: i32) -> i32`
- `__tty_set_raw(fd: i32, mode_ptr: i32, vmin: i32, vtime: i32) -> i32`
- `__tty_restore(fd: i32, mode_ptr: i32) -> i32`
- `__tty_get_size(fd: i32, out_ptr: i32) -> i32`

Behavior:
- Native (Linux): backed by `termios` (`ioctl`), returns `0` on success or errno on failure.
- Non-TTY stdin is preserved: calls fail with errno from the OS (for example `ENOTTY`).

Caveats:
- Raw mode should always be restored before process exit.

## Validation

IR seam smoke:
```bash
./tests/run_ir_smoke.sh
```

x86_64 runtime suite:
```bash
./tests/run_x86_runtime_suite.sh
```

AArch64 runtime suite:
```bash
./tests/run_aarch64_runtime_suite.sh
```

## Repository Layout

- `examples/` sample programs
- `tests/` integration and smoke suites
- `tools/` IR frontend/lowerer/linker utilities
- `ROADMAP.md` near-term milestones
- `SPEC.md` language notes

## Safety & Memory Model

Coatl is a low-level systems language. It is **not memory safe** and provides fewer guardrails than C.

- **Manual Memory:** Memory is accessed via raw intrinsics (__mem_load/__mem_store) with integer addresses. No pointers or bounds checks.
- **System Access:** Direct interaction with Linux system calls via assembly lowerers.

For more details on how to write Coatl, see the [Syntax Guide](./SYNTAX.md).
