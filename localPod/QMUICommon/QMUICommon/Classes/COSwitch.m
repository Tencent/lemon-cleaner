//
//  COSwitch.m
//  SlideControl
//
//  
//  Copyright (c) 2014 stcui. All rights reserved.
//

#import "COSwitch.h"
#import "LMAppThemeHelper.h"
@import QuartzCore;

#define RGB(r,g,b) [NSColor colorWithDeviceRed:(r)/255.f green:(g)/255.f blue:(b)/255.f alpha:1]
#define RGBHEX(hex) RGB((hex >> 16), ((hex >> 8) & 0xff) , (hex & 0xff))
@interface COSwitch (){
      NSTrackingArea *trackingArea;
}
@property (assign, nonatomic) CGFloat hoverProgress;
@property (assign, nonatomic) CGFloat mouseDownProgress;
@property (assign, nonatomic) CGFloat progress;

@end

@implementation COSwitch

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)commonInit
{
//    _onBorderColor = RGBHEX(0x51b465);
//    _onToggleColor = RGBHEX(0x63b574);
//    _offBorderColor = RGBHEX(0xbdc5cb);
//    _offToggleColor = RGBHEX(0xadb2b9);
    _onBorderColor = RGBHEX(0x00D899);
    _onToggleColor = RGBHEX(0xFFFFFF);
    _offBorderColor = RGBHEX(0xE5E5EA);
    _offToggleColor = RGBHEX(0xFFFFFF);
    _offFillColor = [LMAppThemeHelper getMainBgColor];
    _isEnable = YES;
    _isAnimator = YES;
}

+ (id)defaultAnimationForKey:(NSString *)key NS_AVAILABLE_MAC(10_5)
{
    if ([key isEqualToString:@"progress"] || [key isEqualToString:@"hoverProgress"] || [key isEqualToString:@"mouseDownProgress"]) {
         return [CABasicAnimation animation];
    } else {
        return [super defaultAnimationForKey:key];
    }
}

- (void)setHover:(BOOL)hover
{
    [[self animator] setHoverProgress:hover ? 1 : 0];
}

- (void)setHoverProgress:(CGFloat)hoverProgress
{
    _hoverProgress = hoverProgress;
    [self setNeedsDisplay:YES];
}

- (void)setMouseDownProgress:(CGFloat)mouseDownProgress
{
    _mouseDownProgress = mouseDownProgress;
    [self setNeedsDisplay:YES];
}

// 偶现点击时不响应的问题
//- (void)updateTrackingAreas
//{
//    NSArray *areas = [self trackingAreas];
//    if (areas.count > 0) {
//        for (NSTrackingArea *area in self.trackingAreas) {
//            [self removeTrackingArea:area];
//        }
//    }
//    [self addTrackingRect:self.bounds
//                    owner:self
//                 userData:NULL
//             assumeInside:NO];
//}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:trackingArea]) {
        [self addTrackingArea:trackingArea];
    }
}

- (void)ensureTrackingArea {
    if (trackingArea == nil) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSColor *borderColor = nil, *toggleColor = nil;
    CGFloat borderDefault = 2;
    CGFloat border = borderDefault + _hoverProgress;

    if ((_progress == borderDefault || _progress == 0) && _mouseDownProgress  > 0) {
        borderColor = [self _gradualColorFromColor:self.offBorderColor to:self.onBorderColor progress:_mouseDownProgress reverse:self.on];
        toggleColor = [self _gradualColorFromColor:self.offToggleColor to:self.onToggleColor progress:_mouseDownProgress reverse:self.on];
    } else {
        borderColor = [self _gradualColorFromColor:self.offBorderColor to:self.onBorderColor progress:_progress];
        toggleColor = [self _gradualColorFromColor:self.offToggleColor to:self.onToggleColor progress:_progress];
    }
    [borderColor set];

    if (self.on) {
        NSRect frameBounds = self.bounds;
        CGFloat radius = NSHeight(frameBounds) / 2;
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:frameBounds xRadius:radius yRadius:radius];
        path.lineWidth = border;
        [path fill];
    } else {
//        NSRect frameBounds = NSInsetRect(self.bounds, 1+border/2, 1+border/2);
//        CGFloat radius = NSHeight(frameBounds) / 2;
//        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:frameBounds xRadius:radius yRadius:radius];
//        path.lineWidth = border;
//        [[NSColor whiteColor] set];
//        [path fill];
//        
//        [borderColor set];
//        [path stroke];
        NSRect frameBounds = NSInsetRect(self.bounds, border/2, border/2);
        CGFloat radius = NSHeight(frameBounds) / 2;
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:frameBounds xRadius:radius yRadius:radius];
        [_offFillColor set];
        [path fill];
        
        path.lineWidth = border;
        [borderColor set];
        [path stroke];
    }

    [toggleColor set];
    CGFloat center = NSHeight(self.bounds) / 2;
    CGFloat x = center + (NSWidth(self.bounds) - center - center) * _progress;
    CGFloat r = NSHeight(self.bounds) - borderDefault * 2;
    //NSBezierPath *oval = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(x - r / 2, center - r / 2, r, r)];
    //[oval fill];
    
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(ctx);
    CGRect rectangle = CGRectMake(x - r / 2, center - r / 2, r, r);
    CGContextSetShadow(ctx, CGSizeMake(0, 0), 2);
    CGContextAddEllipseInRect(ctx, rectangle);
    CGContextFillPath(ctx);
    CGContextRestoreGState(ctx);
}

- (void)setOn:(BOOL)on
{
    if (_on == on) return;
    _on = on;
    if (self.isAnimator) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.1;
            [[self animator] setProgress: on ? 1 : 0];
        } completionHandler:^{
        }];
    } else {
        [self setProgress: on ? 1 : 0];
    }
    
    if (self.onValueChanged) {
        self.onValueChanged(self);
    }
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    [self setNeedsDisplay:YES];
}

- (NSColor *)_gradualColorFromColor:(NSColor *)start to:(NSColor *)end progress:(CGFloat)progress reverse:(BOOL)reverse
{
    CGFloat r,g, b, a, rr, gg, bb, aa;
    if (reverse) {
        [end getRed:&r green:&g blue:&b alpha:&a];
        [start getRed:&rr green:&gg blue:&bb alpha:&aa];
    } else {
        [start getRed:&r green:&g blue:&b alpha:&a];
        [end getRed:&rr green:&gg blue:&bb alpha:&aa];
    }
    NSColor *ret = [NSColor colorWithCalibratedRed:r + (rr-r) * progress green:g + (gg - g) *progress blue: b + (bb-b) * progress alpha:a + (aa - a) * progress];
    return ret;
}

- (NSColor *)_gradualColorFromColor:(NSColor *)start to:(NSColor *)end progress:(CGFloat)progress
{
    return [self _gradualColorFromColor:start to:end progress:progress reverse:NO];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (!self.isEnable) {
        return;
    }
    self.on = !self.on;
    [self.animator setMouseDownProgress:0];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (!self.isEnable) {
        return;
    }
    [self.animator setMouseDownProgress:1];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    if (self.isAnimator) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.1;
            [[self animator] setHover:YES];
        } completionHandler:nil];
    } else {
        [self setHover:YES];
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [[self animator] setHover:NO];
}

- (nullable id) getAnimator{
    if (self.isAnimator) {
        return [self animator];
    } else {
        return self;
    }
}
@end
