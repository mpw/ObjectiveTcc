//
//  TinyCCompiler.m
//  ObjectiveTcc
//
//  Created by Marcel Weiher on 29.10.19.
//  Copyright © 2019 metaobject. All rights reserved.
//

#import "TinyCCompiler.h"
#include "tcc.h"

@implementation TinyCCompiler

-(int)compileAndRun:(NSString*)programText
{
    TCCState *s=tcc_new();
    char *args[]={ "hello","", NULL};
    s->output_type = TCC_OUTPUT_MEMORY;
    s->nostdlib=1;
//    programText = [@"#define __GNUC__ 7\n" stringByAppendingString:programText];
    tcc_add_sysinclude_path( s, "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include");
    tcc_compile_string(s, [programText UTF8String]);
    int retval=tcc_run(s, 1, args);
    tcc_delete(s);
    return retval;
}


@end
