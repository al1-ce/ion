import std.stdio: writefln, writeln;
import std.getopt: getopt, GetoptResult, config;
import std.array: popFront, join;
import std.file: readText, exists, isFile;
import std.path: buildNormalizedPath, absolutePath;

import ion.repl;
import ion.interpreter;
import sily.getopt;

int main(string[] args) {

    bool doJustCheck = false;
    bool doCompileJS = false;

    GetoptResult helpInfo = getopt(
        args, 
        config.bundling,
        "check|c", "Syntax check without executing.", &doJustCheck,
        "js", "Compile into javascript.", &doCompileJS
    );

    string[] nargs = args.dup;
    nargs.popFront();
    string file = nargs.join();

    if (helpInfo.helpWanted) {
        Commands[] com = [Commands("run", "Runs script")];
        printGetopt("", "ion [options] [script.i] [arguments]", com,helpInfo.options);
        return 0;
    }

    if (file == "") {
        // GOTO repl
        repl();
    } else {
        // read file
        string path = file.buildNormalizedPath.absolutePath;

        if (!path.exists) {
            writefln("Path \"%s\" does not exists.", path);
            return 1;
        }

        if (!path.isFile) {
            writefln("\"%s\" is a directory.", path);
            return 1;
        }

        char[] content = readText!(char[])(path);
        
        EvalReturn ret = Interpreter.staticEval(content);

        if (ret.status == EvalStatus.success) writeln(ret.result);
    }

    return 0;
}