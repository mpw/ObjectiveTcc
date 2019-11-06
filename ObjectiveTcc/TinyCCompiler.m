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

-(void)addPointer:(void*)aPointer forCSymbol:(const char*)symbol
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
//    NSLog(@"will compile: %@",programText);
    tcc_compile_string(s, [programText UTF8String]);
}

extern int local_scope,section_sym;

-(void)beginGeneratingCode
{
    tcc_set_output_type(s,TCC_OUTPUT_MEMORY);
    s->nostdlib=1;
    tccelf_begin_file(s);

    cur_text_section = text_section;
    funcname = "";
    anon_sym = SYM_FIRST_ANOM;
    section_sym = 0;
    const_wanted = 0;
    nocode_wanted = 0x80000000;
    local_scope = 0;

    /* define some often used types */
    int_type.t = VT_INT;
    char_pointer_type.t = VT_BYTE;
    mk_pointer(&char_pointer_type);
    size_type.t = VT_LONG | VT_LLONG | VT_UNSIGNED;
    //        ptrdiff_type.t = VT_LONG | VT_LLONG;

    func_old_type.t = VT_FUNC;
    func_old_type.ref = sym_push(SYM_FIELD, &int_type, 0, 0);
    func_old_type.ref->f.func_call = FUNC_CDECL;
    func_old_type.ref->f.func_type = FUNC_OLD;
    nocode_wanted = 0;
    ind = cur_text_section->data_offset;
    if (YES) {
        size_t newoff = section_add(cur_text_section, 0,
                                    1 << 4);
        gen_fill_nops(newoff - ind);
    }
#ifdef TCC_TARGET_ARM
    arm_init(s1);
#endif

#ifdef INC_DEBUG
    printf("%s: **** new file\n", file->filename);
#endif
}

-(void)generateFunctionEpilogue:(Sym*)sym
{
    gv(RC_IRET);
    gsym(rsym);
    nocode_wanted = 0;
    gfunc_epilog();
    cur_text_section->data_offset = ind;
    /* reset local stack */
    sym_pop(&local_stack, NULL, 0);
    local_scope = 0;
    label_pop(&global_label_stack, NULL, 0);
    //    sym_pop(&all_cleanups, NULL, 0);
    /* patch symbol size */
    elfsym(sym)->st_size = ind - func_ind;
    /* end of function */
    tcc_debug_funcend(tcc_state, ind - func_ind);
    /* It's better to crash than to generate wrong code */
    cur_text_section = NULL;
    funcname = ""; /* for safety */
    func_vt.t = VT_VOID; /* for safety */
    func_var = 0; /* for safety */
    ind = 0; /* for safety */
    nocode_wanted = 0x80000000;
    //    check_vstack();
    tccelf_end_file(s);
//    NSLog(@"end compile function %s",get_tok_str(sym->v, NULL));
}

-(void)functionProlog:(char*)name symbolStorage:(Sym*)sym returnType:(int)returnType argTypes:(char*)typeString
{
//    NSLog(@"function: '%s'",name);
    TokenSym *tokenSym = tok_alloc( name, (int)strlen(name));
//    AttributeDef *ad=NULL;
    sym->v = tokenSym->tok;
    sym->type.t = VT_FUNC;
    Sym fTypeSym={0};
    fTypeSym.type.t=returnType;
    fTypeSym.f.func_type=0;         // not a vararg function
    Sym *fTypeSymRef=&fTypeSym;
    Sym *cur=fTypeSymRef;
    for (long i=0,max=strlen(typeString); i<max;i++) {
        char objcType=typeString[i];
        switch (objcType) {
            case 'i':
            {
                CType type;
                type.t=VT_INT;
                Sym *arg_sym=calloc(1, sizeof *arg_sym);
                arg_sym->type=type;
                arg_sym->v = anon_sym++;
                cur->next = arg_sym;
                cur=arg_sym;
            }
                break;
            default:
                [NSException raise:@"invalidtypestring" format:@"unhandled objc type '%c' at position %d of typestring %s",objcType,i,typeString];
                break;
        }
    }

    //        tcc_debug_start(s);

    /* Initialize VLA state */
    //    struct scope f = { 0 };
    //    cur_scope = root_scope = &f;

    /* NOTE: we patch the symbol size later */


    put_extern_sym(sym, cur_text_section, ind, 0);

//    if (ad && ad->a.constructor) {
//        add_init_array (tcc_state, sym);
//    }
//    if (ad && ad->a.destructor) {
//        add_fini_array (tcc_state, sym);
//    }

    funcname = get_tok_str(sym->v, NULL);
    func_ind = ind;

    /* put debug symbol */
    tcc_debug_funcstart(tcc_state, sym);
    /* push a dummy symbol to enable local sym storage */
    sym_push2(&local_stack, SYM_FIELD, 0, 0);
    local_scope = 1; /* for function parameters */
    sym->type.ref = fTypeSymRef;

    gfunc_prolog(&sym->type);       // these might be the parameters? (type is the arg-types?)

    //    local_scope = 0;
    rsym = 0;
    clear_temp_local_var_list();
}


-(void)pushInt:(long)value
{
    CType type;
    type.t = VT_PTR;
    CValue tokc;
    tokc.i=value;
    vsetc(&type, VT_CONST, &tokc);
}

-(void)pushObject:(id)value
{
    CType type;
    type.t = VT_PTR;
    CValue tokc;
    tokc.i=(long)value;
    vsetc(&type, VT_CONST, &tokc);
}

-(void)pushPointer:(void*)value
{
    CType type;
    type.t = VT_PTR;
    CValue tokc;
    tokc.i=(long)value;
    vsetc(&type, VT_CONST, &tokc);
}

-(void)pushFunctionPointer:(void*)value
{
    CType type;
    type.t = VT_FUNC;
    Sym s;
    s.f.func_type=FUNC_NEW;
    type.ref = &s;
    s.type.t=VT_PTR;
    s.next=NULL;
    CValue tokc;
    tokc.i=(long)value;
    vsetc(&type, VT_CONST, &tokc);
}


-(void)pushFunctionArg:(int)which
{
    which++;
    CType type;
    type.t = VT_INT;
    CValue tokc;
    tokc.i=-8 * which;

    vsetc(&type, VT_LOCAL | VT_LVAL, &tokc);
}

-(void)genOp:(int)theOp
{
    gen_op(theOp);
}

-(void)call:(int)numArgs
{
    gfunc_call(numArgs);
}


typedef void (^voidBlock)(void);

-(void)functionWithName:(char*)name returnType:(int)tccReturnType argTypes:(char*)objcTypeString body:(voidBlock)bodyBlock
{
    Sym theSym={0};
    [self beginGeneratingCode];
    [self functionProlog:name symbolStorage:&theSym returnType:tccReturnType argTypes:objcTypeString];
    bodyBlock();
    [self generateFunctionEpilogue:&theSym];
    [self relocate];
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
    } else {
        [NSException raise:@"notfound" format:@"function with name %@ not found",name];
    }
    return retval;
}

-(long)run:(NSString*)name sender:(void*)sender object:(void*)anObject selector:(SEL)selector {
    long (*func)(void*,void*,SEL);
    long retval=0;
    func=tcc_get_symbol(s, [name UTF8String]);
    if (func) {
        retval=func(sender,anObject,selector);
    } else {
        [NSException raise:@"notfound" format:@"function with name %@ not found",name];
    }
    return retval;
}

-(id)objRun:(NSString*)name object:(void*)anObject selector:(SEL)selector {
    id (*func)(void*,SEL);
    id retval=nil;
    func=tcc_get_symbol(s, [name UTF8String]);
    if (func) {
        retval=func(anObject,selector);
    } else {
        [NSException raise:@"notfound" format:@"function with name %@ not found",name];
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
    [tcc compile:@"int myFun(void) {  return 522; }"];
    [tcc relocate];
    INTEXPECT([tcc run:@"myFun"], 522, @"run result");
}


+(void)testCompileAndRunNamedFunWithArg
{
    TinyCCompiler* tcc=[TinyCCompiler new];
    [tcc compile:@"int times3(int arg,int arg2) {  return arg*3; }"];
    [tcc relocate];
    INTEXPECT([tcc run:@"times3" arg:12], 36, @"run result");
}

+(void)testCompileAndRunAMessageSend
{
    TinyCCompiler* tcc=[TinyCCompiler new];
    [tcc compile:@"extern int objc_msgSend(void* ,void*); int sendMsg(void *obj, void *sel) {  return objc_msgSend( obj, sel); }"];
    [tcc relocate];
    INTEXPECT([tcc run:@"sendMsg" object:@"Hello World" selector:@selector(length)], 11, @"msg send result");
}

+(void)testCompileAndRunAMessageSendViaPtr
{
    TinyCCompiler* tcc=[TinyCCompiler new];
    [tcc compile:@"typedef int (*senderFun)(void* ,void*); int sendMsg(senderFun sender,void *obj, void *sel) {  return sender( obj, sel); }"];
    [tcc relocate];
    INTEXPECT([tcc run:@"sendMsg" sender:(void*)objc_msgSend object:@"Hello World" selector:@selector(length)], 11, @"msg send result");
}

+(void)testCompileAndRunAMessageSendWithBuiltinSelector
{
    TinyCCompiler* tcc=[TinyCCompiler new];
    SEL lensel=@selector(length);
    [tcc addPointer:&lensel forCSymbol:"lenSel"];
    [tcc compile:@"extern void *lenSel; extern int objc_msgSend(void* obj,void* msg); long sendlen(void *obj) {  return objc_msgSend( obj,lenSel); }"];
    [tcc relocate];
    INTEXPECT([tcc run:@"sendlen" object:@"Hello Cruel World" selector:NULL], 17, @"msg send result");
}

+(void)testCompileFunctionReturningConstantViaAPI
{
    TinyCCompiler* tcc=[TinyCCompiler new];
    [tcc functionWithName:"constTestFun" returnType:VT_INT argTypes:"i" body:^{
        [tcc pushInt:49];
    }];
    INTEXPECT([tcc run:@"constTestFun"], 49, @"constant fun");
}


+(void)testCompileFunctionReturningItsArgumentViaAPI
{
    TinyCCompiler* tcc=[TinyCCompiler new];
    [tcc functionWithName:"idTestFun" returnType:VT_INT argTypes:"i" body:^{
        [tcc pushFunctionArg:0];
    }];
    INTEXPECT([tcc run:@"idTestFun" arg:23], 23, @"function returns its arg");
    INTEXPECT([tcc run:@"idTestFun" arg:22], 22, @"function returns its arg");
}


+(void)testCompileFunctionAddingConstantToArgumentViaAPI
{
    TinyCCompiler* tcc=[TinyCCompiler new];
    [tcc functionWithName:"addFun" returnType:VT_INT argTypes:"i" body:^{
        [tcc pushInt:10];
        [tcc pushFunctionArg:0];
        [tcc genOp:'+'];
    }];
    INTEXPECT([tcc run:@"addFun" arg:13], 23, @"function returns its arg");
    INTEXPECT([tcc run:@"addFun" arg:120], 130, @"function returns its arg");
}

+(void)testReturnObject
{
    TinyCCompiler* tcc=[TinyCCompiler new];
    NSString *testObj=@"hi there";
    [tcc functionWithName:"objReturnFun" returnType:VT_PTR argTypes:"" body:^{
        [tcc pushObject:testObj];
    }];
    IDEXPECT([tcc objRun:@"objReturnFun" object:nil selector:NULL], testObj, @"function returns its arg");
}
static int flag=0;
void setFlag() {
    flag=1;
}


+(void)testGenerateCallWithoutArgs
{
    TinyCCompiler* tcc=[TinyCCompiler new];
    [tcc functionWithName:"setFlagFun" returnType:VT_VOID argTypes:"" body:^{
        [tcc pushFunctionPointer:setFlag];
        [tcc call:0];
    }];
    EXPECTFALSE(flag, @"fun not called yet");
    [tcc run:@"setFlagFun" object:nil selector:NULL];
    EXPECTTRUE(flag, @"fun got called");
}

+testSelectors
{
    return @[
        @"testBasicCompileAndRun",
        @"testCompileAndRunNamedFun",
        @"testCompileAndRunNamedFunWithArg",
        @"testCompileAndRunAMessageSend",
        @"testCompileAndRunAMessageSendViaPtr",
        @"testCompileAndRunAMessageSendWithBuiltinSelector",
        @"testCompileFunctionReturningConstantViaAPI",
        @"testCompileFunctionReturningItsArgumentViaAPI",
        @"testCompileFunctionAddingConstantToArgumentViaAPI",
        @"testReturnObject",
        @"testGenerateCallWithoutArgs",
    ];
}

@end
