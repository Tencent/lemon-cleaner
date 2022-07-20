//
//  MyPopoverRootView.m
//  LemonSpaceAnalyse
//
//  
//

#import "LMPopoverRootView.h"
#import "LMPopoverBackgroundView.h"

@implementation LMPopoverRootView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)viewDidMoveToWindow {
     NSView * aFrameView = [[self.window contentView] superview];
     LMPopoverBackgroundView * aBGView  =[[LMPopoverBackgroundView alloc] initWithFrame:aFrameView.bounds];
     aBGView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
     [aFrameView addSubview:aBGView positioned:NSWindowBelow relativeTo:aFrameView];
     [super viewDidMoveToWindow];
}

@end
