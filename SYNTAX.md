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

Currently, Coatl primarily supports `i32` (32-bit signed integer).

- `i32`: Used for numbers, booleans (0/1), and memory addresses (pointers).

## Variables

Variables must be declared with `let` and explicit types.

```coatl
let x: i32 = 42;
let y: i32 = x + 10;
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
- **Strings:** `"Hello
"`. String literals are stored in the data segment, and their value in code is a `i32` pointer to the start of the string.

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
