# ObjectiveTcc

[Tinycc](https://bellard.org/tcc/) as an Objective-C framework.  The goal is a compact/fast code-generator for [Objective-Smalltalk](http://objective.st).

# Steps

This is a rough overview.

1. Package as framework
2. Mach-O writer
3. Generate code without C source code
4. Objective-C message sending


# Progress

1. Available as a framework, with in-process tests
2. Callable from Objective-Smalltalk
3. Starts of a Mach-O reader (needed to verify any writer)
4. Sent an Objective-C message from TCC generated codee (via objc_msgSend() )
5. Generated/called an empty  without any C source code, just by calling the codegen functions within TCC.


# Up next


1. Factor the code-gen and enable more functionality (arguments, arithmeetic, ...)
2. Disentangle output generation from ELF-specifics if necessary
3. Write Mach-O with canned data
4. Hook up TCC codegen to Mach-O writer

# Background/Motivation

I have an LLVM-based code-generation [backend](https://github.com/mpw/Objective-Smalltalk/tree/master/ObjSTNative), but LLVM is way too cumbersome, with long compile-times, gigantic binaries, C++ etc.

In addition, all the sophisticated machinery is almost certainly of little or no benefit for Objective-Smalltalk.
