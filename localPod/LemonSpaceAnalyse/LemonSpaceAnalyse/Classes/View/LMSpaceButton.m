//
//  LMSpaceButton.m
//  LemonSpaceAnalyse
//
//  
//

#import "LMSpaceButton.h"
#import <QMCoreFunction/NSColor+Extension.h>

@interface LMSpaceButton ()

@property(nonatomic, strong) NSTrackingArea *trackingArea;
@property (nonatomic, assign) BOOL mouseEnter;

@end

@implementation LMSpaceButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    self.wantsLayer = YES;
    if(self.isEnabled == NO){
        self.layer.backgroundColor = [NSColor clearColor].CGColor;
        return;
    }
    if (_mouseEnter) {
        self.layer.backgroundColor = [NSColor colorWithHex:0xBFBFBF alpha:0.2].CGColor;
    }else{
        self.layer.backgroundColor = [NSColor clearColor].CGColor;
    }
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
//    if (!self.isEnabled)
//    {
//        return;
//    }
//
    self.mouseEnter = YES;
    [self setNeedsDisplay];
}

- (void)mouseExited:(NSEvent *)event {
//    if (!self.isEnabled)
//    {
//        return;
//    }
    
    self.mouseEnter = NO;
    [self setNeedsDisplay];
}

@end
