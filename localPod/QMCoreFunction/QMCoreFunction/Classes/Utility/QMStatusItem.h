//
//  QMStatusItem.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMStatusItem : NSObject
@property (nonatomic, assign) NSInteger status;
@property (nonatomic, strong) id object;

+ (id)itemWithObject:(id)object;

@end
