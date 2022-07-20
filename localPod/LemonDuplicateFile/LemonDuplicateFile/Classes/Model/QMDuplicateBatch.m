//
//  QMDuplicateItem.m
//  QMDuplicateFile
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "QMDuplicateBatch.h"

@implementation QMDuplicateFile

@end

@interface QMDuplicateBatch () {
    NSMutableArray *_subItemArray;
}
@end

@implementation QMDuplicateBatch

- (void)addSubItem:(QMDuplicateFile *)item {
    if (!_subItemArray) _subItemArray = [NSMutableArray array];
    [_subItemArray addObject:item];
}

- (NSArray *)subItems {
    return _subItemArray;
}

@end
