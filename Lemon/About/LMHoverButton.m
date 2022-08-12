//
//  LMHoverButton.m
//  Lemon
//
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "LMHoverButton.h"

@interface LMHoverButton ()

@property(nonatomic, strong) NSTrackingArea *trackingArea;

@end

@implementation LMHoverButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:self.trackingArea]) {
        [self addTrackingArea:self.trackingArea];
    }
}

- (void)ensureTrackingArea {
    if (self.trackingArea == nil) {
        self.trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    }
}

- (void)mouseEntered:(NSEvent *)event {
    NSCursor *cursor = [NSCursor pointingHandCursor];
    [cursor set];
}

- (void)mouseExited:(NSEvent *)event {
    NSCursor *cursor = [NSCursor arrowCursor];
    [cursor set];
}
@end
