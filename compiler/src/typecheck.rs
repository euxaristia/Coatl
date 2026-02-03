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

    for f in &prog.functions {
        typecheck_function(f, &fn_sigs)?;
    }

    Ok(())
}

fn typecheck_function(f: &Function, fn_sigs: &HashMap<String, (Vec<Type>, Type)>) -> Result<(), TypeError> {
    let mut vars: HashMap<String, Type> = HashMap::new();
    for p in &f.params {
        vars.insert(p.name.clone(), p.ty.clone());
    }
    typecheck_block(&f.body, &mut vars, fn_sigs, &f.ret)
}

fn typecheck_block(
    block: &Block,
    vars: &mut HashMap<String, Type>,
    fn_sigs: &HashMap<String, (Vec<Type>, Type)>,
    ret_ty: &Type,
) -> Result<(), TypeError> {
    for stmt in &block.statements {
        match stmt {
            Stmt::Let { name, ty, expr } => {
                let ety = type_of_expr(expr, vars, fn_sigs)?;
                if &ety != ty {
                    return Err(TypeError { message: format!("type mismatch in let {}", name) });
                }
                vars.insert(name.clone(), ty.clone());
            }
            Stmt::Assign { name, expr } => {
                let var_ty = vars.get(name)
                    .ok_or_else(|| TypeError { message: format!("unknown variable {}", name) })?
                    .clone();
                let ety = type_of_expr(expr, vars, fn_sigs)?;
                if ety != var_ty {
                    return Err(TypeError { message: format!("type mismatch in assignment to {}", name) });
                }
            }
            Stmt::If { cond, then_block, else_block } => {
                let cty = type_of_expr(cond, vars, fn_sigs)?;
                if cty != Type::Bool {
                    return Err(TypeError { message: "if condition must be bool".to_string() });
                }
                typecheck_block(then_block, vars, fn_sigs, ret_ty)?;
                if let Some(eb) = else_block {
                    typecheck_block(eb, vars, fn_sigs, ret_ty)?;
                }
            }
            Stmt::While { cond, body } => {
                let cty = type_of_expr(cond, vars, fn_sigs)?;
                if cty != Type::Bool {
                    return Err(TypeError { message: "while condition must be bool".to_string() });
                }
                typecheck_block(body, vars, fn_sigs, ret_ty)?;
            }
            Stmt::Return(expr) => {
                let ety = type_of_expr(expr, vars, fn_sigs)?;
                if &ety != ret_ty {
                    return Err(TypeError { message: "return type mismatch".to_string() });
                }
            }
            Stmt::Expr(expr) => {
                let _ = type_of_expr(expr, vars, fn_sigs)?;
            }
        }
    }
    Ok(())
}

fn type_of_expr(
    expr: &Expr,
    vars: &HashMap<String, Type>,
    fn_sigs: &HashMap<String, (Vec<Type>, Type)>,
) -> Result<Type, TypeError> {
    match expr {
        Expr::Int(_) => Ok(Type::I32),
        Expr::Bool(_) => Ok(Type::Bool),
        Expr::Ident(name) => vars.get(name).cloned().ok_or_else(|| TypeError { message: format!("unknown variable {}", name) }),
        Expr::Binary { op, left, right } => {
            let l = type_of_expr(left, vars, fn_sigs)?;
            let r = type_of_expr(right, vars, fn_sigs)?;
            if l != Type::I32 || r != Type::I32 {
                return Err(TypeError { message: "binary ops require i32".to_string() });
            }
            match op {
                BinOp::Lt | BinOp::Gt | BinOp::LtEq | BinOp::GtEq | BinOp::Eq | BinOp::NotEq => {
                    Ok(Type::Bool)
                }
                _ => Ok(Type::I32),
            }
        }
        Expr::Call { callee, args } => {
            let (params, ret) = fn_sigs.get(callee)
                .ok_or_else(|| TypeError { message: format!("unknown function {}", callee) })?
                .clone();
            if params.len() != args.len() {
                return Err(TypeError { message: format!("arity mismatch for {}", callee) });
            }
            for (arg, pty) in args.iter().zip(params.iter()) {
                let aty = type_of_expr(arg, vars, fn_sigs)?;
                if &aty != pty {
                    return Err(TypeError { message: format!("arg type mismatch for {}", callee) });
                }
            }
            Ok(ret)
        }
    }
}
