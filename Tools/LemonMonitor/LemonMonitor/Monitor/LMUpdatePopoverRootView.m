//
//  MyPopoverRootView.m
//  LemonSpaceAnalyse
//

//

#import "LMUpdatePopoverRootView.h"
#import "LMUpdatePopoverBackgroundView.h"

@implementation LMUpdatePopoverRootView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)viewDidMoveToWindow {
     NSView * aFrameView = [[self.window contentView] superview];
     LMUpdatePopoverBackgroundView * aBGView  =[[LMUpdatePopoverBackgroundView alloc] initWithFrame:aFrameView.bounds];
     aBGView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
     [aFrameView addSubview:aBGView positioned:NSWindowBelow relativeTo:aFrameView];
     [super viewDidMoveToWindow];
}

@end
