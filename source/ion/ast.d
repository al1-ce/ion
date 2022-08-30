module ion.ast;
/* -------------------------------------------------------------------------- */
/*                            Abstract Syntax Tree                            */
/* -------------------------------------------------------------------------- */

import ion.token;

enum AstType {
    // -a +a  // =a
    unaryOp,
    // a+b a-b a*b a/b  // a==b a!=b a>>b a<<b a<b a>b a>=b a<=b
    binOp, 
    // 12 14 1 -2 -5 0 ...
    num, 
    ignore,
}

/** 
 * Dereferences AstNode struct (makes struct from pointer).
 * Params:
 *   ast = Pointer to struct
 * Returns: AstNode struct
 */
AstNode deref(AstNode* ast) {
    return (*cast(AstNode*)(ast));
}

struct AstNode {
    AstType type;
    Token token;

    @disable this();
    
    /** 
     * Creates BinOp node
     * Params:
     *   _left = 
     *   _token = 
     *   _right = 
     */
    this(AstNode* _left, Token _token, AstNode* _right) {
    	token = _token;
        type = AstType.binOp;
        left = _left;
        right = _right;
    }
    
    /** 
     * Creates Num node
     * Params:
     *   _token = 
     *   _value = 
     */
    this(Token _token, int _value) {
    	token = _token;
        type = AstType.num;
        value = _value;
    }
    
    /** 
     * Creates UnaryOp node
     * Params:
     *   _token = 
     *   _expr = 
     */
    this(Token _token, AstNode* _expr) {
    	token = _token;
        type = AstType.unaryOp;
        expr = _expr;
    }
    
    /** 
     * Creates Ignore node
     * Params:
     *   _token = 
     *   _expr = 
     */
    this(Token _token) {
    	token = _token;
        type = AstType.ignore;
    }
    
    union {
        struct {
            AstNode* left;
            AstNode* right;
        }
        struct {
            int value;
        }
        struct {
            AstNode* expr;
        }
    }
}