//
//  MPWMachOSegment.m
//  ObjectiveTcc
//
//  Created by Marcel Weiher on 29.10.19.
//  Copyright © 2019 metaobject. All rights reserved.
//

#import "MPWMachOSegment.h"
#import "MPWMachOSection.h"
#import <mach-o/loader.h>

@import MPWFoundation;


@implementation MPWMachOSegment {
    const struct segment_command_64 *segment;
}


-initWithRange:(NSRange)segmentRange fileData:(NSData*)fileData
{
    self=[super initWithRange:segmentRange fileData:fileData];

    NSAssert(data.length == sizeof(segment_command_64),@"data size equal to a segment command");

    segment=[self.partData bytes];
    return self;
}


-(NSString*)segmentName
{
    return [self stringWithoutLeadingSpace:self->segment->segname];
}

-(long)numSections
{
    return segment->nsects;
}

-(NSArray*)sections
{
    NSMutableArray *sections=[NSMutableArray array];
    struct section_64 *sectionPtr=(struct section_64*)([[self fileData] bytes] + self.partRange.location + sizeof(struct segment_command_64));
    for (int i=0;i<segment->nsects;i++) {
        NSRange sectionRange=NSMakeRange( (void*)sectionPtr - [self.fileData bytes], sizeof *sectionPtr);
        MPWMachOSection *section=[[MPWMachOSection alloc] initWithRange:sectionRange fileData:self.fileData];
        [sections addObject:section];
        sectionPtr++;
    }
    return sections;
}

-(void)writeOnByteStream:(MPWByteStream*)s {
    [s printf:@"segment name: '%s' number of sections: %d offset: %llu size: %llu\n",[[self stringWithoutLeadingSpace: segment->segname] UTF8String],segment->nsects,segment->fileoff,segment->filesize];
    NSArray *sections=[self sections];
    for (int i=0;i<sections.count;i++) {
        [s printf:@"section[%d]: ",i];
        [s writeObject:sections[i]];
    }

    [s writeNewline];
}
@end

#import "MPWMachOFile.h"
#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachOSegment(testing)

+(NSArray*)segmentsForTestFileName:(NSString*)name
{
    NSData *macho=[self frameworkResource:name category:nil];
    MPWMachOFile *file=[[MPWMachOFile alloc] initWithData:macho];
    return [file segments];
}


+(void)testGetSegmentsAndSectionsForObjectFile
{
    NSArray *segments = [self segmentsForTestFileName:@"return.o"];
    INTEXPECT( segments.count, 1,@"number of segments");
    MPWMachOSegment *segment=[segments firstObject];
    INTEXPECT( [segment numSections], 3,@"number of sections");
    NSArray *sections = [segment sections];
    INTEXPECT( sections.count, 3,@"number of sections returned");
}

+testSelectors
{
    return @[
        @"testGetSegmentsAndSectionsForObjectFile",
    ];
}

@end
