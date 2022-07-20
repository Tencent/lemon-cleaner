//
//  McDetailOutlineItemCellView.m
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "McDetailOutlineItemCellView.h"
#import "NSColor+Extension.h"
#import "LMOutlineRowView.h"

@implementation McDetailOutlineItemCellView
{
    NSTrackingArea *trackingArea;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self.textFileName setTextColor:[NSColor colorWithHex:0x333333]];
        [self.textSize setTextColor:[NSColor colorWithHex:0x333333]];
        [self.textVersion setTextColor:[NSColor colorWithHex:0x94979B]];
        self.icon.imageScaling = NSImageScaleProportionallyUpOrDown;
        self.btnShowFinder.hidden = YES;
    }
    return self;
}

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
    [self updateRowViewSelectState:YES];
//    LMOutlineRowView *rowView = (LMOutlineRowView*)self.superview;
//    if(!rowView.rowViewDelegate.isPreviewing)
    
    if(_needShowPath){
        self.pathBarView.hidden = NO;
        self.btnShowFinder.hidden = NO;
    }
  
}

- (void)mouseExited:(NSEvent *)event {
    [self updateRowViewSelectState:NO];
//    QMResultTableRowView *rowView = (QMResultTableRowView *)self.superview;
//    if(!rowView.rowViewDelegate.isPreviewing)
    self.pathBarView.hidden = YES;
    self.btnShowFinder.hidden = YES;
}

- (IBAction)showFinder:(id)sender {
    [[NSWorkspace sharedWorkspace] selectFile:self.path
                     inFileViewerRootedAtPath:[self.path stringByDeletingLastPathComponent]];
}

- (void)updateRowViewSelectState:(BOOL)selected {
    NSView *superView = self.superview;
    if (superView != nil && [superView isKindOfClass:LMOutlineRowView.class]) {
        LMOutlineRowView *rowView = (LMOutlineRowView *) superView;
        [rowView setSelected:selected];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
