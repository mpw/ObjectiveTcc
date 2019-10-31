//
//  TinyCCompiler.m
//  ObjectiveTcc
//
//  Created by Marcel Weiher on 29.10.19.
//  Copyright © 2019 metaobject. All rights reserved.
//

#import "TinyCCompiler.h"
#include "tcc.h"

@import ObjectiveC;

@implementation TinyCCompiler {
    TCCState *s;
}

-(instancetype)init
{
    if (nil != (self=[super init])) {
        s=tcc_new();
        [self addPointer:objc_msgSend forCSymbol:"objc_msgSend"];
        [self addPointer:sel_getUid forCSymbol:"sel_getUid"];

    }
    return self;
}

-(void)addPointer:(void*)aPointer forCSymbol:(char*)symbol
{
    tcc_add_symbol(s, symbol, aPointer);
}

-(void)addPointer:(void*)aPointer forSymbol:(NSString*)symbol
{
    [self addPointer:aPointer forCSymbol:[symbol UTF8String]];
}

-(void)compile:(NSString*)programText
{
    tcc_set_output_type(s,TCC_OUTPUT_MEMORY);
    s->nostdlib=1;
//    programText = [@"#define __GNUC__ 7\n" stringByAppendingString:programText];
    tcc_add_sysinclude_path( s, "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include");
    tcc_compile_string(s, [programText UTF8String]);
}

-(void)relocate
{
    tcc_relocate(s ,TCC_RELOCATE_AUTO);
}

-(long)run
{
    char *args[]={ "hello","", NULL};
    long retval=tcc_run(s, 1, args);
    return retval;
}

-(long)run:(NSString*)name
{
    return [self run:name arg:0];
}


-(long)run:(NSString*)name arg:(long)arg
{
    return [self run:name object:(void*)arg selector:NULL];
 }

-(long)run:(NSString*)name object:(void*)anObject selector:(SEL)selector {
    long (*func)(void*,SEL);
    long retval=0;
    func=tcc_get_symbol(s, [name UTF8String]);
    if (func) {
        retval=func(anObject,selector);
    }
    return retval;
}


-(long)compileAndRun:(NSString*)programText
{
    [self compile:programText];
    return [self run];
}

-(void)dealloc
{
    tcc_delete(s);
}

@end

#import <MPWFoundation/DebugMacros.h>

@implementation TinyCCompiler(testing)


+(void)testBasicCompileAndRun
{
    TinyCCompiler* tcc=[TinyCCompiler new];
    [tcc compile:@"int _start() {  return 41; }"];
    INTEXPECT([tcc run], 41, @"run result");
}

+(void)testCompileAndRunNamedFun
{
    TinyCCompiler* tcc=[TinyCCompiler new];
    [tcc compile:@"int myFun() {  return 522; }"];
    [tcc relocate];
    INTEXPECT([tcc run:@"myFun"], 522, @"run result");
}

static SEL lenSel() {
    return @selector(length);
}

static int fourfive() {
    return 45;
}

+(void)testCompileAndRunNamedFunWithArg
{
    TinyCCompiler* tcc=[TinyCCompiler new];
    [tcc compile:@"int times3(int arg) {  return arg*3; }"];
    [tcc relocate];
    INTEXPECT([tcc run:@"times3" arg:12], 36, @"run result");
}

+(void)testCompileAndRunAMessageSend
{
    TinyCCompiler* tcc=[TinyCCompiler new];
    [tcc compile:@"extern int objc_msgSend(void*,void*); int sendMsg(void *obj, void *sel) {  return objc_msgSend( obj, sel); }"];
    [tcc relocate];
    INTEXPECT([tcc run:@"sendMsg" object:@"Hello World" selector:@selector(length)], 11, @"msg send result");
}

+(void)testCompileAndRunAMessageSendWithBuildinSelector
{
    TinyCCompiler* tcc=[TinyCCompiler new];
    [tcc addPointer:fourfive forCSymbol:"fourfive"];
    [tcc addPointer:lenSel forCSymbol:"lenSel"];
    SEL lensel=@selector(length);
    [tcc addPointer:&lensel forCSymbol:"lenSel1"];
    [tcc compile:@"extern void *lenSel(); extern void *lenSel1; extern int objc_msgSend(void*,void*); long sendlen(void *obj) {  return objc_msgSend( obj,lenSel1); }"];
    [tcc relocate];
    INTEXPECT([tcc run:@"sendlen" object:@"Hello Cruel World" selector:NULL], 17, @"msg send result");
}



+testSelectors
{
    return @[
        @"testBasicCompileAndRun",
        @"testCompileAndRunNamedFun",
        @"testCompileAndRunNamedFunWithArg",
        @"testCompileAndRunAMessageSend",
        @"testCompileAndRunAMessageSendWithBuildinSelector",
    ];
}

@end
