module ion.lexer;

import std.string: isNumeric;
import std.conv: to, parse;
import std.stdio: writeln;
import std.format: format;
import std.uni: isSpace, isWhite;
import std.algorithm: canFind;

import ion.token;
import sily.addons: isAlpha, isAlphaNumeric, isDigit, isOneOf, isHex, isOct;

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
        string result;
        TokenType type = TokenType.INT;
        int base = 10;

        // check if number is hex
        if (isDigit(_char) && isOneOf!char(peek(), 'x', 'X')) {
            base = 16;
            advance(); advance(); // eat 0x
            while ( isHex(_char)  && !_isEOF ) {
                result ~= _char;
                advance();
            }
        } else
        // check if number is binary
        if (isDigit(_char) && isOneOf!char(peek(), 'b', 'B')) {
            base = 2;
            advance(); advance(); // eat 0b
            while ( (_char == '0' || _char == '1')  && !_isEOF ) {
                result ~= _char;
                advance();
            }
        } else {
            while ( isDigit(_char) && !_isEOF ) {
                result ~= _char;
                advance();
            }

            // if type is float, double or real
            // at first assume double
            if (lookAt('.') && isDigit(peek())) {
                type = TokenType.DOUBLE;
                result ~= _char;
                advance();

                while ( isDigit(_char) && !_isEOF ) {
                    result ~= _char;
                    advance();
                }
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
            // check if type is unsigned
            if (isOneOf!char(_char, 'u', 'U')) {
                advance(); // eat U
                // check if type is long
                if (isOneOf!char(_char, 'l', 'L')) {
                    advance(); // eat L
                    type = TokenType.ULONG;
                } else {
                    error("\'" ~ _char ~ "\' suffix is not allowed");
                }
            } else 
            if (isOneOf!char(_char, 'f', 'F')) {
                advance(); // eat F
                type = TokenType.FLOAT;
            } else 
            if (isOneOf!char(_char, 'l', 'L')) {
                advance(); // eat L
                type = TokenType.LONG;
            }
        }

        return Token(type, parse!(int, string)(result, base), _currentLine, _currentLinePos);
    }

    private Token pstring() {
        string result = "";
        // TODO escape sequences 
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

        if (lookAt('\'') || _isEOF) {
            error("unterminated character constant");
        } else
        // TODO put escape sequences in own method
        // start escape sequence
        if (lookAt('\\')) {
            advance(); // eat \
            if (_char == '0' && lookAt('\'')) { result = '\0'; advance(); }
            if (_char == 'a') { result = '\a'; advance(); }
            if (_char == 'b') { result = '\b'; advance(); }
            if (_char == 'f') { result = '\f'; advance(); }
            if (_char == 'n') { result = '\n'; advance(); }
            if (_char == 'r') { result = '\r'; advance(); }
            if (_char == 't') { result = '\t'; advance(); }
            if (_char == 'v') { result = '\v'; advance(); }
            if (_char == '\\') { result = '\\'; advance(); }
            if (_char == '\'') { result = '\''; advance(); }
            if (_char == '\"') { result = '\"'; advance(); }
            if (_char == '\?') { result = '\?'; advance(); }

            if (isOct(_char)) { // \nnn octal number
                string octs = "\\";
                for (int i = 0; i < 3; i ++) {
                    octs ~= _char;
                    advance();
                    if (lookAt('\'')) break;
                    if (!isOct(_char)) {
                        error("unexpected character in octal sequence");
                        octs = "\\000";
                    }
                }
                result = parse!(char, string)(octs);
            }

            if (_char == 'x') { // \xhh...
                string hex = "\\x";
                advance(); // eat x
                // expect first hex and loop until it's not
                if (isHex(_char)) {
                    hex ~= _char; advance();
                    while (isHex(_char) && !_isEOF) {
                        hex ~= _char; advance();
                    }
                } else {
                    error("unexpected character in hex sequence");
                    hex = "\\x0";
                }
                result = parse!(char, string)(hex);
            }

            if (_char == 'u' || _char == 'U') { // \uhhhh or \Uhhhhhhhh
                string uni = "\\u";
                byte n = _char == 'u' ? 4 : 8;
                advance(); // eat U
                // expect 4 or 8 hex
                for (int i = 0; i < n; i ++) {
                    if (_isEOF) {
                        error("unterminated character constant");
                        uni = "\\u0000";
                        break;
                    }
                    if (!isHex(_char)) {
                        error("escape hex sequence has " ~ (i + 1).to!string ~ " hex digits instead of " ~ n.to!string);
                        uni = "\\u0000";
                        break;
                    }
                    uni ~= _char;
                    advance();
                }
                result = parse!(char, string)(uni);
            }
        } else {
            // expect one char
            result = _char;
            advance(); // eat char
        }

        if (!lookAt('\'') || _isEOF) {
            error("character constanct has multiple characters");
        } else {
            // remove closing '
            advance();
        }


        return Token(TokenType.CHAR, result, _currentLine, _currentLinePos);
    }

    private Token comment() {
        if (lookAt('/')) { // comment //
            advance(); // consume /
            while (!_isEOF) {
                // scanning for \n here because otherwise
                // it's not going to detect \n in while(\n)
                // and line number will be incorrect
                if (lookAt('\n')) { 
                    newLine();
                    advance();
                    break; 
                }
                advance();
            }
        } else
        if (lookAt('*')) { // comment /* */
            advance(); // consume *
            while (!(lookAt('*') && peekAt('/')) && !_isEOF) {
                if (lookAt('\n')) {
                    newLine();
                }
                advance();
            }
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
                    return Token(TokenType.SLASH, line(), linePos());
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