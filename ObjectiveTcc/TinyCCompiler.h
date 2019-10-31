//
//  TinyCCompiler.h
//  ObjectiveTcc
//
//  Created by Marcel Weiher on 29.10.19.
//  Copyright © 2019 metaobject. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TinyCCompiler : NSObject

-(long)compileAndRun:(NSString*)s;

@end

NS_ASSUME_NONNULL_END
