//
//  MPWMachOSegment.h
//  ObjectiveTcc
//
//  Created by Marcel Weiher on 29.10.19.
//  Copyright © 2019 metaobject. All rights reserved.
//

#import "MPWMachOComponent.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPWMachOSegment : MPWMachOComponent

-(NSArray*)sections;

@end

NS_ASSUME_NONNULL_END
