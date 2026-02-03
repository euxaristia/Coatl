use std::collections::HashMap;

use crate::ast::{BinOp, Expr, Function, Program, Stmt, Type};

pub fn emit_wat(prog: &Program) -> String {
    let mut out = String::new();
    out.push_str("(module\n");
    for f in &prog.functions {
        out.push_str(&emit_function_wat(f));
    }
    if prog.functions.iter().any(|f| f.name == "main") {
        out.push_str("  (export \"main\" (func $main))\n");
    }
    out.push_str(")\n");
    out
}

pub fn emit_x86_64_asm(prog: &Program) -> String {
    let mut out = String::new();
    out.push_str(".text\n");
    for f in &prog.functions {
        out.push_str(&emit_function_x86_64(f));
    }
    out
}

fn emit_function_wat(f: &Function) -> String {
    let mut out = String::new();
    let mut locals = HashMap::new();
    for (idx, p) in f.params.iter().enumerate() {
        locals.insert(p.name.clone(), idx as i32);
    }

    let mut local_decls: Vec<String> = Vec::new();
    let mut local_index = f.params.len() as i32;
    for stmt in &f.body.statements {
        if let Stmt::Let { name, ty, .. } = stmt {
            if *ty == Type::I32 || *ty == Type::Bool {
                local_decls.push(format!("  (local ${} i32)", name));
                locals.insert(name.clone(), local_index);
                local_index += 1;
            }
        }
    }

    out.push_str(&format!("  (func ${}", f.name));
    for p in &f.params {
        out.push_str(&format!(" (param ${} i32)", p.name));
    }
    if f.ret == Type::I32 || f.ret == Type::Bool {
        out.push_str(" (result i32)");
    }
    out.push_str("\n");
    for d in &local_decls {
        out.push_str(d);
        out.push_str("\n");
    }

    for stmt in &f.body.statements {
        emit_stmt_wat(stmt, &locals, &mut out);
    }

    if f.ret == Type::I32 || f.ret == Type::Bool {
        out.push_str("  i32.const 0\n  return\n");
    }

    out.push_str("  )\n");
    out
}

fn emit_function_x86_64(f: &Function) -> String {
    let mut out = String::new();
    let mut locals = HashMap::new();
    let mut local_order = Vec::new();

    for p in &f.params {
        local_order.push(p.name.clone());
    }

    for stmt in &f.body.statements {
        if let Stmt::Let { name, ty, .. } = stmt {
            if *ty == Type::I32 || *ty == Type::Bool {
                local_order.push(name.clone());
            }
        }
    }

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
    for stmt in &f.body.statements {
        emit_stmt_x86_64(stmt, &locals, &ret_label, &mut out);
    }

    if f.ret == Type::I32 || f.ret == Type::Bool {
        out.push_str("  mov rax, 0\n");
    }

    out.push_str(&format!("{}:\n", ret_label));
    out.push_str("  mov rsp, rbp\n  pop rbp\n  ret\n\n");
    out
}

fn emit_stmt_wat(stmt: &Stmt, locals: &HashMap<String, i32>, out: &mut String) {
    match stmt {
        Stmt::Let { name, expr, .. } => {
            emit_expr_wat(expr, locals, out);
            out.push_str(&format!("  local.set ${}\n", name));
        }
        Stmt::Return(expr) => {
            emit_expr_wat(expr, locals, out);
            out.push_str("  return\n");
        }
        Stmt::Expr(expr) => {
            emit_expr_wat(expr, locals, out);
            out.push_str("  drop\n");
        }
    }
}

fn emit_stmt_x86_64(stmt: &Stmt, locals: &HashMap<String, i32>, ret_label: &str, out: &mut String) {
    match stmt {
        Stmt::Let { name, expr, .. } => {
            emit_expr_x86_64(expr, locals, out);
            if let Some(off) = locals.get(name) {
                out.push_str(&format!("  mov QWORD PTR [rbp{}], rax\n", fmt_offset(*off)));
            }
        }
        Stmt::Return(expr) => {
            emit_expr_x86_64(expr, locals, out);
            out.push_str(&format!("  jmp {}\n", ret_label));
        }
        Stmt::Expr(expr) => {
            emit_expr_x86_64(expr, locals, out);
        }
    }
}

fn emit_expr_wat(expr: &Expr, locals: &HashMap<String, i32>, out: &mut String) {
    match expr {
        Expr::Int(v) => {
            out.push_str(&format!("  i32.const {}\n", v));
        }
        Expr::Bool(v) => {
            let n = if *v { 1 } else { 0 };
            out.push_str(&format!("  i32.const {}\n", n));
        }
        Expr::Ident(name) => {
            if locals.contains_key(name) {
                out.push_str(&format!("  local.get ${}\n", name));
            }
        }
        Expr::Binary { op, left, right } => {
            emit_expr_wat(left, locals, out);
            emit_expr_wat(right, locals, out);
            let instr = match op {
                BinOp::Add => "i32.add",
                BinOp::Sub => "i32.sub",
                BinOp::Mul => "i32.mul",
                BinOp::Div => "i32.div_s",
            };
            out.push_str(&format!("  {}\n", instr));
        }
        Expr::Call { callee, args } => {
            for arg in args {
                emit_expr_wat(arg, locals, out);
            }
            out.push_str(&format!("  call ${}\n", callee));
        }
    }
}

fn emit_expr_x86_64(expr: &Expr, locals: &HashMap<String, i32>, out: &mut String) {
    match expr {
        Expr::Int(v) => {
            out.push_str(&format!("  mov rax, {}\n", v));
        }
        Expr::Bool(v) => {
            let n = if *v { 1 } else { 0 };
            out.push_str(&format!("  mov rax, {}\n", n));
        }
        Expr::Ident(name) => {
            if let Some(off) = locals.get(name) {
                out.push_str(&format!("  mov rax, QWORD PTR [rbp{}]\n", fmt_offset(*off)));
            }
        }
        Expr::Binary { op, left, right } => {
            emit_expr_x86_64(left, locals, out);
            out.push_str("  push rax\n");
            emit_expr_x86_64(right, locals, out);
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
                    emit_expr_x86_64(&args[i], locals, out);
                    out.push_str("  push rax\n");
                }
            }

            for i in (0..reg_count).rev() {
                emit_expr_x86_64(&args[i], locals, out);
                out.push_str(&format!("  mov {}, rax\n", arg_regs[i]));
            }

            out.push_str(&format!("  call {}\n", callee));

            if stack_count > 0 || needs_pad {
                let cleanup = (stack_count as i32) * 8 + if needs_pad { 8 } else { 0 };
                out.push_str(&format!("  add rsp, {}\n", cleanup));
            }
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
