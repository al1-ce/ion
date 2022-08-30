module ion.interpreter;

import std.conv: to;
import std.algorithm: canFind;
import std.stdio: writeln, writef;
import std.format: format;

import ion.ast;
import ion.token;
import ion.parser;
import ion.lexer;

import sily.addons: isOneOf;

class Interpreter {

    private Parser _parser;
    private bool _exceptionCaught = false;

    this(Parser parser) {
        _parser = parser;
    }

    /* ----------------------------- error handling ----------------------------- */

    /** 
     * Prints general syntax error as `0,1: Invalid syntax, message.`
     * Params:
     *   message = Message to show (lowercase, no full stop at end)
     */
    private void error(string message, Token token) {
        // string err = 
        //     "\n%d,%d: Invalid syntax, %s."
        //     .format(_lexer.line + 1, _lexer.linePos + 1, message);
        string err = "\n%d,%d: Illegal operation, %s.".format(token.line + 1, token.linePos, message);
        writeln(err);
        // throw new Exception("Invalid syntax.");
        /* --------------------------- REPLACE EXIT LATER --------------------------- */
        // exit(1);
        exitEval();
    }

    /** 
     * Prints general syntax error as `0,1: Invalid syntax, message.`
     * Params:
     *   message = Message to show (lowercase, no full stop at end)
     */
    private void error(string message) {
        // string err = 
        //     "\n%d,%d: Invalid syntax, %s."
        //     .format(_lexer.line + 1, _lexer.linePos + 1, message);
        string err = "\nIllegal operation, %s.".format(message);
        writeln(err);
        // throw new Exception("Invalid syntax.");
        /* --------------------------- REPLACE EXIT LATER --------------------------- */
        // exit(1);
        exitEval();
    }

    private void exitEval() {
        _exceptionCaught = true;
    }

    public bool errorStatus() {
        return _exceptionCaught || _parser.errorStatus();
    }

    /* ------------------------------- visit logic ------------------------------ */

    private int visit(AstNode node) {
        if (errorStatus()) return 0;
        // writef("%s", node);

        switch (node.type) {
            case AstType.unaryOp: return visitUnaryOp(node);
            case AstType.binOp: return visitBinOp(node);
            case AstType.num: return visitNum(node);
            default: error("unknown op \"%s\"".format(node.type), node.token); exitEval(); return 0;
        }
    }

    private int visitBinOp(AstNode node) {
        writef("(");

        switch (node.token.type) {
            case TokenType.ADD: 
                int left = visit(deref(node.left));
                writef(" + ");
                int right = visit(deref(node.right));
                writef(")");
            return left + right;

            case TokenType.SUB: 
                int left = visit(deref(node.left));
                writef(" - ");
                int right = visit(deref(node.right));
                writef(")");
            return left - right;

            case TokenType.MUL: 
                int left = visit(deref(node.left));
                writef(" * ");
                int right = visit(deref(node.right));
                writef(")");
            return left * right;

            case TokenType.DIV: 
                int left = visit(deref(node.left));
                writef(" / ");
                int right = visit(deref(node.right));
                writef(")");
                if (right == 0) {
                    error("dividing by zero");
                    return 0;
                }
            return left / right;

            case TokenType.MOD: 
                int left = visit(deref(node.left));
                writef(" %% ");
                int right = visit(deref(node.right));
                writef(")");
                if (right == 0) {
                    error("dividing by zero");
                    return 0;
                }
            return left % right;

            case TokenType.POW: 
                int left = visit(deref(node.left));
                writef(" ^^ ");
                int right = visit(deref(node.right));
                writef(")");
            return left ^^ right;
            
            default: 
                error("unknown binary op \"%s\"".format(node.type), node.token);
            return 0;
        }
    }

    private int visitUnaryOp(AstNode node) {
        // writef("%s\n", node);
        // writef("%s\n", deref(node.expr));
        switch (node.token.type) {
            case TokenType.POS: 
                writef("+");
                int val = visit(deref(node.expr));
            return +val;

            case TokenType.NEG: 
                writef("-");
                int val = visit(deref(node.expr));
            return -val;

            case TokenType.NOT: 
                // FIXME add parser for that
                // LINK https://craftinginterpreters.com/evaluating-expressions.html#truthiness-and-falsiness
                writef("!");
                int val = visit(deref(node.expr));
                if (val != 0) val = 0; else val = 1;
            return val;
            
            default: 
                error("unknown unary op \"%s\"".format(node.token.type), node.token);
            return 0;
        }
    }

    private int visitNum(AstNode node) {
        writef("%d", node.value);
        return node.value;
    }

    /* ---------------------------- general interface --------------------------- */

    public EvalReturn eval() {
        AstNode tree = _parser.parse();
        if (errorStatus) { return EvalReturn(EvalStatus.fail, 0); }
        writef("Expr: ");
        int result = visit(tree); 
        writeln();

        if (errorStatus()) {
            return EvalReturn(EvalStatus.fail, 0);
        } else {
            return EvalReturn(EvalStatus.success, result);
        }
    }

    public static EvalReturn staticEval(char[] p_text) {
        Interpreter intp = new Interpreter(new Parser(new Lexer(p_text)));
        // int res = intp.eval();
        EvalReturn ret = intp.eval();

        return ret;
    }
}

struct EvalReturn {
    EvalStatus status;
    int result;
}

enum EvalStatus {
    success, fail
}