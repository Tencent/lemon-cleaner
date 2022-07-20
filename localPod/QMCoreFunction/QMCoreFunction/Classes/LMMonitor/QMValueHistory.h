//
//  QMValueHistory.h
//  LemonMonitor
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMValueHistoryItem : NSObject
@property (strong) NSValue *value;
@property (strong) NSDate *date;
@end

@interface QMValueHistory : NSObject
@property (readonly) NSArray *items;
- (id)initWithCapacity:(NSUInteger)capacity;
- (void)feed:(NSValue *)value;
- (void)clear;
- (NSArray *)valueArray;
@end

@interface QMValueHistory (NSArrayMethods)
- (NSUInteger)count;
- (QMValueHistoryItem *)objectAtIndex:(NSUInteger)index;
- (QMValueHistoryItem *)objectAtIndexedSubscript:(NSUInteger)idx;
- (QMValueHistoryItem *)lastObject;
@end
