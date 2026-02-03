# Mee

Mee is a draft systems language that aims to be safer than C while staying predictable and portable.

## Quick Start

```
cd compiler
cargo run -- build ../examples/hello.mee --emit=wat
cargo run -- build ../examples/hello.mee --emit=asm
```

## Example

```
fn main() -> i32 {
  let x: i32 = 40;
  let y: i32 = 2;
  return x + y;
}
```

This currently emits WAT (WebAssembly text) and x86_64 SysV assembly. The x86_64 backend supports i32/bool with register and stack argument passing. Binary WASM and other native backends are planned.
