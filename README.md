# Ion (NOT READY TO USE. CURRENTLY IN PRE-ALPHA STAGES)
A simple c-style interpreted programming language

# Ion language specification

File extension: `.i` or `.ion` (i.e `helloworld.i` or `helloworld.ion`)

## Example code:
Hello world:
```D
import std.stdio: writeln;

void main() {
    writeln("hello world");
}
```

or:

```D
import std.stdio: writeln;

writeln("hello world");
```


Type mix:
```D
import std.type: var;
import std.stdio;

alias println = writeln;

function add(int a, var b) {
    return a + b;
}

println(add(3, "2"));

if (true) {
    println(true.toString);
}

/* Expected result:
 * 5
 * true
 */
```

## Definition
Ion is an interpreted scripting languade written in D. Main points of Ion are:
- Dynamic typing (with ability to inforce certain types by writing `type` instead of `var`)
- Familliar syntax to such languages as: c, c++, c#, d, java, javion, typescript
- Acessibility in tearms of definitions (i.e. `var count: number`, `var count`, `var count: int` and `int count` are all valid definitions of a variable). Which allows for broader appeal
- Powerful alias system that allows for overloading function names `alias a = b;`, variable names, types  (`alias let = std.type.var;`), imports (`import io = std.stdio;`) and keywords (`keyword alias fn = function;`)

## Keywords:
```d
void
int
bool
char
real
double
float
keyword
alias
true
false
```
## Types
#### Numeric:
`int`, `float`, `double`, `real`
#### String:
`string`, `char`
#### Boolean:
`bool`
#### Other:
`void`, `var`

## Aliases

#### Basic aliases
Basic alias create a name that refers to another symbol.

##### Examples:
Type alias:
```d
alias mytype = proj.types.StructType;
alias i = int;
```

Method alias:
```d
void doStuff() {}
alias ds = doStuff;
```

Template alias:
```d
void doTempl(T)() {}
alias t1 = doTempl!(int);
```

Variable alias:
```d
int d = 0;
alias id = d;
```

#### Keyword aliases
Keyword alias must be a statement, attribute, keyword or sum of all above. It cannot be expression and will not behave like macro.

##### Examples:
Variant type aliases, defined in core.styles.js:
```d
keyword alias var = public core.type.variant;
keyword alias let = private core.type.variant;
keyword alias constructor = this;
```
Or TS style in core.styles.ts:
```d
keyword alias number = float;
keyword alias boolean = bool;
```

Rust-like code, defined in core.styles.rust:
```d
keyword alias fn = function; // function serves two purposes. Declaration & pointers
keyword alias let = immutable core.type.variant;
keyword alias mut = mutable;
keyword alias var = mut core.type.variant;
keyword alias i8 = byte;
...
keyword alias i64 = long;
keyword alias str = string;
keyword alias mod = module;
keyword alias imp = import; // you need that too
keyword alias pub = public;
keyword alias priv = private; // removed from rust but necessary here
keyword alias self = this;
```
Which produces:
```rust
// module.i
mod hello_sayer;

priv fn private_print(text: str) {
    print(str);
}

pub fn public_print(text: str, num: i32) {
    private_print(text);
    println(num);
}
```
```rust
// main.i
imp module;

fn main() {
    let i: i8 = 1;
    var num: i32 = 42;
    num += i;
    // private_print("Throws error because it's visible only in module");
    public_print("Hello world ", num); // prints "Hello world 43"
}
```
Not exactly one to one conversion, but still a nice transition.
