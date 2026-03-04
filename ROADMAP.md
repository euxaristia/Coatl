# Coatl Roadmap

Last updated: 2026-03-04

## Completed

- **Integrated Python Compiler**: Frontend (Lexer/Parser) and multiple Backends (x86_64, AArch64, CByte) integrated into a single standalone tool.
- Lexer/parser/AST baseline (`i32`/`bool`/`i64`/`f32`/`f64`/`str`, string literals with hex escapes).
- **x86_64 backend**: Direct IR->ASM and IR->BIN (linked with intrinsics) paths. Correct calling convention for 7+ arguments.
- **AArch64 backend**: Native code generation for ARM64.
- **CByte VM**: Obfuscated bytecode emitter and integrated virtual machine.
- **Embedded Intrinsics**: Core memory and I/O assembly routines embedded directly in the compiler script.
- Struct support across all native compile lanes.
- **Type-directed codegen**: `bool`, `i64`, `f32`, `f64`, `str`, `[T N]` arrays.

## Current Focus

- Improve error reporting and diagnostics in the Python-based frontend.
- Optimize the generated assembly for better performance.
- Extend the `cbyte` VM with more syscall support.

## Next Milestones

### v0.3
- Stable standard library interface for common tasks (e.g., file I/O beyond raw syscalls).
- Broader test coverage for complex control-flow and nested struct scenarios.

### v0.4
- Support for more target architectures.
- Initial work on safer memory abstractions (ownership tracking).

### v1.0
- Stable language specification.
- Package/dependency workflow.
- Complete documentation and tutorials.
