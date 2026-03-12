use std::env;
use std::fs;
use std::path::Path;
use std::process;

#[derive(Debug, Clone, PartialEq)]
pub enum IRNode {
    Atom(String),
    List(Vec<IRNode>),
}

impl IRNode {
    pub fn is_list(&self) -> bool {
        matches!(self, IRNode::List(_))
    }

    pub fn as_list(&self) -> Option<&Vec<IRNode>> {
        match self {
            IRNode::List(l) => Some(l),
            _ => None,
        }
    }

    pub fn as_atom(&self) -> Option<&String> {
        match self {
            IRNode::Atom(s) => Some(s),
            _ => None,
        }
    }

    pub fn to_ir(&self) -> String {
        match self {
            IRNode::Atom(s) => {
                if s.contains(' ') || s.is_empty() {
                    format!("\"{}\"", s.replace("\"", "\\\""))
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
            if c.is_whitespace() {
                chars.next();
            } else if c == '(' || c == ')' {
                tokens.push(c.to_string());
                chars.next();
            } else if c == '"' {
                chars.next();
                let mut s = String::new();
                while let Some(nc) = chars.next() {
                    if nc == '"' { break; }
                    if nc == '\\' {
                        if let Some(esc) = chars.next() {
                            s.push(match esc {
                                'n' => '\n',
                                'r' => '\r',
                                't' => '\t',
                                _ => esc,
                            });
                        }
                    } else {
                        s.push(nc);
                    }
                }
                tokens.push(format!("\"{}\"", s)); // Keep quotes to distinguish from atoms if needed, or strip
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
                if let Some(node) = self.parse() {
                    list.push(node);
                }
            }
            if self.pos < self.tokens.len() { self.pos += 1; } // Consume ")"
            Some(IRNode::List(list))
        } else if token.starts_with('"') && token.ends_with('"') {
            Some(IRNode::Atom(token[1..token.len()-1].to_string()))
        } else {
            Some(IRNode::Atom(token.clone()))
        }
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        println!("Usage: coatl <input.coatl|input.ir> [-o output.s]");
        process::exit(1);
    }

    let input_path = &args[1];
    let source = fs::read_to_string(input_path).expect("Failed to read input file");
    
    if input_path.ends_with(".ir") {
        let mut parser = IRParser::new(&source);
        if let Some(ir) = parser.parse() {
            println!("Successfully parsed IR from {}", input_path);
            // In the future, this IR will be passed to the backends
        } else {
            eprintln!("Failed to parse IR");
            process::exit(1);
        }
    } else {
        println!("Source parsing not yet implemented in Rust - use .ir files for now.");
    }
}
