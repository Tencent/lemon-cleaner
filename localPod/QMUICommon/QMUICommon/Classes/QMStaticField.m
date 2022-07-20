//
//  QMStaticField.m
//  QMUICommon
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMStaticField.h"

@implementation QMStaticField

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setEditable:NO];
        [self setSelectable:NO];
        [self setDrawsBackground:NO];
        [self setBezeled:NO];
        [self setBordered:NO];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
