# Coatl

Coatl follows an ancient, sleek serpent aesthetic: fluid paths, precise control, and minimal friction.

Coatl is a native systems language focusing on x86_64 and AArch64 Linux backends. The compiler is implemented in Rust.

## Documentation

The official documentation is available on the GitHub Wiki: <https://github.com/euxaristia/Coatl/wiki>

## Quick Start

Here is a simple "Hello, world!" program in Coatl (`examples/hello.coatl`):

```coatl
import "std/io"

fn main() returns i32 {
  io.print("Hello, world!\n")
  return 0
}
```

Build and install the compiler:

```bash
cargo build --release
```

Build a native x86_64 Linux binary:

```bash
./target/release/coatl examples/hello.coatl -o /tmp/hello
/tmp/hello
```

Build x86_64 assembly:

```bash
./target/release/coatl examples/hello.coatl -o /tmp/hello.s
```

Emit textual IR:

```bash
./target/release/coatl examples/hello.coatl -o /tmp/hello.ir
```

## Core Tooling

Usage:

```
coatl <input.coatl|input.ir> [-o output] [--arch=<arch>]
```

Output format is inferred from the `-o` extension:
- `.s` — assembly source
- `.ir` — textual IR
- anything else — linked ELF binary

Environment flags:

- `CC` — override the C compiler/linker (default: `cc`)
- `--arch=x86_64|aarch64` — target architecture (default: `x86_64`)

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

Run all tests:

```bash
cargo test
```

## Repository Layout

- `examples/` — sample programs
- `tests/` — integration and smoke suites
- `src/` — compiler source (Rust)
- `runtime/` — intrinsics assembly (`intrinsics.s`, `intrinsics_aarch64.s`)
- `std/` — standard library modules
- `man/` — manual pages

## Safety & Memory Model

Coatl is a low-level systems language. It is **not memory safe** and provides fewer guardrails than C.

- **Manual Memory:** Memory is accessed via raw intrinsics (`__mem_load`/`__mem_store`) with integer addresses. No pointers or bounds checks.
- **System Access:** Direct interaction with Linux system calls via assembly templates.
