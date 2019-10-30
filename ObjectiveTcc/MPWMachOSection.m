//
//  MPWMachOSection.m
//  ObjectiveTcc
//
//  Created by Marcel Weiher on 30.10.19.
//  Copyright © 2019 metaobject. All rights reserved.
//

#import "MPWMachOSection.h"
#import <mach-o/loader.h>

@import MPWFoundation;

@implementation MPWMachOSection {
    const struct section_64 *section;
}


-initWithRange:(NSRange)sectionRange fileData:(NSData*)fileData
{
    self=[super initWithRange:sectionRange fileData:fileData];
    section=[self.partData bytes];
    return self;
}


-(void)writeOnByteStream:(MPWByteStream*)s {

    [self printName:section->segname on:s];
    [s printf:@"/"];
    [self printName:section->sectname on:s];
    [s printf:@"' size %llu\n",section->size];
}

@end
