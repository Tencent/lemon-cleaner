//
//  NSArray+Extension.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Remove)
- (NSArray *)arrayByRemoveObject:(id)obj;
- (NSArray *)arrayByRemoveObjectsFromArray:(NSArray *)array;
@end

@interface NSArray (Map)
- (NSMutableArray *)map:(id(^)(id obj, NSUInteger index))block;
@end
