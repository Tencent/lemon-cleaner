//
//  MyPopoverBackgroundView.m
//  LemonSpaceAnalyse
//
//  
//

#import "LMPopoverBackgroundView.h"

@implementation LMPopoverBackgroundView

-(void)drawRect:(NSRect)dirtyRect
{
    [[NSColor blackColor] set];
    NSRectFill(self.bounds);
}


@end
