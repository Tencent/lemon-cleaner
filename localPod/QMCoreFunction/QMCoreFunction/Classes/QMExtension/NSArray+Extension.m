//
//  NSArray+Extension.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "NSArray+Extension.h"

@implementation NSArray (Remove)

- (NSArray *)arrayByRemoveObject:(id)obj
{
    //返回Copy对象是因为外部调用此方法的预期是获得一个新的NSArray,无论是否成功
    if (!obj)
        return [self copy];
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self];
    [tempArray removeObject:obj];
    NSArray *resultArray = [[NSArray alloc] initWithArray:tempArray];
    return resultArray;
}

- (NSArray *)arrayByRemoveObjectsFromArray:(NSArray *)array
{
    //返回Copy对象是因为外部调用此方法的预期是获得一个新的NSArray,无论是否成功
    if ([array count] == 0)
        return [self copy];
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self];
    [tempArray removeObjectsInArray:array];
    NSArray *resultArray = [[NSArray alloc] initWithArray:tempArray];
    return resultArray;
}

@end


@implementation NSArray (Map)

- (NSMutableArray *)map:(id(^)(id obj, NSUInteger index))block
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id ret = block(obj, idx) ?: [NSNull null];
        [result addObject:ret];
    }];
    return result;
}

@end
