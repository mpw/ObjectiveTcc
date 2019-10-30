//
//  MPWMachOFile.m
//  ObjectiveTcc
//
//  Created by Marcel Weiher on 29.10.19.
//  Copyright © 2019 metaobject. All rights reserved.
//

#import "MPWMachOFile.h"
#import "MPWMachOSegment.h"
#import <mach-o/loader.h>

@import MPWFoundation;

@implementation MPWMachOFile

-(void)dump:(NSData*)machofile
{
    MPWByteStream *s=[MPWByteStream Stdout];
    const struct mach_header_64 *header=[machofile bytes];

    [s printf:@"magic: %x\n",header->magic];
    [s printf:@"is 64 bit with ny endianness: %d\n",header->magic == MH_MAGIC_64];
    [s printf:@"number of load commands: %d\n",header->ncmds];

    [s printf:@"segments:\n"];
    [s writeObject:[self segmentsFor:machofile]];

}

-(NSArray*)segmentsFor:(NSData*)machofile
{
    MPWByteStream *s=[MPWByteStream Stdout];
    const struct mach_header_64 *header=[machofile bytes];
    int numCommands =header->ncmds;
    const struct load_command *command=[machofile bytes] + sizeof *header;
    NSMutableArray *segments=[NSMutableArray array];
    for (int i=0;i<numCommands;i++) {
        int cmd = command->cmd;
        switch ( cmd) {
            case LC_SEGMENT_64:
            {
                [s printf:@"segment 64 length %d\n",command->cmdsize];
                NSRange segmentRange=NSMakeRange((void*)command - [machofile bytes],command->cmdsize);
                MPWMachOSegment *segment=[[MPWMachOSegment alloc] initWithSegmentRange:segmentRange fileData:machofile];
                [segments addObject:segment];
                break;
            }
            case LC_SYMTAB:
            {
                [s printf:@"symtab length %d\n",command->cmdsize];
                break;
            }

            case LC_DYSYMTAB:
            {
               [s printf:@"dsymtab length %d\n",command->cmdsize];
                break;
            }
            case LC_LOAD_DYLINKER:
            {
                [s printf:@"load dynamic linker length %d\n",command->cmdsize];
                break;
            }
            case LC_UUID:
            {
                [s printf:@"UUID length %d\n",command->cmdsize];
                break;
            }

            case LC_LOAD_DYLIB:
            {
                struct dylib_command *dylib=(struct dylib_command*)command;
                char *name=(char*)command;
                int offset=dylib->dylib.name.offset;
                int nameLen=command->cmdsize - offset;
                name+=offset;

                [s printf:@"dynamic library: %*s\n",nameLen,name];
                break;
            }
            case LC_DYLD_INFO_ONLY:
            case LC_DYLD_INFO:
            {
                [s printf:@"dyld info (compressed) library length %d\n",command->cmdsize];
                break;
            }
            case LC_MAIN:
            {
                [s printf:@"LC_MAIN length %d\n",command->cmdsize];
                break;
            }

            case LC_DATA_IN_CODE:
            {
                [s printf:@"data in code %d\n",command->cmdsize];
                break;
            }
            case LC_SOURCE_VERSION:
            {
                [s printf:@"LC_SOURCE_VERSION length %d\n",command->cmdsize];
                break;
            }

            case LC_FUNCTION_STARTS:
            {
                [s printf:@"LC_FUNCTION_STARTS %d\n",command->cmdsize];
                break;
            }
            case LC_BUILD_VERSION: {
                 [s printf:@"LC_BUILD_VERSION %d\n",command->cmdsize];
                 break;
             }
            case LC_ID_DYLIB:
            {
                [s printf:@"LC_ID_DYLIB %d\n",command->cmdsize];
                break;
            }

            case LC_CODE_SIGNATURE:
            {
                [s printf:@"LC_CODE_SIGNATURE %d\n",command->cmdsize];
                break;
            }
            case LC_VERSION_MIN_MACOSX:
            {
                [s printf:@"LC_VERSION_MIN_MACOSX %d\n",command->cmdsize];
                break;
            }




            default:
                [s printf:@"======= command type %x length %d\n",cmd,command->cmdsize];
        }
        command = (struct load_command*)(((char*)command)+command->cmdsize);
    }
    return segments;
}

@end
