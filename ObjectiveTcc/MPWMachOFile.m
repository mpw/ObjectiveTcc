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

@implementation MPWMachOFile

-(void)dump:(NSData*)machofile
{
    const struct mach_header_64 *header=[machofile bytes];
    printf("magic: %x\n",header->magic);
    printf("is 64 bit with ny endianness: %d\n",header->magic == MH_MAGIC_64);
    printf("number of load commands: %d\n",header->ncmds);
    NSArray *segments=[self segmentsFor:machofile];
    printf("segments: %s\n",[[segments description] UTF8String]);
}

-(NSArray*)segmentsFor:(NSData*)machofile
{
    const struct mach_header_64 *header=[machofile bytes];
    int numCommands =header->ncmds;
    const struct load_command *command=[machofile bytes] + sizeof *header;
    NSMutableArray *segments=[NSMutableArray array];
    for (int i=0;i<numCommands;i++) {
        int cmd = command->cmd;
        switch ( cmd) {
            case LC_SEGMENT_64:
            {
                printf("segment 64 length %d\n",command->cmdsize);
                NSRange segmentRange=NSMakeRange((void*)command - [machofile bytes],command->cmdsize);
                MPWMachOSegment *segment=[[MPWMachOSegment alloc] initWithSegmentRange:segmentRange fileData:machofile];
                [segments addObject:segment];
                break;
            }
            case LC_SYMTAB:
            {
                printf("symtab length %d\n",command->cmdsize);
                break;
            }

            case LC_DYSYMTAB:
            {
                printf("dsymtab length %d\n",command->cmdsize);
                break;
            }
            case LC_LOAD_DYLINKER:
            {
                printf("load dynamic linker length %d\n",command->cmdsize);
                break;
            }
            case LC_UUID:
            {
                printf("UUID length %d\n",command->cmdsize);
                break;
            }

            case LC_LOAD_DYLIB:
            {
                struct dylib_command *dylib=(struct dylib_command*)command;
                char *name=(char*)command;
                int offset=dylib->dylib.name.offset;
                int nameLen=command->cmdsize - offset;
                name+=offset;

                printf("dynamic library: %*s\n",nameLen,name);
                break;
            }
            case LC_DYLD_INFO_ONLY:
            case LC_DYLD_INFO:
            {
                printf("dyld info (compressed) library length %d\n",command->cmdsize);
                break;
            }
            case LC_MAIN:
            {
                printf("LC_MAIN length %d\n",command->cmdsize);
                break;
            }

            case LC_DATA_IN_CODE:
            {
                printf("data in code %d\n",command->cmdsize);
                break;
            }
            case LC_SOURCE_VERSION:
            {
                printf("LC_SOURCE_VERSION length %d\n",command->cmdsize);
                break;
            }

            case LC_FUNCTION_STARTS:
            {
                printf("LC_FUNCTION_STARTS %d\n",command->cmdsize);
                break;
            }
            case LC_BUILD_VERSION: {
                 printf("LC_BUILD_VERSION %d\n",command->cmdsize);
                 break;
             }
            case LC_ID_DYLIB:
            {
                printf("LC_ID_DYLIB %d\n",command->cmdsize);
                break;
            }

            case LC_CODE_SIGNATURE:
            {
                printf("LC_CODE_SIGNATURE %d\n",command->cmdsize);
                break;
            }
            case LC_VERSION_MIN_MACOSX:
            {
                printf("LC_VERSION_MIN_MACOSX %d\n",command->cmdsize);
                break;
            }




            default:
                printf("======= command type %x length %d\n",cmd,command->cmdsize);
        }
        command = (struct load_command*)(((char*)command)+command->cmdsize);
    }
    return segments;
}

@end
