# Self-Hosting Quick Guide (Plain English)

This is a short, plain-language primer so you can read the self-hosting work without needing prior WASM/WASI knowledge.

## 1) Big Picture

There are two compilers in this repo:

- **Rust compiler** (`compiler/`): the current "real" compiler.
- **Bootstrap compiler** (`selfhost/bootstrap.mee`): a compiler written in Mee that will eventually compile itself.

The goal of **self-hosting** is for the bootstrap compiler to compile its own source, so Mee can be developed without the Rust compiler.

## 2) What "WAT output" means

Mee currently emits **WAT**, which is WebAssembly Text format. It's the human-readable form of WebAssembly.

Example (very small WAT):
```
(module
  (func $main (result i32)
    i32.const 42
    return
  )
  (export "main" (func $main))
)
```

The bootstrap compiler builds this WAT text in memory before we can write it anywhere.

## 3) Why we care about "stdout"

Programs can print to the terminal (stdout). In WASI (WebAssembly System Interface),
the low-level function that writes to stdout is `fd_write`.

So if the bootstrap compiler can call **`fd_write`**, it can print its generated WAT
text to the terminal.

That's the Stage 5 goal: "the compiler can write its output somewhere".

## 4) The `__fd_write` intrinsic

Mee doesn't directly know about WASI, so we add a special **intrinsic** function:

```
__fd_write(fd, iov_ptr, iov_cnt, nwritten_ptr) -> i32
```

- `fd`: which output (1 = stdout)
- `iov_ptr`: pointer to a memory buffer
- `iov_cnt`: how many buffers (usually 1)
- `nwritten_ptr`: where to store the number of bytes written

The Rust compiler recognizes this intrinsic and emits the right WASI call in WAT.

## 5) Output buffer and `out_flush`

The bootstrap compiler already builds WAT text into an in-memory output buffer.

We added `out_flush()`:

- It builds a tiny "iov" structure in memory
- Then calls `__fd_write(1, iov_ptr, 1, nwritten_ptr)`
- This prints the buffer to stdout

So:

- `gen_wat_module_all()` creates WAT in memory
- `out_flush()` prints it

## 6) The runtime flag (so it doesn’t always print)

In `selfhost/bootstrap.mee`, we added:

```
fn emit_wat_stdout_enabled() -> i32 { return 0; }
```

If this returns `1`, the compiler prints WAT to stdout.
If it returns `0`, it doesn’t.

Right now it’s **hardcoded**, so you have to edit that function if you want output.

## 7) Where to look in the code

- Rust compiler WAT codegen: `compiler/src/codegen.rs`
- Rust compiler type checker: `compiler/src/typecheck.rs`
- Bootstrap compiler: `selfhost/bootstrap.mee`
  - Output buffer and WAT generation: search for `Stage 5: WAT Text Output`
  - `out_flush()` and `compile_program_to_stdout()` are near the Stage 5 section

## 8) Glossary (super short)

- **WAT**: WebAssembly Text format
- **WASI**: System interface for WebAssembly (like a minimal OS API)
- **stdout**: terminal output
- **intrinsic**: a built-in function that the compiler treats specially

## 9) If you want a 1‑line summary

We taught the bootstrap compiler how to print its generated WAT text to stdout, by
adding a `__fd_write` intrinsic and an `out_flush()` function.

