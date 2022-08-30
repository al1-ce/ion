module ion.parser;

import std.conv: to;
import std.format: format;
import std.stdio: writeln;
import std.algorithm: canFind;

import ion.token;
import ion.lexer;
import ion.ast;

import sily.addons: isOneOf;

/* ---------------------------------- bugs ---------------------------------- */

// LINK https://wiki.dlang.org/Operator_precedence
// operator precedence (first to last):
// ! template
// => lambda
// . ++ -- ( [ postfix
// ^^  power
// & ++ -- * + - ! ~ cast  !unary!
// * / % mult
// + - ~ additive
// << >> >>> bitshift
// == != > < >= <= in !in is !is
// &
// ^
// |
// &&
// ||
// ? : conditional
// = ^^= *= /= %= += -= ~= <<= >>= >>>= &= |= ^= assign
// => lambda abstraction ???
// , comma
// .. range

class Parser {
    private Lexer _lexer;
    private Token _currentToken;
    private bool _isEOF = false;
    private bool _exceptionCaught = false;

    this(Lexer lexer) {
        _lexer = lexer;
        _currentToken = _lexer.getNextToken();
    }

    /* ----------------------------- error handling ----------------------------- */

    /** 
     * Prints unexpected token error
     * Params:
     *   tokenGot = Token parser got
     *   tokenExp = Token parser expects
     *   pos = Position of parser
     */
    private AstNode* error(TokenType tokenGot, TokenType tokenExp) {
        // if (errorStatus()) return errorNode(); // if error occured, don't print anything

        string exp = tokenStrings.keys.canFind(tokenExp) ? tokenStrings[tokenExp] : tokenExp.to!string;
        string got = tokenStrings.keys.canFind(tokenGot) ? tokenStrings[tokenGot] : tokenGot.to!string;
        string err = 
            "\n%d,%d: Expected \"%s\" instead of \"%s\"."
            .format(_lexer.line + 1, _lexer.linePos, exp, got);
        writeln(err);
        
        exitEval();

        return errorNode();
    }

    /** 
     * Prints general syntax error as `0,1: Invalid syntax, message.`
     * Params:
     *   message = Message to show (lowercase, no full stop at end)
     */
    private AstNode* error(string message) {
        // if (errorStatus()) return errorNode(); // if error occured, don't print anything
        string err = 
            "\n%d,%d: Invalid syntax, %s."
            .format(_lexer.line + 1, _lexer.linePos, message);
        writeln(err);
        
        exitEval();

        return errorNode();
    }

    public bool errorStatus() {
        return _exceptionCaught || _lexer.errorStatus();
    }

    private AstNode* errorNode() { return new AstNode(Token(TokenType.NONE, _lexer.line(), _lexer.linePos())); }

    private void exitEval() {
        _exceptionCaught = true;
        _isEOF = true;
    }

    private bool checkUnpaired() {
        TokenType[] errorTokens = [TokenType.RPAREN, TokenType.RBRACE, TokenType.RBRACKET];
        
        if (isOneOf!TokenType(_currentToken.type, errorTokens)) {
            switch (_currentToken.type) {
                case TokenType.RPAREN: error("unexpected \")\""); break;
                case TokenType.RBRACE: error("unexpected \"}\""); break;
                case TokenType.RBRACKET: error("unexpected \"]\""); break;
                default: break;
            }
            return true;
        }

        return false;
    }

    /* ------------------------------ token parsing ----------------------------- */

    /** 
     * Advances if `type` is same as current token type. \
     * If else throws exception.
     * Params:
     *   type = Expected token type
     */
    private void shift(TokenType type) {
        if (_currentToken.type == type) {
            _currentToken = _lexer.getNextToken();
        // } else if (_currentToken.type == TokenType.EOF) {
        //     exitEval();
        } else {
            error(_currentToken.type, type);
        }
    }
    
    /** 
     * Transforms token into new type
     * Params:
     *   token = Token to transform
     */
    private void mutate(ref Token token, TokenType type) { token.type = type; }

    /** 
     * Parses for `PLUS|MINUS factor`, `INTEGER`, `LPAREN expr RPAREN` \
     * Parses unary, numbers, parenthesis
     * Returns: value
     */
    private AstNode* factor() {
        Token token = _currentToken;

        switch (_currentToken.type) {
            case TokenType.PLUS:
                shift(TokenType.PLUS);
                mutate(token, TokenType.POS);
                AstNode* fact = factor();
                AstNode* node = new AstNode(token, fact);
            return node;

            case TokenType.MINUS:
                shift(TokenType.MINUS);
                mutate(token, TokenType.NEG);
                AstNode* fact = factor();
                AstNode* node = new AstNode(token, fact);
            return node;

            case TokenType.BANG:
                shift(TokenType.BANG);
                mutate(token, TokenType.NOT);
                AstNode* fact = factor();
                AstNode* node = new AstNode(token, fact);
            return node;

            case TokenType.INTEGER:
                shift(TokenType.INTEGER);
                AstNode* node = new AstNode(token, token.ival);
            return node;

            case TokenType.LPAREN:
                shift(TokenType.LPAREN);
                AstNode* node = expr();
                shift(TokenType.RPAREN);
            return node;

            // explicitly returning empty node because
            // it needs return and I'd prever visibility here
            // when expr reaches ')' it exits coz it's neither
            // + or - which makes it return whatever is 
            // currently in expr
            // so this part of code should be never reached and
            // if it is then it's gonna be an error
            // FIXME expr (1+1)) evaluates correctly, which it shouldnt
            // FIXME actually 1+1' and others are evaluating correctly which is bad
            case TokenType.RPAREN: return error("unexpected \")\"");
            
            default: return error("primary expression expected");
        }
    }

    /** 
     * Parses for `factor (MUL|DIV factor)`
     * Returns: value
     */
    private AstNode* term() {
        AstNode* nodeptr = factor();

        TokenType[] allowedTokens = [TokenType.STAR, TokenType.SLASH, TokenType.PERCENT, TokenType.POW];
        
        while (isOneOf!TokenType(_currentToken.type, allowedTokens)) {
            Token token = _currentToken;
            switch (token.type) {
                case TokenType.STAR:
                    shift(TokenType.STAR); 
                    mutate(token, TokenType.MUL);
                break;

                case TokenType.SLASH:
                    shift(TokenType.SLASH); 
                    mutate(token, TokenType.DIV);
                break;

                case TokenType.PERCENT:
                    shift(TokenType.PERCENT); 
                    mutate(token, TokenType.MOD);
                break;

                case TokenType.POW:
                    shift(TokenType.POW); 
                    // mutate(token, TokenType.MOD); // no need to mutate
                break;

                default: return error("primary expression expected");
            }

            AstNode* rptr = factor();
            AstNode* newNode = new AstNode(nodeptr, token, rptr);
            nodeptr = newNode;
        }
        return nodeptr;
    }

    /** 
     * Arithmetic expression parser \
     * \
     * expr   : term (**PLUS**|**MINUS** term) \
     * term   : factor (**MUL**|**DIV** factor) \
     * factor : **INTEGER** | **LPAREN** expr **RPAREN** 
     * Returns: evaluated result `EvalReturn(status, result)`
     */ 
    private AstNode* expr() {
        AstNode* nodeptr = term();

        TokenType[] allowedTokens = [TokenType.PLUS, TokenType.MINUS];

        while (isOneOf!TokenType(_currentToken.type, allowedTokens)) {
            Token token = _currentToken;
            
            switch (token.type) {
                case TokenType.PLUS: 
                    shift(TokenType.PLUS); 
                    mutate(token, TokenType.ADD);
                break;

                case TokenType.MINUS: 
                    shift(TokenType.MINUS); 
                    mutate(token, TokenType.SUB);
                break;

                default: return error("primary expression expected");
            }
            
            AstNode* rptr = term();
            AstNode* newNode = new AstNode(nodeptr, token, rptr);
            nodeptr = newNode;
        }
        
        return nodeptr;
    }

    /* ---------------------------- general interface --------------------------- */

    public AstNode parse() {
        AstNode* tree = expr();

        return deref(tree);
    }

}