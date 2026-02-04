use crate::ast::{BinOp, Block, Expr, Function, Param, Program, StructDecl, Stmt, Type, UnOp};
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
        let mut structs = Vec::new();
        while self.curr.kind != TokenKind::Eof {
            match self.curr.kind {
                TokenKind::Fn => functions.push(self.parse_function()?),
                TokenKind::Struct => structs.push(self.parse_struct()?),
                _ => return Err(ParseError { message: "expected fn or struct".to_string(), pos: self.curr.pos }),
            }
        }
        Ok(Program { functions, structs })
    }

    fn parse_struct(&mut self) -> Result<StructDecl, ParseError> {
        self.expect(TokenKind::Struct)?;
        let name = self.expect_ident()?;
        self.expect(TokenKind::LBrace)?;
        let mut fields = Vec::new();
        while self.curr.kind != TokenKind::RBrace {
            let fname = self.expect_ident()?;
            self.expect(TokenKind::Colon)?;
            let fty = self.parse_type()?;
            fields.push(Param { name: fname, ty: fty });
            if self.curr.kind == TokenKind::Comma {
                self.bump();
            } else {
                break;
            }
        }
        self.expect(TokenKind::RBrace)?;
        Ok(StructDecl { name, fields })
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
                    "char" => Type::Char,
                    "bool" => Type::Bool,
                    "str" => Type::Str,
                    "void" => Type::Void,
                    _ => Type::Struct(name.clone()),
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
            TokenKind::If => {
                self.bump();
                self.expect(TokenKind::LParen)?;
                let cond = self.parse_expr()?;
                self.expect(TokenKind::RParen)?;
                let then_block = self.parse_block()?;
                let else_block = if self.curr.kind == TokenKind::Else {
                    self.bump();
                    Some(self.parse_block()?)
                } else {
                    None
                };
                Ok(Stmt::If { cond, then_block, else_block })
            }
            TokenKind::While => {
                self.bump();
                self.expect(TokenKind::LParen)?;
                let cond = self.parse_expr()?;
                self.expect(TokenKind::RParen)?;
                let body = self.parse_block()?;
                Ok(Stmt::While { cond, body })
            }
            TokenKind::Ident(name) => {
                self.bump();
                if self.curr.kind == TokenKind::Eq {
                    self.bump();
                    let expr = self.parse_expr()?;
                    self.expect(TokenKind::Semicolon)?;
                    Ok(Stmt::Assign { name, expr })
                } else if self.curr.kind == TokenKind::LParen {
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
                    self.expect(TokenKind::Semicolon)?;
                    Ok(Stmt::Expr(Expr::Call { callee: name, args }))
                } else {
                    let left = Expr::Ident(name);
                    let mut node = left;
                    loop {
                        if self.curr.kind == TokenKind::Dot {
                            self.bump();
                            let field = self.expect_ident()?;
                            node = Expr::FieldAccess { expr: Box::new(node), field };
                        } else {
                            break;
                        }
                    }

                    if self.curr.kind == TokenKind::Eq {
                        self.bump();
                        let expr = self.parse_expr()?;
                        self.expect(TokenKind::Semicolon)?;
                        return match node {
                            Expr::Ident(name) => Ok(Stmt::Assign { name, expr }),
                            Expr::FieldAccess { expr: base, field } => {
                                if let Expr::Ident(base_name) = *base {
                                    Ok(Stmt::FieldAssign { base: base_name, field, expr })
                                } else {
                                    Err(ParseError {
                                        message: "left-hand side of assignment must be a variable or field".to_string(),
                                        pos: self.curr.pos,
                                    })
                                }
                            }
                            _ => Err(ParseError {
                                message: "left-hand side of assignment must be a variable or field".to_string(),
                                pos: self.curr.pos,
                            }),
                        };
                    }

                    let expr = self.parse_expr_rest(node)?;
                    self.expect(TokenKind::Semicolon)?;
                    Ok(Stmt::Expr(expr))
                }
            }
            _ => {
                let expr = self.parse_expr()?;
                self.expect(TokenKind::Semicolon)?;
                Ok(Stmt::Expr(expr))
            }
        }
    }

    fn parse_expr(&mut self) -> Result<Expr, ParseError> {
        self.parse_or()
    }

    fn parse_expr_rest(&mut self, left: Expr) -> Result<Expr, ParseError> {
        let node = self.parse_additive_rest(left)?;
        let node = self.parse_comparison_rest(node)?;
        let node = self.parse_and_rest(node)?;
        self.parse_or_rest(node)
    }

    fn parse_comparison(&mut self) -> Result<Expr, ParseError> {
        let node = self.parse_additive()?;
        self.parse_comparison_rest(node)
    }

    fn parse_comparison_rest(&mut self, mut node: Expr) -> Result<Expr, ParseError> {
        loop {
            match self.curr.kind {
                TokenKind::Lt => {
                    self.bump();
                    let rhs = self.parse_additive()?;
                    node = Expr::Binary { op: BinOp::Lt, left: Box::new(node), right: Box::new(rhs) };
                }
                TokenKind::Gt => {
                    self.bump();
                    let rhs = self.parse_additive()?;
                    node = Expr::Binary { op: BinOp::Gt, left: Box::new(node), right: Box::new(rhs) };
                }
                TokenKind::LtEq => {
                    self.bump();
                    let rhs = self.parse_additive()?;
                    node = Expr::Binary { op: BinOp::LtEq, left: Box::new(node), right: Box::new(rhs) };
                }
                TokenKind::GtEq => {
                    self.bump();
                    let rhs = self.parse_additive()?;
                    node = Expr::Binary { op: BinOp::GtEq, left: Box::new(node), right: Box::new(rhs) };
                }
                TokenKind::EqEq => {
                    self.bump();
                    let rhs = self.parse_additive()?;
                    node = Expr::Binary { op: BinOp::Eq, left: Box::new(node), right: Box::new(rhs) };
                }
                TokenKind::NotEq => {
                    self.bump();
                    let rhs = self.parse_additive()?;
                    node = Expr::Binary { op: BinOp::NotEq, left: Box::new(node), right: Box::new(rhs) };
                }
                _ => break,
            }
        }
        Ok(node)
    }

    fn parse_additive(&mut self) -> Result<Expr, ParseError> {
        let node = self.parse_term()?;
        self.parse_additive_rest(node)
    }

    fn parse_additive_rest(&mut self, mut node: Expr) -> Result<Expr, ParseError> {
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
        let mut node = self.parse_unary()?;
        loop {
            if self.curr.kind == TokenKind::Dot {
                self.bump();
                let field = self.expect_ident()?;
                node = Expr::FieldAccess { expr: Box::new(node), field };
            } else {
                break;
            }
        }
        Ok(node)
    }

    fn parse_unary(&mut self) -> Result<Expr, ParseError> {
        if self.curr.kind == TokenKind::Bang {
            self.bump();
            let expr = self.parse_unary()?;
            return Ok(Expr::Unary { op: UnOp::Not, expr: Box::new(expr) });
        }
        self.parse_primary()
    }

    fn parse_primary(&mut self) -> Result<Expr, ParseError> {
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
            TokenKind::Char(c) => {
                self.bump();
                Ok(Expr::Char(c))
            }
            TokenKind::StringLit(s) => {
                self.bump();
                Ok(Expr::StringLit(s))
            }
            TokenKind::Ident(name) => {
                self.bump();
                if self.curr.kind == TokenKind::LParen {
                    // Call
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
                } else if self.curr.kind == TokenKind::LBrace {
                    // Struct Init
                    self.bump();
                    let mut fields = Vec::new();
                    if self.curr.kind != TokenKind::RBrace {
                         loop {
                             let fname = self.expect_ident()?;
                             self.expect(TokenKind::Colon)?;
                             let val = self.parse_expr()?;
                             fields.push((fname, val));
                             if self.curr.kind == TokenKind::Comma {
                                 self.bump();
                                 continue;
                             }
                             break;
                         }
                    }
                    self.expect(TokenKind::RBrace)?;
                    Ok(Expr::StructInit { name, fields })
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

    fn parse_and(&mut self) -> Result<Expr, ParseError> {
        let node = self.parse_comparison()?;
        self.parse_and_rest(node)
    }

    fn parse_and_rest(&mut self, mut node: Expr) -> Result<Expr, ParseError> {
        loop {
            if self.curr.kind == TokenKind::And {
                self.bump();
                let rhs = self.parse_comparison()?;
                node = Expr::Binary { op: BinOp::And, left: Box::new(node), right: Box::new(rhs) };
            } else {
                break;
            }
        }
        Ok(node)
    }

    fn parse_or(&mut self) -> Result<Expr, ParseError> {
        let node = self.parse_and()?;
        self.parse_or_rest(node)
    }

    fn parse_or_rest(&mut self, mut node: Expr) -> Result<Expr, ParseError> {
        loop {
            if self.curr.kind == TokenKind::Or {
                self.bump();
                let rhs = self.parse_and()?;
                node = Expr::Binary { op: BinOp::Or, left: Box::new(node), right: Box::new(rhs) };
            } else {
                break;
            }
        }
        Ok(node)
    }
}
