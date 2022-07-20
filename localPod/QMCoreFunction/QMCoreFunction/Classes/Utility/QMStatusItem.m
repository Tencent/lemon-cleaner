//
//  QMStatusItem.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMStatusItem.h"

@implementation QMStatusItem
@synthesize status;
@synthesize object;

+ (id)itemWithObject:(id)object
{
    QMStatusItem *item = [[QMStatusItem alloc] init];
    item.object = object;
    return item;
}

@end
