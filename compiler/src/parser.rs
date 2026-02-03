use crate::ast::{BinOp, Block, Expr, Function, Param, Program, Stmt, Type};
use crate::lexer::{Lexer, Token, TokenKind};

#[derive(Debug)]
pub struct ParseError {
    pub message: String,
    pub pos: usize,
}

pub struct Parser<'a> {
    lexer: Lexer<'a>,
    curr: Token,
}

impl<'a> Parser<'a> {
    pub fn new(src: &'a str) -> Self {
        let mut lexer = Lexer::new(src);
        let curr = lexer.next_token();
        Self { lexer, curr }
    }

    fn bump(&mut self) {
        self.curr = self.lexer.next_token();
    }

    fn expect(&mut self, kind: TokenKind) -> Result<(), ParseError> {
        if self.curr.kind == kind {
            self.bump();
            Ok(())
        } else {
            Err(ParseError { message: format!("expected {:?}", kind), pos: self.curr.pos })
        }
    }

    fn expect_ident(&mut self) -> Result<String, ParseError> {
        match &self.curr.kind {
            TokenKind::Ident(name) => {
                let name = name.clone();
                self.bump();
                Ok(name)
            }
            _ => Err(ParseError { message: "expected identifier".to_string(), pos: self.curr.pos }),
        }
    }

    pub fn parse_program(&mut self) -> Result<Program, ParseError> {
        let mut functions = Vec::new();
        while self.curr.kind != TokenKind::Eof {
            functions.push(self.parse_function()?);
        }
        Ok(Program { functions })
    }

    fn parse_function(&mut self) -> Result<Function, ParseError> {
        self.expect(TokenKind::Fn)?;
        let name = self.expect_ident()?;
        self.expect(TokenKind::LParen)?;
        let mut params = Vec::new();
        if self.curr.kind != TokenKind::RParen {
            loop {
                let pname = self.expect_ident()?;
                self.expect(TokenKind::Colon)?;
                let pty = self.parse_type()?;
                params.push(Param { name: pname, ty: pty });
                if self.curr.kind == TokenKind::Comma {
                    self.bump();
                    continue;
                }
                break;
            }
        }
        self.expect(TokenKind::RParen)?;
        self.expect(TokenKind::Arrow)?;
        let ret = self.parse_type()?;
        let body = self.parse_block()?;
        Ok(Function { name, params, ret, body })
    }

    fn parse_type(&mut self) -> Result<Type, ParseError> {
        match &self.curr.kind {
            TokenKind::Ident(name) => {
                let ty = match name.as_str() {
                    "i32" => Type::I32,
                    "bool" => Type::Bool,
                    "void" => Type::Void,
                    _ => return Err(ParseError { message: format!("unknown type {}", name), pos: self.curr.pos }),
                };
                self.bump();
                Ok(ty)
            }
            _ => Err(ParseError { message: "expected type".to_string(), pos: self.curr.pos }),
        }
    }

    fn parse_block(&mut self) -> Result<Block, ParseError> {
        self.expect(TokenKind::LBrace)?;
        let mut statements = Vec::new();
        while self.curr.kind != TokenKind::RBrace {
            statements.push(self.parse_stmt()?);
        }
        self.expect(TokenKind::RBrace)?;
        Ok(Block { statements })
    }

    fn parse_stmt(&mut self) -> Result<Stmt, ParseError> {
        match self.curr.kind.clone() {
            TokenKind::Let => {
                self.bump();
                let name = self.expect_ident()?;
                self.expect(TokenKind::Colon)?;
                let ty = self.parse_type()?;
                self.expect(TokenKind::Eq)?;
                let expr = self.parse_expr()?;
                self.expect(TokenKind::Semicolon)?;
                Ok(Stmt::Let { name, ty, expr })
            }
            TokenKind::Return => {
                self.bump();
                let expr = self.parse_expr()?;
                self.expect(TokenKind::Semicolon)?;
                Ok(Stmt::Return(expr))
            }
            _ => {
                let expr = self.parse_expr()?;
                self.expect(TokenKind::Semicolon)?;
                Ok(Stmt::Expr(expr))
            }
        }
    }

    fn parse_expr(&mut self) -> Result<Expr, ParseError> {
        self.parse_additive()
    }

    fn parse_additive(&mut self) -> Result<Expr, ParseError> {
        let mut node = self.parse_term()?;
        loop {
            match self.curr.kind {
                TokenKind::Plus => {
                    self.bump();
                    let rhs = self.parse_term()?;
                    node = Expr::Binary { op: BinOp::Add, left: Box::new(node), right: Box::new(rhs) };
                }
                TokenKind::Minus => {
                    self.bump();
                    let rhs = self.parse_term()?;
                    node = Expr::Binary { op: BinOp::Sub, left: Box::new(node), right: Box::new(rhs) };
                }
                _ => break,
            }
        }
        Ok(node)
    }

    fn parse_term(&mut self) -> Result<Expr, ParseError> {
        let mut node = self.parse_factor()?;
        loop {
            match self.curr.kind {
                TokenKind::Star => {
                    self.bump();
                    let rhs = self.parse_factor()?;
                    node = Expr::Binary { op: BinOp::Mul, left: Box::new(node), right: Box::new(rhs) };
                }
                TokenKind::Slash => {
                    self.bump();
                    let rhs = self.parse_factor()?;
                    node = Expr::Binary { op: BinOp::Div, left: Box::new(node), right: Box::new(rhs) };
                }
                _ => break,
            }
        }
        Ok(node)
    }

    fn parse_factor(&mut self) -> Result<Expr, ParseError> {
        match self.curr.kind.clone() {
            TokenKind::Int(v) => {
                self.bump();
                Ok(Expr::Int(v))
            }
            TokenKind::True => {
                self.bump();
                Ok(Expr::Bool(true))
            }
            TokenKind::False => {
                self.bump();
                Ok(Expr::Bool(false))
            }
            TokenKind::Ident(name) => {
                self.bump();
                if self.curr.kind == TokenKind::LParen {
                    self.bump();
                    let mut args = Vec::new();
                    if self.curr.kind != TokenKind::RParen {
                        loop {
                            args.push(self.parse_expr()?);
                            if self.curr.kind == TokenKind::Comma {
                                self.bump();
                                continue;
                            }
                            break;
                        }
                    }
                    self.expect(TokenKind::RParen)?;
                    Ok(Expr::Call { callee: name, args })
                } else {
                    Ok(Expr::Ident(name))
                }
            }
            TokenKind::LParen => {
                self.bump();
                let expr = self.parse_expr()?;
                self.expect(TokenKind::RParen)?;
                Ok(expr)
            }
            _ => Err(ParseError { message: "unexpected token".to_string(), pos: self.curr.pos }),
        }
    }
}
