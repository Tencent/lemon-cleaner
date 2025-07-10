//
//  NSArray+Extension.h
//  QMCoreFunction
//
//  Created by TanHao on 13-10-31.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Remove)
- (NSArray *)arrayByRemoveObject:(id)obj;
- (NSArray *)arrayByRemoveObjectsFromArray:(NSArray *)array;
@end

@interface NSArray (Map)
- (NSMutableArray *)filteredMappedArray:(id(^)(id obj, NSUInteger index))block;
@end
