module ion.lexer;

import std.string: isNumeric;
import std.conv: to, parse;
import std.stdio: writeln;
import std.format: format;
import std.uni: isSpace, isWhite;
import std.algorithm: canFind;

import ion.token;
import sily.addons: isAlpha, isAlphaNumeric, isDigit, isOneOf;

class Lexer {
    private char[] _text;
    private int _pos;
    private char _currentChar;
    private bool _isEOF = false;
    private size_t _currentLine = 0;
    private size_t _currentLinePos = 0;
    private bool _exceptionCaught = false;

    private alias _char = _currentChar;

    this(char[] p_text) {
        _text = p_text;
        _pos = 0;
        // _currentToken = TokenType.NONE;
        _currentChar = (_pos > _text.length) ? '\0' : _text[_pos];
    }

    /* --------------------------------- getters -------------------------------- */

    public size_t line() { return _currentLine; }
    public size_t linePos() { return _currentLinePos; }
    public bool errorStatus() { return _exceptionCaught; }
    public bool isEOF() { return _isEOF; }

    /* ----------------------------- error handling ----------------------------- */

    /** 
     * Prints unknown token error
     * Params:
     *   c = Char representing token
     *   pos = Position of interpreter
     */
    private void error(char c) {
        string err = 
            "\n%d,%d: Invalid character, unknown character \"%s\" (%d)."
            .format(line + 1, linePos, c, c);
        writeln(err);

        _exceptionCaught = true;
        _isEOF = true;
    }

    /** 
     * Prints general syntax error as `0,1: Invalid syntax, message.`
     * Params:
     *   message = Message to show (lowercase, no full stop at end)
     */
    private void error(string message) {
        string err = 
            "\n%d,%d: Invalid syntax, %s."
            .format(line + 1, linePos, message);
        writeln(err);
        
        _exceptionCaught = true;
        _isEOF = true;
    }

    /* ----------------------------- stream handling ---------------------------- */

    /** 
     * Returns: Current character
     */
    private char look() {
        return _char;
    }

    /** 
     * Compares current char to `c`
     * Params:
     *   c = Char to compare
     * Returns: `c == look()`
     */
    private bool lookAt(char c) {
        return look() == c;
    }

    /** 
     * Returns: Next character
     */
    private char peek() {
        int peekPos = _pos + 1;
        if (peekPos >= _text.length) {
            return '\0';
        }
        return _text[peekPos];
    }

    /** 
     * Compares next char to `c`
     * Params:
     *   c = Char to compare
     * Returns: `c == peek()`
     */
    private bool peekAt(char c) {
        return peek() == c;
    }

    /** 
     * Moves to next token
     */
    private void advance() {
        _pos++;
        if (_pos >= _text.length) {
            _isEOF = true;
            _char = '\0';
        } else {
            _char = _text[_pos];
            _currentLinePos++;
        }
    }

    /** 
     * Skips whitespaces
     */
    private void skipWhitespace() {
        while ( _char.isWhite && !_isEOF ) {
            if (lookAt('\n')) {
                newLine();
            }
            advance();
        }
    }

    private void newLine() {
        _currentLinePos = 0;
        _currentLine++;
    }

    /* --------------------------------- tokens --------------------------------- */

    private Token identifier() {
        string result;
        while ( isAlphaNumeric(_char) && !_isEOF ) {
            result ~= _char;
            advance();
        }

        if (keywords.keys.canFind(result)) {
            return Token(keywords[result], _currentLine, _currentLinePos);
        }

        return Token(TokenType.IDENTIFIER, result, _currentLine, _currentLinePos);
    }

    /** 
     * Parses numeric token types and returns full number
     * Returns: number
     */
    private Token number() {
        // TODO hex numbers ( 0xFF1A )
        string result;

        while ( isDigit(_char) && !_isEOF ) {
            result ~= _char;
            advance();
        }

        if (lookAt('.') && isDigit(peek())) {
            result ~= _char;
            advance();

            while ( isDigit(_char) && !_isEOF ) {
                result ~= _char;
                advance();
            }
        }

        // u - unsigned
        // l - long
        // f - float
        // possible to concider:
        // d - double
        // r - real
        // c - char
        if (isOneOf!char(_char, 'u', 'U', 'l', 'L', 'f', 'F')) {
            // TODO number literals
            result ~= _char;
            advance();
        }

        return Token(TokenType.INTEGER, result.parse!int, _currentLine, _currentLinePos);
    }

    private Token pstring() {
        string result = "";
        while (!lookAt('"') && !_isEOF) {
            if (lookAt('\n')) {
                newLine();
            }
            result ~= _char;
            advance();
        }
        if (_isEOF) {
            error("unterminated string");
        }

        // remove closing "
        advance();

        return Token(TokenType.STRING, result, _currentLine, _currentLinePos);
    }

    private Token pchar() {
        char result = '\0';
        while (!lookAt('\'') && !_isEOF) {
            if (lookAt('\n')) {
                newLine();
            }
            result = _char;
            advance();
            // TODO error if char is empty
            // TODO error if char.length > 0
        }
        if (_isEOF) {
            error("unterminated char");
        }

        // remove closing '
        advance();

        return Token(TokenType.CHAR, result, _currentLine, _currentLinePos);
    }

    private Token comment() {
        if (lookAt('/')) {
            advance(); // consume /
            while (!lookAt('\n') && !_isEOF) advance();
            advance(); // consume '\n'
        } else
        if (lookAt('*')) { 
            advance(); // consume *
            while (!(lookAt('*') && peekAt('/')) && !_isEOF) advance();
            advance(); advance(); // consume '*/'
        }
        return getNextToken();
    }

    /* ----------------------------- get next token ----------------------------- */

    /** 
     * Advances to next token
     * Returns: next token
     */
    public Token getNextToken() {

        while (!_isEOF) {
            if (_char.isWhite) {
                skipWhitespace();
                continue;
            }
            
            if (isDigit(_char)) {
                return number();
            }

            if (isAlpha(_char)) {
                return identifier();
            }

            switch (_char) {
                case '+': advance(); return Token(TokenType.PLUS, line(), linePos());
                case '-': advance(); return Token(TokenType.MINUS, line(), linePos());
                case '*': advance(); return Token(TokenType.STAR, line(), linePos());
                case '/': advance();
                    if (lookAt('/') || lookAt('*')) return comment(); else
                    return Token(TokenType.DIV, line(), linePos());
                case '%': advance(); return Token(TokenType.PERCENT, line(), linePos());
                case '~': advance(); return Token(TokenType.TILDE, line(), linePos());
                case '^': advance();
                    if (lookAt('^')) { advance(); 
                        return Token(TokenType.POW, line(), linePos());
                    } else {
                        return Token(TokenType.XOR, line(), linePos());
                    }
                
                case '(': advance(); return Token(TokenType.LPAREN, line(), linePos());
                case ')': advance(); return Token(TokenType.RPAREN, line(), linePos());
                
                case '{': advance(); return Token(TokenType.LBRACE, line(), linePos());
                case '}': advance(); return Token(TokenType.RBRACE, line(), linePos());
                
                case '[': advance(); return Token(TokenType.LBRACKET, line(), linePos());
                case ']': advance(); return Token(TokenType.RBRACKET, line(), linePos());
                
                case ';': advance(); return Token(TokenType.SEMICOLON, line(), linePos());
                
                case '!': advance();
                    if (lookAt('=')) { advance(); 
                        return Token(TokenType.NOTEQ, line(), linePos());
                    } else {
                        return Token(TokenType.BANG, line(), linePos());
                    }
                case '=': advance();
                    if (lookAt('=')) { advance(); 
                        return Token(TokenType.EQ, line(), linePos());
                    } else {
                        return Token(TokenType.EQUALS, line(), linePos());
                    }
                case '<': advance();
                    if (lookAt('=')) { advance(); 
                        return Token(TokenType.LTEQ, line(), linePos());
                    } else {
                        return Token(TokenType.LTHEN, line(), linePos());
                    }
                case '>': advance();
                    if (lookAt('=')) { advance(); 
                        return Token(TokenType.GTEQ, line(), linePos());
                    } else {
                        return Token(TokenType.GTHEN, line(), linePos());
                    }

                
                case '"': advance(); return pstring();
                case '\'': advance(); return pchar();

                default: break;
            }

            error(_char);
        }

        return Token(TokenType.EOF, line, linePos);
    }
}