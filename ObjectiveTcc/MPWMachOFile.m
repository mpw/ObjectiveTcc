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
        switch ( command->cmd) {
            case LC_SEGMENT_64:
            {
                printf("segment 64 length %d\n",command->cmdsize);
                NSData *segmentData=[NSData dataWithBytes:command length:command->cmdsize];
                MPWMachOSegment *segment=[[MPWMachOSegment alloc] initWithData:segmentData];
                [segments addObject:segment];
                break;
            }
            default:
                printf("command type %x length %d\n",command->cmd,command->cmdsize);
        }
        command = (struct load_command*)(((char*)command)+command->cmdsize);
    }
    return segments;
}

@end
