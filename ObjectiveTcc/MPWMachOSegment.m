//
//  MPWMachOSegment.m
//  ObjectiveTcc
//
//  Created by Marcel Weiher on 29.10.19.
//  Copyright © 2019 metaobject. All rights reserved.
//

#import "MPWMachOSegment.h"
#import <mach-o/loader.h>

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

-(NSString*)description{
    NSMutableString *descr = [NSMutableString stringWithFormat:@"segment, command %d name: '%16s' number of sections: %d offset: %llu size: %llu\n",segment->cmd,segment->segname,segment->nsects,segment->fileoff,segment->filesize];
    struct section_64 *section=(struct section_64*)([[self fileData] bytes] + self.segmentRange.location + sizeof(struct segment_command_64));
    for (int i=0;i<segment->nsects;i++) {
        [descr appendFormat:@"section[%d] name: '%16s/%16s' size %llu\n",i,section->sectname,section->segname,section->size];
        section++;
    }
    return descr;
}
@end
