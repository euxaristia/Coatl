use crate::ast::{BinOp, Block, Expr, Function, Param, Program, Stmt, Type, UnOp};

fn ind(n: usize) -> String {
    "  ".repeat(n)
}

fn escape_str(s: &str) -> String {
    s.chars()
        .flat_map(|c| match c {
            '\\' => "\\\\".chars().collect::<Vec<_>>(),
            '"' => "\\\"".chars().collect::<Vec<_>>(),
            '\n' => "\\n".chars().collect::<Vec<_>>(),
            '\r' => "\\r".chars().collect::<Vec<_>>(),
            '\t' => "\\t".chars().collect::<Vec<_>>(),
            _ => vec![c],
        })
        .collect()
}

fn type_name(ty: &Type) -> String {
    match ty {
        Type::I32 => "i32".to_string(),
        Type::Char => "char".to_string(),
        Type::Bool => "bool".to_string(),
        Type::Str => "str".to_string(),
        Type::Void => "void".to_string(),
        Type::Struct(name) => format!("(struct {})", name),
    }
}

fn unop_name(op: UnOp) -> &'static str {
    match op {
        UnOp::Not => "not",
    }
}

fn binop_name(op: BinOp) -> &'static str {
    match op {
        BinOp::Add => "add",
        BinOp::Sub => "sub",
        BinOp::Mul => "mul",
        BinOp::Div => "div",
        BinOp::Lt => "lt",
        BinOp::Gt => "gt",
        BinOp::LtEq => "le",
        BinOp::GtEq => "ge",
        BinOp::Eq => "eq",
        BinOp::NotEq => "ne",
        BinOp::And => "and",
        BinOp::Or => "or",
    }
}

fn emit_param(p: &Param, depth: usize) -> String {
    format!("{}(param {} {})", ind(depth), p.name, type_name(&p.ty))
}

fn emit_expr(expr: &Expr, depth: usize) -> String {
    match expr {
        Expr::Int(v) => format!("{}(int {})", ind(depth), v),
        Expr::Char(c) => format!("{}(char {})", ind(depth), *c as u32),
        Expr::Bool(v) => format!("{}(bool {})", ind(depth), if *v { 1 } else { 0 }),
        Expr::StringLit(s) => format!("{}(string \"{}\")", ind(depth), escape_str(s)),
        Expr::Ident(name) => format!("{}(ident {})", ind(depth), name),
        Expr::Unary { op, expr } => {
            let mut out = String::new();
            out.push_str(&format!("{}(unary {}\n", ind(depth), unop_name(*op)));
            out.push_str(&emit_expr(expr, depth + 1));
            out.push_str(&format!("\n{})", ind(depth)));
            out
        }
        Expr::Binary { op, left, right } => {
            let mut out = String::new();
            out.push_str(&format!("{}(binary {}\n", ind(depth), binop_name(*op)));
            out.push_str(&emit_expr(left, depth + 1));
            out.push('\n');
            out.push_str(&emit_expr(right, depth + 1));
            out.push_str(&format!("\n{})", ind(depth)));
            out
        }
        Expr::Call { callee, args } => {
            let mut out = String::new();
            out.push_str(&format!("{}(call {}", ind(depth), callee));
            if args.is_empty() {
                out.push(')');
                return out;
            }
            out.push('\n');
            for (i, arg) in args.iter().enumerate() {
                out.push_str(&emit_expr(arg, depth + 1));
                if i + 1 != args.len() {
                    out.push('\n');
                }
            }
            out.push_str(&format!("\n{})", ind(depth)));
            out
        }
        Expr::FieldAccess { expr, field } => {
            let mut out = String::new();
            out.push_str(&format!("{}(field {}\n", ind(depth), field));
            out.push_str(&emit_expr(expr, depth + 1));
            out.push_str(&format!("\n{})", ind(depth)));
            out
        }
        Expr::StructInit { name, fields } => {
            let mut out = String::new();
            out.push_str(&format!("{}(struct_init {}", ind(depth), name));
            if fields.is_empty() {
                out.push(')');
                return out;
            }
            out.push('\n');
            for (i, (field_name, field_expr)) in fields.iter().enumerate() {
                out.push_str(&format!("{}(field {}\n", ind(depth + 1), field_name));
                out.push_str(&emit_expr(field_expr, depth + 2));
                out.push_str(&format!("\n{})", ind(depth + 1)));
                if i + 1 != fields.len() {
                    out.push('\n');
                }
            }
            out.push_str(&format!("\n{})", ind(depth)));
            out
        }
    }
}

fn emit_stmt(stmt: &Stmt, depth: usize) -> String {
    match stmt {
        Stmt::Let { name, ty, expr } => {
            let mut out = String::new();
            out.push_str(&format!("{}(let {} {}\n", ind(depth), name, type_name(ty)));
            out.push_str(&emit_expr(expr, depth + 1));
            out.push_str(&format!("\n{})", ind(depth)));
            out
        }
        Stmt::Assign { name, expr } => {
            let mut out = String::new();
            out.push_str(&format!("{}(assign {}\n", ind(depth), name));
            out.push_str(&emit_expr(expr, depth + 1));
            out.push_str(&format!("\n{})", ind(depth)));
            out
        }
        Stmt::FieldAssign { base, field, expr } => {
            let mut out = String::new();
            out.push_str(&format!("{}(field_assign {} {}\n", ind(depth), base, field));
            out.push_str(&emit_expr(expr, depth + 1));
            out.push_str(&format!("\n{})", ind(depth)));
            out
        }
        Stmt::If {
            cond,
            then_block,
            else_block,
        } => {
            let mut out = String::new();
            out.push_str(&format!("{}(if\n", ind(depth)));
            out.push_str(&emit_expr(cond, depth + 1));
            out.push('\n');
            out.push_str(&emit_block(then_block, depth + 1));
            if let Some(eb) = else_block {
                out.push('\n');
                out.push_str(&format!("{}(else\n", ind(depth + 1)));
                out.push_str(&emit_block(eb, depth + 2));
                out.push_str(&format!("\n{})", ind(depth + 1)));
            }
            out.push_str(&format!("\n{})", ind(depth)));
            out
        }
        Stmt::While { cond, body } => {
            let mut out = String::new();
            out.push_str(&format!("{}(while\n", ind(depth)));
            out.push_str(&emit_expr(cond, depth + 1));
            out.push('\n');
            out.push_str(&emit_block(body, depth + 1));
            out.push_str(&format!("\n{})", ind(depth)));
            out
        }
        Stmt::Return(expr) => {
            let mut out = String::new();
            out.push_str(&format!("{}(return\n", ind(depth)));
            out.push_str(&emit_expr(expr, depth + 1));
            out.push_str(&format!("\n{})", ind(depth)));
            out
        }
        Stmt::Expr(expr) => {
            let mut out = String::new();
            out.push_str(&format!("{}(expr\n", ind(depth)));
            out.push_str(&emit_expr(expr, depth + 1));
            out.push_str(&format!("\n{})", ind(depth)));
            out
        }
    }
}

fn emit_block(block: &Block, depth: usize) -> String {
    let mut out = String::new();
    out.push_str(&format!("{}(block", ind(depth)));
    if block.statements.is_empty() {
        out.push(')');
        return out;
    }
    out.push('\n');
    for (i, stmt) in block.statements.iter().enumerate() {
        out.push_str(&emit_stmt(stmt, depth + 1));
        if i + 1 != block.statements.len() {
            out.push('\n');
        }
    }
    out.push_str(&format!("\n{})", ind(depth)));
    out
}

fn emit_fn(f: &Function, depth: usize) -> String {
    let mut out = String::new();
    out.push_str(&format!("{}(fn {}\n", ind(depth), f.name));
    out.push_str(&format!("{}(params", ind(depth + 1)));
    if f.params.is_empty() {
        out.push(')');
    } else {
        out.push('\n');
        for (i, p) in f.params.iter().enumerate() {
            out.push_str(&emit_param(p, depth + 2));
            if i + 1 != f.params.len() {
                out.push('\n');
            }
        }
        out.push_str(&format!("\n{})", ind(depth + 1)));
    }
    out.push('\n');
    out.push_str(&format!("{}(ret {})", ind(depth + 1), type_name(&f.ret)));
    out.push('\n');
    out.push_str(&emit_block(&f.body, depth + 1));
    out.push_str(&format!("\n{})", ind(depth)));
    out
}

pub fn emit_ir(program: &Program) -> String {
    let mut out = String::new();
    out.push_str("(mee_ir v0\n");
    out.push_str("  (structs");
    if program.structs.is_empty() {
        out.push(')');
    } else {
        out.push('\n');
        for (i, s) in program.structs.iter().enumerate() {
            out.push_str(&format!("    (struct {}", s.name));
            if s.fields.is_empty() {
                out.push(')');
            } else {
                out.push('\n');
                for (j, f) in s.fields.iter().enumerate() {
                    out.push_str(&emit_param(f, 3));
                    if j + 1 != s.fields.len() {
                        out.push('\n');
                    }
                }
                out.push_str("\n    )");
            }
            if i + 1 != program.structs.len() {
                out.push('\n');
            }
        }
        out.push_str("\n  )");
    }
    out.push('\n');
    out.push_str("  (functions");
    if program.functions.is_empty() {
        out.push(')');
    } else {
        out.push('\n');
        for (i, f) in program.functions.iter().enumerate() {
            out.push_str(&emit_fn(f, 2));
            if i + 1 != program.functions.len() {
                out.push('\n');
            }
        }
        out.push_str("\n  )");
    }
    out.push_str("\n)\n");
    out
}
