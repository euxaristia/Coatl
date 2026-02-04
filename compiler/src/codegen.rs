use std::collections::HashMap;

use crate::ast::{BinOp, Block, Expr, Function, Param, Program, Stmt, Type};

fn is_scalar(ty: &Type) -> bool {
    matches!(ty, Type::I32 | Type::Char | Type::Bool)
}

fn field_local_name(var: &str, field: &str) -> String {
    format!("__field__{}__{}", var, field)
}

fn collect_struct_defs(prog: &Program) -> HashMap<String, Vec<Param>> {
    let mut defs = HashMap::new();
    for s in &prog.structs {
        defs.insert(s.name.clone(), s.fields.clone());
    }
    defs
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

fn stmt_uses_fd_write(stmt: &Stmt) -> bool {
    match stmt {
        Stmt::Let { expr, .. } => expr_uses_fd_write(expr),
        Stmt::Assign { expr, .. } => expr_uses_fd_write(expr),
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

fn expr_uses_fd_write(expr: &Expr) -> bool {
    match expr {
        Expr::Call { callee, args } => {
            if callee == "__fd_write" {
                return true;
            }
            args.iter().any(expr_uses_fd_write)
        }
        Expr::Binary { left, right, .. } => expr_uses_fd_write(left) || expr_uses_fd_write(right),
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
        Expr::FieldAccess { expr, .. } => expr_uses_fd_read(expr),
        Expr::StructInit { fields, .. } => fields.iter().any(|(_, e)| expr_uses_fd_read(e)),
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
        Expr::FieldAccess { expr, .. } => expr_uses_memory(expr),
        Expr::StructInit { fields, .. } => fields.iter().any(|(_, e)| expr_uses_memory(e)),
        _ => false,
    }
}

pub fn emit_wat(prog: &Program) -> String {
    let strings = collect_strings_from_program(prog);
    let struct_defs = collect_struct_defs(prog);
    let needs_fd_write = uses_fd_write(prog);
    let needs_fd_read = uses_fd_read(prog);
    let needs_wasi = needs_fd_write || needs_fd_read;
    let needs_memory = !strings.is_empty() || uses_memory(prog) || needs_wasi;
    let mut out = String::new();
    out.push_str("(module\n");

    if needs_fd_write {
        out.push_str("  (import \"wasi_snapshot_preview1\" \"fd_write\" (func $__fd_write (param i32 i32 i32 i32) (result i32)))\n");
    }
    if needs_fd_read {
        out.push_str("  (import \"wasi_snapshot_preview1\" \"fd_read\" (func $__fd_read (param i32 i32 i32 i32) (result i32)))\n");
    }

    // Emit memory if we have strings or use memory intrinsics
    if needs_memory {
        out.push_str("  (memory 1024)\n");
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
        out.push_str(&emit_function_wat_with_strings(f, &string_offsets, &struct_defs));
    }
    if prog.functions.iter().any(|f| f.name == "main") {
        out.push_str("  (export \"main\" (func $main))\n");
    }
    out.push_str(")\n");
    out
}

pub fn emit_x86_64_asm(prog: &Program) -> String {
    let strings = collect_strings_from_program(prog);
    let struct_defs = collect_struct_defs(prog);
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

    out.push_str(".text\n");
    for f in &prog.functions {
        out.push_str(&emit_function_x86_64_with_strings(f, &strings, &struct_defs));
    }
    out
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
) -> String {
    let mut out = String::new();
    let mut locals = HashMap::new();
    let mut var_types: HashMap<String, Type> = HashMap::new();
    for (idx, p) in f.params.iter().enumerate() {
        if matches!(p.ty, Type::Struct(_)) {
            panic!("struct params are not supported in codegen");
        }
        var_types.insert(p.name.clone(), p.ty.clone());
        locals.insert(p.name.clone(), idx as i32);
    }

    let mut local_decls: Vec<String> = Vec::new();
    let mut local_index = f.params.len() as i32;
    collect_locals_from_block(
        &f.body,
        &mut locals,
        &mut local_index,
        &mut local_decls,
        struct_defs,
        &mut var_types,
    );

    out.push_str(&format!("  (func ${}", f.name));
    for p in &f.params {
        out.push_str(" (param i32)");
    }
    if is_scalar(&f.ret) {
        out.push_str(" (result i32)");
    } else if matches!(f.ret, Type::Struct(_)) {
        panic!("struct return values are not supported in codegen");
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
        &mut label_counter,
        string_offsets,
        &mut out,
    );

    if is_scalar(&f.ret) {
        out.push_str("  i32.const 0\n  return\n");
    }

    out.push_str("  )\n");
    out
}

fn emit_function_x86_64_with_strings(
    f: &Function,
    strings: &[String],
    struct_defs: &HashMap<String, Vec<Param>>,
) -> String {
    let mut out = String::new();
    let mut locals = HashMap::new();
    let mut local_order = Vec::new();
    let mut var_types: HashMap<String, Type> = HashMap::new();

    for p in &f.params {
        if matches!(p.ty, Type::Struct(_)) {
            panic!("struct params are not supported in codegen");
        }
        var_types.insert(p.name.clone(), p.ty.clone());
        local_order.push(p.name.clone());
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
    for (i, p) in f.params.iter().enumerate() {
        if let Some(off) = locals.get(&p.name) {
            if i < arg_regs.len() {
                out.push_str(&format!("  mov QWORD PTR [rbp{}], {}\n", fmt_offset(*off), arg_regs[i]));
            }
        }
    }

    let ret_label = format!(".Lreturn_{}", f.name);
    let mut label_counter = 0;
    emit_block_x86_64_with_strings(
        &f.body,
        &locals,
        &var_types,
        struct_defs,
        &ret_label,
        &mut label_counter,
        strings,
        &mut out,
    );

    if is_scalar(&f.ret) {
        out.push_str("  mov rax, 0\n");
    } else if matches!(f.ret, Type::Struct(_)) {
        panic!("struct return values are not supported in codegen");
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
    label_counter: &mut i32,
    string_offsets: &HashMap<String, i32>,
    out: &mut String,
) {
    for stmt in &block.statements {
        emit_stmt_wat_with_strings(stmt, locals, var_types, struct_defs, label_counter, string_offsets, out);
    }
}

fn emit_stmt_wat_with_strings(
    stmt: &Stmt,
    locals: &HashMap<String, i32>,
    var_types: &HashMap<String, Type>,
    struct_defs: &HashMap<String, Vec<Param>>,
    label_counter: &mut i32,
    string_offsets: &HashMap<String, i32>,
    out: &mut String,
) {
    match stmt {
        Stmt::Let { name, ty, expr } => {
            if is_scalar(ty) {
                emit_expr_wat_with_strings(expr, locals, var_types, struct_defs, string_offsets, out);
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
                            emit_expr_wat_with_strings(&init_expr, locals, var_types, struct_defs, string_offsets, out);
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
                emit_expr_wat_with_strings(expr, locals, var_types, struct_defs, string_offsets, out);
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
                            emit_expr_wat_with_strings(&init_expr, locals, var_types, struct_defs, string_offsets, out);
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
                    _ => {
                        panic!("unsupported struct assignment to {}", name);
                    }
                }
            } else {
                panic!("unsupported assignment type");
            }
        }
        Stmt::If { cond, then_block, else_block } => {
            emit_expr_wat_with_strings(cond, locals, var_types, struct_defs, string_offsets, out);
            out.push_str("  (if\n");
            out.push_str("    (then\n");
            emit_block_wat_with_strings(then_block, locals, var_types, struct_defs, label_counter, string_offsets, out);
            out.push_str("    )\n");
            if let Some(eb) = else_block {
                out.push_str("    (else\n");
                emit_block_wat_with_strings(eb, locals, var_types, struct_defs, label_counter, string_offsets, out);
                out.push_str("    )\n");
            }
            out.push_str("  )\n");
        }
        Stmt::While { cond, body } => {
            let n = *label_counter;
            *label_counter += 1;
            out.push_str(&format!("  (block $exit_{}\n", n));
            out.push_str(&format!("    (loop $loop_{}\n", n));
            emit_expr_wat_with_strings(cond, locals, var_types, struct_defs, string_offsets, out);
            out.push_str("      i32.eqz\n");
            out.push_str(&format!("      br_if $exit_{}\n", n));
            emit_block_wat_with_strings(body, locals, var_types, struct_defs, label_counter, string_offsets, out);
            out.push_str(&format!("      br $loop_{}\n", n));
            out.push_str("    )\n");
            out.push_str("  )\n");
        }
        Stmt::Return(expr) => {
            emit_expr_wat_with_strings(expr, locals, var_types, struct_defs, string_offsets, out);
            out.push_str("  return\n");
        }
        Stmt::Expr(expr) => {
            emit_expr_wat_with_strings(expr, locals, var_types, struct_defs, string_offsets, out);
            out.push_str("  drop\n");
        }
    }
}

fn emit_block_x86_64_with_strings(
    block: &Block,
    locals: &HashMap<String, i32>,
    var_types: &HashMap<String, Type>,
    struct_defs: &HashMap<String, Vec<Param>>,
    ret_label: &str,
    label_counter: &mut i32,
    strings: &[String],
    out: &mut String,
) {
    for stmt in &block.statements {
        emit_stmt_x86_64_with_strings(stmt, locals, var_types, struct_defs, ret_label, label_counter, strings, out);
    }
}

fn emit_stmt_x86_64_with_strings(
    stmt: &Stmt,
    locals: &HashMap<String, i32>,
    var_types: &HashMap<String, Type>,
    struct_defs: &HashMap<String, Vec<Param>>,
    ret_label: &str,
    label_counter: &mut i32,
    strings: &[String],
    out: &mut String,
) {
    match stmt {
        Stmt::Let { name, ty, expr } => {
            if is_scalar(ty) {
                emit_expr_x86_64_with_strings(expr, locals, var_types, struct_defs, strings, out);
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
                            emit_expr_x86_64_with_strings(&init_expr, locals, var_types, struct_defs, strings, out);
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
                emit_expr_x86_64_with_strings(expr, locals, var_types, struct_defs, strings, out);
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
                            emit_expr_x86_64_with_strings(&init_expr, locals, var_types, struct_defs, strings, out);
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
                    _ => {
                        panic!("unsupported struct assignment to {}", name);
                    }
                }
            } else {
                panic!("unsupported assignment type");
            }
        }
        Stmt::If { cond, then_block, else_block } => {
            let n = *label_counter;
            *label_counter += 1;
            emit_expr_x86_64_with_strings(cond, locals, var_types, struct_defs, strings, out);
            out.push_str("  cmp rax, 0\n");
            out.push_str(&format!("  je .Lelse_{}\n", n));
            emit_block_x86_64_with_strings(then_block, locals, var_types, struct_defs, ret_label, label_counter, strings, out);
            out.push_str(&format!("  jmp .Lendif_{}\n", n));
            out.push_str(&format!(".Lelse_{}:\n", n));
            if let Some(eb) = else_block {
                emit_block_x86_64_with_strings(eb, locals, var_types, struct_defs, ret_label, label_counter, strings, out);
            }
            out.push_str(&format!(".Lendif_{}:\n", n));
        }
        Stmt::While { cond, body } => {
            let n = *label_counter;
            *label_counter += 1;
            out.push_str(&format!(".Lloop_{}:\n", n));
            emit_expr_x86_64_with_strings(cond, locals, var_types, struct_defs, strings, out);
            out.push_str("  cmp rax, 0\n");
            out.push_str(&format!("  je .Lexit_{}\n", n));
            emit_block_x86_64_with_strings(body, locals, var_types, struct_defs, ret_label, label_counter, strings, out);
            out.push_str(&format!("  jmp .Lloop_{}\n", n));
            out.push_str(&format!(".Lexit_{}:\n", n));
        }
        Stmt::Return(expr) => {
            emit_expr_x86_64_with_strings(expr, locals, var_types, struct_defs, strings, out);
            out.push_str(&format!("  jmp {}\n", ret_label));
        }
        Stmt::Expr(expr) => {
            emit_expr_x86_64_with_strings(expr, locals, var_types, struct_defs, strings, out);
        }
    }
}

fn emit_expr_wat_with_strings(
    expr: &Expr,
    locals: &HashMap<String, i32>,
    var_types: &HashMap<String, Type>,
    _struct_defs: &HashMap<String, Vec<Param>>,
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
            emit_expr_wat_with_strings(left, locals, var_types, _struct_defs, string_offsets, out);
            emit_expr_wat_with_strings(right, locals, var_types, _struct_defs, string_offsets, out);
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
            };
            out.push_str(&format!("  {}\n", instr));
        }
        Expr::Call { callee, args } => {
            // Handle memory intrinsics
            if callee == "__mem_load" {
                if args.len() != 1 {
                    panic!("__mem_load expects 1 argument (address)");
                }
                emit_expr_wat_with_strings(&args[0], locals, var_types, _struct_defs, string_offsets, out);
                out.push_str("  i32.load\n");
                return;
            }
            if callee == "__mem_load8" {
                if args.len() != 1 {
                    panic!("__mem_load8 expects 1 argument (address)");
                }
                emit_expr_wat_with_strings(&args[0], locals, var_types, _struct_defs, string_offsets, out);
                out.push_str("  i32.load8_u\n");
                return;
            }
            if callee == "__mem_store" {
                if args.len() != 2 {
                    panic!("__mem_store expects 2 arguments (address, value)");
                }
                emit_expr_wat_with_strings(&args[0], locals, var_types, _struct_defs, string_offsets, out);
                emit_expr_wat_with_strings(&args[1], locals, var_types, _struct_defs, string_offsets, out);
                out.push_str("  i32.store\n");
                out.push_str("  i32.const 0\n"); // Return 0 (store is side-effect only)
                return;
            }
            if callee == "__mem_store8" {
                if args.len() != 2 {
                    panic!("__mem_store8 expects 2 arguments (address, value)");
                }
                emit_expr_wat_with_strings(&args[0], locals, var_types, _struct_defs, string_offsets, out);
                emit_expr_wat_with_strings(&args[1], locals, var_types, _struct_defs, string_offsets, out);
                out.push_str("  i32.store8\n");
                out.push_str("  i32.const 0\n");
                return;
            }
            if callee == "__fd_write" {
                if args.len() != 4 {
                    panic!("__fd_write expects 4 arguments (fd, iov_ptr, iov_cnt, nwritten_ptr)");
                }
                emit_expr_wat_with_strings(&args[0], locals, var_types, _struct_defs, string_offsets, out);
                emit_expr_wat_with_strings(&args[1], locals, var_types, _struct_defs, string_offsets, out);
                emit_expr_wat_with_strings(&args[2], locals, var_types, _struct_defs, string_offsets, out);
                emit_expr_wat_with_strings(&args[3], locals, var_types, _struct_defs, string_offsets, out);
                out.push_str("  call $__fd_write\n");
                return;
            }
            if callee == "__fd_read" {
                if args.len() != 4 {
                    panic!("__fd_read expects 4 arguments (fd, iov_ptr, iov_cnt, nread_ptr)");
                }
                emit_expr_wat_with_strings(&args[0], locals, var_types, _struct_defs, string_offsets, out);
                emit_expr_wat_with_strings(&args[1], locals, var_types, _struct_defs, string_offsets, out);
                emit_expr_wat_with_strings(&args[2], locals, var_types, _struct_defs, string_offsets, out);
                emit_expr_wat_with_strings(&args[3], locals, var_types, _struct_defs, string_offsets, out);
                out.push_str("  call $__fd_read\n");
                return;
            }
            for arg in args {
                emit_expr_wat_with_strings(arg, locals, var_types, _struct_defs, string_offsets, out);
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
    _struct_defs: &HashMap<String, Vec<Param>>,
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
             if let Some(idx) = strings.iter().position(|x| x == s) {
                 out.push_str(&format!("  lea rax, [rip + .Lstr_{}]\n", idx));
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
            emit_expr_x86_64_with_strings(left, locals, var_types, _struct_defs, strings, out);
            out.push_str("  push rax\n");
            emit_expr_x86_64_with_strings(right, locals, var_types, _struct_defs, strings, out);
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
            }
        }
        Expr::Call { callee, args } => {
            // Handle memory intrinsics
            if callee == "__mem_load" {
                if args.len() != 1 {
                    panic!("__mem_load expects 1 argument (address)");
                }
                emit_expr_x86_64_with_strings(&args[0], locals, var_types, _struct_defs, strings, out);
                // rax has address, load 32-bit value and sign-extend to 64-bit
                out.push_str("  movsxd rax, DWORD PTR [rax]\n");
                return;
            }
            if callee == "__mem_load8" {
                if args.len() != 1 {
                    panic!("__mem_load8 expects 1 argument (address)");
                }
                emit_expr_x86_64_with_strings(&args[0], locals, var_types, _struct_defs, strings, out);
                // rax has address, load byte and zero-extend
                out.push_str("  movzx rax, BYTE PTR [rax]\n");
                return;
            }
            if callee == "__mem_store" {
                if args.len() != 2 {
                    panic!("__mem_store expects 2 arguments (address, value)");
                }
                emit_expr_x86_64_with_strings(&args[0], locals, var_types, _struct_defs, strings, out);
                out.push_str("  push rax\n");
                emit_expr_x86_64_with_strings(&args[1], locals, var_types, _struct_defs, strings, out);
                out.push_str("  pop rcx\n");
                // rcx has address, rax has value
                out.push_str("  mov DWORD PTR [rcx], eax\n");
                out.push_str("  xor rax, rax\n"); // Return 0
                return;
            }
            if callee == "__mem_store8" {
                if args.len() != 2 {
                    panic!("__mem_store8 expects 2 arguments (address, value)");
                }
                emit_expr_x86_64_with_strings(&args[0], locals, var_types, _struct_defs, strings, out);
                out.push_str("  push rax\n");
                emit_expr_x86_64_with_strings(&args[1], locals, var_types, _struct_defs, strings, out);
                out.push_str("  pop rcx\n");
                // rcx has address, rax has value
                out.push_str("  mov BYTE PTR [rcx], al\n");
                out.push_str("  xor rax, rax\n"); // Return 0
                return;
            }
            if callee == "__fd_write" {
                panic!("__fd_write is not supported in the x86_64 backend yet");
            }
            if callee == "__fd_read" {
                panic!("__fd_read is not supported in the x86_64 backend yet");
            }
            let arg_regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"];
            let reg_count = if args.len() < arg_regs.len() { args.len() } else { arg_regs.len() };
            let stack_count = args.len().saturating_sub(arg_regs.len());
            let needs_pad = stack_count % 2 == 1;

            if needs_pad {
                out.push_str("  sub rsp, 8\n");
            }

            if args.len() > arg_regs.len() {
                for i in (arg_regs.len()..args.len()).rev() {
                    emit_expr_x86_64_with_strings(&args[i], locals, var_types, _struct_defs, strings, out);
                    out.push_str("  push rax\n");
                }
            }

            for i in (0..reg_count).rev() {
                emit_expr_x86_64_with_strings(&args[i], locals, var_types, _struct_defs, strings, out);
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
