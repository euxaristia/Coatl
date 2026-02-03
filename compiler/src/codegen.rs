use std::collections::HashMap;

use crate::ast::{BinOp, Block, Expr, Function, Program, Stmt, Type};

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

pub fn emit_wat(prog: &Program) -> String {
    let strings = collect_strings_from_program(prog);
    let mut out = String::new();
    out.push_str("(module\n");

    // Emit memory and string data if we have strings
    if !strings.is_empty() {
        out.push_str("  (memory 1)\n");
        let mut offset = 0;
        for s in strings.iter() {
            // Emit string data
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
        out.push_str(&emit_function_wat_with_strings(f, &string_offsets));
    }
    if prog.functions.iter().any(|f| f.name == "main") {
        out.push_str("  (export \"main\" (func $main))\n");
    }
    out.push_str(")\n");
    out
}

pub fn emit_x86_64_asm(prog: &Program) -> String {
    let strings = collect_strings_from_program(prog);
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
        out.push_str(&emit_function_x86_64_with_strings(f, &strings));
    }
    out
}

fn collect_locals_from_block(block: &Block, locals: &mut HashMap<String, i32>, local_index: &mut i32, local_decls: &mut Vec<String>) {
    for stmt in &block.statements {
        match stmt {
            Stmt::Let { name, ty, .. } => {
                if *ty == Type::I32 || *ty == Type::Char || *ty == Type::Bool {
                    local_decls.push(format!("  (local ${} i32)", name));
                    locals.insert(name.clone(), *local_index);
                    *local_index += 1;
                }
            }
            Stmt::If { then_block, else_block, .. } => {
                collect_locals_from_block(then_block, locals, local_index, local_decls);
                if let Some(eb) = else_block {
                    collect_locals_from_block(eb, locals, local_index, local_decls);
                }
            }
            Stmt::While { body, .. } => {
                collect_locals_from_block(body, locals, local_index, local_decls);
            }
            _ => {}
        }
    }
}

fn collect_locals_x86_64(block: &Block, local_order: &mut Vec<String>) {
    for stmt in &block.statements {
        match stmt {
            Stmt::Let { name, ty, .. } => {
                if *ty == Type::I32 || *ty == Type::Char || *ty == Type::Bool {
                    local_order.push(name.clone());
                }
            }
            Stmt::If { then_block, else_block, .. } => {
                collect_locals_x86_64(then_block, local_order);
                if let Some(eb) = else_block {
                    collect_locals_x86_64(eb, local_order);
                }
            }
            Stmt::While { body, .. } => {
                collect_locals_x86_64(body, local_order);
            }
            _ => {}
        }
    }
}

fn emit_function_wat_with_strings(f: &Function, string_offsets: &HashMap<String, i32>) -> String {
    let mut out = String::new();
    let mut locals = HashMap::new();
    for (idx, p) in f.params.iter().enumerate() {
        locals.insert(p.name.clone(), idx as i32);
    }

    let mut local_decls: Vec<String> = Vec::new();
    let mut local_index = f.params.len() as i32;
    collect_locals_from_block(&f.body, &mut locals, &mut local_index, &mut local_decls);

    out.push_str(&format!("  (func ${}", f.name));
    for p in &f.params {
        out.push_str(&format!(" (param ${} i32)", p.name));
    }
    if f.ret == Type::I32 || f.ret == Type::Char || f.ret == Type::Bool {
        out.push_str(" (result i32)");
    }
    out.push_str("\n");
    for d in &local_decls {
        out.push_str(d);
        out.push_str("\n");
    }

    let mut label_counter = 0;
    emit_block_wat_with_strings(&f.body, &locals, &mut label_counter, string_offsets, &mut out);

    if f.ret == Type::I32 || f.ret == Type::Char || f.ret == Type::Bool {
        out.push_str("  i32.const 0\n  return\n");
    }

    out.push_str("  )\n");
    out
}

fn emit_function_x86_64_with_strings(f: &Function, strings: &[String]) -> String {
    let mut out = String::new();
    let mut locals = HashMap::new();
    let mut local_order = Vec::new();

    for p in &f.params {
        local_order.push(p.name.clone());
    }

    collect_locals_x86_64(&f.body, &mut local_order);

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
    emit_block_x86_64_with_strings(&f.body, &locals, &ret_label, &mut label_counter, strings, &mut out);

    if f.ret == Type::I32 || f.ret == Type::Char || f.ret == Type::Bool {
        out.push_str("  mov rax, 0\n");
    }

    out.push_str(&format!("{}:\n", ret_label));
    out.push_str("  mov rsp, rbp\n  pop rbp\n  ret\n\n");
    out
}

fn emit_block_wat_with_strings(block: &Block, locals: &HashMap<String, i32>, label_counter: &mut i32, string_offsets: &HashMap<String, i32>, out: &mut String) {
    for stmt in &block.statements {
        emit_stmt_wat_with_strings(stmt, locals, label_counter, string_offsets, out);
    }
}

fn emit_stmt_wat_with_strings(stmt: &Stmt, locals: &HashMap<String, i32>, label_counter: &mut i32, string_offsets: &HashMap<String, i32>, out: &mut String) {
    match stmt {
        Stmt::Let { name, expr, .. } => {
            emit_expr_wat_with_strings(expr, locals, string_offsets, out);
            out.push_str(&format!("  local.set ${}\n", name));
        }
        Stmt::Assign { name, expr } => {
            emit_expr_wat_with_strings(expr, locals, string_offsets, out);
            out.push_str(&format!("  local.set ${}\n", name));
        }
        Stmt::If { cond, then_block, else_block } => {
            emit_expr_wat_with_strings(cond, locals, string_offsets, out);
            out.push_str("  (if\n");
            out.push_str("    (then\n");
            emit_block_wat_with_strings(then_block, locals, label_counter, string_offsets, out);
            out.push_str("    )\n");
            if let Some(eb) = else_block {
                out.push_str("    (else\n");
                emit_block_wat_with_strings(eb, locals, label_counter, string_offsets, out);
                out.push_str("    )\n");
            }
            out.push_str("  )\n");
        }
        Stmt::While { cond, body } => {
            let n = *label_counter;
            *label_counter += 1;
            out.push_str(&format!("  (block $exit_{}\n", n));
            out.push_str(&format!("    (loop $loop_{}\n", n));
            emit_expr_wat_with_strings(cond, locals, string_offsets, out);
            out.push_str("      i32.eqz\n");
            out.push_str(&format!("      br_if $exit_{}\n", n));
            emit_block_wat_with_strings(body, locals, label_counter, string_offsets, out);
            out.push_str(&format!("      br $loop_{}\n", n));
            out.push_str("    )\n");
            out.push_str("  )\n");
        }
        Stmt::Return(expr) => {
            emit_expr_wat_with_strings(expr, locals, string_offsets, out);
            out.push_str("  return\n");
        }
        Stmt::Expr(expr) => {
            emit_expr_wat_with_strings(expr, locals, string_offsets, out);
            out.push_str("  drop\n");
        }
    }
}

fn emit_block_x86_64_with_strings(block: &Block, locals: &HashMap<String, i32>, ret_label: &str, label_counter: &mut i32, strings: &[String], out: &mut String) {
    for stmt in &block.statements {
        emit_stmt_x86_64_with_strings(stmt, locals, ret_label, label_counter, strings, out);
    }
}

fn emit_stmt_x86_64_with_strings(stmt: &Stmt, locals: &HashMap<String, i32>, ret_label: &str, label_counter: &mut i32, strings: &[String], out: &mut String) {
    match stmt {
        Stmt::Let { name, expr, .. } => {
            emit_expr_x86_64_with_strings(expr, locals, strings, out);
            if let Some(off) = locals.get(name) {
                out.push_str(&format!("  mov QWORD PTR [rbp{}], rax\n", fmt_offset(*off)));
            }
        }
        Stmt::Assign { name, expr } => {
            emit_expr_x86_64_with_strings(expr, locals, strings, out);
            if let Some(off) = locals.get(name) {
                out.push_str(&format!("  mov QWORD PTR [rbp{}], rax\n", fmt_offset(*off)));
            }
        }
        Stmt::If { cond, then_block, else_block } => {
            let n = *label_counter;
            *label_counter += 1;
            emit_expr_x86_64_with_strings(cond, locals, strings, out);
            out.push_str("  cmp rax, 0\n");
            out.push_str(&format!("  je .Lelse_{}\n", n));
            emit_block_x86_64_with_strings(then_block, locals, ret_label, label_counter, strings, out);
            out.push_str(&format!("  jmp .Lendif_{}\n", n));
            out.push_str(&format!(".Lelse_{}:\n", n));
            if let Some(eb) = else_block {
                emit_block_x86_64_with_strings(eb, locals, ret_label, label_counter, strings, out);
            }
            out.push_str(&format!(".Lendif_{}:\n", n));
        }
        Stmt::While { cond, body } => {
            let n = *label_counter;
            *label_counter += 1;
            out.push_str(&format!(".Lloop_{}:\n", n));
            emit_expr_x86_64_with_strings(cond, locals, strings, out);
            out.push_str("  cmp rax, 0\n");
            out.push_str(&format!("  je .Lexit_{}\n", n));
            emit_block_x86_64_with_strings(body, locals, ret_label, label_counter, strings, out);
            out.push_str(&format!("  jmp .Lloop_{}\n", n));
            out.push_str(&format!(".Lexit_{}:\n", n));
        }
        Stmt::Return(expr) => {
            emit_expr_x86_64_with_strings(expr, locals, strings, out);
            out.push_str(&format!("  jmp {}\n", ret_label));
        }
        Stmt::Expr(expr) => {
            emit_expr_x86_64_with_strings(expr, locals, strings, out);
        }
    }
}

fn emit_expr_wat_with_strings(expr: &Expr, locals: &HashMap<String, i32>, string_offsets: &HashMap<String, i32>, out: &mut String) {
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
            if locals.contains_key(name) {
                out.push_str(&format!("  local.get ${}\n", name));
            }
        }
        Expr::Binary { op, left, right } => {
            emit_expr_wat_with_strings(left, locals, string_offsets, out);
            emit_expr_wat_with_strings(right, locals, string_offsets, out);
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
            for arg in args {
                emit_expr_wat_with_strings(arg, locals, string_offsets, out);
            }
            out.push_str(&format!("  call ${}\n", callee));
        }
        Expr::FieldAccess { .. } => {
            panic!("WAT codegen for field access is not implemented");
        }
        Expr::StructInit { .. } => {
            panic!("WAT codegen for struct init is not implemented");
        }
    }
}

fn emit_expr_x86_64_with_strings(expr: &Expr, locals: &HashMap<String, i32>, strings: &[String], out: &mut String) {
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
            emit_expr_x86_64_with_strings(left, locals, strings, out);
            out.push_str("  push rax\n");
            emit_expr_x86_64_with_strings(right, locals, strings, out);
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
            let arg_regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"];
            let reg_count = if args.len() < arg_regs.len() { args.len() } else { arg_regs.len() };
            let stack_count = args.len().saturating_sub(arg_regs.len());
            let needs_pad = stack_count % 2 == 1;

            if needs_pad {
                out.push_str("  sub rsp, 8\n");
            }

            if args.len() > arg_regs.len() {
                for i in (arg_regs.len()..args.len()).rev() {
                    emit_expr_x86_64_with_strings(&args[i], locals, strings, out);
                    out.push_str("  push rax\n");
                }
            }

            for i in (0..reg_count).rev() {
                emit_expr_x86_64_with_strings(&args[i], locals, strings, out);
                out.push_str(&format!("  mov {}, rax\n", arg_regs[i]));
            }

            out.push_str(&format!("  call {}\n", callee));

            if stack_count > 0 || needs_pad {
                let cleanup = (stack_count as i32) * 8 + if needs_pad { 8 } else { 0 };
                out.push_str(&format!("  add rsp, {}\n", cleanup));
            }
        }
        Expr::FieldAccess { .. } => {
            panic!("x86_64 codegen for field access is not implemented");
        }
        Expr::StructInit { .. } => {
            panic!("x86_64 codegen for struct init is not implemented");
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
