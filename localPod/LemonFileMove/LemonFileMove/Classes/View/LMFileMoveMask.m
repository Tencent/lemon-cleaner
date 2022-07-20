//
//  LMFileMoveMask.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveMask.h"
#import <QMCoreFunction/NSColor+Extension.h>

@interface LMFileMoveMask () {
    NSTrackingArea * _trackingArea;
}
@end

@implementation LMFileMoveMask

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    if ([self.delegate respondsToSelector:@selector(fileMoveMaskSelect:)]) {
        [self.delegate fileMoveMaskSelect:isSelected];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    if(_trackingArea) {
        [self removeTrackingArea:_trackingArea];
    }
    _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    
    [self addTrackingArea:_trackingArea];
}

- (void)mouseMoved:(NSEvent *)event{

}

- (void)mouseEntered:(NSEvent *)theEvent {
    
    if ([self.delegate respondsToSelector:@selector(fileMoveMaskMoveIn)]) {
        [self.delegate fileMoveMaskMoveIn];
    }
}


- (void)mouseExited:(NSEvent *)theEvent {

    if ([self.delegate respondsToSelector:@selector(fileMoveMaskMoveOut)]) {
        [self.delegate fileMoveMaskMoveOut];
    }
}
@end
