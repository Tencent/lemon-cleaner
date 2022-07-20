//
//  QMStatusCircleView.m
//  LemonMonitor
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMStatusCircleView.h"
#import <QuartzCore/QuartzCore.h>
#import <QMCoreFunction/QMEnvironmentInfo.h>

@interface QMStatusCircleView ()
{
    NSImage *bgImage;
    NSImage *_showImage;
    NSImage *_showImageDark;
    NSImage *bgHLImage;
    NSImage *_purgeImage;
    NSImage *_purgeImageDark;

    NSImage *networkTrafficImage;
    BOOL highlight;
}
- (NSImage *)purgeImage;
- (NSImage *)showImage;

@end

@implementation QMStatusCircleView
@synthesize progress;
@synthesize actionBlock;

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self)
    {
        NSBundle *bundle = [NSBundle bundleForClass:self.class];
        bgImage = [bundle imageForResource:@"status_bg"];
        bgHLImage = [bundle imageForResource:@"status_bg_HL"];
        
    }
    return self;
}

- (double)progress
{
    return progress;
}

- (void)setProgress:(double)value
{
    if (progress != value)
    {
        progress = value;
        [self setNeedsDisplay:YES];
    }
}

//这就是你需要去实现的一个方法，根据属性返回一个动画对象
+ (id)defaultAnimationForKey:(NSString *)key
{
    if ([key isEqualToString:@"progress"])
    {
        return [CABasicAnimation animation];
    }else
    {
        return [super defaultAnimationForKey:key];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
//    [highlight?bgHLImage:bgImage drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
//
//    if (!highlight)
//    {
//        [NSGraphicsContext saveGraphicsState];
//        NSBezierPath *bezierPath = [NSBezierPath bezierPath];
//        [bezierPath moveToPoint:NSMakePoint(NSMidX(self.bounds), NSMidY(self.bounds))];
//        [bezierPath appendBezierPathWithArcWithCenter:NSMakePoint(NSMidX(self.bounds), NSMidY(self.bounds)) radius:NSWidth(self.bounds)/2 startAngle:90 endAngle:90-360*progress clockwise:YES];
//        [bezierPath setClip];
//        [[self showImage] drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
//        [NSGraphicsContext restoreGraphicsState];
//    }
    
//    if (highlight) [[self purgeImage] drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    [[[NSBundle bundleForClass:self.class] imageForResource:@"LOGO_16_black"] drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)updateTrackingAreas
{
    NSArray *trackingAreas = [self trackingAreas];
    for (NSTrackingArea *area in trackingAreas)
    {
        [self removeTrackingArea:area];
    }
    
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:area];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    highlight = YES;
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    highlight = NO;
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    
    NSEvent *nextEvent = [self.window nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask];
    if (nextEvent.type == NSLeftMouseUp)
    {
        if (actionBlock) actionBlock();
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    highlight = NO;
    [super mouseDragged:theEvent];
}

- (NSImage *)lazyLoadImage:(NSString *)name attr:(NSImage *__strong*)attr
{
    NSParameterAssert(attr);
    if (!(*attr)) {
        NSBundle *bundle = [NSBundle bundleForClass:self.class];
        *attr = [bundle imageForResource:name];
    }
    return *attr;
}

- (NSImage *)autoDarkImage:(NSString *)name attr:(NSImage *__strong*)attr darkAttr:(NSImage *__strong*)darkAttr
{
    BOOL isDark = [QMEnvironmentInfo isDarkMode];
    if (isDark) {
        return [self lazyLoadImage:[name stringByAppendingString:@"_dark"] attr:darkAttr];
    } else {
        return [self lazyLoadImage:name attr:attr];
    }
}

- (NSImage *)purgeImage {
    return [self autoDarkImage:@"status_purge" attr:&_purgeImage darkAttr:&_purgeImageDark];
}

- (NSImage *)showImage {
    return [self autoDarkImage:@"status_moving" attr:&_showImage darkAttr:&_showImageDark];
}

@end
