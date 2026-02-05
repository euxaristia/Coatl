use std::collections::HashMap;

use crate::ast::{BinOp, Block, Expr, Function, Param, Program, Stmt, Type};

#[derive(Clone)]
struct FnSig {
    params: Vec<Type>,
    ret: Type,
}

const STRUCT_RET_SCRATCH_BASE: i32 = 65536;
const X86_LINEAR_MEMORY_SIZE: i32 = 83_886_080; // 80 MiB

fn is_scalar(ty: &Type) -> bool {
    matches!(ty, Type::I32 | Type::Char | Type::Bool)
}

fn field_local_name(var: &str, field: &str) -> String {
    format!("__field__{}__{}", var, field)
}

fn collectstruct_defs(prog: &Program) -> HashMap<String, Vec<Param>> {
    let mut defs = HashMap::new();
    for s in &prog.structs {
        defs.insert(s.name.clone(), s.fields.clone());
    }
    defs
}

fn collect_fn_sigs(prog: &Program) -> HashMap<String, FnSig> {
    let mut out = HashMap::new();
    for f in &prog.functions {
        out.insert(
            f.name.clone(),
            FnSig {
                params: f.params.iter().map(|p| p.ty.clone()).collect(),
                ret: f.ret.clone(),
            },
        );
    }
    out
}

fn struct_fields<'a>(struct_defs: &'a HashMap<String, Vec<Param>>, sname: &str) -> &'a Vec<Param> {
    struct_defs
        .get(sname)
        .unwrap_or_else(|| panic!("unknown struct {}", sname))
}

fn collect_strings_from_program(prog: &Program) -> Vec<String> {
    let mut strings = Vec::new();
    for f in &prog.functions {
        collect_strings_from_block(&f.body, &mut strings);
    }
    strings
}

fn collect_strings_from_block(block: &Block, strings: &mut Vec<String>) {
    for stmt in &block.statements {
        match stmt {
            Stmt::Let { expr, .. } => collect_strings_from_expr(expr, strings),
            Stmt::Assign { expr, .. } => collect_strings_from_expr(expr, strings),
            Stmt::FieldAssign { expr, .. } => collect_strings_from_expr(expr, strings),
            Stmt::If { cond, then_block, else_block } => {
                collect_strings_from_expr(cond, strings);
                collect_strings_from_block(then_block, strings);
                if let Some(eb) = else_block {
                    collect_strings_from_block(eb, strings);
                }
            }
            Stmt::While { cond, body } => {
                collect_strings_from_expr(cond, strings);
                collect_strings_from_block(body, strings);
            }
            Stmt::Return(expr) => collect_strings_from_expr(expr, strings),
            Stmt::Expr(expr) => collect_strings_from_expr(expr, strings),
        }
    }
}

fn collect_strings_from_expr(expr: &Expr, strings: &mut Vec<String>) {
    match expr {
        Expr::StringLit(s) => {
            if !strings.contains(s) {
                strings.push(s.clone());
            }
        }
        Expr::Binary { left, right, .. } => {
            collect_strings_from_expr(left, strings);
            collect_strings_from_expr(right, strings);
        }
        Expr::Unary { expr, .. } => collect_strings_from_expr(expr, strings),
        Expr::Call { args, .. } => {
            for arg in args {
                collect_strings_from_expr(arg, strings);
            }
        }
        Expr::FieldAccess { expr, .. } => {
            collect_strings_from_expr(expr, strings);
        }
        Expr::StructInit { fields, .. } => {
            for (_, val) in fields {
                collect_strings_from_expr(val, strings);
            }
        }
        _ => {}
    }
}

fn uses_memory(prog: &Program) -> bool {
    for f in &prog.functions {
        if block_uses_memory(&f.body) {
            return true;
        }
    }
    false
}

fn uses_fd_write(prog: &Program) -> bool {
    for f in &prog.functions {
        if block_uses_fd_write(&f.body) {
            return true;
        }
    }
    false
}

fn uses_fd_read(prog: &Program) -> bool {
    for f in &prog.functions {
        if block_uses_fd_read(&f.body) {
            return true;
        }
    }
    false
}

fn uses_path_open(prog: &Program) -> bool {
    for f in &prog.functions {
        if block_uses_path_open(&f.body) {
            return true;
        }
    }
    false
}

fn uses_fd_close(prog: &Program) -> bool {
    for f in &prog.functions {
        if block_uses_fd_close(&f.body) {
            return true;
        }
    }
    false
}

fn block_uses_fd_write(block: &Block) -> bool {
    for stmt in &block.statements {
        if stmt_uses_fd_write(stmt) {
            return true;
        }
    }
    false
}

fn block_uses_fd_read(block: &Block) -> bool {
    for stmt in &block.statements {
        if stmt_uses_fd_read(stmt) {
            return true;
        }
    }
    false
}

fn block_uses_path_open(block: &Block) -> bool {
    for stmt in &block.statements {
        if stmt_uses_path_open(stmt) {
            return true;
        }
    }
    false
}

fn block_uses_fd_close(block: &Block) -> bool {
    for stmt in &block.statements {
        if stmt_uses_fd_close(stmt) {
            return true;
        }
    }
    false
}

fn stmt_uses_fd_write(stmt: &Stmt) -> bool {
    match stmt {
        Stmt::Let { expr, .. } => expr_uses_fd_write(expr),
        Stmt::Assign { expr, .. } => expr_uses_fd_write(expr),
        Stmt::FieldAssign { expr, .. } => expr_uses_fd_write(expr),
        Stmt::If { cond, then_block, else_block } => {
            expr_uses_fd_write(cond)
                || block_uses_fd_write(then_block)
                || else_block.as_ref().map_or(false, block_uses_fd_write)
        }
        Stmt::While { cond, body } => expr_uses_fd_write(cond) || block_uses_fd_write(body),
        Stmt::Return(expr) => expr_uses_fd_write(expr),
        Stmt::Expr(expr) => expr_uses_fd_write(expr),
    }
}

fn stmt_uses_fd_read(stmt: &Stmt) -> bool {
    match stmt {
        Stmt::Let { expr, .. } => expr_uses_fd_read(expr),
        Stmt::Assign { expr, .. } => expr_uses_fd_read(expr),
        Stmt::FieldAssign { expr, .. } => expr_uses_fd_read(expr),
        Stmt::If { cond, then_block, else_block } => {
            expr_uses_fd_read(cond)
                || block_uses_fd_read(then_block)
                || else_block.as_ref().map_or(false, block_uses_fd_read)
        }
        Stmt::While { cond, body } => expr_uses_fd_read(cond) || block_uses_fd_read(body),
        Stmt::Return(expr) => expr_uses_fd_read(expr),
        Stmt::Expr(expr) => expr_uses_fd_read(expr),
    }
}

fn stmt_uses_path_open(stmt: &Stmt) -> bool {
    match stmt {
        Stmt::Let { expr, .. } => expr_uses_path_open(expr),
        Stmt::Assign { expr, .. } => expr_uses_path_open(expr),
        Stmt::FieldAssign { expr, .. } => expr_uses_path_open(expr),
        Stmt::If { cond, then_block, else_block } => {
            expr_uses_path_open(cond)
                || block_uses_path_open(then_block)
                || else_block.as_ref().map_or(false, block_uses_path_open)
        }
        Stmt::While { cond, body } => expr_uses_path_open(cond) || block_uses_path_open(body),
        Stmt::Return(expr) => expr_uses_path_open(expr),
        Stmt::Expr(expr) => expr_uses_path_open(expr),
    }
}

fn stmt_uses_fd_close(stmt: &Stmt) -> bool {
    match stmt {
        Stmt::Let { expr, .. } => expr_uses_fd_close(expr),
        Stmt::Assign { expr, .. } => expr_uses_fd_close(expr),
        Stmt::FieldAssign { expr, .. } => expr_uses_fd_close(expr),
        Stmt::If { cond, then_block, else_block } => {
            expr_uses_fd_close(cond)
                || block_uses_fd_close(then_block)
                || else_block.as_ref().map_or(false, block_uses_fd_close)
        }
        Stmt::While { cond, body } => expr_uses_fd_close(cond) || block_uses_fd_close(body),
        Stmt::Return(expr) => expr_uses_fd_close(expr),
        Stmt::Expr(expr) => expr_uses_fd_close(expr),
    }
}

fn expr_uses_fd_write(expr: &Expr) -> bool {
    match expr {
        Expr::Call { callee, args } => {
            if callee == "__fd_write" {
                return true;
            }
            args.iter().any(expr_uses_fd_write)
        }
        Expr::Binary { left, right, .. } => expr_uses_fd_write(left) || expr_uses_fd_write(right),
        Expr::Unary { expr, .. } => expr_uses_fd_write(expr),
        Expr::FieldAccess { expr, .. } => expr_uses_fd_write(expr),
        Expr::StructInit { fields, .. } => fields.iter().any(|(_, e)| expr_uses_fd_write(e)),
        _ => false,
    }
}

fn expr_uses_fd_read(expr: &Expr) -> bool {
    match expr {
        Expr::Call { callee, args } => {
            if callee == "__fd_read" {
                return true;
            }
            args.iter().any(expr_uses_fd_read)
        }
        Expr::Binary { left, right, .. } => expr_uses_fd_read(left) || expr_uses_fd_read(right),
        Expr::Unary { expr, .. } => expr_uses_fd_read(expr),
        Expr::FieldAccess { expr, .. } => expr_uses_fd_read(expr),
        Expr::StructInit { fields, .. } => fields.iter().any(|(_, e)| expr_uses_fd_read(e)),
        _ => false,
    }
}

fn expr_uses_path_open(expr: &Expr) -> bool {
    match expr {
        Expr::Call { callee, args } => {
            if callee == "__path_open" {
                return true;
            }
            args.iter().any(expr_uses_path_open)
        }
        Expr::Binary { left, right, .. } => expr_uses_path_open(left) || expr_uses_path_open(right),
        Expr::Unary { expr, .. } => expr_uses_path_open(expr),
        Expr::FieldAccess { expr, .. } => expr_uses_path_open(expr),
        Expr::StructInit { fields, .. } => fields.iter().any(|(_, e)| expr_uses_path_open(e)),
        _ => false,
    }
}

fn expr_uses_fd_close(expr: &Expr) -> bool {
    match expr {
        Expr::Call { callee, args } => {
            if callee == "__fd_close" {
                return true;
            }
            args.iter().any(expr_uses_fd_close)
        }
        Expr::Binary { left, right, .. } => expr_uses_fd_close(left) || expr_uses_fd_close(right),
        Expr::Unary { expr, .. } => expr_uses_fd_close(expr),
        Expr::FieldAccess { expr, .. } => expr_uses_fd_close(expr),
        Expr::StructInit { fields, .. } => fields.iter().any(|(_, e)| expr_uses_fd_close(e)),
        _ => false,
    }
}

fn block_uses_memory(block: &Block) -> bool {
    for stmt in &block.statements {
        if stmt_uses_memory(stmt) {
            return true;
        }
    }
    false
}

fn stmt_uses_memory(stmt: &Stmt) -> bool {
    match stmt {
        Stmt::Let { expr, .. } => expr_uses_memory(expr),
        Stmt::Assign { expr, .. } => expr_uses_memory(expr),
        Stmt::FieldAssign { expr, .. } => expr_uses_memory(expr),
        Stmt::If { cond, then_block, else_block } => {
            expr_uses_memory(cond)
                || block_uses_memory(then_block)
                || else_block.as_ref().map_or(false, block_uses_memory)
        }
        Stmt::While { cond, body } => expr_uses_memory(cond) || block_uses_memory(body),
        Stmt::Return(expr) => expr_uses_memory(expr),
        Stmt::Expr(expr) => expr_uses_memory(expr),
    }
}

fn expr_uses_memory(expr: &Expr) -> bool {
    match expr {
        Expr::Call { callee, args } => {
            if callee == "__mem_load" || callee == "__mem_store"
                || callee == "__mem_load8" || callee == "__mem_store8"
            {
                return true;
            }
            args.iter().any(expr_uses_memory)
        }
        Expr::Binary { left, right, .. } => expr_uses_memory(left) || expr_uses_memory(right),
        Expr::Unary { expr, .. } => expr_uses_memory(expr),
        Expr::FieldAccess { expr, .. } => expr_uses_memory(expr),
        Expr::StructInit { fields, .. } => fields.iter().any(|(_, e)| expr_uses_memory(e)),
        _ => false,
    }
}

pub fn emit_wat(prog: &Program) -> String {
    let strings = collect_strings_from_program(prog);
    let struct_defs = collectstruct_defs(prog);
    let fn_sigs = collect_fn_sigs(prog);
    let needs_fd_write = uses_fd_write(prog);
    let needs_fd_read = uses_fd_read(prog);
    let needs_path_open = uses_path_open(prog);
    let needs_fd_close = uses_fd_close(prog);
    let needs_wasi = needs_fd_write || needs_fd_read || needs_path_open || needs_fd_close;
    let has_struct_returns = prog.functions.iter().any(|f| matches!(f.ret, Type::Struct(_)));
    let needs_memory = !strings.is_empty() || uses_memory(prog) || needs_wasi || has_struct_returns;
    let mut out = String::new();
    out.push_str("(module\n");

    if needs_fd_write {
        out.push_str("  (import \"wasi_snapshot_preview1\" \"fd_write\" (func $__fd_write (param i32 i32 i32 i32) (result i32)))\n");
    }
    if needs_fd_read {
        out.push_str("  (import \"wasi_snapshot_preview1\" \"fd_read\" (func $__fd_read (param i32 i32 i32 i32) (result i32)))\n");
    }
    if needs_path_open {
        out.push_str("  (import \"wasi_snapshot_preview1\" \"path_open\" (func $__path_open (param i32 i32 i32 i32 i32 i64 i64 i32 i32) (result i32)))\n");
    }
    if needs_fd_close {
        out.push_str("  (import \"wasi_snapshot_preview1\" \"fd_close\" (func $__fd_close (param i32) (result i32)))\n");
    }

    // Emit memory if we have strings or use memory intrinsics
    if needs_memory {
        out.push_str("  (memory 2048)\n");
        out.push_str("  (export \"memory\" (memory 0))\n");
    }

    // Emit string data
    if !strings.is_empty() {
        let mut offset = 0;
        for s in strings.iter() {
            out.push_str(&format!("  (data (i32.const {}) \"", offset));
            for c in s.chars() {
                match c {
                    '\n' => out.push_str("\\n"),
                    '\r' => out.push_str("\\r"),
                    '\t' => out.push_str("\\t"),
                    '\0' => out.push_str("\\00"),
                    '"' => out.push_str("\\\""),
                    '\\' => out.push_str("\\\\"),
                    c if c.is_ascii_graphic() || c == ' ' => out.push(c),
                    c => out.push_str(&format!("\\{:02x}", c as u8)),
                }
            }
            out.push_str("\")\n");
            offset += s.len() as i32;
        }
    }

    // Build string table for codegen
    let mut string_offsets = HashMap::new();
    let mut offset = 0i32;
    for s in &strings {
        string_offsets.insert(s.clone(), offset);
        offset += s.len() as i32;
    }

    for f in &prog.functions {
        out.push_str(&emit_function_wat_with_strings(f, &string_offsets, &struct_defs, &fn_sigs));
    }
    if prog.functions.iter().any(|f| f.name == "main") {
        out.push_str("  (export \"main\" (func $main))\n");
    }
    out.push_str(")\n");
    out
}

pub fn emit_x86_64_asm(prog: &Program) -> String {
    let strings = collect_strings_from_program(prog);
    let struct_defs = collectstruct_defs(prog);
    let fn_sigs = collect_fn_sigs(prog);
    let needs_fd_write = uses_fd_write(prog);
    let needs_fd_read = uses_fd_read(prog);
    let needs_path_open = uses_path_open(prog);
    let needs_fd_close = uses_fd_close(prog);
    let mut out = String::new();
    out.push_str(".intel_syntax noprefix\n");

    // Emit string data in .rodata section
    if !strings.is_empty() {
        out.push_str(".section .rodata\n");
        for (i, s) in strings.iter().enumerate() {
            out.push_str(&format!(".Lstr_{}:\n", i));
            out.push_str("  .byte ");
            let bytes: Vec<String> = s.bytes().map(|b| format!("{}", b)).collect();
            out.push_str(&bytes.join(", "));
            if !s.is_empty() {
                out.push_str(", ");
            }
            out.push_str("0\n"); // null terminator
        }
    }

    out.push_str(".section .bss\n");
    out.push_str(".align 16\n");
    out.push_str(".globl __mee_memory\n");
    out.push_str("__mee_memory:\n");
    out.push_str(&format!("  .zero {}\n", X86_LINEAR_MEMORY_SIZE));
    out.push_str(".globl __mee_mem_inited\n");
    out.push_str("__mee_mem_inited:\n");
    out.push_str("  .zero 4\n");

    out.push_str(".text\n");
    if !strings.is_empty() {
        emit_x86_64_memory_init_helper(&strings, &mut out);
    }
    emit_x86_64_intrinsic_helpers(
        needs_fd_write,
        needs_fd_read,
        needs_path_open,
        needs_fd_close,
        &mut out,
    );
    for f in &prog.functions {
        out.push_str(&emit_function_x86_64_with_strings(f, &strings, &struct_defs, &fn_sigs));
    }
    out
}

fn emit_x86_64_memory_init_helper(strings: &[String], out: &mut String) {
    out.push_str(".globl __mee_init_memory\n");
    out.push_str("__mee_init_memory:\n");
    out.push_str("  cmp DWORD PTR [rip + __mee_mem_inited], 1\n");
    out.push_str("  je .Lmee_mem_init_done\n");
    let mut offset: i32 = 0;
    for s in strings {
        for (i, b) in s.bytes().enumerate() {
            out.push_str(&format!(
                "  mov BYTE PTR [rip + __mee_memory + {}], {}\n",
                offset + i as i32,
                b
            ));
        }
        out.push_str(&format!(
            "  mov BYTE PTR [rip + __mee_memory + {}], 0\n",
            offset + s.len() as i32
        ));
        offset += s.len() as i32 + 1;
    }
    out.push_str("  mov DWORD PTR [rip + __mee_mem_inited], 1\n");
    out.push_str(".Lmee_mem_init_done:\n");
    out.push_str("  ret\n\n");
}

fn emit_x86_64_intrinsic_helpers(
    needs_fd_write: bool,
    needs_fd_read: bool,
    needs_path_open: bool,
    needs_fd_close: bool,
    out: &mut String,
) {
    if needs_fd_write {
        out.push_str(".globl __mee_fd_write\n");
        out.push_str("__mee_fd_write:\n");
        out.push_str("  push rbp\n  mov rbp, rsp\n");
        out.push_str("  push rbx\n");
        out.push_str("  push r12\n");
        out.push_str("  push r13\n");
        out.push_str("  lea r12, [rip + __mee_memory]\n");
        out.push_str("  lea rsi, [r12 + rsi]\n"); // iov ptr offset -> host ptr
        out.push_str("  lea rbx, [r12 + rcx]\n"); // nwritten ptr offset -> host ptr
        out.push_str("  mov r13, rdx\n"); // iov_cnt
        out.push_str("  xor r8, r8\n"); // total written
        out.push_str("  xor r9, r9\n"); // iov index
        out.push_str(".Lmee_fd_write_loop:\n");
        out.push_str("  cmp r9, r13\n");
        out.push_str("  jge .Lmee_fd_write_done\n");
        out.push_str("  mov eax, DWORD PTR [rsi + r9*8]\n"); // buf offset (u32)
        out.push_str("  lea r10, [r12 + rax]\n"); // offset -> host ptr
        out.push_str("  mov r11d, DWORD PTR [rsi + r9*8 + 4]\n"); // len (u32)
        out.push_str("  push rdi\n"); // preserve fd
        out.push_str("  mov rsi, r10\n"); // syscall arg: buf
        out.push_str("  mov rdx, r11\n"); // syscall arg: len
        out.push_str("  mov rax, 1\n"); // SYS_write
        out.push_str("  syscall\n");
        out.push_str("  pop rdi\n");
        out.push_str("  test rax, rax\n");
        out.push_str("  js .Lmee_fd_write_err\n");
        out.push_str("  add r8, rax\n");
        out.push_str("  inc r9\n");
        out.push_str("  jmp .Lmee_fd_write_loop\n");
        out.push_str(".Lmee_fd_write_done:\n");
        out.push_str("  mov DWORD PTR [rbx], r8d\n");
        out.push_str("  xor eax, eax\n");
        out.push_str("  pop r13\n");
        out.push_str("  pop r12\n");
        out.push_str("  pop rbx\n");
        out.push_str("  mov rsp, rbp\n  pop rbp\n  ret\n");
        out.push_str(".Lmee_fd_write_err:\n");
        out.push_str("  mov DWORD PTR [rbx], r8d\n");
        out.push_str("  neg eax\n"); // Linux returns -errno; intrinsic returns errno
        out.push_str("  pop r13\n");
        out.push_str("  pop r12\n");
        out.push_str("  pop rbx\n");
        out.push_str("  mov rsp, rbp\n  pop rbp\n  ret\n\n");
    }

    if needs_fd_read {
        out.push_str(".globl __mee_fd_read\n");
        out.push_str("__mee_fd_read:\n");
        out.push_str("  push rbp\n  mov rbp, rsp\n");
        out.push_str("  push rbx\n");
        out.push_str("  push r12\n");
        out.push_str("  push r13\n");
        out.push_str("  lea r12, [rip + __mee_memory]\n");
        out.push_str("  lea rsi, [r12 + rsi]\n"); // iov ptr offset -> host ptr
        out.push_str("  lea rbx, [r12 + rcx]\n"); // nread ptr offset -> host ptr
        out.push_str("  mov r13, rdx\n"); // iov_cnt
        out.push_str("  xor r8, r8\n"); // total read
        out.push_str("  xor r9, r9\n"); // iov index
        out.push_str(".Lmee_fd_read_loop:\n");
        out.push_str("  cmp r9, r13\n");
        out.push_str("  jge .Lmee_fd_read_done\n");
        out.push_str("  mov eax, DWORD PTR [rsi + r9*8]\n"); // buf offset (u32)
        out.push_str("  lea r10, [r12 + rax]\n"); // offset -> host ptr
        out.push_str("  mov r11d, DWORD PTR [rsi + r9*8 + 4]\n"); // len (u32)
        out.push_str("  push rdi\n"); // preserve fd
        out.push_str("  mov rsi, r10\n"); // syscall arg: buf
        out.push_str("  mov rdx, r11\n"); // syscall arg: len
        out.push_str("  mov rax, 0\n"); // SYS_read
        out.push_str("  syscall\n");
        out.push_str("  pop rdi\n");
        out.push_str("  test rax, rax\n");
        out.push_str("  js .Lmee_fd_read_err\n");
        out.push_str("  add r8, rax\n");
        out.push_str("  cmp rax, 0\n");
        out.push_str("  je .Lmee_fd_read_done\n");
        out.push_str("  inc r9\n");
        out.push_str("  jmp .Lmee_fd_read_loop\n");
        out.push_str(".Lmee_fd_read_done:\n");
        out.push_str("  mov DWORD PTR [rbx], r8d\n");
        out.push_str("  xor eax, eax\n");
        out.push_str("  pop r13\n");
        out.push_str("  pop r12\n");
        out.push_str("  pop rbx\n");
        out.push_str("  mov rsp, rbp\n  pop rbp\n  ret\n");
        out.push_str(".Lmee_fd_read_err:\n");
        out.push_str("  mov DWORD PTR [rbx], r8d\n");
        out.push_str("  neg eax\n"); // Linux returns -errno; intrinsic returns errno
        out.push_str("  pop r13\n");
        out.push_str("  pop r12\n");
        out.push_str("  pop rbx\n");
        out.push_str("  mov rsp, rbp\n  pop rbp\n  ret\n\n");
    }

    if needs_path_open {
        out.push_str(".globl __mee_path_open\n");
        out.push_str("__mee_path_open:\n");
        out.push_str("  push rbp\n  mov rbp, rsp\n");
        out.push_str("  push r12\n");
        out.push_str("  lea r11, [rip + __mee_memory]\n");
        out.push_str("  mov r12, QWORD PTR [rbp + 32]\n"); // opened_fd_ptr offset (9th arg)
        out.push_str("  lea r12, [r11 + r12]\n");
        out.push_str("  lea r10, [r11 + rdx]\n"); // path offset -> host ptr
        out.push_str("  mov eax, 257\n"); // SYS_openat
        out.push_str("  mov rsi, r10\n"); // pathname
        out.push_str("  cmp r8d, 0\n"); // WASI oflags
        out.push_str("  jne .Lmee_open_write\n");
        out.push_str("  mov edx, 0\n"); // O_RDONLY
        out.push_str("  jmp .Lmee_open_flags_done\n");
        out.push_str(".Lmee_open_write:\n");
        out.push_str("  mov edx, 577\n"); // O_WRONLY | O_CREAT | O_TRUNC
        out.push_str(".Lmee_open_flags_done:\n");
        out.push_str("  mov r10d, 438\n"); // mode 0666
        out.push_str("  syscall\n");
        out.push_str("  test rax, rax\n");
        out.push_str("  js .Lmee_open_err\n");
        out.push_str("  mov DWORD PTR [r12], eax\n");
        out.push_str("  xor eax, eax\n");
        out.push_str("  pop r12\n");
        out.push_str("  mov rsp, rbp\n  pop rbp\n  ret\n");
        out.push_str(".Lmee_open_err:\n");
        out.push_str("  neg eax\n"); // Linux returns -errno; intrinsic returns errno
        out.push_str("  pop r12\n");
        out.push_str("  mov rsp, rbp\n  pop rbp\n  ret\n\n");
    }

    if needs_fd_close {
        out.push_str(".globl __mee_fd_close\n");
        out.push_str("__mee_fd_close:\n");
        out.push_str("  mov rax, 3\n"); // SYS_close
        out.push_str("  syscall\n");
        out.push_str("  test rax, rax\n");
        out.push_str("  js .Lmee_close_err\n");
        out.push_str("  xor eax, eax\n");
        out.push_str("  ret\n");
        out.push_str(".Lmee_close_err:\n");
        out.push_str("  neg eax\n"); // Linux returns -errno; intrinsic returns errno
        out.push_str("  ret\n\n");
    }
}

fn collect_locals_from_block(
    block: &Block,
    locals: &mut HashMap<String, i32>,
    local_index: &mut i32,
    local_decls: &mut Vec<String>,
    struct_defs: &HashMap<String, Vec<Param>>,
    var_types: &mut HashMap<String, Type>,
) {
    for stmt in &block.statements {
        match stmt {
            Stmt::Let { name, ty, .. } => {
                var_types.insert(name.clone(), ty.clone());
                if is_scalar(ty) {
                    local_decls.push("  (local i32)".to_string());
                    locals.insert(name.clone(), *local_index);
                    *local_index += 1;
                } else if let Type::Struct(sname) = ty {
                    let fields = struct_defs
                        .get(sname)
                        .unwrap_or_else(|| panic!("unknown struct {}", sname));
                    for field in fields {
                        if !is_scalar(&field.ty) {
                            panic!("non-scalar field {}.{} is not supported in codegen", sname, field.name);
                        }
                        let lname = field_local_name(name, &field.name);
                        local_decls.push("  (local i32)".to_string());
                        locals.insert(lname, *local_index);
                        *local_index += 1;
                    }
                }
            }
            Stmt::If { then_block, else_block, .. } => {
                collect_locals_from_block(then_block, locals, local_index, local_decls, struct_defs, var_types);
                if let Some(eb) = else_block {
                    collect_locals_from_block(eb, locals, local_index, local_decls, struct_defs, var_types);
                }
            }
            Stmt::While { body, .. } => {
                collect_locals_from_block(body, locals, local_index, local_decls, struct_defs, var_types);
            }
            _ => {}
        }
    }
}

fn collect_locals_x86_64(
    block: &Block,
    local_order: &mut Vec<String>,
    struct_defs: &HashMap<String, Vec<Param>>,
    var_types: &mut HashMap<String, Type>,
) {
    for stmt in &block.statements {
        match stmt {
            Stmt::Let { name, ty, .. } => {
                var_types.insert(name.clone(), ty.clone());
                if is_scalar(ty) {
                    local_order.push(name.clone());
                } else if let Type::Struct(sname) = ty {
                    let fields = struct_defs
                        .get(sname)
                        .unwrap_or_else(|| panic!("unknown struct {}", sname));
                    for field in fields {
                        if !is_scalar(&field.ty) {
                            panic!("non-scalar field {}.{} is not supported in codegen", sname, field.name);
                        }
                        local_order.push(field_local_name(name, &field.name));
                    }
                }
            }
            Stmt::If { then_block, else_block, .. } => {
                collect_locals_x86_64(then_block, local_order, struct_defs, var_types);
                if let Some(eb) = else_block {
                    collect_locals_x86_64(eb, local_order, struct_defs, var_types);
                }
            }
            Stmt::While { body, .. } => {
                collect_locals_x86_64(body, local_order, struct_defs, var_types);
            }
            _ => {}
        }
    }
}

fn emit_function_wat_with_strings(
    f: &Function,
    string_offsets: &HashMap<String, i32>,
    struct_defs: &HashMap<String, Vec<Param>>,
    fn_sigs: &HashMap<String, FnSig>,
) -> String {
    let mut out = String::new();
    let mut locals = HashMap::new();
    let mut var_types: HashMap<String, Type> = HashMap::new();
    let mut param_index = 0i32;
    if matches!(f.ret, Type::Struct(_)) {
        locals.insert("__sret_ptr".to_string(), param_index);
        param_index += 1;
    }
    for p in &f.params {
        var_types.insert(p.name.clone(), p.ty.clone());
        if is_scalar(&p.ty) {
            locals.insert(p.name.clone(), param_index);
            param_index += 1;
        } else if let Type::Struct(sname) = &p.ty {
            for field in struct_fields(struct_defs, sname) {
                let lname = field_local_name(&p.name, &field.name);
                locals.insert(lname, param_index);
                param_index += 1;
            }
        }
    }

    let mut local_decls: Vec<String> = Vec::new();
    let mut local_index = param_index;
    collect_locals_from_block(
        &f.body,
        &mut locals,
        &mut local_index,
        &mut local_decls,
        struct_defs,
        &mut var_types,
    );

    out.push_str(&format!("  (func ${}", f.name));
    if matches!(f.ret, Type::Struct(_)) {
        out.push_str(" (param i32)");
    }
    for p in &f.params {
        if is_scalar(&p.ty) {
            out.push_str(" (param i32)");
        } else if let Type::Struct(sname) = &p.ty {
            for _ in struct_fields(struct_defs, sname) {
                out.push_str(" (param i32)");
            }
        }
    }
    if is_scalar(&f.ret) {
        out.push_str(" (result i32)");
    }
    out.push_str("\n");
    for d in &local_decls {
        out.push_str(d);
        out.push_str("\n");
    }

    let mut label_counter = 0;
    emit_block_wat_with_strings(
        &f.body,
        &locals,
        &var_types,
        struct_defs,
        fn_sigs,
        &mut label_counter,
        string_offsets,
        &mut out,
    );

    if is_scalar(&f.ret) {
        out.push_str("  i32.const 0\n  return\n");
    } else if matches!(f.ret, Type::Struct(_)) {
        out.push_str("  return\n");
    }

    out.push_str("  )\n");
    out
}

fn emit_function_x86_64_with_strings(
    f: &Function,
    strings: &[String],
    struct_defs: &HashMap<String, Vec<Param>>,
    fn_sigs: &HashMap<String, FnSig>,
) -> String {
    let mut out = String::new();
    let mut locals = HashMap::new();
    let mut local_order = Vec::new();
    let mut var_types: HashMap<String, Type> = HashMap::new();

    if matches!(f.ret, Type::Struct(_)) {
        local_order.push("__sret_ptr".to_string());
    }
    for p in &f.params {
        var_types.insert(p.name.clone(), p.ty.clone());
        if is_scalar(&p.ty) {
            local_order.push(p.name.clone());
        } else if let Type::Struct(sname) = &p.ty {
            for field in struct_fields(struct_defs, sname) {
                local_order.push(field_local_name(&p.name, &field.name));
            }
        }
    }

    collect_locals_x86_64(&f.body, &mut local_order, struct_defs, &mut var_types);

    for (i, name) in local_order.iter().enumerate() {
        let offset = -8 * (i as i32 + 1);
        locals.insert(name.clone(), offset);
    }

    let mut frame_size = (local_order.len() as i32) * 8;
    if frame_size % 16 != 0 {
        frame_size += 8;
    }

    out.push_str(&format!(".globl {}\n", f.name));
    out.push_str(&format!("{}:\n", f.name));
    out.push_str("  push rbp\n  mov rbp, rsp\n");
    if frame_size > 0 {
        out.push_str(&format!("  sub rsp, {}\n", frame_size));
    }

    let arg_regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"];
    let mut param_names: Vec<String> = Vec::new();
    if matches!(f.ret, Type::Struct(_)) {
        param_names.push("__sret_ptr".to_string());
    }
    for p in &f.params {
        if is_scalar(&p.ty) {
            param_names.push(p.name.clone());
        } else if let Type::Struct(sname) = &p.ty {
            for field in struct_fields(struct_defs, sname) {
                param_names.push(field_local_name(&p.name, &field.name));
            }
        }
    }

    for (i, pname) in param_names.iter().enumerate() {
        if let Some(off) = locals.get(pname) {
            if i < arg_regs.len() {
                out.push_str(&format!("  mov QWORD PTR [rbp{}], {}\n", fmt_offset(*off), arg_regs[i]));
            }
        }
    }
    if !strings.is_empty() {
        out.push_str("  call __mee_init_memory\n");
    }

    let ret_label = format!(".Lreturn_{}", f.name);
    let mut label_counter = 0;
    emit_block_x86_64_with_strings(
        &f.body,
        &locals,
        &var_types,
        struct_defs,
        fn_sigs,
        &ret_label,
        &mut label_counter,
        strings,
        &mut out,
    );

    if is_scalar(&f.ret) {
        out.push_str("  mov rax, 0\n");
    } else if matches!(f.ret, Type::Struct(_)) {
        if let Some(off) = locals.get("__sret_ptr") {
            out.push_str(&format!("  mov rax, QWORD PTR [rbp{}]\n", fmt_offset(*off)));
        } else {
            out.push_str("  xor rax, rax\n");
        }
    }

    out.push_str(&format!("{}:\n", ret_label));
    out.push_str("  mov rsp, rbp\n  pop rbp\n  ret\n\n");
    out
}

fn emit_block_wat_with_strings(
    block: &Block,
    locals: &HashMap<String, i32>,
    var_types: &HashMap<String, Type>,
    struct_defs: &HashMap<String, Vec<Param>>,
    fn_sigs: &HashMap<String, FnSig>,
    label_counter: &mut i32,
    string_offsets: &HashMap<String, i32>,
    out: &mut String,
) {
    for stmt in &block.statements {
        emit_stmt_wat_with_strings(stmt, locals, var_types, struct_defs, fn_sigs, label_counter, string_offsets, out);
    }
}

fn emit_stmt_wat_with_strings(
    stmt: &Stmt,
    locals: &HashMap<String, i32>,
    var_types: &HashMap<String, Type>,
    struct_defs: &HashMap<String, Vec<Param>>,
    fn_sigs: &HashMap<String, FnSig>,
    label_counter: &mut i32,
    string_offsets: &HashMap<String, i32>,
    out: &mut String,
) {
    match stmt {
        Stmt::Let { name, ty, expr } => {
            if is_scalar(ty) {
                emit_expr_wat_with_strings(expr, locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                let idx = locals.get(name).unwrap_or_else(|| panic!("unknown local {}", name));
                out.push_str(&format!("  local.set {}\n", idx));
            } else if let Type::Struct(sname) = ty {
                let fields = struct_defs
                    .get(sname)
                    .unwrap_or_else(|| panic!("unknown struct {}", sname));
                match expr {
                    Expr::StructInit { name: init_name, fields: init_fields } => {
                        if init_name != sname {
                            panic!("struct init type mismatch: {} vs {}", init_name, sname);
                        }
                        for field in fields {
                            let init_expr = init_fields
                                .iter()
                                .find(|(fname, _)| fname == &field.name)
                                .unwrap_or_else(|| panic!("missing field {} in init for {}", field.name, sname))
                                .1
                                .clone();
                            emit_expr_wat_with_strings(&init_expr, locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                            let lname = field_local_name(name, &field.name);
                            let idx = locals.get(&lname).unwrap_or_else(|| panic!("unknown local {}", lname));
                            out.push_str(&format!("  local.set {}\n", idx));
                        }
                    }
                    Expr::Ident(src) => {
                        for field in fields {
                            let src_name = field_local_name(src, &field.name);
                            let dst_name = field_local_name(name, &field.name);
                            let src_idx = locals.get(&src_name).unwrap_or_else(|| panic!("unknown local {}", src_name));
                            let dst_idx = locals.get(&dst_name).unwrap_or_else(|| panic!("unknown local {}", dst_name));
                            out.push_str(&format!("  local.get {}\n", src_idx));
                            out.push_str(&format!("  local.set {}\n", dst_idx));
                        }
                    }
                    Expr::Call { callee, args } => {
                        let sig = fn_sigs.get(callee).unwrap_or_else(|| panic!("unknown function {}", callee));
                        if !matches!(sig.ret, Type::Struct(_)) {
                            panic!("expected struct-returning function in struct let init: {}", callee);
                        }
                        out.push_str(&format!("  i32.const {}\n", STRUCT_RET_SCRATCH_BASE));
                        for (arg, pty) in args.iter().zip(sig.params.iter()) {
                            match pty {
                                Type::Struct(sname2) => {
                                    let arg_fields = struct_fields(struct_defs, sname2);
                                    if let Expr::Ident(vname) = arg {
                                        for f2 in arg_fields {
                                            let lname2 = field_local_name(vname, &f2.name);
                                            let idx2 = locals.get(&lname2).unwrap_or_else(|| panic!("unknown local {}", lname2));
                                            out.push_str(&format!("  local.get {}\n", idx2));
                                        }
                                    } else {
                                        panic!("unsupported struct argument expression");
                                    }
                                }
                                _ => emit_expr_wat_with_strings(arg, locals, var_types, struct_defs, fn_sigs, string_offsets, out),
                            }
                        }
                        out.push_str(&format!("  call ${}\n", callee));
                        if is_scalar(&sig.ret) {
                            out.push_str("  drop\n");
                        }
                        for (i, field) in fields.iter().enumerate() {
                            out.push_str(&format!("  i32.const {}\n", STRUCT_RET_SCRATCH_BASE + (i as i32) * 4));
                            out.push_str("  i32.load\n");
                            let lname = field_local_name(name, &field.name);
                            let idx = locals.get(&lname).unwrap_or_else(|| panic!("unknown local {}", lname));
                            out.push_str(&format!("  local.set {}\n", idx));
                        }
                    }
                    _ => {
                        panic!("unsupported struct initializer for {}", name);
                    }
                }
            } else {
                panic!("unsupported let type");
            }
        }
        Stmt::Assign { name, expr } => {
            let ty = var_types.get(name).unwrap_or_else(|| panic!("unknown variable {}", name));
            if is_scalar(ty) {
                emit_expr_wat_with_strings(expr, locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                let idx = locals.get(name).unwrap_or_else(|| panic!("unknown local {}", name));
                out.push_str(&format!("  local.set {}\n", idx));
            } else if let Type::Struct(sname) = ty {
                let fields = struct_defs
                    .get(sname)
                    .unwrap_or_else(|| panic!("unknown struct {}", sname));
                match expr {
                    Expr::StructInit { name: init_name, fields: init_fields } => {
                        if init_name != sname {
                            panic!("struct init type mismatch: {} vs {}", init_name, sname);
                        }
                        for field in fields {
                            let init_expr = init_fields
                                .iter()
                                .find(|(fname, _)| fname == &field.name)
                                .unwrap_or_else(|| panic!("missing field {} in init for {}", field.name, sname))
                                .1
                                .clone();
                            emit_expr_wat_with_strings(&init_expr, locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                            let lname = field_local_name(name, &field.name);
                            let idx = locals.get(&lname).unwrap_or_else(|| panic!("unknown local {}", lname));
                            out.push_str(&format!("  local.set {}\n", idx));
                        }
                    }
                    Expr::Ident(src) => {
                        for field in fields {
                            let src_name = field_local_name(src, &field.name);
                            let dst_name = field_local_name(name, &field.name);
                            let src_idx = locals.get(&src_name).unwrap_or_else(|| panic!("unknown local {}", src_name));
                            let dst_idx = locals.get(&dst_name).unwrap_or_else(|| panic!("unknown local {}", dst_name));
                            out.push_str(&format!("  local.get {}\n", src_idx));
                            out.push_str(&format!("  local.set {}\n", dst_idx));
                        }
                    }
                    Expr::Call { callee, args } => {
                        let sig = fn_sigs.get(callee).unwrap_or_else(|| panic!("unknown function {}", callee));
                        if !matches!(sig.ret, Type::Struct(_)) {
                            panic!("expected struct-returning function in struct assignment: {}", callee);
                        }
                        out.push_str(&format!("  i32.const {}\n", STRUCT_RET_SCRATCH_BASE));
                        for (arg, pty) in args.iter().zip(sig.params.iter()) {
                            match pty {
                                Type::Struct(sname2) => {
                                    let arg_fields = struct_fields(struct_defs, sname2);
                                    if let Expr::Ident(vname) = arg {
                                        for f2 in arg_fields {
                                            let lname2 = field_local_name(vname, &f2.name);
                                            let idx2 = locals.get(&lname2).unwrap_or_else(|| panic!("unknown local {}", lname2));
                                            out.push_str(&format!("  local.get {}\n", idx2));
                                        }
                                    } else {
                                        panic!("unsupported struct argument expression");
                                    }
                                }
                                _ => emit_expr_wat_with_strings(arg, locals, var_types, struct_defs, fn_sigs, string_offsets, out),
                            }
                        }
                        out.push_str(&format!("  call ${}\n", callee));
                        if is_scalar(&sig.ret) {
                            out.push_str("  drop\n");
                        }
                        for (i, field) in fields.iter().enumerate() {
                            out.push_str(&format!("  i32.const {}\n", STRUCT_RET_SCRATCH_BASE + (i as i32) * 4));
                            out.push_str("  i32.load\n");
                            let lname = field_local_name(name, &field.name);
                            let idx = locals.get(&lname).unwrap_or_else(|| panic!("unknown local {}", lname));
                            out.push_str(&format!("  local.set {}\n", idx));
                        }
                    }
                    _ => {
                        panic!("unsupported struct assignment to {}", name);
                    }
                }
            } else {
                panic!("unsupported assignment type");
            }
        }
        Stmt::FieldAssign { base, field, expr } => {
            let ty = var_types.get(base).unwrap_or_else(|| panic!("unknown variable {}", base));
            if !matches!(ty, Type::Struct(_)) {
                panic!("field assignment on non-struct {}", base);
            }
            emit_expr_wat_with_strings(expr, locals, var_types, struct_defs, fn_sigs, string_offsets, out);
            let lname = field_local_name(base, field);
            let idx = locals.get(&lname).unwrap_or_else(|| panic!("unknown field {} on {}", field, base));
            out.push_str(&format!("  local.set {}\n", idx));
        }
        Stmt::If { cond, then_block, else_block } => {
            emit_expr_wat_with_strings(cond, locals, var_types, struct_defs, fn_sigs, string_offsets, out);
            out.push_str("  (if\n");
            out.push_str("    (then\n");
            emit_block_wat_with_strings(then_block, locals, var_types, struct_defs, fn_sigs, label_counter, string_offsets, out);
            out.push_str("    )\n");
            if let Some(eb) = else_block {
                out.push_str("    (else\n");
                emit_block_wat_with_strings(eb, locals, var_types, struct_defs, fn_sigs, label_counter, string_offsets, out);
                out.push_str("    )\n");
            }
            out.push_str("  )\n");
        }
        Stmt::While { cond, body } => {
            let n = *label_counter;
            *label_counter += 1;
            out.push_str(&format!("  (block $exit_{}\n", n));
            out.push_str(&format!("    (loop $loop_{}\n", n));
            emit_expr_wat_with_strings(cond, locals, var_types, struct_defs, fn_sigs, string_offsets, out);
            out.push_str("      i32.eqz\n");
            out.push_str(&format!("      br_if $exit_{}\n", n));
            emit_block_wat_with_strings(body, locals, var_types, struct_defs, fn_sigs, label_counter, string_offsets, out);
            out.push_str(&format!("      br $loop_{}\n", n));
            out.push_str("    )\n");
            out.push_str("  )\n");
        }
        Stmt::Return(expr) => {
            if locals.contains_key("__sret_ptr") {
                let sret_ptr_idx = *locals.get("__sret_ptr").unwrap();
                match expr {
                    Expr::StructInit { name, fields } => {
                        let sfields = struct_fields(struct_defs, name);
                        for (i, f) in sfields.iter().enumerate() {
                            let val = fields.iter().find(|(fname, _)| fname == &f.name).unwrap_or_else(|| panic!("missing field {} in return init", f.name)).1.clone();
                            out.push_str(&format!("  local.get {}\n", sret_ptr_idx));
                            out.push_str(&format!("  i32.const {}\n", (i as i32) * 4));
                            out.push_str("  i32.add\n");
                            emit_expr_wat_with_strings(&val, locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                            out.push_str("  i32.store\n");
                        }
                    }
                    Expr::Ident(src) => {
                        let ty = var_types.get(src).unwrap_or_else(|| panic!("unknown variable {}", src));
                        if let Type::Struct(sname) = ty {
                            let sfields = struct_fields(struct_defs, sname);
                            for (i, f) in sfields.iter().enumerate() {
                                let lname = field_local_name(src, &f.name);
                                let idx = locals.get(&lname).unwrap_or_else(|| panic!("unknown local {}", lname));
                                out.push_str(&format!("  local.get {}\n", sret_ptr_idx));
                                out.push_str(&format!("  i32.const {}\n", (i as i32) * 4));
                                out.push_str("  i32.add\n");
                                out.push_str(&format!("  local.get {}\n", idx));
                                out.push_str("  i32.store\n");
                            }
                        } else {
                            panic!("struct-return function must return struct expression");
                        }
                    }
                    _ => panic!("unsupported struct return expression"),
                }
                out.push_str("  return\n");
            } else {
                emit_expr_wat_with_strings(expr, locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                out.push_str("  return\n");
            }
        }
        Stmt::Expr(expr) => {
            emit_expr_wat_with_strings(expr, locals, var_types, struct_defs, fn_sigs, string_offsets, out);
            out.push_str("  drop\n");
        }
    }
}

fn emit_block_x86_64_with_strings(
    block: &Block,
    locals: &HashMap<String, i32>,
    var_types: &HashMap<String, Type>,
    struct_defs: &HashMap<String, Vec<Param>>,
    fn_sigs: &HashMap<String, FnSig>,
    ret_label: &str,
    label_counter: &mut i32,
    strings: &[String],
    out: &mut String,
) {
    for stmt in &block.statements {
        emit_stmt_x86_64_with_strings(stmt, locals, var_types, struct_defs, fn_sigs, ret_label, label_counter, strings, out);
    }
}

fn emit_stmt_x86_64_with_strings(
    stmt: &Stmt,
    locals: &HashMap<String, i32>,
    var_types: &HashMap<String, Type>,
    struct_defs: &HashMap<String, Vec<Param>>,
    fn_sigs: &HashMap<String, FnSig>,
    ret_label: &str,
    label_counter: &mut i32,
    strings: &[String],
    out: &mut String,
) {
    match stmt {
        Stmt::Let { name, ty, expr } => {
            if is_scalar(ty) {
                emit_expr_x86_64_with_strings(expr, locals, var_types, struct_defs, fn_sigs, strings, out);
                if let Some(off) = locals.get(name) {
                    out.push_str(&format!("  mov QWORD PTR [rbp{}], rax\n", fmt_offset(*off)));
                }
            } else if let Type::Struct(sname) = ty {
                let fields = struct_defs
                    .get(sname)
                    .unwrap_or_else(|| panic!("unknown struct {}", sname));
                match expr {
                    Expr::StructInit { name: init_name, fields: init_fields } => {
                        if init_name != sname {
                            panic!("struct init type mismatch: {} vs {}", init_name, sname);
                        }
                        for field in fields {
                            let init_expr = init_fields
                                .iter()
                                .find(|(fname, _)| fname == &field.name)
                                .unwrap_or_else(|| panic!("missing field {} in init for {}", field.name, sname))
                                .1
                                .clone();
                            emit_expr_x86_64_with_strings(&init_expr, locals, var_types, struct_defs, fn_sigs, strings, out);
                            if let Some(off) = locals.get(&field_local_name(name, &field.name)) {
                                out.push_str(&format!("  mov QWORD PTR [rbp{}], rax\n", fmt_offset(*off)));
                            }
                        }
                    }
                    Expr::Ident(src) => {
                        for field in fields {
                            if let Some(src_off) = locals.get(&field_local_name(src, &field.name)) {
                                out.push_str(&format!("  mov rax, QWORD PTR [rbp{}]\n", fmt_offset(*src_off)));
                            }
                            if let Some(dst_off) = locals.get(&field_local_name(name, &field.name)) {
                                out.push_str(&format!("  mov QWORD PTR [rbp{}], rax\n", fmt_offset(*dst_off)));
                            }
                        }
                    }
                    Expr::Call { callee, args } => {
                        let sig = fn_sigs.get(callee).unwrap_or_else(|| panic!("unknown function {}", callee));
                        if !matches!(sig.ret, Type::Struct(_)) {
                            panic!("expected struct-returning function in struct let init: {}", callee);
                        }
                        let mut flat_args: Vec<Expr> = Vec::new();
                        for (arg, pty) in args.iter().zip(sig.params.iter()) {
                            match pty {
                                Type::Struct(sname2) => {
                                    let arg_fields = struct_fields(struct_defs, sname2);
                                    match arg {
                                        Expr::Ident(vname) => {
                                            for f2 in arg_fields {
                                                flat_args.push(Expr::FieldAccess {
                                                    expr: Box::new(Expr::Ident(vname.clone())),
                                                    field: f2.name.clone(),
                                                });
                                            }
                                        }
                                        Expr::StructInit { name, fields: vals } => {
                                            if name != sname2 {
                                                panic!("struct call arg type mismatch: {} vs {}", name, sname2);
                                            }
                                            for f2 in arg_fields {
                                                let val = vals
                                                    .iter()
                                                    .find(|(fname, _)| fname == &f2.name)
                                                    .unwrap_or_else(|| panic!("missing field {} in arg init", f2.name))
                                                    .1
                                                    .clone();
                                                flat_args.push(val);
                                            }
                                        }
                                        _ => panic!("unsupported struct argument expression"),
                                    }
                                }
                                _ => flat_args.push(arg.clone()),
                            }
                        }

                        let scratch_size = ((fields.len() as i32) * 4 + 15) / 16 * 16;
                        out.push_str(&format!("  sub rsp, {}\n", scratch_size));
                        out.push_str("  lea r11, [rsp]\n");

                        let arg_regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"];
                        let total_args = flat_args.len() + 1;
                        let stack_count = total_args.saturating_sub(arg_regs.len());
                        let needs_pad = stack_count % 2 == 1;
                        if needs_pad {
                            out.push_str("  sub rsp, 8\n");
                        }
                        if total_args > arg_regs.len() {
                            for i in (arg_regs.len()..total_args).rev() {
                                emit_expr_x86_64_with_strings(&flat_args[i - 1], locals, var_types, struct_defs, fn_sigs, strings, out);
                                out.push_str("  push rax\n");
                            }
                        }
                        let reg_count = if total_args < arg_regs.len() { total_args } else { arg_regs.len() };
                        for i in (0..reg_count).rev() {
                            if i == 0 {
                                out.push_str(&format!("  mov {}, r11\n", arg_regs[i]));
                            } else {
                                emit_expr_x86_64_with_strings(&flat_args[i - 1], locals, var_types, struct_defs, fn_sigs, strings, out);
                                out.push_str(&format!("  mov {}, rax\n", arg_regs[i]));
                            }
                        }
                        out.push_str(&format!("  call {}\n", callee));

                        for (i, field) in fields.iter().enumerate() {
                            out.push_str(&format!("  mov eax, DWORD PTR [r11+{}]\n", (i as i32) * 4));
                            if let Some(dst_off) = locals.get(&field_local_name(name, &field.name)) {
                                out.push_str(&format!("  mov DWORD PTR [rbp{}], eax\n", fmt_offset(*dst_off)));
                            }
                        }

                        let cleanup = (stack_count as i32) * 8 + if needs_pad { 8 } else { 0 } + scratch_size;
                        out.push_str(&format!("  add rsp, {}\n", cleanup));
                    }
                    _ => {
                        panic!("unsupported struct initializer for {}", name);
                    }
                }
            } else {
                panic!("unsupported let type");
            }
        }
        Stmt::Assign { name, expr } => {
            let ty = var_types.get(name).unwrap_or_else(|| panic!("unknown variable {}", name));
            if is_scalar(ty) {
                emit_expr_x86_64_with_strings(expr, locals, var_types, struct_defs, fn_sigs, strings, out);
                if let Some(off) = locals.get(name) {
                    out.push_str(&format!("  mov QWORD PTR [rbp{}], rax\n", fmt_offset(*off)));
                }
            } else if let Type::Struct(sname) = ty {
                let fields = struct_defs
                    .get(sname)
                    .unwrap_or_else(|| panic!("unknown struct {}", sname));
                match expr {
                    Expr::StructInit { name: init_name, fields: init_fields } => {
                        if init_name != sname {
                            panic!("struct init type mismatch: {} vs {}", init_name, sname);
                        }
                        for field in fields {
                            let init_expr = init_fields
                                .iter()
                                .find(|(fname, _)| fname == &field.name)
                                .unwrap_or_else(|| panic!("missing field {} in init for {}", field.name, sname))
                                .1
                                .clone();
                            emit_expr_x86_64_with_strings(&init_expr, locals, var_types, struct_defs, fn_sigs, strings, out);
                            if let Some(off) = locals.get(&field_local_name(name, &field.name)) {
                                out.push_str(&format!("  mov QWORD PTR [rbp{}], rax\n", fmt_offset(*off)));
                            }
                        }
                    }
                    Expr::Ident(src) => {
                        for field in fields {
                            if let Some(src_off) = locals.get(&field_local_name(src, &field.name)) {
                                out.push_str(&format!("  mov rax, QWORD PTR [rbp{}]\n", fmt_offset(*src_off)));
                            }
                            if let Some(dst_off) = locals.get(&field_local_name(name, &field.name)) {
                                out.push_str(&format!("  mov QWORD PTR [rbp{}], rax\n", fmt_offset(*dst_off)));
                            }
                        }
                    }
                    Expr::Call { callee, args } => {
                        let sig = fn_sigs.get(callee).unwrap_or_else(|| panic!("unknown function {}", callee));
                        if !matches!(sig.ret, Type::Struct(_)) {
                            panic!("expected struct-returning function in struct assignment: {}", callee);
                        }
                        let mut flat_args: Vec<Expr> = Vec::new();
                        for (arg, pty) in args.iter().zip(sig.params.iter()) {
                            match pty {
                                Type::Struct(sname2) => {
                                    let arg_fields = struct_fields(struct_defs, sname2);
                                    match arg {
                                        Expr::Ident(vname) => {
                                            for f2 in arg_fields {
                                                flat_args.push(Expr::FieldAccess {
                                                    expr: Box::new(Expr::Ident(vname.clone())),
                                                    field: f2.name.clone(),
                                                });
                                            }
                                        }
                                        Expr::StructInit { name, fields: vals } => {
                                            if name != sname2 {
                                                panic!("struct call arg type mismatch: {} vs {}", name, sname2);
                                            }
                                            for f2 in arg_fields {
                                                let val = vals
                                                    .iter()
                                                    .find(|(fname, _)| fname == &f2.name)
                                                    .unwrap_or_else(|| panic!("missing field {} in arg init", f2.name))
                                                    .1
                                                    .clone();
                                                flat_args.push(val);
                                            }
                                        }
                                        _ => panic!("unsupported struct argument expression"),
                                    }
                                }
                                _ => flat_args.push(arg.clone()),
                            }
                        }

                        let scratch_size = ((fields.len() as i32) * 4 + 15) / 16 * 16;
                        out.push_str(&format!("  sub rsp, {}\n", scratch_size));
                        out.push_str("  lea r11, [rsp]\n");

                        let arg_regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"];
                        let total_args = flat_args.len() + 1;
                        let stack_count = total_args.saturating_sub(arg_regs.len());
                        let needs_pad = stack_count % 2 == 1;
                        if needs_pad {
                            out.push_str("  sub rsp, 8\n");
                        }
                        if total_args > arg_regs.len() {
                            for i in (arg_regs.len()..total_args).rev() {
                                emit_expr_x86_64_with_strings(&flat_args[i - 1], locals, var_types, struct_defs, fn_sigs, strings, out);
                                out.push_str("  push rax\n");
                            }
                        }
                        let reg_count = if total_args < arg_regs.len() { total_args } else { arg_regs.len() };
                        for i in (0..reg_count).rev() {
                            if i == 0 {
                                out.push_str(&format!("  mov {}, r11\n", arg_regs[i]));
                            } else {
                                emit_expr_x86_64_with_strings(&flat_args[i - 1], locals, var_types, struct_defs, fn_sigs, strings, out);
                                out.push_str(&format!("  mov {}, rax\n", arg_regs[i]));
                            }
                        }
                        out.push_str(&format!("  call {}\n", callee));

                        for (i, field) in fields.iter().enumerate() {
                            out.push_str(&format!("  mov eax, DWORD PTR [r11+{}]\n", (i as i32) * 4));
                            if let Some(dst_off) = locals.get(&field_local_name(name, &field.name)) {
                                out.push_str(&format!("  mov DWORD PTR [rbp{}], eax\n", fmt_offset(*dst_off)));
                            }
                        }

                        let cleanup = (stack_count as i32) * 8 + if needs_pad { 8 } else { 0 } + scratch_size;
                        out.push_str(&format!("  add rsp, {}\n", cleanup));
                    }
                    _ => {
                        panic!("unsupported struct assignment to {}", name);
                    }
                }
            } else {
                panic!("unsupported assignment type");
            }
        }
        Stmt::FieldAssign { base, field, expr } => {
            let ty = var_types.get(base).unwrap_or_else(|| panic!("unknown variable {}", base));
            if !matches!(ty, Type::Struct(_)) {
                panic!("field assignment on non-struct {}", base);
            }
            emit_expr_x86_64_with_strings(expr, locals, var_types, struct_defs, fn_sigs, strings, out);
            let lname = field_local_name(base, field);
            if let Some(off) = locals.get(&lname) {
                out.push_str(&format!("  mov QWORD PTR [rbp{}], rax\n", fmt_offset(*off)));
            } else {
                panic!("unknown field {} on {}", field, base);
            }
        }
        Stmt::If { cond, then_block, else_block } => {
            let n = *label_counter;
            *label_counter += 1;
            emit_expr_x86_64_with_strings(cond, locals, var_types, struct_defs, fn_sigs, strings, out);
            out.push_str("  cmp rax, 0\n");
            out.push_str(&format!("  je .Lelse_{}\n", n));
            emit_block_x86_64_with_strings(then_block, locals, var_types, struct_defs, fn_sigs, ret_label, label_counter, strings, out);
            out.push_str(&format!("  jmp .Lendif_{}\n", n));
            out.push_str(&format!(".Lelse_{}:\n", n));
            if let Some(eb) = else_block {
                emit_block_x86_64_with_strings(eb, locals, var_types, struct_defs, fn_sigs, ret_label, label_counter, strings, out);
            }
            out.push_str(&format!(".Lendif_{}:\n", n));
        }
        Stmt::While { cond, body } => {
            let n = *label_counter;
            *label_counter += 1;
            out.push_str(&format!(".Lloop_{}:\n", n));
            emit_expr_x86_64_with_strings(cond, locals, var_types, struct_defs, fn_sigs, strings, out);
            out.push_str("  cmp rax, 0\n");
            out.push_str(&format!("  je .Lexit_{}\n", n));
            emit_block_x86_64_with_strings(body, locals, var_types, struct_defs, fn_sigs, ret_label, label_counter, strings, out);
            out.push_str(&format!("  jmp .Lloop_{}\n", n));
            out.push_str(&format!(".Lexit_{}:\n", n));
        }
        Stmt::Return(expr) => {
            if let Some(sret_off) = locals.get("__sret_ptr") {
                match expr {
                    Expr::StructInit { name, fields } => {
                        let sfields = struct_fields(struct_defs, name);
                        out.push_str(&format!("  mov r10, QWORD PTR [rbp{}]\n", fmt_offset(*sret_off)));
                        for (i, f) in sfields.iter().enumerate() {
                            let val = fields
                                .iter()
                                .find(|(fname, _)| fname == &f.name)
                                .unwrap_or_else(|| panic!("missing field {} in return init", f.name))
                                .1
                                .clone();
                            emit_expr_x86_64_with_strings(&val, locals, var_types, struct_defs, fn_sigs, strings, out);
                            out.push_str(&format!("  mov DWORD PTR [r10+{}], eax\n", (i as i32) * 4));
                        }
                    }
                    Expr::Ident(src) => {
                        let ty = var_types.get(src).unwrap_or_else(|| panic!("unknown variable {}", src));
                        if let Type::Struct(sname) = ty {
                            let sfields = struct_fields(struct_defs, sname);
                            out.push_str(&format!("  mov r10, QWORD PTR [rbp{}]\n", fmt_offset(*sret_off)));
                            for (i, f) in sfields.iter().enumerate() {
                                let lname = field_local_name(src, &f.name);
                                let off = locals.get(&lname).unwrap_or_else(|| panic!("unknown local {}", lname));
                                out.push_str(&format!("  mov eax, DWORD PTR [rbp{}]\n", fmt_offset(*off)));
                                out.push_str(&format!("  mov DWORD PTR [r10+{}], eax\n", (i as i32) * 4));
                            }
                        } else {
                            panic!("struct-return function must return struct expression");
                        }
                    }
                    _ => panic!("unsupported struct return expression"),
                }
                out.push_str(&format!("  jmp {}\n", ret_label));
            } else {
                emit_expr_x86_64_with_strings(expr, locals, var_types, struct_defs, fn_sigs, strings, out);
                out.push_str(&format!("  jmp {}\n", ret_label));
            }
        }
        Stmt::Expr(expr) => {
            emit_expr_x86_64_with_strings(expr, locals, var_types, struct_defs, fn_sigs, strings, out);
        }
    }
}

fn emit_expr_wat_with_strings(
    expr: &Expr,
    locals: &HashMap<String, i32>,
    var_types: &HashMap<String, Type>,
    struct_defs: &HashMap<String, Vec<Param>>,
    fn_sigs: &HashMap<String, FnSig>,
    string_offsets: &HashMap<String, i32>,
    out: &mut String,
) {
    match expr {
        Expr::Int(v) => {
            out.push_str(&format!("  i32.const {}\n", v));
        }
        Expr::Char(c) => {
            out.push_str(&format!("  i32.const {}\n", *c as i32));
        }
        Expr::Bool(v) => {
            let n = if *v { 1 } else { 0 };
            out.push_str(&format!("  i32.const {}\n", n));
        }
        Expr::StringLit(s) => {
             if let Some(offset) = string_offsets.get(s) {
                 out.push_str(&format!("  i32.const {}\n", offset));
             } else {
                 out.push_str("  i32.const 0\n"); 
             }
        }
        Expr::Ident(name) => {
            if let Some(idx) = locals.get(name) {
                out.push_str(&format!("  local.get {}\n", idx));
            }
        }
        Expr::Binary { op, left, right } => {
            emit_expr_wat_with_strings(left, locals, var_types, struct_defs, fn_sigs, string_offsets, out);
            emit_expr_wat_with_strings(right, locals, var_types, struct_defs, fn_sigs, string_offsets, out);
            let instr = match op {
                BinOp::Add => "i32.add",
                BinOp::Sub => "i32.sub",
                BinOp::Mul => "i32.mul",
                BinOp::Div => "i32.div_s",
                BinOp::Lt => "i32.lt_s",
                BinOp::Gt => "i32.gt_s",
                BinOp::LtEq => "i32.le_s",
                BinOp::GtEq => "i32.ge_s",
                BinOp::Eq => "i32.eq",
                BinOp::NotEq => "i32.ne",
                BinOp::And => {
                    // (left != 0) * (right != 0)
                    out.push_str("  i32.const 0\n  i32.ne\n");
                    out.push_str("  i32.const 0\n  i32.ne\n");
                    out.push_str("  i32.mul\n");
                    return;
                }
                BinOp::Or => {
                    // (left != 0) + (right != 0) != 0
                    out.push_str("  i32.const 0\n  i32.ne\n");
                    out.push_str("  i32.const 0\n  i32.ne\n");
                    out.push_str("  i32.add\n  i32.const 0\n  i32.ne\n");
                    return;
                }
            };
            out.push_str(&format!("  {}\n", instr));
        }
        Expr::Unary { op, expr } => {
            match op {
                crate::ast::UnOp::Not => {
                    emit_expr_wat_with_strings(expr, locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                    out.push_str("  i32.const 0\n  i32.eq\n");
                }
            }
        }
        Expr::Call { callee, args } => {
            // Handle memory intrinsics
            if callee == "__mem_load" {
                if args.len() != 1 {
                    panic!("__mem_load expects 1 argument (address)");
                }
                emit_expr_wat_with_strings(&args[0], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                out.push_str("  i32.load\n");
                return;
            }
            if callee == "__mem_load8" {
                if args.len() != 1 {
                    panic!("__mem_load8 expects 1 argument (address)");
                }
                emit_expr_wat_with_strings(&args[0], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                out.push_str("  i32.load8_u\n");
                return;
            }
            if callee == "__mem_store" {
                if args.len() != 2 {
                    panic!("__mem_store expects 2 arguments (address, value)");
                }
                emit_expr_wat_with_strings(&args[0], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                emit_expr_wat_with_strings(&args[1], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                out.push_str("  i32.store\n");
                out.push_str("  i32.const 0\n"); // Return 0 (store is side-effect only)
                return;
            }
            if callee == "__mem_store8" {
                if args.len() != 2 {
                    panic!("__mem_store8 expects 2 arguments (address, value)");
                }
                emit_expr_wat_with_strings(&args[0], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                emit_expr_wat_with_strings(&args[1], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                out.push_str("  i32.store8\n");
                out.push_str("  i32.const 0\n");
                return;
            }
            if callee == "__fd_write" {
                if args.len() != 4 {
                    panic!("__fd_write expects 4 arguments (fd, iov_ptr, iov_cnt, nwritten_ptr)");
                }
                emit_expr_wat_with_strings(&args[0], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                emit_expr_wat_with_strings(&args[1], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                emit_expr_wat_with_strings(&args[2], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                emit_expr_wat_with_strings(&args[3], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                out.push_str("  call $__fd_write\n");
                return;
            }
            if callee == "__fd_read" {
                if args.len() != 4 {
                    panic!("__fd_read expects 4 arguments (fd, iov_ptr, iov_cnt, nread_ptr)");
                }
                emit_expr_wat_with_strings(&args[0], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                emit_expr_wat_with_strings(&args[1], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                emit_expr_wat_with_strings(&args[2], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                emit_expr_wat_with_strings(&args[3], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                out.push_str("  call $__fd_read\n");
                return;
            }
            if callee == "__path_open" {
                if args.len() != 9 {
                    panic!("__path_open expects 9 arguments (dirfd, dirflags, path_ptr, path_len, oflags, rights_base, rights_inheriting, fdflags, opened_fd_ptr)");
                }
                emit_expr_wat_with_strings(&args[0], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                emit_expr_wat_with_strings(&args[1], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                emit_expr_wat_with_strings(&args[2], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                emit_expr_wat_with_strings(&args[3], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                emit_expr_wat_with_strings(&args[4], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                emit_expr_wat_with_strings(&args[5], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                out.push_str("  i64.extend_i32_u\n");
                emit_expr_wat_with_strings(&args[6], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                out.push_str("  i64.extend_i32_u\n");
                emit_expr_wat_with_strings(&args[7], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                emit_expr_wat_with_strings(&args[8], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                out.push_str("  call $__path_open\n");
                return;
            }
            if callee == "__fd_close" {
                if args.len() != 1 {
                    panic!("__fd_close expects 1 argument (fd)");
                }
                emit_expr_wat_with_strings(&args[0], locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                out.push_str("  call $__fd_close\n");
                return;
            }
            let sig = fn_sigs.get(callee);
            if let Some(sig) = sig {
                if matches!(sig.ret, Type::Struct(_)) {
                    panic!("struct-return call is not valid in scalar expression context: {}", callee);
                }
                for (arg, pty) in args.iter().zip(sig.params.iter()) {
                    match pty {
                        Type::Struct(sname) => {
                            let fields = struct_fields(struct_defs, sname);
                            match arg {
                                Expr::Ident(vname) => {
                                    for f in fields {
                                        let lname = field_local_name(vname, &f.name);
                                        let idx = locals.get(&lname).unwrap_or_else(|| panic!("unknown local {}", lname));
                                        out.push_str(&format!("  local.get {}\n", idx));
                                    }
                                }
                                Expr::StructInit { name, fields: vals } => {
                                    if name != sname {
                                        panic!("struct call arg type mismatch: {} vs {}", name, sname);
                                    }
                                    for f in fields {
                                        let val = vals.iter().find(|(fname, _)| fname == &f.name).unwrap_or_else(|| panic!("missing field {} in arg init", f.name)).1.clone();
                                        emit_expr_wat_with_strings(&val, locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                                    }
                                }
                                _ => panic!("unsupported struct argument expression"),
                            }
                        }
                        _ => emit_expr_wat_with_strings(arg, locals, var_types, struct_defs, fn_sigs, string_offsets, out),
                    }
                }
            } else {
                for arg in args {
                    emit_expr_wat_with_strings(arg, locals, var_types, struct_defs, fn_sigs, string_offsets, out);
                }
            }
            out.push_str(&format!("  call ${}\n", callee));
        }
        Expr::FieldAccess { expr, field } => {
            if let Expr::Ident(name) = &**expr {
                let ty = var_types.get(name).unwrap_or_else(|| panic!("unknown variable {}", name));
                if !matches!(ty, Type::Struct(_)) {
                    panic!("field access on non-struct {}", name);
                }
                let lname = field_local_name(name, field);
                if locals.contains_key(&lname) {
                    let idx = locals.get(&lname).unwrap_or_else(|| panic!("unknown local {}", lname));
                    out.push_str(&format!("  local.get {}\n", idx));
                } else {
                    panic!("unknown field {} on {}", field, name);
                }
            } else {
                panic!("field access only supported on identifiers");
            }
        }
        Expr::StructInit { .. } => {
            panic!("WAT codegen for struct init is only supported in let/assign");
        }
    }
}

fn emit_expr_x86_64_with_strings(
    expr: &Expr,
    locals: &HashMap<String, i32>,
    var_types: &HashMap<String, Type>,
    struct_defs: &HashMap<String, Vec<Param>>,
    fn_sigs: &HashMap<String, FnSig>,
    strings: &[String],
    out: &mut String,
) {
    match expr {
        Expr::Int(v) => {
            out.push_str(&format!("  mov rax, {}\n", v));
        }
        Expr::Char(c) => {
            out.push_str(&format!("  mov rax, {}\n", *c as i32));
        }
        Expr::Bool(v) => {
            let n = if *v { 1 } else { 0 };
            out.push_str(&format!("  mov rax, {}\n", n));
        }
        Expr::StringLit(s) => {
             if let Some(offset) = x86_string_offset(strings, s) {
                 out.push_str(&format!("  mov rax, {}\n", offset));
            } else {
                 out.push_str("  mov rax, 0\n");
            }
        }
        Expr::Ident(name) => {
            if let Some(off) = locals.get(name) {
                out.push_str(&format!("  mov rax, QWORD PTR [rbp{}]\n", fmt_offset(*off)));
            }
        }
        Expr::Binary { op, left, right } => {
            emit_expr_x86_64_with_strings(left, locals, var_types, struct_defs, fn_sigs, strings, out);
            out.push_str("  push rax\n");
            emit_expr_x86_64_with_strings(right, locals, var_types, struct_defs, fn_sigs, strings, out);
            out.push_str("  pop rcx\n");
            match op {
                BinOp::Add => {
                    out.push_str("  add rax, rcx\n");
                }
                BinOp::Sub => {
                    out.push_str("  sub rcx, rax\n  mov rax, rcx\n");
                }
                BinOp::Mul => {
                    out.push_str("  imul rax, rcx\n");
                }
                BinOp::Div => {
                    out.push_str("  mov r8, rax\n  mov rax, rcx\n  cqo\n  idiv r8\n");
                }
                BinOp::Lt => {
                    out.push_str("  cmp rcx, rax\n  setl al\n  movzx rax, al\n");
                }
                BinOp::Gt => {
                    out.push_str("  cmp rcx, rax\n  setg al\n  movzx rax, al\n");
                }
                BinOp::LtEq => {
                    out.push_str("  cmp rcx, rax\n  setle al\n  movzx rax, al\n");
                }
                BinOp::GtEq => {
                    out.push_str("  cmp rcx, rax\n  setge al\n  movzx rax, al\n");
                }
                BinOp::Eq => {
                    out.push_str("  cmp rcx, rax\n  sete al\n  movzx rax, al\n");
                }
                BinOp::NotEq => {
                    out.push_str("  cmp rcx, rax\n  setne al\n  movzx rax, al\n");
                }
                BinOp::And => {
                    out.push_str("  cmp rcx, 0\n  setne cl\n  movzx rcx, cl\n");
                    out.push_str("  cmp rax, 0\n  setne al\n  movzx rax, al\n");
                    out.push_str("  imul rax, rcx\n");
                }
                BinOp::Or => {
                    out.push_str("  cmp rcx, 0\n  setne cl\n  movzx rcx, cl\n");
                    out.push_str("  cmp rax, 0\n  setne al\n  movzx rax, al\n");
                    out.push_str("  add rax, rcx\n");
                    out.push_str("  cmp rax, 0\n  setne al\n  movzx rax, al\n");
                }
            }
        }
        Expr::Unary { op, expr } => {
            match op {
                crate::ast::UnOp::Not => {
                    emit_expr_x86_64_with_strings(expr, locals, var_types, struct_defs, fn_sigs, strings, out);
                    out.push_str("  cmp rax, 0\n  sete al\n  movzx rax, al\n");
                }
            }
        }
        Expr::Call { callee, args } => {
            // Handle memory intrinsics
            if callee == "__mem_load" {
                if args.len() != 1 {
                    panic!("__mem_load expects 1 argument (address)");
                }
                emit_expr_x86_64_with_strings(&args[0], locals, var_types, struct_defs, fn_sigs, strings, out);
                // rax has linear-memory offset, load 32-bit value and sign-extend
                out.push_str("  lea rcx, [rip + __mee_memory]\n");
                out.push_str("  add rcx, rax\n");
                out.push_str("  movsxd rax, DWORD PTR [rcx]\n");
                return;
            }
            if callee == "__mem_load8" {
                if args.len() != 1 {
                    panic!("__mem_load8 expects 1 argument (address)");
                }
                emit_expr_x86_64_with_strings(&args[0], locals, var_types, struct_defs, fn_sigs, strings, out);
                // rax has linear-memory offset, load byte and zero-extend
                out.push_str("  lea rcx, [rip + __mee_memory]\n");
                out.push_str("  add rcx, rax\n");
                out.push_str("  movzx rax, BYTE PTR [rcx]\n");
                return;
            }
            if callee == "__mem_store" {
                if args.len() != 2 {
                    panic!("__mem_store expects 2 arguments (address, value)");
                }
                emit_expr_x86_64_with_strings(&args[0], locals, var_types, struct_defs, fn_sigs, strings, out);
                out.push_str("  push rax\n");
                emit_expr_x86_64_with_strings(&args[1], locals, var_types, struct_defs, fn_sigs, strings, out);
                out.push_str("  pop rcx\n");
                // rcx has linear-memory offset, rax has value
                out.push_str("  lea rdx, [rip + __mee_memory]\n");
                out.push_str("  add rdx, rcx\n");
                out.push_str("  mov DWORD PTR [rdx], eax\n");
                out.push_str("  xor rax, rax\n"); // Return 0
                return;
            }
            if callee == "__mem_store8" {
                if args.len() != 2 {
                    panic!("__mem_store8 expects 2 arguments (address, value)");
                }
                emit_expr_x86_64_with_strings(&args[0], locals, var_types, struct_defs, fn_sigs, strings, out);
                out.push_str("  push rax\n");
                emit_expr_x86_64_with_strings(&args[1], locals, var_types, struct_defs, fn_sigs, strings, out);
                out.push_str("  pop rcx\n");
                // rcx has linear-memory offset, rax has value
                out.push_str("  lea rdx, [rip + __mee_memory]\n");
                out.push_str("  add rdx, rcx\n");
                out.push_str("  mov BYTE PTR [rdx], al\n");
                out.push_str("  xor rax, rax\n"); // Return 0
                return;
            }
            if callee == "__fd_write" {
                if args.len() != 4 {
                    panic!("__fd_write expects 4 arguments (fd, iov_ptr, iov_cnt, nwritten_ptr)");
                }
                emit_expr_x86_64_with_strings(&args[3], locals, var_types, struct_defs, fn_sigs, strings, out);
                out.push_str("  mov rcx, rax\n");
                emit_expr_x86_64_with_strings(&args[2], locals, var_types, struct_defs, fn_sigs, strings, out);
                out.push_str("  mov rdx, rax\n");
                emit_expr_x86_64_with_strings(&args[1], locals, var_types, struct_defs, fn_sigs, strings, out);
                out.push_str("  mov rsi, rax\n");
                emit_expr_x86_64_with_strings(&args[0], locals, var_types, struct_defs, fn_sigs, strings, out);
                out.push_str("  mov rdi, rax\n");
                out.push_str("  call __mee_fd_write\n");
                return;
            }
            if callee == "__fd_read" {
                if args.len() != 4 {
                    panic!("__fd_read expects 4 arguments (fd, iov_ptr, iov_cnt, nread_ptr)");
                }
                emit_expr_x86_64_with_strings(&args[3], locals, var_types, struct_defs, fn_sigs, strings, out);
                out.push_str("  mov rcx, rax\n");
                emit_expr_x86_64_with_strings(&args[2], locals, var_types, struct_defs, fn_sigs, strings, out);
                out.push_str("  mov rdx, rax\n");
                emit_expr_x86_64_with_strings(&args[1], locals, var_types, struct_defs, fn_sigs, strings, out);
                out.push_str("  mov rsi, rax\n");
                emit_expr_x86_64_with_strings(&args[0], locals, var_types, struct_defs, fn_sigs, strings, out);
                out.push_str("  mov rdi, rax\n");
                out.push_str("  call __mee_fd_read\n");
                return;
            }
            if callee == "__path_open" {
                if args.len() != 9 {
                    panic!("__path_open expects 9 arguments (dirfd, dirflags, path_ptr, path_len, oflags, rights_base, rights_inheriting, fdflags, opened_fd_ptr)");
                }
                let arg_regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"];
                let stack_count = args.len() - arg_regs.len();
                let needs_pad = stack_count % 2 == 1;
                if needs_pad {
                    out.push_str("  sub rsp, 8\n");
                }
                for i in (arg_regs.len()..args.len()).rev() {
                    emit_expr_x86_64_with_strings(&args[i], locals, var_types, struct_defs, fn_sigs, strings, out);
                    out.push_str("  push rax\n");
                }
                for i in (0..arg_regs.len()).rev() {
                    emit_expr_x86_64_with_strings(&args[i], locals, var_types, struct_defs, fn_sigs, strings, out);
                    out.push_str(&format!("  mov {}, rax\n", arg_regs[i]));
                }
                out.push_str("  call __mee_path_open\n");
                let cleanup = (stack_count as i32) * 8 + if needs_pad { 8 } else { 0 };
                if cleanup > 0 {
                    out.push_str(&format!("  add rsp, {}\n", cleanup));
                }
                return;
            }
            if callee == "__fd_close" {
                if args.len() != 1 {
                    panic!("__fd_close expects 1 argument (fd)");
                }
                emit_expr_x86_64_with_strings(&args[0], locals, var_types, struct_defs, fn_sigs, strings, out);
                out.push_str("  mov rdi, rax\n");
                out.push_str("  call __mee_fd_close\n");
                return;
            }
            let flat_args: Vec<Expr> = if let Some(sig) = fn_sigs.get(callee) {
                if matches!(sig.ret, Type::Struct(_)) {
                    panic!("struct-return call is not valid in scalar expression context: {}", callee);
                }
                let mut out_args: Vec<Expr> = Vec::new();
                for (arg, pty) in args.iter().zip(sig.params.iter()) {
                    match pty {
                        Type::Struct(sname) => {
                            let fields = struct_fields(struct_defs, sname);
                            match arg {
                                Expr::Ident(vname) => {
                                    for f in fields {
                                        out_args.push(Expr::FieldAccess {
                                            expr: Box::new(Expr::Ident(vname.clone())),
                                            field: f.name.clone(),
                                        });
                                    }
                                }
                                Expr::StructInit { name, fields: vals } => {
                                    if name != sname {
                                        panic!("struct call arg type mismatch: {} vs {}", name, sname);
                                    }
                                    for f in fields {
                                        let val = vals
                                            .iter()
                                            .find(|(fname, _)| fname == &f.name)
                                            .unwrap_or_else(|| panic!("missing field {} in arg init", f.name))
                                            .1
                                            .clone();
                                        out_args.push(val);
                                    }
                                }
                                _ => panic!("unsupported struct argument expression"),
                            }
                        }
                        _ => out_args.push(arg.clone()),
                    }
                }
                out_args
            } else {
                args.clone()
            };
            let arg_regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"];
            let reg_count = if flat_args.len() < arg_regs.len() { flat_args.len() } else { arg_regs.len() };
            let stack_count = flat_args.len().saturating_sub(arg_regs.len());
            let needs_pad = stack_count % 2 == 1;

            if needs_pad {
                out.push_str("  sub rsp, 8\n");
            }

            if flat_args.len() > arg_regs.len() {
                for i in (arg_regs.len()..flat_args.len()).rev() {
                    emit_expr_x86_64_with_strings(&flat_args[i], locals, var_types, struct_defs, fn_sigs, strings, out);
                    out.push_str("  push rax\n");
                }
            }

            for i in (0..reg_count).rev() {
                emit_expr_x86_64_with_strings(&flat_args[i], locals, var_types, struct_defs, fn_sigs, strings, out);
                out.push_str(&format!("  mov {}, rax\n", arg_regs[i]));
            }

            out.push_str(&format!("  call {}\n", callee));

            if stack_count > 0 || needs_pad {
                let cleanup = (stack_count as i32) * 8 + if needs_pad { 8 } else { 0 };
                out.push_str(&format!("  add rsp, {}\n", cleanup));
            }
        }
        Expr::FieldAccess { expr, field } => {
            if let Expr::Ident(name) = &**expr {
                let ty = var_types.get(name).unwrap_or_else(|| panic!("unknown variable {}", name));
                if !matches!(ty, Type::Struct(_)) {
                    panic!("field access on non-struct {}", name);
                }
                let lname = field_local_name(name, field);
                if let Some(off) = locals.get(&lname) {
                    out.push_str(&format!("  mov rax, QWORD PTR [rbp{}]\n", fmt_offset(*off)));
                } else {
                    panic!("unknown field {} on {}", field, name);
                }
            } else {
                panic!("field access only supported on identifiers");
            }
        }
        Expr::StructInit { .. } => {
            panic!("x86_64 codegen for struct init is only supported in let/assign");
        }
    }
}

fn fmt_offset(off: i32) -> String {
    if off < 0 {
        format!(" - {}", -off)
    } else if off > 0 {
        format!(" + {}", off)
    } else {
        String::new()
    }
}

fn x86_string_offset(strings: &[String], s: &str) -> Option<i32> {
    let mut offset: i32 = 0;
    for item in strings {
        if item == s {
            return Some(offset);
        }
        offset += item.len() as i32 + 1;
    }
    None
}
