//
//  MMScrollView.m
//  MiniMail
//
//  Created by DINH Viêt Hoà on 24/08/10.
//  Copyright 2011 Sparrow SAS. All rights reserved.
//

#import "MMScrollView.h"

@implementation MMScrollView

- (void) tile
{
    NSRect rect = [self contentView].frame;
    if (rect.size.width != self.bounds.size.width)
    {
        rect.size.width = self.bounds.size.width;
        [[self contentView] setFrame:rect];
    }
    if (rect.size.height != self.bounds.size.height)
    {
        rect.size.height = self.bounds.size.height;
        [[self contentView] setFrame:rect];
    }
    
    // 设置竖向的滑动条
    NSRect frame = NSZeroRect;
    
    if([self hasVerticalScroller]){
        CGFloat height;
        height = [self bounds].size.height;
        frame = NSMakeRect([self bounds].size.width - 15, 0, 15, height);
        if ([[self contentView] documentRect].size.height > self.bounds.size.height + 1)
            frame.origin.y = 0;
        else
            frame.size.height = 0;
        [[self verticalScroller] setFrame:frame];
    }
    
    
    // 设置横向的滑动条
    if([self hasHorizontalScroller]){
        CGFloat width;
        width = [self bounds].size.width;
        frame = NSMakeRect(0, 0, width, 15);
        if ([[self contentView] documentRect].size.width > self.bounds.size.width + 1)
            frame.origin.y = 0;
        else
            frame.size.width = 0;
        [[self horizontalScroller] setFrame:frame];
    }
}


@end
