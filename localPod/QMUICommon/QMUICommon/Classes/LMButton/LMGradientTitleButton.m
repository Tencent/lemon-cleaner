//
//  LMGradientTitleButton.m
//  Lemon
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMGradientTitleButton.h"
#import "NSColor+Extension.h"
#import "NSEvent+Extension.h"

@interface NSBezierPath (BezierPathQuartzUtilities)
- (CGPathRef)quartzPath;
@end
@implementation NSBezierPath (BezierPathQuartzUtilities)
// This method works only in OS X v10.2 and later.
- (CGPathRef)quartzPath
{
    int i, numElements;
    
    // Need to begin a path here.
    CGPathRef           immutablePath = NULL;
    
    // Then draw the path elements.
    numElements = [self elementCount];
    if (numElements > 0)
    {
        CGMutablePathRef    path = CGPathCreateMutable();
        NSPoint             points[3];
        BOOL                didClosePath = YES;
        
        for (i = 0; i < numElements; i++)
        {
            switch ([self elementAtIndex:i associatedPoints:points])
            {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                    break;
                    
                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                    didClosePath = NO;
                    break;
                    
                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                          points[1].x, points[1].y,
                                          points[2].x, points[2].y);
                    didClosePath = NO;
                    break;
                    
                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
                    didClosePath = YES;
                    break;
            }
        }
        
        // Be sure the path is closed or Quartz may not do valid hit detection.
        if (!didClosePath)
            CGPathCloseSubpath(path);
        
        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
    }
    
    return immutablePath;
}
@end

@interface LMGradientTitleButton ()
{
    NSTrackingArea *trackingArea;
    BOOL mouseEnter;
    BOOL mouseDown;
}
@end
@implementation LMGradientTitleButton

- (instancetype)init{
    self = [super init];
    if (self) {
        [self setDefault];
    }
    return self;
}
- (instancetype)initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setDefault];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setDefault];
}

- (void)setDefault{
    self.bordered = NO;
    
    _isGradient = YES;
    _isBorder = YES;
    _radius = 2;
    _lineWidth = 1;
    _titleNormalColor = [NSColor colorWithHex:0x94979B];
    _titleHoverColor = [NSColor colorWithHex:0xAFAFAF];
    _titleDownColor = [NSColor colorWithHex:0x7E7E7E];
    _titleDisableColor = [NSColor colorWithHex:0x7E7E7E];
    _normalColor = [NSColor colorWithHex:0xE5E5E5];
    _hoverColor = [NSColor colorWithHex:0xF3F3F3];
    _downColor = [NSColor colorWithHex:0xD4D4D4];
    _disableColor = [NSColor colorWithHex:0x858585];
    _fillColor = [NSColor whiteColor];
    _normalColorArray = [NSArray arrayWithObjects:[NSColor colorWithHex:0x64DFA7],
                         [NSColor colorWithHex:0x00D899], nil];
    _hoverColorArray = [NSArray arrayWithObjects:[NSColor colorWithHex:0x69E8AE],
                        [NSColor colorWithHex:0x00E9A5], nil];
    _downColorArray = [NSArray arrayWithObjects:[NSColor colorWithHex:0x61CE9C],
                       [NSColor colorWithHex:0x00D093], nil];
    _disableColorArray = [NSArray arrayWithObjects:[NSColor colorWithHex:0xD7F7EC],
                          [NSColor colorWithHex:0xD7F7EC], nil];
}
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    if (self.isGradient) {
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:self.radius yRadius:self.radius];
        NSGradient *gradient = nil;
        NSColor *textColor = nil;
        gradient = [[NSGradient alloc] initWithColors:self.normalColorArray];
        textColor = self.titleNormalColor;
        if (self.enabled) {
            if (mouseDown) {
                if(self.downColorArray)
                    gradient = [[NSGradient alloc] initWithColors:self.downColorArray];
                if(self.titleDownColor)
                    textColor = self.titleDownColor;
            } else if (mouseEnter) {
                if(self.hoverColorArray)
                    gradient = [[NSGradient alloc] initWithColors:self.hoverColorArray];
                if(self.titleHoverColor)
                    textColor = self.titleHoverColor;
            }
        } else {
            if(self.disableColorArray)
                gradient = [[NSGradient alloc] initWithColors:self.disableColorArray];
            if(self.titleDisableColor)
                textColor = self.titleDisableColor;
        }
        [gradient drawInBezierPath:path angle:self.angle];
        
        NSDictionary *tdic = @{NSFontAttributeName:self.font,
                               NSForegroundColorAttributeName: textColor};
        NSRect tr = [self.title boundingRectWithSize:self.bounds.size options:NSStringDrawingUsesLineFragmentOrigin attributes:tdic];
        [self.title drawAtPoint:NSMakePoint((self.bounds.size.width-tr.size.width)/2.0, (self.bounds.size.height-tr.size.height)/2.0) withAttributes:tdic];
    } else {
//        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:dirtyRect xRadius:self.radius yRadius:self.radius];
//        [[NSColor whiteColor] set];
//        [path fill];
        NSColor *strokeColor = nil;
        NSColor *textColor = nil;
        strokeColor = self.normalColor;
        textColor = self.titleNormalColor;
        if (self.enabled) {
            if(mouseDown) {
                if(self.downColor)
                    strokeColor = self.downColor;
                if(self.titleDownColor)
                    textColor = self.titleDownColor;
            }
            else if (mouseEnter) {
                if(self.hoverColor)
                    strokeColor = self.hoverColor;
                if(self.titleHoverColor)
                    textColor = self.titleHoverColor;
            }
        } else {
            if(self.disableColor)
                strokeColor = self.disableColor;
            if(self.titleDisableColor)
                textColor = self.titleDisableColor;
        }
//        if (self.isBorder) {
//            path.lineWidth = self.lineWidth;
//            [strokeColor set];
//            [path stroke];
//        }
        CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
        CGContextSetFillColorWithColor(context, _fillColor.CGColor);
        CGContextSetLineWidth(context, self.lineWidth);
        CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
        CGPathRef clippath = [[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(self.lineWidth/2, self.lineWidth/2, dirtyRect.size.width-self.lineWidth, dirtyRect.size.height-self.lineWidth) xRadius:self.radius yRadius:self.radius] quartzPath];
        CGContextAddPath(context, clippath);
        CGContextDrawPath(context, kCGPathFillStroke);
        
        NSDictionary *tdic = @{NSFontAttributeName:self.font,
                               NSForegroundColorAttributeName: textColor};
        NSRect tr = [self.title boundingRectWithSize:self.bounds.size options:NSStringDrawingUsesLineFragmentOrigin attributes:tdic];
        [self.title drawAtPoint:NSMakePoint((self.bounds.size.width-tr.size.width)/2.0, (self.bounds.size.height-tr.size.height)/2.0) withAttributes:tdic];
    }
}


- (void)setEnabled:(BOOL)flag
{
    [super setEnabled:flag];
    [self setNeedsDisplay];
}

- (BOOL)isMouseEnter
{
    return mouseEnter && [NSEvent mouseInView:self];
}

- (void)updateTrackingAreas
{
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

- (void)mouseEntered:(NSEvent *)event
{
    if (!self.isEnabled)
    {
        return;
    }
    
    mouseEnter = YES;
    [self setNeedsDisplay];
}

- (void)mouseExited:(NSEvent *)event
{
    if (!self.isEnabled)
    {
        return;
    }
    
    mouseEnter = NO;
    [self setNeedsDisplay];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (!self.isEnabled)
    {
        return;
    }
    
    mouseDown = YES;
    [self setNeedsDisplay];
}

- (void)mouseUp:(NSEvent *)event {
    if (!self.isEnabled)
    {
        return;
    }
    
    mouseDown = NO;
    [self setNeedsDisplay];
    
    if ([NSEvent mouseInView:self])
    {
        [self sendAction:self.action to:self.target];
    }
}

@end
