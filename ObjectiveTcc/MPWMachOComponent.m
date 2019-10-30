//
//  MPWMachOComponent.m
//  ObjectiveTcc
//
//  Created by Marcel Weiher on 30.10.19.
//  Copyright © 2019 metaobject. All rights reserved.
//

#import "MPWMachOComponent.h"

@import MPWFoundation;

@implementation MPWMachOComponent


-(instancetype)initWithRange:(NSRange)segmentRange fileData:(NSData*)fileData
{
    self=[super init];

    self.partRange=segmentRange;
    self.partData=[fileData subdataWithRange:segmentRange];
    self.fileData=fileData;
    return self;
}

-(NSString*)stringWithoutLeadingSpace:(const char*)s
{
    for (int i=0;i<16 && isspace(*s);i++,s++) {
    }
    NSString *string=[NSString stringWithFormat:@"%s",s];
    return string;
}


-(void)printName:(char*)name on:s
{
    [s writeString:[self stringWithoutLeadingSpace:name]];
}



@end
