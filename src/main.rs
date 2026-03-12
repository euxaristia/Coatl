use std::env;
use std::fs;
use std::path::PathBuf;
use std::process;
use std::collections::{HashMap, HashSet};

#[derive(Debug, Clone, PartialEq)]
pub enum IRNode {
    Atom(String),
    List(Vec<IRNode>),
}

impl IRNode {
    pub fn is_list(&self) -> bool { matches!(self, IRNode::List(_)) }
    pub fn as_list(&self) -> Option<&Vec<IRNode>> {
        match self { IRNode::List(l) => Some(l), _ => None }
    }
    pub fn as_atom(&self) -> Option<&String> {
        match self { IRNode::Atom(s) => Some(s), _ => None }
    }
    pub fn to_ir(&self) -> String {
        match self {
            IRNode::Atom(s) => {
                if s.contains(' ') || s.is_empty() || s.contains('\n') || s.contains('\"') {
                    format!("\"{}\"", s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t"))
                } else {
                    s.clone()
                }
            }
            IRNode::List(l) => {
                let mut res = String::from("(");
                for (i, item) in l.iter().enumerate() {
                    if i > 0 { res.push(' '); }
                    res.push_str(&item.to_ir());
                }
                res.push(')');
                res
            }
        }
    }
}

pub struct IRParser {
    tokens: Vec<String>,
    pos: usize,
}

impl IRParser {
    pub fn new(input: &str) -> Self {
        let mut tokens = Vec::new();
        let mut chars = input.chars().peekable();
        while let Some(&c) = chars.peek() {
            if c.is_whitespace() { chars.next(); }
            else if c == '(' || c == ')' { tokens.push(c.to_string()); chars.next(); }
            else if c == '"' {
                chars.next();
                let mut s = String::new();
                while let Some(nc) = chars.next() {
                    if nc == '"' { break; }
                    if nc == '\\' {
                        if let Some(esc) = chars.next() {
                            s.push(match esc {
                                'n' => '\n', 'r' => '\r', 't' => '\t', _ => esc,
                            });
                        }
                    } else { s.push(nc); }
                }
                tokens.push(format!("\"{}\"", s));
            } else {
                let mut s = String::new();
                while let Some(&nc) = chars.peek() {
                    if nc.is_whitespace() || nc == '(' || nc == ')' { break; }
                    s.push(chars.next().unwrap());
                }
                tokens.push(s);
            }
        }
        Self { tokens, pos: 0 }
    }

    pub fn parse(&mut self) -> Option<IRNode> {
        if self.pos >= self.tokens.len() { return None; }
        let token = &self.tokens[self.pos];
        self.pos += 1;
        if token == "(" {
            let mut list = Vec::new();
            while self.pos < self.tokens.len() && self.tokens[self.pos] != ")" {
                if let Some(node) = self.parse() { list.push(node); }
            }
            if self.pos < self.tokens.len() { self.pos += 1; }
            Some(IRNode::List(list))
        } else if token.starts_with('"') && token.ends_with('"') {
            Some(IRNode::Atom(token[1..token.len()-1].to_string()))
        } else {
            Some(IRNode::Atom(token.clone()))
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
enum TokenKind { Ident, Num, Str, Sym, Eof }

#[derive(Debug, Clone)]
struct Token {
    kind: TokenKind,
    value: String,
    line: usize,
    col: usize,
}

struct Lexer {
    source: Vec<char>,
    pos: usize,
    line: usize,
    col: usize,
}

impl Lexer {
    fn new(source: String) -> Self {
        Self { source: source.chars().collect(), pos: 0, line: 1, col: 1 }
    }
    fn peek(&self, n: usize) -> Option<char> {
        if self.pos + n < self.source.len() { Some(self.source[self.pos + n]) } else { None }
    }
    fn advance(&mut self) -> Option<char> {
        let c = self.peek(0)?;
        self.pos += 1;
        if c == '\n' { self.line += 1; self.col = 1; } else { self.col += 1; }
        Some(c)
    }
    fn tokenize(&mut self) -> Vec<Token> {
        let mut tokens = Vec::new();
        while self.pos < self.source.len() {
            let c = self.peek(0).unwrap();
            if c.is_whitespace() { self.advance(); }
            else if c == '/' && self.peek(1) == Some('/') {
                while self.peek(0).is_some() && self.peek(0) != Some('\n') { self.advance(); }
            } else if c.is_alphabetic() || c == '_' {
                let (sl, sc) = (self.line, self.col);
                let mut val = String::new();
                while let Some(nc) = self.peek(0) {
                    if nc.is_alphanumeric() || nc == '_' { val.push(self.advance().unwrap()); } else { break; }
                }
                tokens.push(Token { kind: TokenKind::Ident, value: val, line: sl, col: sc });
            } else if c.is_digit(10) {
                let (sl, sc) = (self.line, self.col);
                let mut val = String::new();
                if c == '0' && self.peek(1) == Some('x') {
                    val.push(self.advance().unwrap()); val.push(self.advance().unwrap());
                    while let Some(nc) = self.peek(0) {
                        if nc.is_digit(16) { val.push(self.advance().unwrap()); } else { break; }
                    }
                } else {
                    while let Some(nc) = self.peek(0) {
                        if nc.is_digit(10) || nc == '.' { val.push(self.advance().unwrap()); } else { break; }
                    }
                }
                for suf in ["i64", "i32", "f64", "f32"] {
                    let mut match_suf = true;
                    for (j, sc) in suf.chars().enumerate() {
                        if self.peek(j) != Some(sc) { match_suf = false; break; }
                    }
                    if match_suf {
                        val.push_str(suf);
                        for _ in 0..suf.len() { self.advance(); }
                        break;
                    }
                }
                tokens.push(Token { kind: TokenKind::Num, value: val, line: sl, col: sc });
            } else if c == '"' {
                let (sl, sc) = (self.line, self.col);
                self.advance();
                let mut val = String::new();
                while let Some(nc) = self.peek(0) {
                    if nc == '"' { break; }
                    if nc == '\\' {
                        self.advance();
                        let esc = self.advance().unwrap();
                        let char_to_push = match esc {
                            'n' => '\n', 't' => '\t', 'r' => '\r', '"' => '"', '\\' => '\\',
                            'x' => {
                                let h1 = self.advance().unwrap(); let h2 = self.advance().unwrap();
                                u8::from_str_radix(&format!("{}{}", h1, h2), 16).unwrap() as char
                            }
                            _ => { val.push('\\'); esc }
                        };
                        val.push(char_to_push);
                    } else { val.push(self.advance().unwrap()); }
                }
                self.advance();
                tokens.push(Token { kind: TokenKind::Str, value: val, line: sl, col: sc });
            } else {
                let (sl, sc) = (self.line, self.col);
                let mut sym = String::new();
                for s in ["==", "!=", "<=", ">=", "->", "&&", "||"] {
                    let mut match_s = true;
                    for (j, sc) in s.chars().enumerate() {
                        if self.peek(j) != Some(sc) { match_s = false; break; }
                    }
                    if match_s { sym = s.to_string(); break; }
                }
                if !sym.is_empty() {
                    for _ in 0..sym.len() { self.advance(); }
                } else {
                    sym.push(self.advance().unwrap());
                }
                tokens.push(Token { kind: TokenKind::Sym, value: sym, line: sl, col: sc });
            }
        }
        tokens.push(Token { kind: TokenKind::Eof, value: String::new(), line: self.line, col: self.col });
        tokens
    }
}

struct Parser {
    tokens: Vec<Token>,
    pos: usize,
}

impl Parser {
    fn new(tokens: Vec<Token>) -> Self { Self { tokens, pos: 0 } }
    fn peek(&self, n: usize) -> &Token {
        if self.pos + n < self.tokens.len() { &self.tokens[self.pos + n] } else { &self.tokens[self.tokens.len() - 1] }
    }
    fn consume(&mut self, kind: Option<TokenKind>, val: Option<&str>) -> Token {
        let t = self.peek(0).clone();
        if let Some(k) = kind { if t.kind != k { panic!("Expected {:?}, got {:?} at {}:{}", k, t.kind, t.line, t.col); } }
        if let Some(v) = val { if t.value != v { panic!("Expected {}, got {} at {}:{}", v, t.value, t.line, t.col); } }
        self.pos += 1;
        t
    }
    fn parse_type(&mut self) -> String {
        let t = self.peek(0);
        if t.value == "[" {
            self.consume(None, Some("["));
            let ty = self.parse_type();
            let sz = self.consume(Some(TokenKind::Num), None).value;
            self.consume(None, Some("]"));
            format!("[{} {}]", ty, sz)
        } else if t.value == "*" {
            self.consume(None, Some("*"));
            format!("*{}", self.parse_type())
        } else { self.consume(Some(TokenKind::Ident), None).value }
    }
    fn parse_struct(&mut self) -> IRNode {
        self.consume(Some(TokenKind::Ident), Some("struct"));
        let name = self.consume(Some(TokenKind::Ident), None).value;
        let mut fields = vec![IRNode::Atom("struct".to_string()), IRNode::Atom(name)];
        if self.peek(0).value == "{" {
            self.consume(None, Some("{"));
            while self.peek(0).value != "}" {
                let fn_name = self.consume(Some(TokenKind::Ident), None).value;
                self.consume(None, Some(":"));
                let ft = self.parse_type();
                fields.push(IRNode::List(vec![IRNode::Atom("field".to_string()), IRNode::Atom(fn_name), IRNode::Atom(ft)]));
                if self.peek(0).value == "," { self.consume(None, Some(",")); }
            }
            self.consume(None, Some("}"));
        }
        IRNode::List(fields)
    }
    fn parse_fn(&mut self) -> IRNode {
        self.consume(Some(TokenKind::Ident), Some("fn"));
        let name = self.consume(Some(TokenKind::Ident), None).value;
        self.consume(None, Some("("));
        let mut params = vec![IRNode::Atom("params".to_string())];
        while self.peek(0).value != ")" {
            let pn = self.consume(Some(TokenKind::Ident), None).value;
            self.consume(None, Some(":"));
            let pt = self.parse_type();
            params.push(IRNode::List(vec![IRNode::Atom("param".to_string()), IRNode::Atom(pn), IRNode::Atom(pt)]));
            if self.peek(0).value == "," { self.consume(None, Some(",")); }
        }
        self.consume(None, Some(")"));
        let mut rt = "i32".to_string();
        if self.peek(0).value == "returns" || self.peek(0).value == "->" {
            self.consume(None, None);
            rt = self.parse_type();
        }
        let mut block = vec![IRNode::Atom("block".to_string())];
        if self.peek(0).value == "{" {
            self.consume(None, Some("{"));
            while self.peek(0).value != "}" { block.push(self.parse_stmt()); }
            self.consume(None, Some("}"));
        }
        IRNode::List(vec![IRNode::Atom("fn".to_string()), IRNode::Atom(name), IRNode::List(params), IRNode::List(vec![IRNode::Atom("ret".to_string()), IRNode::Atom(rt)]), IRNode::List(block)])
    }
    fn parse_stmt(&mut self) -> IRNode {
        let t = self.peek(0);
        if t.value == "let" {
            self.consume(None, Some("let"));
            let n = self.consume(Some(TokenKind::Ident), None).value;
            self.consume(None, Some(":"));
            let ty = self.parse_type();
            self.consume(None, Some("="));
            let e = self.parse_expr();
            if self.peek(0).value == ";" { self.consume(None, Some(";")); }
            IRNode::List(vec![IRNode::Atom("let".to_string()), IRNode::Atom(n), IRNode::Atom(ty), e])
        } else if t.value == "return" {
            self.consume(None, Some("return"));
            let e = self.parse_expr();
            if self.peek(0).value == ";" { self.consume(None, Some(";")); }
            IRNode::List(vec![IRNode::Atom("return".to_string()), e])
        } else if t.value == "svc" {
            self.consume(None, Some("svc"));
            let mut args = vec![IRNode::Atom("svc".to_string())];
            if self.peek(0).value == "(" {
                self.consume(None, Some("("));
                while self.peek(0).value != ")" {
                    args.push(self.parse_expr());
                    if self.peek(0).value == "," { self.consume(None, Some(",")); }
                }
                self.consume(None, Some(")"));
            } else {
                while self.peek(0).kind != TokenKind::Sym && self.peek(0).kind != TokenKind::Eof {
                    args.push(self.parse_expr());
                    if self.peek(0).value == "," { self.consume(None, Some(",")); }
                }
            }
            if self.peek(0).value == ";" { self.consume(None, Some(";")); }
            IRNode::List(args)
        } else if t.value == "syscall" {
            self.consume(None, Some("syscall"));
            let mut args = vec![IRNode::Atom("syscall".to_string())];
            if self.peek(0).value == "(" {
                self.consume(None, Some("("));
                while self.peek(0).value != ")" {
                    args.push(self.parse_expr());
                    if self.peek(0).value == "," { self.consume(None, Some(",")); }
                }
                self.consume(None, Some(")"));
            }
            if self.peek(0).value == ";" { self.consume(None, Some(";")); }
            IRNode::List(args)
        } else if t.value == "if" {
            self.consume(None, Some("if"));
            let c = self.parse_expr();
            self.consume(None, Some("{"));
            let mut th = vec![IRNode::Atom("block".to_string())];
            while self.peek(0).value != "}" { th.push(self.parse_stmt()); }
            self.consume(None, Some("}"));
            let mut res = vec![IRNode::Atom("if".to_string()), c, IRNode::List(th)];
            if self.peek(0).value == "else" {
                self.consume(None, Some("else"));
                self.consume(None, Some("{"));
                let mut el = vec![IRNode::Atom("block".to_string())];
                while self.peek(0).value != "}" { el.push(self.parse_stmt()); }
                self.consume(None, Some("}"));
                res.push(IRNode::List(vec![IRNode::Atom("else".to_string()), IRNode::List(el)]));
            }
            IRNode::List(res)
        } else if t.value == "while" {
            self.consume(None, Some("while"));
            let c = self.parse_expr();
            self.consume(None, Some("{"));
            let mut b = vec![IRNode::Atom("block".to_string())];
            while self.peek(0).value != "}" { b.push(self.parse_stmt()); }
            self.consume(None, Some("}"));
            IRNode::List(vec![IRNode::Atom("while".to_string()), c, IRNode::List(b)])
        } else if t.kind == TokenKind::Ident && self.peek(1).value == "[" {
            let n = self.consume(Some(TokenKind::Ident), None).value;
            self.consume(None, Some("["));
            let idx = self.parse_expr();
            self.consume(None, Some("]"));
            self.consume(None, Some("="));
            let e = self.parse_expr();
            if self.peek(0).value == ";" { self.consume(None, Some(";")); }
            IRNode::List(vec![IRNode::Atom("array_assign".to_string()), IRNode::Atom(n), idx, e])
        } else if t.kind == TokenKind::Ident && self.peek(1).value == "=" {
            let n = self.consume(Some(TokenKind::Ident), None).value;
            self.consume(None, Some("="));
            let e = self.parse_expr();
            if self.peek(0).value == ";" { self.consume(None, Some(";")); }
            IRNode::List(vec![IRNode::Atom("assign".to_string()), IRNode::Atom(n), e])
        } else if t.kind == TokenKind::Ident && self.peek(1).value == "." && self.peek(3).value == "=" {
            let v = self.consume(Some(TokenKind::Ident), None).value;
            self.consume(None, Some("."));
            let f = self.consume(Some(TokenKind::Ident), None).value;
            self.consume(None, Some("="));
            let e = self.parse_expr();
            if self.peek(0).value == ";" { self.consume(None, Some(";")); }
            IRNode::List(vec![IRNode::Atom("field_assign".to_string()), IRNode::Atom(v), IRNode::Atom(f), e])
        } else {
            let e = self.parse_expr();
            if self.peek(0).value == ";" { self.consume(None, Some(";")); }
            IRNode::List(vec![IRNode::Atom("expr".to_string()), e])
        }
    }
    fn parse_expr(&mut self) -> IRNode { self.parse_or() }
    fn parse_or(&mut self) -> IRNode {
        let mut l = self.parse_and();
        while self.peek(0).value == "||" || self.peek(0).value == "|" {
            self.consume(None, None);
            l = IRNode::List(vec![IRNode::Atom("binary".to_string()), IRNode::Atom("or".to_string()), l, self.parse_and()]);
        }
        l
    }
    fn parse_and(&mut self) -> IRNode {
        let mut l = self.parse_cmp();
        while self.peek(0).value == "&&" || self.peek(0).value == "&" {
            self.consume(None, None);
            l = IRNode::List(vec![IRNode::Atom("binary".to_string()), IRNode::Atom("and".to_string()), l, self.parse_cmp()]);
        }
        l
    }
    fn parse_cmp(&mut self) -> IRNode {
        let mut l = self.parse_add();
        let ops: HashMap<&str, &str> = [("==", "eq"), ("!=", "ne"), ("<", "lt"), (">", "gt"), ("<=", "le"), (">=", "ge")].iter().cloned().collect();
        let val = self.peek(0).value.as_str();
        if let Some(&op) = ops.get(val) {
            self.consume(None, None);
            l = IRNode::List(vec![IRNode::Atom("binary".to_string()), IRNode::Atom(op.to_string()), l, self.parse_add(), IRNode::Atom("bool".to_string())]);
        }
        l
    }
    fn parse_add(&mut self) -> IRNode {
        let mut l = self.parse_mul();
        while self.peek(0).value == "+" || self.peek(0).value == "-" {
            let op = if self.consume(None, None).value == "+" { "add" } else { "sub" };
            l = IRNode::List(vec![IRNode::Atom("binary".to_string()), IRNode::Atom(op.to_string()), l, self.parse_mul()]);
        }
        l
    }
    fn parse_mul(&mut self) -> IRNode {
        let mut l = self.parse_term();
        while self.peek(0).value == "*" || self.peek(0).value == "/" {
            let op = if self.consume(None, None).value == "*" { "mul" } else { "div" };
            l = IRNode::List(vec![IRNode::Atom("binary".to_string()), IRNode::Atom(op.to_string()), l, self.parse_term()]);
        }
        l
    }
    fn parse_term(&mut self) -> IRNode {
        let t = self.peek(0).clone();
        if t.value == "!" {
            self.consume(None, None);
            IRNode::List(vec![IRNode::Atom("binary".to_string()), IRNode::Atom("eq".to_string()), self.parse_term(), IRNode::List(vec![IRNode::Atom("int".to_string()), IRNode::Atom("0".to_string())]), IRNode::Atom("bool".to_string())])
        } else if t.value == "svc" {
            self.consume(None, None);
            let imm = self.consume(Some(TokenKind::Num), None).value;
            if self.peek(0).value == ";" { self.consume(None, Some(";")); }
            IRNode::List(vec![IRNode::Atom("svc".to_string()), IRNode::Atom(imm)])
        } else if t.value == "syscall" {
            self.consume(None, None);
            if self.peek(0).value == ";" { self.consume(None, Some(";")); }
            IRNode::List(vec![IRNode::Atom("syscall".to_string())])
        } else if t.value == "(" {
            self.consume(None, Some("("));
            let e = self.parse_expr();
            self.consume(None, Some(")"));
            e
        } else if t.value == "[" {
            self.consume(None, Some("["));
            let val = self.parse_expr();
            let sz = self.consume(Some(TokenKind::Num), None).value;
            self.consume(None, Some("]"));
            IRNode::List(vec![IRNode::Atom("array_lit".to_string()), val, IRNode::Atom(sz)])
        } else if t.kind == TokenKind::Num {
            let v = self.consume(Some(TokenKind::Num), None).value;
            if v.ends_with("i64") { IRNode::List(vec![IRNode::Atom("int_i64".to_string()), IRNode::Atom(v[..v.len()-3].to_string())]) }
            else if v.ends_with("f32") { IRNode::List(vec![IRNode::Atom("f32".to_string()), IRNode::Atom(v[..v.len()-3].to_string())]) }
            else if v.ends_with("f64") { IRNode::List(vec![IRNode::Atom("f64".to_string()), IRNode::Atom(v[..v.len()-3].to_string())]) }
            else if v.ends_with("i32") { IRNode::List(vec![IRNode::Atom("int".to_string()), IRNode::Atom(v[..v.len()-3].to_string())]) }
            else { IRNode::List(vec![IRNode::Atom("int".to_string()), IRNode::Atom(v)]) }
        } else if t.kind == TokenKind::Str {
            IRNode::List(vec![IRNode::Atom("string_typed".to_string()), IRNode::Atom(self.consume(Some(TokenKind::Str), None).value)])
        } else if t.kind == TokenKind::Ident {
            let n = self.consume(Some(TokenKind::Ident), None).value;
            if n == "true" || n == "false" { return IRNode::List(vec![IRNode::Atom("bool".to_string()), IRNode::Atom(if n == "true" { "1" } else { "0" }.to_string())]); }
            if self.peek(0).value == "{" {
                self.consume(None, Some("{"));
                let mut fields = vec![IRNode::Atom("struct_lit".to_string()), IRNode::Atom(n)];
                while self.peek(0).value != "}" {
                    self.consume(Some(TokenKind::Ident), None); self.consume(None, Some(":"));
                    fields.push(self.parse_expr());
                    if self.peek(0).value == "," { self.consume(None, Some(",")); }
                }
                self.consume(None, Some("}"));
                return IRNode::List(fields);
            }
            if self.peek(0).value == "(" {
                self.consume(None, Some("("));
                let mut args = Vec::new();
                while self.peek(0).value != ")" {
                    args.push(self.parse_expr());
                    if self.peek(0).value == "," { self.consume(None, Some(",")); }
                }
                self.consume(None, Some(")"));
                if n == "str_len" { return IRNode::List(vec![IRNode::Atom("str_len".to_string()), args[0].clone()]); }
                if n == "str_ptr" { return IRNode::List(vec![IRNode::Atom("str_ptr".to_string()), args[0].clone()]); }
                let mut call = vec![IRNode::Atom("call".to_string()), IRNode::Atom(n)];
                call.extend(args);
                return IRNode::List(call);
            }
            if self.peek(0).value == "." {
                self.consume(None, Some("."));
                return IRNode::List(vec![IRNode::Atom("field".to_string()), IRNode::Atom(n), IRNode::Atom(self.consume(Some(TokenKind::Ident), None).value)]);
            }
            if self.peek(0).value == "[" {
                self.consume(None, Some("["));
                let idx = self.parse_expr();
                self.consume(None, Some("]"));
                return IRNode::List(vec![IRNode::Atom("array_index".to_string()), IRNode::Atom(n), idx]);
            }
            IRNode::List(vec![IRNode::Atom("ident".to_string()), IRNode::Atom(n)])
        } else { panic!("Unexpected token {:?}", t) }
    }
}

fn parse_file_recursive(filepath: PathBuf, visited: &mut HashSet<PathBuf>, all_structs: &mut Vec<IRNode>, all_fns: &mut Vec<IRNode>, _all_imports: &mut Vec<IRNode>) {
    let filepath = fs::canonicalize(filepath).expect("Failed to canonicalize path");
    if visited.contains(&filepath) { return; }
    visited.insert(filepath.clone());
    let source = fs::read_to_string(&filepath).expect("Failed to read file");
    let mut lexer = Lexer::new(source);
    let tokens = lexer.tokenize();
    let mut parser = Parser::new(tokens);
    
    let mut imports = Vec::new();
    let mut structs = Vec::new();
    let mut fns = Vec::new();
    
    while parser.peek(0).kind != TokenKind::Eof {
        let t = parser.peek(0);
        if t.value == "import" {
            parser.consume(None, None);
            let imp = parser.consume(Some(TokenKind::Str), None).value;
            imports.push(imp);
        } else if t.value == "struct" { structs.push(parser.parse_struct()); }
        else if t.value == "fn" { fns.push(parser.parse_fn()); }
        else { parser.pos += 1; }
    }
    
    all_structs.extend(structs);
    all_fns.extend(fns);
    for imp in imports {
        let mut imp_path = filepath.parent().unwrap().to_path_buf();
        imp_path.push(format!("{}.coatl", imp));
        parse_file_recursive(imp_path, visited, all_structs, all_fns, _all_imports);
    }
}

const INTRINSICS_X86_64: &str = include_str!("../runtime/intrinsics.s");
const INTRINSICS_AARCH64: &str = include_str!("../runtime/intrinsics_aarch64.s");

struct X86_64Backend {
    ir: IRNode,
    output: Vec<String>,
    vars: HashMap<String, (i32, String)>,
    strings: HashMap<String, i32>,
    structs: HashMap<String, Vec<String>>,
    label_count: i32,
    current_fn: String,
}

impl X86_64Backend {
    fn new(ir: IRNode) -> Self {
        Self {
            ir,
            output: Vec::new(),
            vars: HashMap::new(),
            strings: HashMap::new(),
            structs: HashMap::new(),
            label_count: 0,
            current_fn: String::new(),
        }
    }

    fn emit(&mut self, s: String) { self.output.push(s); }
    fn new_label(&mut self, prefix: &str) -> String {
        self.label_count += 1;
        format!(".{}{}", prefix, self.label_count)
    }

    fn collect_strings(&mut self, node: &IRNode) {
        if let IRNode::List(l) = node {
            if !l.is_empty() {
                if let Some(atom) = l[0].as_atom() {
                    if atom == "string_typed" && l.len() > 1 {
                        if let Some(val) = l[1].as_atom() {
                            self.strings.insert(val.clone(), 0);
                        }
                    }
                }
            }
            for child in l { self.collect_strings(child); }
        }
    }

    fn lower(&mut self) {
        let mut fns: Vec<IRNode> = Vec::new();
        let mut structs_list: Vec<IRNode> = Vec::new();

        if let IRNode::List(root) = &self.ir {
            for child in root {
                if let IRNode::List(c) = child {
                    if !c.is_empty() {
                        if c[0].as_atom().map(|s| s == "functions").unwrap_or(false) {
                            fns = c[1..].to_vec();
                        } else if c[0].as_atom().map(|s| s == "structs").unwrap_or(false) {
                            structs_list = c[1..].to_vec();
                        }
                    }
                }
            }
        }

        for s in structs_list {
            if let IRNode::List(sl) = s {
                let name = sl[1].as_atom().unwrap().clone();
                let fields = sl[2..].iter().map(|f| f.as_list().unwrap()[1].as_atom().unwrap().clone()).collect();
                self.structs.insert(name, fields);
            }
        }

        self.emit(".intel_syntax noprefix".to_string());
        self.emit(".bss".to_string());
        self.emit(".align 16".to_string());
        self.emit(".globl __coatl_mem".to_string());
        self.emit("__coatl_mem:".to_string());
        self.emit("  .zero 1048576".to_string());
        self.emit("__coatl_mem_inited:".to_string());
        self.emit("  .long 0".to_string());
        self.emit(".text".to_string());
        self.emit("__coatl_init_memory:".to_string());
        self.emit("  push rbp; mov rbp, rsp".to_string());
        self.emit("  mov eax, dword ptr [rip+__coatl_mem_inited]; test eax, eax; jne .L_mem_done".to_string());
        self.emit("  mov dword ptr [rip+__coatl_mem_inited], 1".to_string());
        self.emit("  lea rdx, [rip+__coatl_mem]".to_string());

        for func in &fns { self.collect_strings(func); }

        let mut off: i32 = 65536;
        let mut sorted_strings: Vec<_> = self.strings.keys().cloned().collect();
        sorted_strings.sort();
        for s in sorted_strings {
            let bytes = s.as_bytes().to_vec();
            for (i, &b) in bytes.iter().enumerate() {
                self.emit(format!("  mov byte ptr [rdx+{}], {}", off + i as i32, b));
            }
            self.emit(format!("  mov byte ptr [rdx+{}], 0", off + bytes.len() as i32));
            self.strings.insert(s, off);
            off += bytes.len() as i32 + 1;
        }

        self.emit(".L_mem_done:".to_string());
        self.emit("  pop rbp; ret".to_string());

        for func in fns { self.lower_fn(&func); }

        self.emit(".globl coatl_start".to_string());
        self.emit("coatl_start:".to_string());
        self.emit("  call __coatl_init_memory".to_string());
        self.emit("  call main".to_string());
        self.emit("  mov edi, eax; mov eax, 60; syscall".to_string());
        self.emit(INTRINSICS_X86_64.to_string());
    }

    fn lower_fn(&mut self, n: &IRNode) {
        if let IRNode::List(l) = n {
            let name = l[1].as_atom().unwrap();
            self.current_fn = name.clone();
            self.vars.clear();
            self.emit(format!(".global {}\n{}:", name, name));
            self.emit("  push rbp; mov rbp, rsp; sub rsp, 4096".to_string());
            
            let regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"];
            if let IRNode::List(params) = &l[2] {
                for (i, p) in params[1..].iter().enumerate() {
                    if let IRNode::List(pl) = p {
                        let p_name = pl[1].as_atom().unwrap();
                        let p_type = pl[2].as_atom().unwrap();
                        let off = (i as i32 + 1) * 8;
                        self.vars.insert(p_name.clone(), (off, p_type.clone()));
                        if i < 6 { self.emit(format!("  mov [rbp-{}], {}", off, regs[i])); }
                        else {
                            let stack_off = 16 + (i as i32 - 6) * 8;
                            self.emit(format!("  mov rax, [rbp+{}]\n  mov [rbp-{}], rax", stack_off, off));
                        }
                    }
                }
            }

            if let IRNode::List(body) = &l[4] {
                for stmt in &body[1..] { self.lower_stmt(stmt); }
            }
            self.emit(format!(".Lret_{}:; leave; ret", name));
        }
    }

    fn lower_stmt(&mut self, n: &IRNode) {
        let l = n.as_list().unwrap();
        let head = l[0].as_atom().unwrap();
        match head.as_str() {
            "let" => {
                let name = l[1].as_atom().unwrap();
                let vtype = l[2].as_atom().unwrap();
                let off = (self.vars.len() as i32 + 1) * 8;
                self.vars.insert(name.clone(), (off, vtype.clone()));
                self.lower_expr(&l[3]);
                self.emit(format!("  mov [rbp-{}], rax", off));
            }
            "assign" => {
                let name = l[1].as_atom().unwrap();
                let off = self.vars.get(name).unwrap().0;
                self.lower_expr(&l[2]);
                self.emit(format!("  mov [rbp-{}], rax", off));
            }
            "field_assign" => {
                let var_name = l[1].as_atom().unwrap();
                let field_name = l[2].as_atom().unwrap();
                let (off, ty) = self.vars.get(var_name).unwrap().clone();
                let fi = self.structs.get(&ty).unwrap().iter().position(|f| f == field_name).unwrap();
                self.lower_expr(&l[3]);
                self.emit(format!("  mov dword ptr [rbp-{}], eax", off - (fi as i32 * 4)));
            }
            "if" => {
                let l_else = self.new_label("L_else");
                let l_end = self.new_label("L_end");
                self.lower_expr(&l[1]);
                self.emit("  cmp rax, 0; je ".to_string() + &l_else);
                self.lower_stmt(&l[2]);
                self.emit("  jmp ".to_string() + &l_end);
                self.emit(l_else + ":");
                if l.len() > 3 { self.lower_stmt(&l[3].as_list().unwrap()[1]); }
                self.emit(l_end + ":");
            }
            "while" => {
                let l_start = self.new_label("L_while_start");
                let l_end = self.new_label("L_while_end");
                self.emit(l_start.clone() + ":");
                self.lower_expr(&l[1]);
                self.emit("  cmp rax, 0; je ".to_string() + &l_end);
                self.lower_stmt(&l[2]);
                self.emit("  jmp ".to_string() + &l_start);
                self.emit(l_end + ":");
            }
            "block" => { for s in &l[1..] { self.lower_stmt(s); } }
            "return" => {
                self.lower_expr(&l[1]);
                let label = format!(".Lret_{}", self.current_fn);
                self.emit(format!("  jmp {}", label));
            }
            "expr" => { self.lower_expr(&l[1]); }
            _ => {}
        }
    }

    fn lower_expr(&mut self, n: &IRNode) {
        let l = n.as_list().unwrap();
        let head = l[0].as_atom().unwrap();
        match head.as_str() {
            "int" | "int_i64" | "bool" | "f32" | "f64" => {
                let val = l[1].as_atom().unwrap();
                if head == "f32" {
                    let f: f32 = val.parse().unwrap();
                    self.emit(format!("  mov eax, {}; movd xmm0, eax; movss rax, xmm0", f.to_bits()));
                } else if head == "f64" {
                    let f: f64 = val.parse().unwrap();
                    self.emit(format!("  mov rax, {}; movd xmm0, rax; movsd rax, xmm0", f.to_bits()));
                } else {
                    self.emit(format!("  mov rax, {}", val));
                }
            }
            "ident" => {
                let name = l[1].as_atom().unwrap();
                let off = self.vars.get(name).unwrap().0;
                self.emit(format!("  mov rax, [rbp-{}]", off));
            }
            "field" => {
                let var_name = l[1].as_atom().unwrap();
                let field_name = l[2].as_atom().unwrap();
                let (off, ty) = self.vars.get(var_name).unwrap().clone();
                let fi = self.structs.get(&ty).unwrap().iter().position(|f| f == field_name).unwrap();
                self.emit(format!("  movsxd rax, dword ptr [rbp-{}]", off - (fi as i32 * 4)));
            }
            "struct_lit" => {
                for (i, arg) in l[2..4].iter().enumerate() {
                    self.lower_expr(arg);
                    if i == 0 {
                        self.emit("  push rax".to_string());
                    } else {
                        self.emit("  shl rax, 32; pop rcx; or rax, rcx".to_string());
                    }
                }
            }
            "binary" => {
                let op = l[1].as_atom().unwrap();
                self.lower_expr(&l[2]); self.emit("  push rax".to_string());
                self.lower_expr(&l[3]); self.emit("  mov rcx, rax; pop rax".to_string());
                match op.as_str() {
                    "add" => self.emit("  add rax, rcx".to_string()),
                    "sub" => self.emit("  sub rax, rcx".to_string()),
                    "mul" => self.emit("  imul rax, rcx".to_string()),
                    "div" => self.emit("  cqo; idiv rcx".to_string()),
                    "and" => self.emit("  and rax, rcx".to_string()),
                    "or" => self.emit("  or rax, rcx".to_string()),
                    _ => {
                        let cond = match op.as_str() { "eq"=>"e", "ne"=>"ne", "lt"=>"l", "gt"=>"g", "le"=>"le", "ge"=>"ge", _=>"e" };
                        self.emit(format!("  cmp rax, rcx; set{} al; movzx rax, al", cond));
                    }
                }
            }
            "call" => {
                let name = l[1].as_atom().unwrap();
                let regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"];
                let args = &l[2..];
                for i in (6..args.len()).rev() {
                    self.lower_expr(&args[i]);
                    self.emit("  push rax".to_string());
                }
                for arg in args.iter().take(6) {
                    self.lower_expr(arg);
                    self.emit("  push rax".to_string());
                }
                for i in (0..std::cmp::min(args.len(), 6)).rev() {
                    self.emit(format!("  pop {}", regs[i]));
                }
                self.emit(format!("  call {}", name));
                if args.len() > 6 { self.emit(format!("  add rsp, {}", (args.len() - 6) * 8)); }
            }
            "string_typed" => {
                let val = l[1].as_atom().unwrap();
                let off = self.strings.get(val).unwrap();
                self.emit(format!("  mov rax, {}", off));
            }
            "syscall" => self.emit("  syscall".to_string()),
            _ => {}
        }
    }
}

struct AArch64Backend {
    ir: IRNode,
    output: Vec<String>,
    vars: HashMap<String, (i32, String)>,
    strings: HashMap<String, i32>,
    structs: HashMap<String, Vec<String>>,
    label_count: i32,
    current_fn: String,
}

impl AArch64Backend {
    fn new(ir: IRNode) -> Self {
        Self {
            ir,
            output: Vec::new(),
            vars: HashMap::new(),
            strings: HashMap::new(),
            structs: HashMap::new(),
            label_count: 0,
            current_fn: String::new(),
        }
    }

    fn emit(&mut self, s: String) { self.output.push(s); }
    fn new_label(&mut self, prefix: &str) -> String {
        self.label_count += 1;
        format!(".{}{}", prefix, self.label_count)
    }

    fn collect_strings(&mut self, node: &IRNode) {
        if let IRNode::List(l) = node {
            if !l.is_empty() {
                if let Some(atom) = l[0].as_atom() {
                    if atom == "string_typed" && l.len() > 1 {
                        if let Some(val) = l[1].as_atom() {
                            self.strings.insert(val.clone(), 0);
                        }
                    }
                }
            }
            for child in l { self.collect_strings(child); }
        }
    }

    fn safe_mov_imm(&mut self, reg: &str, val: i64) {
        if (0..65536).contains(&val) {
            self.emit(format!("  mov {}, #{}", reg, val));
        } else {
            self.emit(format!("  movz {}, #{}", reg, val & 0xffff));
            if (val >> 16) & 0xffff != 0 { self.emit(format!("  movk {}, #{}", reg, (val >> 16) & 0xffff) + ", lsl #16"); }
            if (val >> 32) & 0xffff != 0 { self.emit(format!("  movk {}, #{}", reg, (val >> 32) & 0xffff) + ", lsl #32"); }
            if (val >> 48) & 0xffff != 0 { self.emit(format!("  movk {}, #{}", reg, (val >> 48) & 0xffff) + ", lsl #48"); }
        }
    }

    fn ldr_x29(&mut self, reg: &str, off: i32) {
        if (-256..=4095).contains(&off) { self.emit(format!("  ldr {}, [x29, #{}]", reg, off)); }
        else { self.safe_mov_imm("x1", off as i64); self.emit(format!("  ldr {}, [x29, x1]", reg)); }
    }

    fn ldrsw_x29(&mut self, reg: &str, off: i32) {
        if (-256..=4095).contains(&off) { self.emit(format!("  ldrsw {}, [x29, #{}]", reg, off)); }
        else { self.safe_mov_imm("x1", off as i64); self.emit(format!("  ldrsw {}, [x29, x1]", reg)); }
    }

    fn str_x29(&mut self, reg: &str, off: i32) {
        if (-256..=4095).contains(&off) { self.emit(format!("  str {}, [x29, #{}]", reg, off)); }
        else { self.safe_mov_imm("x1", off as i64); self.emit(format!("  str {}, [x29, x1]", reg)); }
    }

    fn lower(&mut self) {
        let mut fns: Vec<IRNode> = Vec::new();
        let mut structs_list: Vec<IRNode> = Vec::new();

        if let IRNode::List(root) = &self.ir {
            for child in root {
                if let IRNode::List(c) = child {
                    if !c.is_empty() {
                        if c[0].as_atom().map(|s| s == "functions").unwrap_or(false) {
                            fns = c[1..].to_vec();
                        } else if c[0].as_atom().map(|s| s == "structs").unwrap_or(false) {
                            structs_list = c[1..].to_vec();
                        }
                    }
                }
            }
        }

        for s in structs_list {
            if let IRNode::List(sl) = s {
                let name = sl[1].as_atom().unwrap().clone();
                let fields = sl[2..].iter().map(|f| f.as_list().unwrap()[1].as_atom().unwrap().clone()).collect();
                self.structs.insert(name, fields);
            }
        }

        self.emit(".bss".to_string());
        self.emit(".align 4".to_string());
        self.emit(".globl __coatl_mem".to_string());
        self.emit("__coatl_mem:".to_string());
        self.emit("  .zero 1048576".to_string());
        self.emit("__coatl_mem_inited:".to_string());
        self.emit("  .word 0".to_string());
        self.emit(".text".to_string());
        self.emit("__coatl_init_memory:".to_string());
        self.emit("  stp x29, x30, [sp, #-16]!".to_string());
        self.emit("  mov x29, sp".to_string());
        self.emit("  adrp x0, __coatl_mem_inited; ldr w1, [x0, :lo12:__coatl_mem_inited]; cbnz w1, .L_mem_done".to_string());
        self.emit("  mov w1, #1; str w1, [x0, :lo12:__coatl_mem_inited]".to_string());
        self.emit("  adrp x2, __coatl_mem; add x2, x2, :lo12:__coatl_mem".to_string());

        for func in &fns { self.collect_strings(func); }

        let mut off: i32 = 65536;
        let mut sorted_strings: Vec<_> = self.strings.keys().cloned().collect();
        sorted_strings.sort();
        for s in sorted_strings {
            let bytes = s.as_bytes().to_vec();
            for (i, &b) in bytes.iter().enumerate() {
                self.safe_mov_imm("x1", (off + i as i32) as i64);
                self.emit(format!("  mov w0, #{}; strb w0, [x2, x1]", b));
            }
            self.safe_mov_imm("x1", (off + bytes.len() as i32) as i64);
            self.emit("  strb wzr, [x2, x1]".to_string());
            self.strings.insert(s, off);
            off += bytes.len() as i32 + 1;
        }

        self.emit(".L_mem_done:".to_string());
        self.emit("  ldp x29, x30, [sp], #16".to_string());
        self.emit("  ret".to_string());

        for func in fns { self.lower_fn(&func); }

        self.emit(".globl coatl_start".to_string());
        self.emit("coatl_start:".to_string());
        self.emit("  stp x29, x30, [sp, #-16]!".to_string());
        self.emit("  bl __coatl_init_memory".to_string());
        self.emit("  bl main".to_string());
        self.emit("  mov w0, w0; mov x8, #93; svc #0".to_string());
        self.emit(INTRINSICS_AARCH64.to_string());
    }

    fn lower_fn(&mut self, n: &IRNode) {
        if let IRNode::List(l) = n {
            let name = l[1].as_atom().unwrap();
            self.current_fn = name.clone();
            self.vars.clear();
            self.emit(format!(".global {}\n{}:", name, name));
            self.emit("  stp x29, x30, [sp, #-16]!; mov x29, sp; sub sp, sp, #4096".to_string());
            
            let mut o = 16;
            if let IRNode::List(params) = &l[2] {
                for (i, p) in params[1..].iter().enumerate() {
                    if let IRNode::List(pl) = p {
                        let p_name = pl[1].as_atom().unwrap();
                        let p_type = pl[2].as_atom().unwrap();
                        self.vars.insert(p_name.clone(), (o, p_type.clone()));
                        if i < 8 { self.str_x29(&format!("x{}", i), -o); }
                        else {
                            let stack_off = 16 + (i as i32 - 8) * 8;
                            self.ldr_x29("x0", stack_off);
                            self.str_x29("x0", -o);
                        }
                        o += 8;
                    }
                }
            }

            if let IRNode::List(body) = &l[4] {
                for stmt in &body[1..] { self.lower_stmt(stmt); }
            }
            self.emit(format!(".Lret_{}:; add sp, sp, #4096; ldp x29, x30, [sp], #16; ret", name));
        }
    }

    fn lower_stmt(&mut self, n: &IRNode) {
        let l = n.as_list().unwrap();
        let head = l[0].as_atom().unwrap();
        match head.as_str() {
            "let" => {
                let name = l[1].as_atom().unwrap();
                let vtype = l[2].as_atom().unwrap();
                let off = (self.vars.len() as i32 + 2) * 8;
                self.vars.insert(name.clone(), (off, vtype.clone()));
                self.lower_expr(&l[3]);
                self.str_x29("x0", -off);
            }
            "assign" => {
                let name = l[1].as_atom().unwrap();
                let off = self.vars.get(name).unwrap().0;
                self.lower_expr(&l[2]);
                self.str_x29("x0", -off);
            }
            "if" => {
                let l_else = self.new_label("else");
                let l_end = self.new_label("endif");
                self.lower_expr(&l[1]);
                self.emit(format!("  cbz x0, {}", l_else));
                self.lower_stmt(&l[2]);
                self.emit(format!("  b {}", l_end));
                self.emit(format!("{}:", l_else));
                if l.len() > 3 { self.lower_stmt(&l[3].as_list().unwrap()[1]); }
                self.emit(format!("{}:", l_end));
            }
            "while" => {
                let l_start = self.new_label("while");
                let l_end = self.new_label("endwhile");
                self.emit(format!("{}:", l_start));
                self.lower_expr(&l[1]);
                self.emit(format!("  cbz x0, {}", l_end));
                self.lower_stmt(&l[2]);
                self.emit(format!("  b {}", l_start));
                self.emit(format!("{}:", l_end));
            }
            "block" => { for s in &l[1..] { self.lower_stmt(s); } }
            "return" => {
                self.lower_expr(&l[1]);
                let label = format!(".Lret_{}", self.current_fn);
                self.emit(format!("  b {}", label));
            }
            "svc" => {
                let args = &l[1..];
                for arg in args {
                    self.lower_expr(arg);
                    self.emit("  str x0, [sp, #-16]!".to_string());
                }
                if !args.is_empty() { self.emit("  ldr x8, [sp], #16".to_string()); }
                if args.len() > 1 { self.emit("  ldr x0, [sp], #16".to_string()); }
                if args.len() > 2 { self.emit("  ldr x1, [sp], #16".to_string()); }
                if args.len() > 3 { self.emit("  ldr x2, [sp], #16".to_string()); }
                self.emit("  svc #0".to_string());
            }
            "expr" => { self.lower_expr(&l[1]); }
            _ => {}
        }
    }

    fn lower_expr(&mut self, n: &IRNode) {
        let l = n.as_list().unwrap();
        let head = l[0].as_atom().unwrap();
        match head.as_str() {
            "int" | "int_i64" | "bool" => {
                let val: i64 = l[1].as_atom().unwrap().parse().unwrap();
                self.safe_mov_imm("x0", val);
            }
            "ident" => {
                let name = l[1].as_atom().unwrap();
                let off = self.vars.get(name).unwrap().0;
                self.ldrsw_x29("x0", -off);
            }
            "binary" => {
                let op = l[1].as_atom().unwrap();
                self.lower_expr(&l[2]); self.emit("  str x0, [sp, #-16]!".to_string());
                self.lower_expr(&l[3]); self.emit("  mov x1, x0; ldr x0, [sp], #16".to_string());
                match op.as_str() {
                    "add" => self.emit("  add x0, x0, x1".to_string()),
                    "sub" => self.emit("  sub x0, x0, x1".to_string()),
                    "mul" => self.emit("  mul x0, x0, x1".to_string()),
                    "div" => self.emit("  sdiv x0, x0, x1".to_string()),
                    "and" => self.emit("  and x0, x0, x1".to_string()),
                    "or" => self.emit("  orr x0, x0, x1".to_string()),
                    _ => {
                        let cond = match op.as_str() { "eq"=>"eq", "ne"=>"ne", "lt"=>"lt", "gt"=>"gt", "le"=>"le", "ge"=>"ge", _=>"eq" };
                        self.emit(format!("  cmp x0, x1; cset w0, {}", cond));
                    }
                }
            }
            "call" => {
                let name = l[1].as_atom().unwrap();
                let args = &l[2..];
                for i in (8..args.len()).rev() {
                    self.lower_expr(&args[i]);
                    self.emit("  str x0, [sp, #-16]!".to_string());
                }
                for arg in args.iter().take(8) {
                    self.lower_expr(arg);
                    self.emit("  str x0, [sp, #-16]!".to_string());
                }
                for i in (0..std::cmp::min(args.len(), 8)).rev() {
                    self.emit(format!("  ldr x{}, [sp], #16", i));
                }
                self.emit(format!("  bl {}", name));
                if args.len() > 8 {
                    self.emit(format!("  add sp, sp, #{}", (args.len() - 8) * 16));
                }
            }
            "string_typed" => {
                let val = l[1].as_atom().unwrap();
                let off = self.strings.get(val).unwrap();
                self.safe_mov_imm("x0", *off as i64);
            }
            "str_len" | "str_ptr" => self.lower_expr(&l[1]),
            _ => {}
        }
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 { println!("Usage: coatl <input.coatl|input.ir> [-o output.s] [--arch=<arch>]"); process::exit(1); }
    let mut input_path = String::new();
    let mut output_path = String::new();
    let mut arch = "x86_64".to_string();

    let mut i = 1;
    while i < args.len() {
        if args[i] == "-o" { output_path = args[i+1].clone(); i += 2; }
        else if args[i].starts_with("--arch=") { arch = args[i][7..].to_string(); i += 1; }
        else { input_path = args[i].clone(); i += 1; }
    }

    let ir = if input_path.ends_with(".ir") {
        let source = fs::read_to_string(&input_path).expect("Failed to read input file");
        let mut parser = IRParser::new(&source);
        parser.parse().expect("Failed to parse IR")
    } else {
        let mut all_structs = Vec::new();
        let mut all_fns = Vec::new();
        let mut all_imports = Vec::new();
        let mut visited = HashSet::new();
        parse_file_recursive(PathBuf::from(&input_path), &mut visited, &mut all_structs, &mut all_fns, &mut all_imports);
        IRNode::List(vec![
            IRNode::Atom("coatl_ir".to_string()),
            IRNode::Atom("v1".to_string()),
            IRNode::List(vec![IRNode::Atom("imports".to_string())]), // Simplification: imports already resolved
            IRNode::List(vec![IRNode::Atom("structs".to_string())].into_iter().chain(all_structs).collect()),
            IRNode::List(vec![IRNode::Atom("functions".to_string())].into_iter().chain(all_fns).collect()),
        ])
    };

    if output_path.ends_with(".ir") {
        fs::write(output_path, ir.to_ir()).expect("Failed to write IR output");
        return;
    }

    let output = if arch == "aarch64" {
        let mut backend = AArch64Backend::new(ir);
        backend.lower();
        backend.output.join("\n") + "\n"
    } else {
        let mut backend = X86_64Backend::new(ir);
        backend.lower();
        backend.output.join("\n") + "\n"
    };

    if !output_path.is_empty() {
        if output_path.ends_with(".s") || output_path.ends_with(".ir") {
            fs::write(output_path, output).expect("Failed to write output");
        } else {
            // Need to assemble and link
            let mut tmp_s = env::temp_dir();
            tmp_s.push("coatl_tmp.s");
            fs::write(&tmp_s, output).expect("Failed to write temp assembly");
            
            let cc = env::var("CC").unwrap_or_else(|_| "cc".to_string());
            let mut cmd = process::Command::new(&cc);
            cmd.args(&["-fPIE", "-pie", "-e", "coatl_start", tmp_s.to_str().unwrap(), "-o", &output_path]);
            
            // Special handling for aarch64 cross-compilation match
            if arch == "aarch64" {
                let machine = process::Command::new("uname").arg("-m").output().map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string()).unwrap_or_default();
                if machine != "aarch64" {
                    // Try to find cross compiler
                    let cross_cc = "aarch64-linux-gnu-gcc";
                    if process::Command::new("command").args(&["-v", cross_cc]).status().map(|s| s.success()).unwrap_or(false) {
                        cmd = process::Command::new(cross_cc);
                        cmd.args(&["-fPIE", "-pie", "-e", "coatl_start", tmp_s.to_str().unwrap(), "-o", &output_path]);
                    }
                }
            }

            let status = cmd.status().expect("Failed to run linker");
            if !status.success() {
                eprintln!("Linker failed");
                process::exit(1);
            }
            let _ = fs::remove_file(tmp_s);
        }
    } else {
        print!("{}", output);
    }
}
