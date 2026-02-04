use std::collections::HashMap;

use crate::ast::{BinOp, Block, Expr, Function, Program, Stmt, Type};

#[derive(Debug)]
pub struct TypeError {
    pub message: String,
}

pub fn typecheck_program(prog: &Program) -> Result<(), TypeError> {
    let mut fn_sigs: HashMap<String, (Vec<Type>, Type)> = HashMap::new();
    for f in &prog.functions {
        let params = f.params.iter().map(|p| p.ty.clone()).collect::<Vec<_>>();
        fn_sigs.insert(f.name.clone(), (params, f.ret.clone()));
    }

    let mut struct_defs: HashMap<String, HashMap<String, Type>> = HashMap::new();
    for s in &prog.structs {
        let mut fields = HashMap::new();
        for f in &s.fields {
            fields.insert(f.name.clone(), f.ty.clone());
        }
        struct_defs.insert(s.name.clone(), fields);
    }

    for f in &prog.functions {
        typecheck_function(f, &fn_sigs, &struct_defs)?;
    }

    Ok(())
}

fn typecheck_function(
    f: &Function,
    fn_sigs: &HashMap<String, (Vec<Type>, Type)>,
    struct_defs: &HashMap<String, HashMap<String, Type>>,
) -> Result<(), TypeError> {
    let mut vars: HashMap<String, Type> = HashMap::new();
    for p in &f.params {
        vars.insert(p.name.clone(), p.ty.clone());
    }
    typecheck_block(&f.body, &mut vars, fn_sigs, struct_defs, &f.ret)
}

fn typecheck_block(
    block: &Block,
    vars: &mut HashMap<String, Type>,
    fn_sigs: &HashMap<String, (Vec<Type>, Type)>,
    struct_defs: &HashMap<String, HashMap<String, Type>>,
    ret_ty: &Type,
) -> Result<(), TypeError> {
    for stmt in &block.statements {
        match stmt {
            Stmt::Let { name, ty, expr } => {
                let ety = type_of_expr(expr, vars, fn_sigs, struct_defs)?;
                if &ety != ty {
                    return Err(TypeError { message: format!("type mismatch in let {}", name) });
                }
                vars.insert(name.clone(), ty.clone());
            }
            Stmt::Assign { name, expr } => {
                let var_ty = vars.get(name)
                    .ok_or_else(|| TypeError { message: format!("unknown variable {}", name) })?
                    .clone();
                let ety = type_of_expr(expr, vars, fn_sigs, struct_defs)?;
                if ety != var_ty {
                    return Err(TypeError { message: format!("type mismatch in assignment to {}", name) });
                }
            }
            Stmt::If { cond, then_block, else_block } => {
                let cty = type_of_expr(cond, vars, fn_sigs, struct_defs)?;
                if cty != Type::Bool {
                    return Err(TypeError { message: "if condition must be bool".to_string() });
                }
                typecheck_block(then_block, vars, fn_sigs, struct_defs, ret_ty)?;
                if let Some(eb) = else_block {
                    typecheck_block(eb, vars, fn_sigs, struct_defs, ret_ty)?;
                }
            }
            Stmt::While { cond, body } => {
                let cty = type_of_expr(cond, vars, fn_sigs, struct_defs)?;
                if cty != Type::Bool {
                    return Err(TypeError { message: "while condition must be bool".to_string() });
                }
                typecheck_block(body, vars, fn_sigs, struct_defs, ret_ty)?;
            }
            Stmt::Return(expr) => {
                let ety = type_of_expr(expr, vars, fn_sigs, struct_defs)?;
                if &ety != ret_ty {
                    return Err(TypeError { message: "return type mismatch".to_string() });
                }
            }
            Stmt::Expr(expr) => {
                let _ = type_of_expr(expr, vars, fn_sigs, struct_defs)?;
            }
        }
    }
    Ok(())
}

fn type_of_expr(
    expr: &Expr,
    vars: &HashMap<String, Type>,
    fn_sigs: &HashMap<String, (Vec<Type>, Type)>,
    struct_defs: &HashMap<String, HashMap<String, Type>>,
) -> Result<Type, TypeError> {
    match expr {
        Expr::Int(_) => Ok(Type::I32),
        Expr::Char(_) => Ok(Type::Char),
        Expr::Bool(_) => Ok(Type::Bool),
        Expr::StringLit(_) => Ok(Type::Str),
        Expr::Ident(name) => vars.get(name).cloned().ok_or_else(|| TypeError { message: format!("unknown variable {}", name) }),
        Expr::Binary { op, left, right } => {
            let l = type_of_expr(left, vars, fn_sigs, struct_defs)?;
            let r = type_of_expr(right, vars, fn_sigs, struct_defs)?;
            let l_numeric = l == Type::I32 || l == Type::Char;
            let r_numeric = r == Type::I32 || r == Type::Char;
            if !l_numeric || !r_numeric {
                return Err(TypeError { message: "binary ops require i32 or char".to_string() });
            }
            match op {
                BinOp::Lt | BinOp::Gt | BinOp::LtEq | BinOp::GtEq | BinOp::Eq | BinOp::NotEq => {
                    Ok(Type::Bool)
                }
                _ => Ok(Type::I32),
            }
        }
        Expr::Call { callee, args } => {
            // Handle memory intrinsics
            if callee == "__mem_load" || callee == "__mem_load8" {
                if args.len() != 1 {
                    return Err(TypeError { message: format!("{} expects 1 argument", callee) });
                }
                let aty = type_of_expr(&args[0], vars, fn_sigs, struct_defs)?;
                if aty != Type::I32 {
                    return Err(TypeError { message: format!("{} address must be i32", callee) });
                }
                return Ok(Type::I32);
            }
            if callee == "__mem_store" || callee == "__mem_store8" {
                if args.len() != 2 {
                    return Err(TypeError { message: format!("{} expects 2 arguments", callee) });
                }
                let addr_ty = type_of_expr(&args[0], vars, fn_sigs, struct_defs)?;
                let val_ty = type_of_expr(&args[1], vars, fn_sigs, struct_defs)?;
                if addr_ty != Type::I32 {
                    return Err(TypeError { message: format!("{} address must be i32", callee) });
                }
                if val_ty != Type::I32 {
                    return Err(TypeError { message: format!("{} value must be i32", callee) });
                }
                return Ok(Type::I32);
            }
            if callee == "__fd_write" {
                if args.len() != 4 {
                    return Err(TypeError { message: "__fd_write expects 4 arguments".to_string() });
                }
                let fd_ty = type_of_expr(&args[0], vars, fn_sigs, struct_defs)?;
                let iov_ptr_ty = type_of_expr(&args[1], vars, fn_sigs, struct_defs)?;
                let iov_cnt_ty = type_of_expr(&args[2], vars, fn_sigs, struct_defs)?;
                let nwritten_ptr_ty = type_of_expr(&args[3], vars, fn_sigs, struct_defs)?;
                if fd_ty != Type::I32 || iov_ptr_ty != Type::I32 || iov_cnt_ty != Type::I32 || nwritten_ptr_ty != Type::I32 {
                    return Err(TypeError { message: "__fd_write args must be i32".to_string() });
                }
                return Ok(Type::I32);
            }
            if callee == "__fd_read" {
                if args.len() != 4 {
                    return Err(TypeError { message: "__fd_read expects 4 arguments".to_string() });
                }
                let fd_ty = type_of_expr(&args[0], vars, fn_sigs, struct_defs)?;
                let iov_ptr_ty = type_of_expr(&args[1], vars, fn_sigs, struct_defs)?;
                let iov_cnt_ty = type_of_expr(&args[2], vars, fn_sigs, struct_defs)?;
                let nread_ptr_ty = type_of_expr(&args[3], vars, fn_sigs, struct_defs)?;
                if fd_ty != Type::I32 || iov_ptr_ty != Type::I32 || iov_cnt_ty != Type::I32 || nread_ptr_ty != Type::I32 {
                    return Err(TypeError { message: "__fd_read args must be i32".to_string() });
                }
                return Ok(Type::I32);
            }
            let (params, ret) = fn_sigs.get(callee)
                .ok_or_else(|| TypeError { message: format!("unknown function {}", callee) })?
                .clone();
            if params.len() != args.len() {
                return Err(TypeError { message: format!("arity mismatch for {}", callee) });
            }
            for (arg, pty) in args.iter().zip(params.iter()) {
                let aty = type_of_expr(arg, vars, fn_sigs, struct_defs)?;
                if &aty != pty {
                    return Err(TypeError { message: format!("arg type mismatch for {}", callee) });
                }
            }
            Ok(ret)
        }
        Expr::FieldAccess { expr, field } => {
            let ety = type_of_expr(expr, vars, fn_sigs, struct_defs)?;
            if let Type::Struct(sname) = ety {
                let fields = struct_defs.get(&sname).ok_or_else(|| TypeError { message: format!("unknown struct {}", sname) })?;
                let fty = fields.get(field).ok_or_else(|| TypeError { message: format!("unknown field {} on {}", field, sname) })?;
                Ok(fty.clone())
            } else {
                Err(TypeError { message: "field access on non-struct".to_string() })
            }
        }
        Expr::StructInit { name, fields } => {
            let def_fields = struct_defs.get(name).ok_or_else(|| TypeError { message: format!("unknown struct {}", name) })?;
            if fields.len() != def_fields.len() {
                return Err(TypeError { message: format!("struct init field count mismatch for {}", name) });
            }
            for (fname, val) in fields {
                let fty = def_fields.get(fname).ok_or_else(|| TypeError { message: format!("unknown field {} in struct init for {}", fname, name) })?;
                let vty = type_of_expr(val, vars, fn_sigs, struct_defs)?;
                if fty != &vty {
                    return Err(TypeError { message: format!("field init type mismatch for {}.{}", name, fname) });
                }
            }
            Ok(Type::Struct(name.clone()))
        }
    }
}
