module ion.token;
import std.conv: to;
// public import std.variant;
// public alias var = Variant;

public const TokenType[string] keywords;
public const string[TokenType] tokenStrings;

/** 
 * Dereferences Token struct (makes struct from pointer).
 * Params:
 *   token = Pointer to struct
 * Returns: Token struct
 */
Token deref(Token* token) {
    return (*cast(Token*)(token));
}

struct Token { 
    public TokenType type = TokenType.NONE;
    
    public size_t line;
    public size_t linePos;

    union { 
        bool blval;

        // byte bval;
        // ubyte ubval;
        // short sval;
        // ushort usval;

        int ival;
        // uint uival;
        // long lval;
        // ulong ulval;

        // float fval;
        // double dval;
        // real rval;

        char cval;
        // wchar wcval;
        // dchar dcval;

        string strval;
    }
    
    @disable this();

    /* ------------------------------ constructors ------------------------------ */

    this(TokenType _type, size_t _line, size_t _pos) {
        type = _type;
        line = _line;
        linePos = _pos;
    }

    this(TokenType _type, bool _value, size_t _line, size_t _pos) {
        type = _type;
        blval = _value;
        line = _line;
        linePos = _pos;
    }

    this(TokenType _type, int _value, size_t _line, size_t _pos) {
        type = _type;
        ival = _value;
        line = _line;
        linePos = _pos;
    }

    this(TokenType _type, char _value, size_t _line, size_t _pos) {
        type = _type;
        cval = _value;
        line = _line;
        linePos = _pos;
    }

    this(TokenType _type, string _value, size_t _line, size_t _pos) {
        type = _type;
        strval = _value;
        line = _line;
        linePos = _pos;
    }

    string toString() const {
        return "Token(" ~ type.to!string ~ ")";
    }

    bool isNone() { return type == TokenType.NONE; }
}

shared static this() { 
    keywords = [
    "true": TokenType.TRUE,
    "false": TokenType.FALSE,
    "null": TokenType.NULL,
    "void": TokenType.VOID,
    "enum": TokenType.ENUM,

    "class": TokenType.CLASS,
    "struct": TokenType.STRUCT,
    "union": TokenType.UNION,

    "this": TokenType.THIS,
    "super": TokenType.SUPER,
    "return": TokenType.RETURN,
    "break": TokenType.BREAK,
    "case": TokenType.CASE,
    "switch": TokenType.SWITCH,

    "if": TokenType.IF,
    "else": TokenType.ELSE,
    "do": TokenType.DO,
    "while": TokenType.WHILE,
    "for": TokenType.FOR,
    "foreach": TokenType.FOREACH,

    "print": TokenType.PRINT
    ];

    tokenStrings = [
        TokenType.EOF: "EOF",
        TokenType.LPAREN: "(",
        TokenType.RPAREN: ")",
        TokenType.LBRACE: "[",
        TokenType.RBRACE: "]",
        TokenType.LBRACKET: "{",
        TokenType.RBRACKET: "}",

        TokenType.PLUS: "+",
        TokenType.MINUS: "-",
        TokenType.STAR: "*",
        TokenType.SLASH: "/",
        TokenType.PERCENT: "%",
        TokenType.TILDE: "~",
        TokenType.BANG: "!",
        TokenType.EQUALS: "=",
        TokenType.LTHEN: "<",
        TokenType.GTHEN: ">",
        TokenType.AMPERSAND: "&",
        TokenType.BAR: "|",
        TokenType.AT: "@",
        TokenType.COLON: ":",
        TokenType.SEMICOLON: ";",
    ];
}

enum TokenType {
    /* --------------------------- initial characters --------------------------- */
    // + - * / % ~ ! 
    PLUS, MINUS, STAR, SLASH, PERCENT, TILDE, BANG, 
    // = < > & | @ :
    EQUALS, LTHEN, GTHEN, AMPERSAND, BAR, AT, COLON,

    /* ---------------------------------- scope --------------------------------- */
    // (), {}, []
    LPAREN, RPAREN, LBRACE, RBRACE, LBRACKET, RBRACKET,
    // ;
    SEMICOLON,
    // :
    CHILDOF,

    /* ------------------------------- operations ------------------------------- */
    // BinOp
    // + - * / % -a +a ~ ^^
    ADD, SUB, MUL, DIV, MOD, NEG, POS, CONCAT, POW,
    // ++ --
    INC, DEC,
    // =
    ASSIGN,
    // BitOp
    // & | ^ << >> >>>
    BITAND, BITOR, XOR, LSHIFT, RSHIFT, URSHIFT,
    // Relation
    // != == <= >= && || ! > < 
    NOTEQ, EQ, GTEQ, LTEQ, AND, OR, NOT, GT, LT, 
    // is !is in !in
    IS, NOTIS, IN, NOTIN,
    // .. ...
    SLICE, // TODO ...

    /* ----------------------------------- oop ---------------------------------- */
    // 
    STRUCT, UNION, CLASS, INTERFACE,
    //
    NEW, OVERRIDE, INVARIANT,
    // 
    THIS, SUPER, // STATICTHIS, 

    /* ------------------------------- attributes ------------------------------- */
    // symbol visibility
    PRIVATE, PUBLIC, PROTECTED, SHARED, STATIC, 
    // symbol state
    CONST, IMMUTABLE, FINAL, MUTABLE,
    //
    ABSTRACT, EXTERN, VIRTUAL,
    // 
    INARG, OUT, REF, INOUT, SCOPE, LAZY,
    // 
    PURE, NOTHROW,
    // @prop
    PROPERTY, 

    /* -------------------------------- functions ------------------------------- */
    //
    RETURN, FUNCTION, TEMPLATE, NORETURN, 

    /* ---------------------------------- types --------------------------------- */
    // numeric types
    INTEGER, FLOAT,
    // string types
    CHAR, STRING,
    // 
    BOOL,
    // other types
    TRUE, FALSE, NULL, VOID, 
    //
    ENUM, AUTO, VAR, DELEGATE, 
    // TODO ptr
    PTR,

    /* ---------------------------------- alias --------------------------------- */
    KEYWORD, ALIAS, // KEYWORDALIAS,

    /* -------------------------------------------------------------------------- */
    // keywords
    PRINT, PRAGMA, MIXIN, 

    /* --------------------------------- modules -------------------------------- */
    IMPORT, MODULE,

    /* ----------------------------- error handling ----------------------------- */
    // 
    THROW, CATCH, FINALLY, ASSERT, CAST, 
    
    /* ------------------------------- statements ------------------------------- */
    // 
    IF, ELSE, DO, WHILE, FOR, FOREACH,
    // 
    BREAK, SWITCH, CASE,
    //
    VERSION, // STATICIF, 

    /* ---------------------------------- meta ---------------------------------- */
    NONE, EOF, IDENTIFIER
}