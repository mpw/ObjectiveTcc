//
//  MPWMachOComponent.h
//  ObjectiveTcc
//
//  Created by Marcel Weiher on 30.10.19.
//  Copyright © 2019 metaobject. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWMachOComponent : NSObject

@property (nonatomic,assign) NSRange partRange;
@property (nonatomic,strong) NSData *partData;
@property (nonatomic,strong) NSData *fileData;

-(instancetype)initWithRange:(NSRange)segmentRange fileData:(NSData*)fileData;
-(NSString*)stringWithoutLeadingSpace:(const char*)s;
-(void)printName:(char*)name on:s;


@end

NS_ASSUME_NONNULL_END
