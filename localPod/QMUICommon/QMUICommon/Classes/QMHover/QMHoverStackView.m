//
//  QMHoverStackView.m
//  QMUICommon
//
//

#import "QMHoverStackView.h"

@interface QMHoverStackView ()

@property (nonatomic) BOOL isHovered;

@end

@implementation QMHoverStackView
@synthesize hoverDidChange;

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    
    // 移除现有的追踪区域
    for (NSTrackingArea *trackingArea in self.trackingAreas) {
        [self removeTrackingArea:trackingArea];
    }

    // 添加新的追踪区域
    NSTrackingArea *newTrackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                                   options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways)
                                                                   owner:self
                                                                userInfo:nil];
    [self addTrackingArea:newTrackingArea];
}

- (void)mouseEntered:(NSEvent *)event {
    self.isHovered = YES;
}

- (void)mouseExited:(NSEvent *)event {
    self.isHovered = NO;
}

- (void)setIsHovered:(BOOL)isHovered {
    BOOL temp = _isHovered;
    if (temp != isHovered) {
        _isHovered = isHovered;
        if (self.hoverDidChange) self.hoverDidChange(self);
    }
}

@end
