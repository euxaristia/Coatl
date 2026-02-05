mod ast;
mod codegen;
mod ir;
mod lexer;
mod parser;
mod typecheck;

use std::env;
use std::fs;

use codegen::{emit_wat, emit_x86_64_asm};
use ir::emit_ir;
use parser::Parser;
use typecheck::typecheck_program;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 3 || args[1] != "build" {
        eprintln!("usage: mee build <file> [--emit=wat|asm|ir] [-o <output>]");
        std::process::exit(1);
    }

    let file = args[2].clone();
    let emit = args.iter().find(|a| a.starts_with("--emit=")).cloned().unwrap_or("--emit=wat".to_string());
    let mut output: Option<String> = None;
    let mut i = 3;
    while i < args.len() {
        if args[i] == "-o" {
            if i + 1 >= args.len() {
                eprintln!("missing output path after -o");
                std::process::exit(1);
            }
            output = Some(args[i + 1].clone());
            i += 2;
            continue;
        }
        i += 1;
    }

    let src = match fs::read_to_string(&file) {
        Ok(s) => s,
        Err(err) => {
            eprintln!("failed to read {}: {}", file, err);
            std::process::exit(1);
        }
    };

    let mut parser = Parser::new(&src);
    let program = match parser.parse_program() {
        Ok(p) => p,
        Err(err) => {
            eprintln!("parse error at {}: {}", err.pos, err.message);
            std::process::exit(1);
        }
    };

    if let Err(err) = typecheck_program(&program) {
        eprintln!("type error: {}", err.message);
        std::process::exit(1);
    }

    match emit.as_str() {
        "--emit=wat" => {
            let wat = emit_wat(&program);
            if let Some(path) = output {
                if let Err(err) = fs::write(&path, wat) {
                    eprintln!("failed to write {}: {}", path, err);
                    std::process::exit(1);
                }
            } else {
                print!("{}", wat);
            }
        }
        "--emit=asm" => {
            let asm = emit_x86_64_asm(&program);
            if let Some(path) = output {
                if let Err(err) = fs::write(&path, asm) {
                    eprintln!("failed to write {}: {}", path, err);
                    std::process::exit(1);
                }
            } else {
                print!("{}", asm);
            }
        }
        "--emit=ir" => {
            let ir = emit_ir(&program);
            if let Some(path) = output {
                if let Err(err) = fs::write(&path, ir) {
                    eprintln!("failed to write {}: {}", path, err);
                    std::process::exit(1);
                }
            } else {
                print!("{}", ir);
            }
        }
        _ => {
            eprintln!("unknown emit target: {}", emit);
            std::process::exit(1);
        }
    }
}
