//
//  QMSimpleWindow.m
//  QMSimpleWindow
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMSimpleWindow.h"

@interface QMSimpleHeaderView : NSView
@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, assign) BOOL drawTitle;
@end

@implementation QMSimpleHeaderView
@synthesize backgroundColor;
@synthesize drawTitle;

- (NSColor *)backgroundColor
{
    return backgroundColor;
};

- (void)setBackgroundColor:(NSColor *)color
{
    backgroundColor = color;
    [self setNeedsDisplay:YES];
}


- (void)drawRect:(NSRect)dirtyRect
{
    NSColor *color = backgroundColor ?: [NSColor whiteColor];
    [color set];
    
    const CGFloat radius = 4.0;
    NSRect bounds = self.bounds;
    
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(NSMinX(bounds), NSMinY(bounds))];
    [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(bounds), NSMaxY(bounds))
                                   toPoint:NSMakePoint(NSMinX(bounds)+radius, NSMaxY(bounds))
                                    radius:radius];
    [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(bounds), NSMaxY(bounds))
                                   toPoint:NSMakePoint(NSMaxX(bounds), NSMaxY(bounds)-radius)
                                    radius:radius];
    [path lineToPoint:NSMakePoint(NSMaxX(bounds), NSMinY(bounds))];
    [path closePath];
    [path fill];
    
    if (drawTitle)
    {
        //阴影
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowOffset = NSMakeSize(0, -1);
        shadow.shadowColor = [NSColor colorWithCalibratedRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0];
        
        //title颜色
        NSColor *textColor = nil;
        if ([self.window isKeyWindow])
            textColor = [NSColor colorWithCalibratedRed:50/255.0 green:50/255.0 blue:50/255.0 alpha:1.0];
        else
            textColor = [NSColor colorWithCalibratedRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1.0];
        
        NSAttributedString *title = [[NSAttributedString alloc] initWithString:self.window.title
                                                                    attributes:@{NSFontAttributeName: [NSFont labelFontOfSize:13.0],
                                                                                 NSForegroundColorAttributeName: textColor,
                                                                                 NSShadowAttributeName: shadow}];
        
        [title drawAtPoint:NSMakePoint(NSMidX(bounds)-title.size.width/2, NSMidY(bounds)-title.size.height/2)];
    }
}

@end

#pragma mark - QMSimpleWindow

@interface QMSimpleWindow ()
{
    QMSimpleHeaderView *headerView;
}
@end

@implementation QMSimpleWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    if (self)
    {
        headerView = [[QMSimpleHeaderView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(self.frame), 22)];
        headerView.autoresizingMask = NSViewMinYMargin|NSViewWidthSizable;
        
        NSView *containerView = nil;
        
#ifdef __MAC_10_10
        //Yosemite and later
        if (rint(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9)
        {
            self.titlebarAppearsTransparent = YES;
            NSView *themeView = [[self contentView] superview];
            NSArray *subViews = [themeView subviews];
            for (NSView *subView in subViews)
            {
                if (subView != [self contentView])
                {
                    containerView = subView;
                    break;
                }
            }
        }else
#endif
        //Mavericks and lower
        {
            headerView.drawTitle = YES;
            NSRect frame = headerView.frame;
            frame.origin.y = NSHeight(self.frame)-NSHeight(frame);
            headerView.frame = frame;
            
            containerView = [[self contentView] superview];
        }
        
        [containerView addSubview:headerView positioned:NSWindowBelow relativeTo:nil];
        
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor whiteColor]];
        [self setMovableByWindowBackground:YES];
    }
    return self;
}


- (void)setBackgroundColor:(NSColor *)color
{
    [headerView setBackgroundColor:color];
    [super setBackgroundColor:color];
}

- (void)setTitle:(NSString *)aString
{
    [super setTitle:aString];
    [headerView setNeedsDisplay:YES];
}

@end
