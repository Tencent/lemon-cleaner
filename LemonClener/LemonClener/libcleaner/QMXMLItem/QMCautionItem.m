//
//  QMCleanItem.m
//  libcleaner
//

//  Copyright (c) 2013年 Magican Software Ltd. All rights reserved.
//

#import "QMCautionItem.h"
#import "QMCleanUtils.h"
#import "QMResultItem.h"

@implementation QMCautionItem
@synthesize cautionID;
@synthesize column;
@synthesize bundleID;
@synthesize appName;

- (BOOL)fliterCleanItem:(NSString *)path bundleID:(NSString **)bundle appName:(NSString **)name
{
    *bundle = bundleID;
    *name = appName;
    if ([column isEqualToString:@"filename"])
    {
        if ([QMCleanUtils assertRegex:_value matchStr:[path lastPathComponent]])
            return YES;
    }
    else if ([column isEqualToString:@"filepath"])
    {
        if ([QMCleanUtils assertRegex:_value matchStr:path])
            return YES;
    }
    return NO;
}

- (void)setValue:(NSString *)value
{
    if ([column isEqualToString:@"filepath"])
        _value = [value stringByExpandingTildeInPath];
    else
        _value = value;
}

@end
