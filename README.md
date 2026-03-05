# Coatl

Coatl follows an ancient, sleek serpent aesthetic: fluid paths, precise control, and minimal friction.

Coatl is a native systems language focusing on x86_64 and AArch64 Linux backends. The compiler is implemented in Python for maximum portability and developer agility.

## Documentation

- Wiki: https://github.com/euxaristia/Coatl/wiki
- Language draft/spec: `SPEC.md`

## Quick Start

Here is a simple "Hello, world!" program in Coatl (`examples/hello.coatl`):

```coatl
fn main() -> i32 {
  // message string is stored in the data segment pointer returned by the literal
  let msg: i32 = "Hello, world!\n"
  let iov: i32 = 64
  let nwritten: i32 = 80

  __mem_store(iov, msg)
  __mem_store(iov + 4, 14)
  __mem_store(nwritten, 0)

  __fd_write(1, iov, 1, nwritten)
  return 0
}
```

Build native x86_64 Linux binary:
```bash
./coatl build ./examples/hello.coatl -o /tmp/hello
/tmp/hello
```

Build x86_64 assembly:
```bash
./coatl build ./examples/hello.coatl -o /tmp/hello.s
```

Build ELF binary (linked with intrinsics):
```bash
./coatl build ./examples/hello.coatl -o /tmp/hello
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

Run core tests:
```bash
make test
```

IR smoke suite:
```bash
python3 tests/run_ir_smoke.py
```

Snake smoke test (x86_64 native):
```bash
python3 tests/run_snake_smoke.py
```

## Repository Layout

- `examples/` sample programs
- `tests/` integration and smoke suites
- `tools/` Python-based compiler and utilities
- `ROADMAP.md` near-term milestones
- `SPEC.md` language notes

## Safety & Memory Model

Coatl is a low-level systems language. It is **not memory safe** and provides fewer guardrails than C.

- **Manual Memory:** Memory is accessed via raw intrinsics (__mem_load/__mem_store) with integer addresses. No pointers or bounds checks.
- **System Access:** Direct interaction with Linux system calls via assembly templates.

For more details on how to write Coatl, see the [Syntax Guide](./SYNTAX.md).
