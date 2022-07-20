//
//  NSView+Extension.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "NSView+Extension.h"

@implementation NSView (ScreenShot)

- (NSImage *)screenShot
{
    NSSize size = [self bounds].size;
    
    NSBitmapImageRep *bitmapRep = [self bitmapImageRepForCachingDisplayInRect:self.bounds];
    [bitmapRep setSize:size];
    [self cacheDisplayInRect:self.bounds toBitmapImageRep:bitmapRep];
    
    NSImage * image = [[NSImage alloc] initWithSize:size];
    [image addRepresentation:bitmapRep];
    return image;
}

- (instancetype)insertVibrancyViewBlendingMode:(NSVisualEffectBlendingMode)mode
{
    Class vibrantClass=NSClassFromString(@"NSVisualEffectView");
    if (vibrantClass)
    {
        NSVisualEffectView *vibrant=[[vibrantClass alloc] initWithFrame:self.bounds];
        [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [vibrant setBlendingMode:mode];
        [self addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
        
        return vibrant;
    }
    return nil;
}

@end
