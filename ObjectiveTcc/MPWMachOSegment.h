//
//  MPWMachOSegment.h
//  ObjectiveTcc
//
//  Created by Marcel Weiher on 29.10.19.
//  Copyright © 2019 metaobject. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWMachOSegment : NSObject
-initWithSegmentRange:(NSRange)segmentRange fileData:(NSData*)fileData;

@end

NS_ASSUME_NONNULL_END
