//
//  MPWMachOSegment.m
//  ObjectiveTcc
//
//  Created by Marcel Weiher on 29.10.19.
//  Copyright © 2019 metaobject. All rights reserved.
//

#import "MPWMachOSegment.h"
#import <mach-o/loader.h>

@import MPWFoundation;

@interface MPWMachOSegment()

@property (nonatomic,assign) NSRange segmentRange;
@property (nonatomic,strong) NSData *segmentCommandData;
@property (nonatomic,strong) NSData *fileData;

@end


@implementation MPWMachOSegment {
    const struct segment_command_64 *segment;
}


-initWithSegmentRange:(NSRange)segmentRange fileData:(NSData*)fileData
{
    self=[super init];

    NSAssert(data.length == sizeof(segment_command_64),@"data size equal to a segment command");

    self.segmentRange=segmentRange;
    self.segmentCommandData=[fileData subdataWithRange:segmentRange];
    self.fileData=fileData;
    segment=[self.segmentCommandData bytes];
    return self;
}

-(NSString*)stringWithoutLeadingSpace:(const char*)s
{
    for (int i=0;i<16 && isspace(*s);i++,s++) {
    }
    NSString *string=[NSString stringWithFormat:@"%s",s];
    return string;
}

-(NSString*)segmentName
{
    return [self stringWithoutLeadingSpace:self->segment->segname];
}

-(long)numSections
{
    return segment->nsects;
}

-(void)printName:(char*)name on:s
{
    [s writeString:[self stringWithoutLeadingSpace:name]];
}

-(void)writeOnByteStream:(MPWByteStream*)s {
    [s printf:@"segment, command %d name: '%16s' number of sections: %d offset: %llu size: %llu\n",segment->cmd,segment->segname,segment->nsects,segment->fileoff,segment->filesize];
    struct section_64 *section=(struct section_64*)([[self fileData] bytes] + self.segmentRange.location + sizeof(struct segment_command_64));
    for (int i=0;i<segment->nsects;i++) {
        [s printf:@"section[%d] name: '",i];
        [self printName:section->segname on:s];
        [s printf:@"/"];
        [self printName:section->sectname on:s];

        [s printf:@"' size %llu\n",section->size];
        section++;
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

+(void)testGetSegmentsForObjectFile
{
    NSArray *segments = [self segmentsForTestFileName:@"return.o"];
    INTEXPECT( segments.count, 1,@"number of segments");
    MPWMachOSegment *segment=[segments firstObject];
    INTEXPECT( [segment numSections], 3,@"number of sections");

}

+testSelectors
{
    return @[
        @"testGetSegmentsForObjectFile",
    ];
}

@end
