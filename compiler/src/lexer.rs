#[derive(Debug, Clone, PartialEq)]
pub enum TokenKind {
    Ident(String),
    Int(i32),
    True,
    False,
    Fn,
    Let,
    Mut,
    Return,
    If,
    Else,
    While,
    Struct,
    Enum,
    Import,
    Extern,
    Colon,
    Semicolon,
    Comma,
    LParen,
    RParen,
    LBrace,
    RBrace,
    Arrow,
    Plus,
    Minus,
    Star,
    Slash,
    Eq,
    Lt,
    Gt,
    LtEq,
    GtEq,
    EqEq,
    NotEq,
    Bang,
    Eof,
}

#[derive(Debug, Clone)]
pub struct Token {
    pub kind: TokenKind,
    pub pos: usize,
}

pub struct Lexer<'a> {
    src: &'a str,
    chars: std::str::Chars<'a>,
    curr: Option<char>,
    pos: usize,
}

impl<'a> Lexer<'a> {
    pub fn new(src: &'a str) -> Self {
        let mut chars = src.chars();
        let curr = chars.next();
        Self { src, chars, curr, pos: 0 }
    }

    fn bump(&mut self) {
        if let Some(c) = self.curr {
            self.pos += c.len_utf8();
        }
        self.curr = self.chars.next();
    }

    fn peek(&self) -> Option<char> {
        self.curr
    }

    fn skip_ws(&mut self) {
        while let Some(c) = self.peek() {
            if c.is_whitespace() {
                self.bump();
            } else if c == '/' {
                let mut iter = self.chars.clone();
                if iter.next() == Some('/') {
                    self.bump();
                    self.bump();
                    while let Some(nc) = self.peek() {
                        if nc == '\n' { break; }
                        self.bump();
                    }
                } else {
                    break;
                }
            } else {
                break;
            }
        }
    }

    fn read_ident(&mut self) -> String {
        let start = self.pos;
        while let Some(c) = self.peek() {
            if c.is_ascii_alphanumeric() || c == '_' {
                self.bump();
            } else {
                break;
            }
        }
        self.src[start..self.pos].to_string()
    }

    fn read_int(&mut self) -> i32 {
        let start = self.pos;
        while let Some(c) = self.peek() {
            if c.is_ascii_digit() {
                self.bump();
            } else {
                break;
            }
        }
        self.src[start..self.pos].parse::<i32>().unwrap_or(0)
    }

    pub fn next_token(&mut self) -> Token {
        self.skip_ws();
        let pos = self.pos;
        let kind = match self.peek() {
            Some(c) if c.is_ascii_alphabetic() || c == '_' => {
                let ident = self.read_ident();
                match ident.as_str() {
                    "fn" => TokenKind::Fn,
                    "let" => TokenKind::Let,
                    "mut" => TokenKind::Mut,
                    "return" => TokenKind::Return,
                    "if" => TokenKind::If,
                    "else" => TokenKind::Else,
                    "while" => TokenKind::While,
                    "struct" => TokenKind::Struct,
                    "enum" => TokenKind::Enum,
                    "import" => TokenKind::Import,
                    "extern" => TokenKind::Extern,
                    "true" => TokenKind::True,
                    "false" => TokenKind::False,
                    _ => TokenKind::Ident(ident),
                }
            }
            Some(c) if c.is_ascii_digit() => TokenKind::Int(self.read_int()),
            Some(':') => { self.bump(); TokenKind::Colon }
            Some(';') => { self.bump(); TokenKind::Semicolon }
            Some(',') => { self.bump(); TokenKind::Comma }
            Some('(') => { self.bump(); TokenKind::LParen }
            Some(')') => { self.bump(); TokenKind::RParen }
            Some('{') => { self.bump(); TokenKind::LBrace }
            Some('}') => { self.bump(); TokenKind::RBrace }
            Some('+') => { self.bump(); TokenKind::Plus }
            Some('-') => {
                self.bump();
                if self.peek() == Some('>') {
                    self.bump();
                    TokenKind::Arrow
                } else {
                    TokenKind::Minus
                }
            }
            Some('*') => { self.bump(); TokenKind::Star }
            Some('/') => { self.bump(); TokenKind::Slash }
            Some('=') => {
                self.bump();
                if self.peek() == Some('=') {
                    self.bump();
                    TokenKind::EqEq
                } else {
                    TokenKind::Eq
                }
            }
            Some('<') => {
                self.bump();
                if self.peek() == Some('=') {
                    self.bump();
                    TokenKind::LtEq
                } else {
                    TokenKind::Lt
                }
            }
            Some('>') => {
                self.bump();
                if self.peek() == Some('=') {
                    self.bump();
                    TokenKind::GtEq
                } else {
                    TokenKind::Gt
                }
            }
            Some('!') => {
                self.bump();
                if self.peek() == Some('=') {
                    self.bump();
                    TokenKind::NotEq
                } else {
                    TokenKind::Bang
                }
            }
            None => TokenKind::Eof,
            Some(_) => {
                self.bump();
                TokenKind::Eof
            }
        };
        Token { kind, pos }
    }
}
