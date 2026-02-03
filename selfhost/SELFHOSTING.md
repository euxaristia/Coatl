# Self-Hosting Plan (WIP)

This repo doesn't yet have a Mee-written compiler. This directory will host a tiny, staged bootstrap compiler written in Mee.

## Constraints (current Mee compiler)
- No structs/field access codegen (parsing/typecheck exist, codegen panics).
- No arrays, no heap, no I/O.
- Strings are opaque pointers only; no string ops.

## Stages
1) Stage0: "compiler" that parses a *fixed* Mee subset (hardcoded input) and emits a constant WAT string.
2) Stage1: add a tiny lexer for integers and symbols using only numeric state (no strings).
3) Stage2: add an AST encoded without structs (e.g., parallel arrays) once arrays exist.
4) Stage3: switch to real structs after struct codegen exists.

## Next steps
- Keep the Stage0 program compiling with the current Rust compiler.
- Incrementally replace placeholders as the Rust compiler grows.
