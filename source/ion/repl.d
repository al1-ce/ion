module ion.repl;

import std.stdio;
import std.conv: to;
import std.array: popBack, popFront, join;
import std.algorithm: max;
import core.thread.osthread;
import core.time;

import core.stdc.stdlib: exit;

import ion.interpreter;

version (Posix) {
    import core.sys.posix.signal;
}

version (Windows) {
    import core.sys.windows.windows;
}

// private __gshared const string _exitPrompt = "To exit, press Ctrl+C again or Ctrl+D or type .exit\n";
private __gshared const string _exitPrompt = "Exiting.\n";

// console look: //
// Ion v0.0.1 (main, 6 aug 2022, 22:29:12)
// Type ".help" for more information.
// >
// help options:
// .break .clear .editor .exit .help .load .save

version (Posix) {
    extern (C) void linSigintHandler(int signal) nothrow {
        printf("%s", _exitPrompt.ptr);
        // printf("SIG: %d\n", signal);
        exit(0);
    }
}

version (Windows) {
    extern (Windows) BOOL winSigintHandler(DWORD crtlType) nothrow @system {
    // BOOL winSigintHandler(DWORD crtlType) {
        switch (crtlType) {
            case CTRL_C_EVENT:
                printf("%s", _exitPrompt.ptr);
                // printf("Ctrl-C event\n");
                exit(0);
                // return TRUE; // true - program handled the signal
            
            case CTRL_BREAK_EVENT:
                // printf("To exit, press Ctrl+C again or Ctrl+D or type .exit\n");
                printf("Ctrl-Break event\n");
                return TRUE; // true - program handled the signal

            case CTRL_CLOSE_EVENT:
                // printf("To exit, press Ctrl+C again or Ctrl+D or type .exit\n");
                printf("Ctrl-Close event\n");
                return TRUE; // true - program handled the signal

            default:
                return FALSE; // false - call default handlers
        }
    }
}

const string _ver = "v0.0.1";
const string _branch = "main";
const string _date = "6 aug 2022";
const string _time = "22:29:12";

__gshared ubyte isLastInterrupt = 0;

int repl() {

    version (Posix) {
        sigaction_t sigIntHandler;
        sigIntHandler.sa_handler = &linSigintHandler;
        sigemptyset(&sigIntHandler.sa_mask);
        sigIntHandler.sa_flags = 0;

        sigaction(SIGINT, &sigIntHandler, null);
        writeln("Version: Posix");
    }

    version (Windows) {
        SetConsoleCtrlHandler(&winSigintHandler, true);
        writeln("Version: Windows");
    }

	writefln("Ion %s (%s, %s, $s)", _ver, _branch, _date, _time);
    writefln("Type \".help\" for more information.");
    char[] expr = " ".dup;
    // auto ch = input.getch(true);
    // term.writeln("You pressed ", ch, " ", ch.to!int, " ", " ", (ch == 4)); // ctrl+d == 4
    // ctrl + d = 4
    // enter = 10
    // term.writeln(term.stdinIsTerminal);
    
    while (true) {
        // if (expr != "") 
        writef("> ");
        readln(expr);
        if (expr.length != 0) { 
            expr.popBack(); 
        } else {
            // TODO detect ctrl+d
            // if (!isLastInterrupt) {
            //     writeln();
            //     break;
            // }
        }
        // writeln(expr);

        if (expr == ".exit") break;
        if (expr == ".help") {printReplHelp(); continue;}
        if (expr == "") {writeln(); continue;}
        // if (isLastInterrupt && expr != "") isLastInterrupt = false;

        EvalReturn ret = Interpreter.staticEval(expr);
        if (ret.status == EvalStatus.success) writeln(ret.result);
    }

    return 0;
}

void printReplHelp() {
    string[] coms = [".exit", ".help"];
    string[] expl = ["Exit the REPL.", "Prints this help message."];

    int maxLen = 0;

    foreach (it; coms) {
        maxLen = max(maxLen, it.length).to!int;
    }

    for (int i = 0; i < coms.length; i ++) {
        writefln(" %-*s  %s", maxLen, coms[i], expl[i]);
    }
}