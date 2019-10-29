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

@property (nonatomic,strong) NSData *segmentCommandData;

@end


@implementation MPWMachOSegment {
    const struct segment_command_64 *segment;
}


-initWithData:(NSData*)data
{
    self=[super init];
    NSAssert(data.length == sizeof(segment_command_64),@"data size equal to a segment command");
    self.segmentCommandData=data;
    segment=[data bytes];
    return self;
}

-(NSString*)description{
    return [NSString stringWithFormat:@"segment %d %.16s",segment->cmd,segment->segname];
}
@end
