# Self-Hosting Plan (WIP)

This repo doesn't yet have a Mee-written compiler. This directory will host a tiny, staged bootstrap compiler written in Mee.

## Current Status

**Stage 0 complete**: The bootstrap compiler validates a full pipeline over hardcoded input:
- Lexer: tokenizes `fn main() -> i32 { let x: i32 = 1; let y: i32 = 2; return x + y; }`
- Parser: validates token stream matches expected grammar
- AST: builds nodes (let, int, ident, add, return) as scalar locals
- IR: lowers AST to linear opcode stream (const, store, load, add, ret)
- WAT: maps IR to WebAssembly ops (i32.const, local.set, local.get, i32.add, return)

The entire pipeline is validated at each stage before proceeding.

## Constraints (current Mee compiler)
- No arrays (codegen missing) - blocks dynamic AST/IR storage
- No struct field access codegen (parsing/typecheck exist, codegen panics)
- No memory ops (load/store to linear memory) - blocks arrays/strings
- No I/O - blocks reading source files

## Stages

### Stage 0 ✓ (complete)
Compiler stub with hardcoded input, validates full pipeline.

### Stage 1: Linear Memory + Arrays (next)
**Goal**: Enable fixed-size arrays via WASM linear memory.
**Rust compiler work**:
- [ ] Add `i32.load` / `i32.store` emission in WAT backend
- [ ] Add array type `[T; N]` to AST and parser
- [ ] Codegen: arrays as memory offsets from a base pointer
- [ ] Add index expression `arr[i]` lowering

**Bootstrap work**:
- [ ] Replace scalar AST locals (`n0_kind`, `n1_kind`, ...) with memory array
- [ ] Replace scalar IR locals (`op0`, `op1`, ...) with memory array
- [ ] Add `ast_set(idx, kind, a, b, c)` and `ast_get_*(idx)` helpers
- [ ] Parse variable-length statements (not just 2 lets + 1 return)

### Stage 2: Struct Field Access
**Goal**: Enable struct values with field read/write.
**Rust compiler work**:
- [ ] Fix struct codegen panic (flatten fields to locals or memory)
- [ ] Lower `s.field` read to appropriate local/memory access
- [ ] Lower `s.field = val` write

**Bootstrap work**:
- [ ] Replace parallel arrays with `struct Node { kind: i32, a: i32, b: i32, c: i32 }`
- [ ] Use structs for Token, IR instruction representation

### Stage 3: Dynamic Input
**Goal**: Read source from memory instead of hardcoded `char_at()`.
**Rust compiler work**:
- [ ] Add WASI imports for `fd_read` / `fd_write` (or simple syscall FFI)
- [ ] String operations: length, index, compare

**Bootstrap work**:
- [ ] Replace `char_at(pos)` with memory read from input buffer
- [ ] Load source string into linear memory at startup
- [ ] Parse arbitrary single-function programs

### Stage 4: Multi-Function Programs
**Goal**: Compile programs with multiple functions.
**Bootstrap work**:
- [ ] Track function table: name → local index
- [ ] Emit WAT `(func ...)` blocks for each function
- [ ] Handle function calls and parameter passing
- [ ] Symbol table for resolving identifiers across functions

### Stage 5: File I/O + Output
**Goal**: Read source file, write WAT output file.
**Rust compiler work**:
- [ ] WASI `path_open`, `fd_read`, `fd_write`
- [ ] Basic heap allocation (bump allocator) for dynamic buffers

**Bootstrap work**:
- [ ] Read source file path from args
- [ ] Emit WAT text to output file
- [ ] String building for WAT output

### Stage 6: Self-Compile
**Goal**: Bootstrap compiler can compile itself.
**Bootstrap work**:
- [ ] Implement all constructs used by bootstrap.mee
- [ ] Type checker (at least for i32)
- [ ] Error reporting (line numbers)
- [ ] Verify: `mee build bootstrap.mee` produces identical output

## Milestones

| Milestone | Description | Blocks |
|-----------|-------------|--------|
| M1 | Arrays work in Mee | Stage 1 |
| M2 | Struct field access works | Stage 2 |
| M3 | Bootstrap parses arbitrary input | Stage 3 |
| M4 | Bootstrap compiles multi-fn programs | Stage 4 |
| M5 | Bootstrap reads/writes files | Stage 5 |
| M6 | Self-hosting achieved | Stage 6 |

## Immediate Next Steps

1. **Rust compiler**: Implement `i32.load` / `i32.store` in WAT codegen
2. **Rust compiler**: Add array type `[i32; N]` with index expression
3. **Bootstrap**: Convert AST from scalars to memory array
4. **Bootstrap**: Add more binary operators (-, *, /, comparisons)
5. **Bootstrap**: Parse `if` and `while` statements

## Design Notes

### Memory Layout (Stage 1+)
```
0x0000 - 0x0FFF: AST node array (256 nodes × 16 bytes)
0x1000 - 0x1FFF: IR instruction array (256 ops × 8 bytes)
0x2000 - 0x2FFF: Source input buffer (4KB)
0x3000 - 0x3FFF: Output buffer (4KB)
0x4000+        : Heap (bump allocator)
```

### AST Node Format (16 bytes)
```
offset 0: kind (i32)
offset 4: arg_a (i32)
offset 8: arg_b (i32)
offset 12: arg_c (i32)
```

### IR Instruction Format (8 bytes)
```
offset 0: opcode (i32)
offset 4: argument (i32)
```
