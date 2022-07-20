//
//  LMCategoryStateImageView.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMCategoryStateImageView.h"

@interface LMCategoryStateImageView()
{
    NSTrackingArea *trackingArea;
}
@end

@implementation LMCategoryStateImageView

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:trackingArea]) {
        [self addTrackingArea:trackingArea];
    }
}

- (void)ensureTrackingArea {
    if (trackingArea == nil) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                    options:NSTrackingInVisibleRect | NSTrackingActiveAlways |
                        NSTrackingMouseEnteredAndExited
                                                      owner:self userInfo:nil];
    }
}

- (void)mouseEntered:(NSEvent *)event {
    [self.delegate onProgressViewMouseEnter:self];
}

- (void)mouseExited:(NSEvent *)event {
    [self.delegate onProgressViewMouseExit:self];
}

@end
