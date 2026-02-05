# Self-Hosting Plan (WIP)

This repo doesn't yet have a Mee-written compiler. This directory will host a tiny, staged bootstrap compiler written in Mee.

## Current Status

**Stage 0 complete** ✓
**Stage 1 complete** ✓ (memory-based storage)
**Stage 1.5 complete** ✓ (general parser with precedence)
**Stage 1.6 complete** ✓ (general codegen with end-to-end validation)
**Stage 1.7 complete** ✓ (full pipeline: parse → AST → IR → WAT)
**Stage 3 complete** ✓ (dynamic input from memory buffer)
**Stage 4 complete** ✓ (multi-function programs with parameters)
**Stage 5 nearly complete** (WAT text output, needs file I/O)

## Self-Hosting Status (Verified 2026-02-04)

- `bootstrap.wat` → `bootstrap2.wat`
- `bootstrap2.wat` → `bootstrap3.wat`
- `bootstrap2_clean.wat` == `bootstrap3_clean.wat`
- `bootstrap2_clean.wat` and `bootstrap3_clean.wat` both run `main` and return `0`

Command sequence used:

```bash
# Rust-free (seeded) compile path for regular use:
./selfhost/build_with_selfhost.sh build ./examples/hello.mee -o /tmp/hello-self.wat
wasmtime --invoke main /tmp/hello-self.wat

# Rust-free maintenance path (default):
./selfhost/check_self_compile.sh
./selfhost/run_roundtrip_suite.sh
./selfhost/update_seed.sh

# Single entrypoint for no-Rust CI-like checks:
./selfhost/run_no_rust_ci.sh

# Full automated convergence check (recommended)
./selfhost/check_self_compile.sh --with-rust

# Full round-trip suite (convergence + compile/run test programs with
# self-hosted and Rust compilers, compare behavior)
./selfhost/run_roundtrip_suite.sh --with-rust

# Manual entry point:
# set state_stdin_flag (state_base + 44) to 1 in a WAT module, then run:
wasmtime --invoke main /tmp/some-bootstrap-with-stdin-flag.wat < ../selfhost/bootstrap.mee > /tmp/next.raw
# strip trailing NUL + whitespace to get the final WAT text
```

`main()` now has a dedicated "compile mode": when `state_stdin_flag` is set, it skips self-tests and directly compiles stdin to stdout. This keeps normal test runs unchanged, while making self-compile stages deterministic.

The bootstrap compiler (4800+ lines of Mee) implements a nearly complete compiler:
- **Lexer**: tokenizes Mee source from memory buffer (supports comments)
- **Parser**: recursive descent with operator precedence, builds AST in memory
- **AST**: 21 node kinds (let, return, if, while, call, assign, binary ops, etc.)
- **IR**: 20 opcodes (const, load, store, add, call, br_if, etc.)
- **WAT**: 22 opcodes lowered from IR
- **Multi-function**: parses multiple functions with parameters and arguments
- **WAT output**: generates complete WAT module text in memory
- **18 test phases**: all passing

Memory intrinsics (`__mem_load`, `__mem_store`, `__mem_load8`, `__mem_store8`) enable dynamic storage.

## Constraints (current Mee compiler)
- ~~No memory ops~~ ✓ **DONE**: `__mem_load`/`__mem_store` intrinsics added
- No array syntax `[T; N]` - use memory intrinsics as workaround
- Bootstrap compiler now parses struct declarations/types/field access/literals in the selfhost WASM path.
- Struct typechecking now includes struct-aware call argument checks and negative regression coverage; native backend ownership remains in Rust.
- No I/O - blocks reading source files

## Stages

### Stage 0 ✓ (complete)
Compiler stub with hardcoded input, validates full pipeline.

### Stage 1 ✓ (complete)
**Goal**: Enable dynamic storage via WASM linear memory.

**Rust compiler work** ✓:
- [x] Add `i32.load` / `i32.store` emission in WAT backend (`__mem_load`/`__mem_store`)
- [x] Add `i32.load8_u` / `i32.store8` emission (`__mem_load8`/`__mem_store8`)
- [x] Type checker recognizes memory intrinsics
- [x] x86_64 backend supports memory intrinsics

**Bootstrap work** ✓:
- [x] Replace scalar AST locals with memory array (`ast_set`, `ast_kind`, `ast_a`, etc.)
- [x] Replace scalar IR locals with memory array (`ir_set`, `ir_opcode`, `ir_arg`)
- [x] Add WAT opcode storage in memory (`wat_set`, `wat_opcode`, `wat_arg`)
- [x] Add token kinds for all operators (-, *, /, <, >, ==)
- [x] Add token kinds for control flow (if, else, while)
- [x] Add node kinds, IR opcodes, WAT opcodes for extended operations

### Stage 1.5: General Parser ✓ (complete)
**Goal**: Parse variable-length programs, not just fixed pattern.

**Bootstrap work** ✓:
- [x] Parser state management infrastructure (position, AST counter, symbol table)
- [x] Refactor parser to use loops for statement lists (recursive `parse_stmts_until_rbrace`)
- [x] Parse expression with precedence (*, / before +, -)
- [x] Parse `if` statements with optional `else`
- [x] Parse `while` loops
- [x] Test expression precedence (`1 + 2 * 3` → `add(1, mul(2, 3))`)
- [x] Test input support via memory buffer

### Stage 1.6: General Codegen ✓ (complete)
**Goal**: Emit IR/WAT from dynamically parsed AST.

**Bootstrap work** ✓:
- [x] Walk AST recursively to emit IR (`emit_ir_expr`, `emit_ir_stmt`)
- [x] Handle expressions: int, ident, add, sub, mul, div, comparisons
- [x] Handle statements: let, return, if, while
- [x] Basic tests for codegen (expression + let statement)
- [x] End-to-end test: parse "1 + 2 * 3" → AST → IR → validate

### Stage 1.7: Complete Pipeline Integration ✓ (complete)
**Goal**: Replace hardcoded compile_stub with general parser + codegen.

**Bootstrap work** ✓:
- [x] Parse function header (`parse_fn_header`)
- [x] Parse function body using general parser (`parse_fn_body_general`)
- [x] Emit IR using general codegen
- [x] Emit WAT from IR using general lowering (`emit_wat_from_ir_general`)
- [x] End-to-end test with full verification of AST, IR, and WAT
- [x] `compile_fn_general()` - complete pipeline function
- [x] Control flow codegen tests (if, while)

### Stage 2: Struct Field Access
**Goal**: Enable struct values with field read/write.
**Rust compiler work**:
- [x] Fix struct codegen panic (flatten fields to locals or memory)
- [x] Lower `s.field` read to appropriate local/memory access
- [x] Lower `s.field = val` write
- [x] Lower struct params/returns in WAT and x86_64 backends (sret + flattened fields)

**Bootstrap work**:
- [ ] Replace parallel arrays with `struct Node { kind: i32, a: i32, b: i32, c: i32 }`
- [ ] Use structs for Token, IR instruction representation

### Stage 3: Dynamic Input ✓ (complete)
**Goal**: Read source from memory instead of hardcoded `char_at()`.
**Rust compiler work**:
- [ ] Add WASI imports for `fd_read` / `fd_write` (or simple syscall FFI)

**Bootstrap work** ✓:
- [x] Dynamic character reader (`char_at_dyn`) reads from memory buffer
- [x] Dynamic lexer (`lex_dyn`, `skip_ws_dyn`, etc.)
- [x] Dynamic parser (`parse_expr_dyn`, `parse_stmt_dyn`, etc.)
- [x] Dynamic compile pipeline (`compile_fn_dyn`)
- [x] Test: compile `fn main() { let a = 5; let b = 3; return a * b; }` from memory
- [x] Test: compile program with `if` statement from memory

### Stage 4: Multi-Function Programs ✓ (complete)
**Goal**: Compile programs with multiple functions.
**Bootstrap work** ✓:
- [x] Function table (`fn_set`, `fn_ident`, `register_fn`, `lookup_fn`)
- [x] Function AST storage (`set_fn_ast`, `get_fn_ast`)
- [x] Parse function definitions (`parse_fn_def_dyn`)
- [x] Parse multiple functions (`parse_program_dyn`)
- [x] Function calls in expressions (`nk_call`, `parse_call_dyn`)
- [x] IR emission for calls (`emit_ir_call`, `op_call`)
- [x] WAT emission for calls (`emit_wat_call`, `w_call`)
- [x] Function parameters (`parse_params_dyn`, `parse_param_list_dyn`)
- [x] Function arguments (`parse_args_dyn`, `emit_ir_args`)
- [x] Assignment statements (`nk_assign`, `parse_assign_or_expr_dyn`, `emit_ir_assign`)
- [x] Tests: multi-function, parameters, assignments
- [x] Line comments (`// ...`)

### Stage 5: WAT Text Output (current)
**Goal**: Generate WAT text output.
Note: file output test is gated by `state_emit_file_flag` (state_base+72) and requires a preopened dir (`wasmtime --dir .`).
**Rust compiler work**:
- [x] WASI `path_open`, `fd_read`, `fd_write`, `fd_close` imports
- [x] Add intrinsic(s) for output: `__fd_write`, `__fd_read`, `__path_open`, `__fd_close`
- [x] Wire intrinsic(s) through type checker and WAT/x86_64 backends

**Bootstrap work**:
- [x] Output buffer infrastructure (`out_init`, `out_byte`, `out_char`)
- [x] String output helpers (`out_str_const`, `out_str_return`, etc.)
- [x] Number output (`out_num`, `out_num_pos`)
- [x] WAT instruction generation (`gen_wat_instr`)
- [x] WAT function generation (`gen_wat_fn`, `gen_wat_params`, `gen_wat_locals`)
- [x] WAT module generation (`gen_wat_module`)
- [x] Test: generate and verify WAT text output
- [x] Generate WAT for all functions (`gen_wat_module_all`, `gen_wat_all_fns`)
- [x] Export main function
- [x] Test: multi-function WAT generation
- [x] Add `out_flush` to write buffer via `__fd_write`
- [x] Add file output wrapper (`compile_program_to_file`)
- [x] Test: verify written WAT file contents (via `test_wat_file`)

### Stage 6: Self-Compile
**Goal**: Bootstrap compiler can compile itself.
**Bootstrap work**:
- [x] Basic name checking (undefined locals error)
- [x] Basic call arity checking (non-intrinsics)
- [x] Implement all constructs used by `bootstrap.mee` (audit complete: `fn`, `let`, assign, `return`, `if`/`else`, `while`, calls, numeric/bool/string literals, `!`, `&&`, `||`, comparisons, memory/file intrinsics)
- [x] Minimal type checker (i32 only, no inference)
- [x] Error reporting with line/column spans (parse errors)
- [x] Error reporting with line/column spans (semantic/type/name errors)
- [x] Boolean literals + logical `&&`/`||` (non-short-circuit)
- [x] String literals (WAT data segments, i32 pointer values)
- [x] Unary `!` operator
- [x] `break` / `continue` in loops
- [x] Extended string escapes (`\\n`, `\\r`, `\\t`, `\\0`, `\\xNN`, `\\u{...}`)
- [x] Deterministic output (stable ordering, stable formatting)
- [x] Verification: convergence check script (`selfhost/check_self_compile.sh`)
- [x] Round-trip check: bootstrap compiles itself and runs test suite (`selfhost/run_roundtrip_suite.sh`)

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

1. ~~**Bootstrap**: Full pipeline: parse → AST → IR → WAT~~ ✓
2. ~~**Bootstrap**: Dynamic input from memory buffer~~ ✓
3. ~~**Bootstrap**: Multi-function programs with function calls~~ ✓
4. ~~**Bootstrap**: Function parameters and arguments~~ ✓
5. ~~**Bootstrap**: Assignment statements~~ ✓
6. ~~**Bootstrap**: Line comments~~ ✓
7. ~~**Rust compiler**: Add WASI imports + output intrinsic(s) (Stage 5)~~ ✓
8. ~~**Bootstrap**: `out_flush` + write WAT to file (Stage 5)~~ ✓
9. ~~**Bootstrap**: Minimal type checker + error reporting (Stage 6)~~ ✓
10. ~~**Bootstrap**: Self-compile verification loop (Stage 6)~~ ✓
11. ~~**Bootstrap**: Add semantic error spans (line/column for type/name errors)~~ ✓
12. ~~**Bootstrap**: Expand negative tests (expected parser/typecheck failures)~~ ✓

## Stage 5 Detailed Tasks (File I/O + WAT Output)

- Define ABI for output intrinsic(s): `__fd_write(fd, ptr, len) -> written` or `__write_all(ptr, len)`
- Add WASI imports in Rust compiler (`fd_write`, `path_open`, `fd_close`)
- Provide Mee-level wrappers for open/write/close (or a single "write to stdout" path first)
- Wire intrinsic(s) through type checker (argument + return types)
- WAT backend: emit `call` to import with proper stack values
- x86_64 backend: stub or syscall-backed implementation (explicitly document if unsupported)
- Bootstrap: add `out_flush` to emit buffer via intrinsic
- Bootstrap: add `compile_program_to_file(path)` or `compile_program_to_stdout()`
- Test: compile a simple program and compare generated WAT to in-memory expected output
- Test: multi-function program writes full module with proper `export "main"`

## Stage 6 Detailed Tasks (Self-Compile)

- ~~Inventory constructs used in `bootstrap.mee` and confirm parser/codegen coverage~~ ✓
- Add minimal type checker for i32:
- Track symbol table with types for locals, params, and function returns
- Validate binary ops are i32-only, comparisons return i32 (0/1)
- Validate call arity and return type is i32
- Add error reporting with line/column spans:
- Track current line/column in lexer
- Store spans in AST nodes or in parallel arrays
- Emit error messages with source snippet and caret
- Deterministic output:
- Stable function ordering in module output
- Stable local ordering in WAT generation
- Fixed formatting for numbers and whitespace
- Verification loop:
- Build `bootstrap.mee` with Rust compiler -> `bootstrap.wat`
- Run `bootstrap.wat` to compile `bootstrap.mee` -> `bootstrap2.wat`
- Compare `bootstrap.wat` vs `bootstrap2.wat` (byte-for-byte)
- Run test suite with self-compiled compiler

## Acceptance Criteria

- Stage 5: `mee build input.mee` writes a valid WAT file that runs under `wasmtime`
- Stage 5: output is identical between in-memory WAT and file WAT
- Stage 6: self-compile produces identical WAT output across two generations
- Stage 6: all existing tests pass using the self-compiled compiler

## Design Notes

### Memory Layout (implemented)
```
0x000000 - 0x1FFFFF: AST node array (128K nodes × 16 bytes)     [ast_base() = 0]
0x200000 - 0x9FFFFF: IR instruction array (1M ops × 8 bytes)    [ir_base() = 2097152]
0xA00000 - 0x11FFFFF: WAT opcode array (1M ops × 8 bytes)       [wat_base() = 10485760]
0x1200000 - 0x123FFFF: Parser/state + symbol table              [state_base() = 18874368]
0x1240000 - 0x12BFFFF: Source input buffer (512KB)
0x12C0000 - 0x12FFFFF: Function tables (entries/AST/IR counts)
0x1300000 - 0x42FFFFF: Output buffer (48MB)
0x4300000 - 0x44FFFFF: Function local identifier table (per-function locals)
0x4600000+      : I/O scratch (iovec + counters)
```

### AST Node Format (16 bytes)
```
offset 0: kind (i32)   - node type (nk_int, nk_let, nk_add, etc.)
offset 4: arg_a (i32)  - first argument (value, ident_id, child node, etc.)
offset 8: arg_b (i32)  - second argument
offset 12: arg_c (i32) - third argument (reserved)
```

### IR Instruction Format (8 bytes)
```
offset 0: opcode (i32)   - operation (op_const, op_load, op_add, etc.)
offset 4: argument (i32) - operand (constant value, local index, etc.)
```

### WAT Opcode Format (8 bytes)
```
offset 0: opcode (i32)   - WAT instruction (w_const, w_local_get, w_add, etc.)
offset 4: argument (i32) - operand
```

### Token Packing
Tokens are packed as: `kind * 10000 + next_position`
- `lex_kind(tok)`: extract kind via `tok / 10000`
- `lex_next(tok)`: extract next position via `tok - kind * 10000`
