# Coatl Language Syntax Guide

Coatl is a C-like systems language with a minimal syntax designed for bootstrapping.

## Basic Structure

A Coatl program consists of a series of function definitions. There is no global scope for variables; all code must reside within functions.

```coatl
fn main() -> i32 {
  // Your code here
  return 0;
}
```

## Data Types

Coatl supports the following scalar types, with type-directed WebAssembly code generation:

| Type | Description | WASM type |
|------|-------------|-----------|
| `i32` | 32-bit signed integer | `i32` |
| `bool` | Boolean (`true`/`false`, stored as i32 0/1) | `i32` |
| `i64` | 64-bit signed integer | `i64` |
| `f32` | 32-bit float | `f32` |
| `f64` | 64-bit float | `f64` |
| `str` | String handle (pointer to {ptr, len} header) | `i32` |

### Composite Types

- **Structs:** User-defined structs with named fields (flattened to scalars).
- **Fixed-size arrays:** `[T; N]` where `T` is an element type and `N` is the size.

```coatl
let arr: [i32; 4] = [0; 4];
arr[0] = 10;
let x: i32 = arr[0];
```

## Variables

Variables must be declared with `let` and explicit types.

```coatl
let x: i32 = 42;
let y: i32 = x + 10;
let big: i64 = 100i64;
let pi: f32 = 3.14159;
```

**Reassignment:**
Variables are mutable and can be reassigned without `let`.

```coatl
x = 100;
```

## Functions

Functions are defined with `fn`, parameters, return type, and a body block.

```coatl
fn add(a: i32, b: i32) -> i32 {
  return a + b;
}
```

- **Return:** The `return` statement is mandatory for returning values.

## Control Flow

### If / Else
Standard C-style conditionals. Braces `{}` are required.

```coatl
if (x > 10) {
  x = x - 1;
} else {
  x = x + 1;
}
```

### While Loop
The only loop construct is `while`.

```coatl
while (running == 1) {
  // Loop body
}
```

## Literals

- **Integers:** `123`, `-45`, `0`.
- **i64 integers:** `42i64` (suffix denotes 64-bit).
- **Floats:** `3.14` (defaults to `f32`), `3.14f64` (explicit `f64`).
- **Booleans:** `true`, `false`.
- **Strings:** `"Hello\n"`. String literals are stored in the data segment. As `i32`, the value is a pointer to the raw bytes. As `str`, the value is a pointer to a `{ptr, len}` header.
- **Array initializers:** `[0; 4]` (creates a 4-element array filled with 0).

## String Intrinsics

When using the `str` type, the following intrinsics are available:

- `str_len(s: str) -> i32`: Returns the length of the string.
- `str_ptr(s: str) -> i32`: Returns the pointer to the raw string data.

```coatl
let s: str = "hello";
let n: i32 = str_len(s); // 5
```

## Intrinsics (Standard Library)

Coatl has no standard library in the traditional sense. It relies on compiler intrinsics for system interaction and memory access.

### Memory Access
Since Coatl has no pointer syntax (`*ptr`), you must use intrinsics to read/write memory directly using integer addresses.

- `__mem_load(addr: i32) -> i32`: Read an integer from address `addr`.
- `__mem_store(addr: i32, val: i32)`: Write integer `val` to address `addr`.
- `__mem_load8(addr: i32) -> i32`: Read a byte.
- `__mem_store8(addr: i32, val: i32)`: Write a byte.

### System Calls (WASI)
- `__fd_write(fd: i32, iov_ptr: i32, iov_cnt: i32, res_ptr: i32) -> i32`: Write to file descriptor.
- `__fd_read(fd: i32, iov_ptr: i32, iov_cnt: i32, res_ptr: i32) -> i32`: Read from file descriptor.
- `__tty_set_raw(fd: i32, mode_ptr: i32, vmin: i32, vtime: i32)`: Enable raw mode (if supported).

## Comments

Single-line comments start with `//`.

```coatl
// This is a comment
let a: i32 = 1;
```
