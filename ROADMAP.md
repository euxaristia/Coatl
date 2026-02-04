# Mee Roadmap

## v0.1 (now)
- Lexer + parser + AST
- Type checker for integers/bool
- WASM text emitter (WAT)
- Basic `fn`, `return`, integer arithmetic
- Bootstrap Stage 0: pipeline validated with hardcoded input

## v0.1.1 (next - memory ops)
- `i32.load` / `i32.store` in WAT codegen
- Array type `[T; N]` with fixed size
- Index expression `arr[i]` for read/write
- **Unlocks**: Bootstrap Stage 1 (dynamic AST/IR storage)

## v0.1.2 (struct codegen)
- Struct field access in WAT codegen (currently panics)
- Struct init expression codegen
- **Unlocks**: Bootstrap Stage 2 (proper data structures)

## v0.2
- Ownership/borrow checking
- Enums, pattern matching
- WASI I/O (`fd_read`, `fd_write`)
- **Unlocks**: Bootstrap Stage 3-5 (file I/O, arbitrary input)

## v0.3
- WASM binary emitter
- x86_64 SysV backend
- AArch64 backend

## v0.4 (self-hosting)
- Bootstrap compiler can compile itself
- Drop Rust compiler dependency for development
- Mee-in-Mee: all future development in Mee

## v1.0
- Stable standard library
- Package manager
- Debug info + tooling

---

## Self-Hosting Dependency Graph

```
v0.1.1 (arrays) ──► Stage 1: Dynamic AST storage
         │
         ▼
v0.1.2 (structs) ──► Stage 2: Proper node types
         │
         ▼
v0.2 (WASI I/O) ──► Stage 3-5: File I/O, arbitrary input
         │
         ▼
v0.4 ◄─────────────► Stage 6: Self-compile
```

See `selfhost/SELFHOSTING.md` for detailed bootstrap stages.
