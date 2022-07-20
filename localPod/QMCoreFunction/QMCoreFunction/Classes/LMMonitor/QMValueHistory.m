//
//  QMValueHistory.m
//  LemonMonitor
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMValueHistory.h"

@implementation QMValueHistory
{
    NSMutableArray *_items;
    NSUInteger _capacity;
}
@synthesize items = _items;
- (id)initWithCapacity:(NSUInteger)capacity
{
    self = [super init];
    if (self) {
        _capacity = capacity;
        _items = [NSMutableArray arrayWithCapacity:capacity];
    }
    return self;
}

- (void)feed:(NSValue *)value
{
    QMValueHistoryItem *item = [[QMValueHistoryItem alloc] init];
    item.value = value;
    item.date = [NSDate date];
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:_items.count];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"items"];
    [_items addObject:item];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"items"];
    
    if (_items.count >= _capacity) {
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:0] forKey:@"items"];
        [_items removeObjectAtIndex:0];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:0] forKey:@"items"];
    }
}

- (void)clear
{
    [_items removeAllObjects];
}

- (NSArray *)valueArray
{
    return [_items valueForKeyPath:@"value"];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return _items;
}
@end

@implementation QMValueHistoryItem
@end
