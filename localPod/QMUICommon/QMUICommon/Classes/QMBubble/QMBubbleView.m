//
//  QMBubbleView.m
//  QQMacMgrMonitor
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMBubbleView.h"

@interface QMBubbleView ()
{
    BOOL refreshShadow;
    NSBezierPath *bezierPath;
    CGPoint dragStartPoint;
    BOOL _inRubberForce;
}
@end

@implementation QMBubbleView
@synthesize direction,drawArrow,arrowHeight,arrowWidth,arrowDistance,cornerRadius;
@synthesize borderWidth,borderColor,backgroudColor;

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self)
    {
        [self setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setUp];
    }
    return self;
}

- (void)setUp
{
    direction = QMArrowRight;
    drawArrow = YES;
    arrowHeight = 10;
    arrowWidth = 10;
    cornerRadius = 4.0;
    arrowDistance = 0;
    borderWidth = 0;
    backgroudColor = [NSColor whiteColor];
    _inRubberForce =  YES;
}

- (void)refreshShadow
{
    refreshShadow = YES;
    [self setNeedsDisplay:YES];
}

- (BOOL)mouseInPath
{
    NSPoint point = [NSEvent mouseLocation];
    point = [self.window convertRectFromScreen:NSMakeRect(point.x, point.y, 0, 0)].origin;
    point = [self convertPoint:point fromView:nil];
    return [bezierPath containsPoint:point];
}

- (QMArrowDirection)faceDirection
{
    QMArrowDirection faceDirection = 0;
    
    switch (direction)
    {
        case QMArrowTop:
        case QMArrowTopLeft:
        case QMArrowTopRight:
        case QMArrowSideTop:
            faceDirection = QMArrowTop;
            break;
            
        case QMArrowBottom:
        case QMArrowBottomLeft:
        case QMArrowBottomRight:
        case QMArrowSideBottom:
            faceDirection = QMArrowBottom;
            break;
            
        case QMArrowLeft:
        case QMArrowLeftTop:
        case QMArrowLeftBottom:
        case QMArrowSideLeft:
            faceDirection = QMArrowLeft;
            break;
            
        case QMArrowRight:
        case QMArrowRightTop:
        case QMArrowRightBottom:
        case QMArrowSideRight:
            faceDirection = QMArrowRight;
            break;
            
        default:
            break;
    }
    
    return faceDirection;
}

- (QMArrowDirection)offsetDirection
{
    QMArrowDirection offsetDirection = 0;
    
    switch (direction)
    {
        case QMArrowLeft:
        case QMArrowRight:
        case QMArrowLeftTop:
        case QMArrowRightTop:
        case QMArrowSideTop:
            offsetDirection = QMArrowTop;
            break;
            
        case QMArrowLeftBottom:
        case QMArrowRightBottom:
        case QMArrowSideBottom:
            offsetDirection = QMArrowBottom;
            break;
            
        case QMArrowTop:
        case QMArrowBottom:
        case QMArrowTopLeft:
        case QMArrowBottomLeft:
        case QMArrowSideLeft:
            offsetDirection = QMArrowLeft;
            break;
            
        case QMArrowTopRight:
        case QMArrowBottomRight:
        case QMArrowSideRight:
            offsetDirection = QMArrowRight;
            break;
            
        default:
            break;
    }
    
    return offsetDirection;
}

- (NSRect)drawRect
{
    NSRect drawRect = NSInsetRect(self.bounds, borderWidth/2, borderWidth/2);
    return drawRect;
}

- (double)drawDistance
{
    NSRect drawRect = [self drawRect];
    
    double drawDistance = arrowDistance;
    drawDistance = MAX(drawDistance, arrowWidth/2);
    
    if (direction == QMArrowTop || direction == QMArrowBottom)
        drawDistance = NSWidth(drawRect)/2;
    if (direction == QMArrowLeft || direction == QMArrowRight)
        drawDistance = NSHeight(drawRect)/2;
    
    if (self.faceDirection == QMArrowTop || self.faceDirection == QMArrowBottom)
        drawDistance = MIN(drawDistance, NSWidth(drawRect)/2);
    if (self.faceDirection == QMArrowLeft || self.faceDirection == QMArrowRight)
        drawDistance = MIN(drawDistance, NSHeight(drawRect)/2);
    
    return drawDistance;
}

- (void)resetDragStartToCurrentPosition
{
    NSPoint location = [self.window convertRectFromScreen: (NSRect){[NSEvent mouseLocation], NSZeroSize}].origin;
    dragStartPoint = location;
    _inRubberForce = YES;
}

- (NSPoint)arrowPoint
{
    NSRect drawRect = [self drawRect];
    
    NSPoint point = NSZeroPoint;
    if (direction &  QMArrowSideTop) {
        point.y = NSMaxY(drawRect);
    } else if (direction & QMArrowSideBottom) {
        point.y = NSMinY(drawRect);
    }
    
    if (direction & QMArrowLeft) {
        point.x = NSMinX(drawRect) + arrowDistance + arrowWidth;
    } else if (direction & QMArrowRight) {
        point.x = NSMaxX(drawRect) - arrowDistance - arrowWidth;
    } else {
        point.x = NSMidX(drawRect);
    }
    return point;
}

- (void)resetBezierPath
{
    NSRect drawRect = [self drawRect];
    
    if (!drawArrow)
    {
        if (self.titleMode == QMBubbleTitleModeTitleBar) {
            if (self.direction & QMArrowSideTop) {
                drawRect.size.height -= arrowHeight;
            } else if (self.direction & QMArrowSideLeft) {
                drawRect.origin.x += arrowHeight;
                drawRect.size.width -= arrowHeight;
            } else if (self.direction & QMArrowSideBottom) {
                drawRect.size.height -= arrowHeight;
                drawRect.origin.y += arrowHeight;
            } else if (self.direction & QMArrowSideRight) {
                drawRect.size.width -= arrowHeight;
            }
            bezierPath = [NSBezierPath bezierPathWithRoundedRect:drawRect xRadius:cornerRadius yRadius:cornerRadius];
        } else {
            bezierPath = [NSBezierPath bezierPathWithRoundedRect:drawRect xRadius:cornerRadius yRadius:cornerRadius];
        }
        return;
    }
    
    double drawDistance = [self drawDistance];
    bezierPath = [NSBezierPath bezierPath];
    BOOL topOrBottom = (direction & QMArrowSideTop) || (direction & QMArrowSideBottom);
    
    if (topOrBottom) {
        //绘制上左角的图形,其它上下方向形状的可通过此图形变幻而来
        if (drawDistance < arrowWidth/2+cornerRadius)
        {
            [bezierPath moveToPoint:NSMakePoint(NSMinX(drawRect), NSMaxY(drawRect)-arrowHeight-cornerRadius/2)];
        }else
        {
            [bezierPath moveToPoint:NSMakePoint(NSMinX(drawRect), NSMaxY(drawRect)-arrowHeight-cornerRadius)];
            [bezierPath appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(drawRect), NSMaxY(drawRect)-arrowHeight)
                                                 toPoint:NSMakePoint(NSMinX(drawRect)+cornerRadius, NSMaxY(drawRect)-arrowHeight)
                                                  radius:cornerRadius];
            [bezierPath lineToPoint:NSMakePoint(NSMinX(drawRect)+drawDistance-arrowWidth/2, NSMaxY(drawRect)-arrowHeight)];
        }
        [bezierPath lineToPoint:NSMakePoint(NSMinX(drawRect)+drawDistance, NSMaxY(drawRect))];
        [bezierPath lineToPoint:NSMakePoint(NSMinX(drawRect)+drawDistance+arrowWidth/2, NSMaxY(drawRect)-arrowHeight)];
        [bezierPath lineToPoint:NSMakePoint(NSMaxX(drawRect)-cornerRadius, NSMaxY(drawRect)-arrowHeight)];
        
        [bezierPath appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(drawRect), NSMaxY(drawRect)-arrowHeight)
                                             toPoint:NSMakePoint(NSMaxX(drawRect), NSMaxY(drawRect)-arrowHeight-cornerRadius)
                                              radius:cornerRadius];
        [bezierPath lineToPoint:NSMakePoint(NSMaxX(drawRect), NSMinY(drawRect)+cornerRadius)];
        
        [bezierPath appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(drawRect), NSMinY(drawRect))
                                             toPoint:NSMakePoint(NSMaxX(drawRect)-cornerRadius, NSMinY(drawRect))
                                              radius:cornerRadius];
        [bezierPath lineToPoint:NSMakePoint(NSMinX(drawRect)+cornerRadius, NSMinY(drawRect))];
        
        [bezierPath appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(drawRect), NSMinY(drawRect))
                                             toPoint:NSMakePoint(NSMinX(drawRect), NSMinY(drawRect)+cornerRadius)
                                              radius:cornerRadius];
        [bezierPath closePath];
    } else {
        //绘制左上角的图形,其它左右方向形状的可通过此图形变幻而来
        if (arrowHeight>0 && drawDistance < arrowWidth/2+cornerRadius)
        {
            [bezierPath moveToPoint:NSMakePoint(NSMinX(drawRect)+arrowHeight+cornerRadius/2, NSMaxY(drawRect))];
        }else
        {
            [bezierPath moveToPoint:NSMakePoint(NSMinX(drawRect)+arrowHeight+cornerRadius, NSMaxY(drawRect))];
            [bezierPath appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(drawRect)+arrowHeight, NSMaxY(drawRect))
                                                 toPoint:NSMakePoint(NSMinX(drawRect)+arrowHeight, NSMaxY(drawRect)-cornerRadius)
                                                  radius:cornerRadius];
            [bezierPath lineToPoint:NSMakePoint(NSMinX(drawRect)+arrowHeight, NSMaxY(drawRect)-drawDistance+arrowWidth/2)];
        }
        
        [bezierPath lineToPoint:NSMakePoint(NSMinX(drawRect), NSMaxY(drawRect)-drawDistance)];
        [bezierPath lineToPoint:NSMakePoint(NSMinX(drawRect)+arrowHeight, NSMaxY(drawRect)-drawDistance-arrowWidth/2)];
        [bezierPath lineToPoint:NSMakePoint(NSMinX(drawRect)+arrowHeight, NSMinY(drawRect)+cornerRadius)];
        
        [bezierPath appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(drawRect)+arrowHeight, NSMinY(drawRect))
                                             toPoint:NSMakePoint(NSMinX(drawRect)+arrowHeight+cornerRadius, NSMinY(drawRect))
                                              radius:cornerRadius];
        [bezierPath lineToPoint:NSMakePoint(NSMaxX(drawRect)-cornerRadius, NSMinY(drawRect))];
        
        [bezierPath appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(drawRect), NSMinY(drawRect))
                                             toPoint:NSMakePoint(NSMaxX(drawRect), NSMinY(drawRect)+cornerRadius)
                                              radius:cornerRadius];
        [bezierPath lineToPoint:NSMakePoint(NSMaxX(drawRect), NSMaxY(drawRect)-cornerRadius)];
        
        [bezierPath appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(drawRect), NSMaxY(drawRect))
                                             toPoint:NSMakePoint(NSMaxX(drawRect)-cornerRadius, NSMaxY(drawRect))
                                              radius:cornerRadius];
        [bezierPath closePath];
    }
    
    NSAffineTransform *transform = [NSAffineTransform transform];
    if (topOrBottom) {
        if (direction & QMArrowSideBottom) {
            //上下翻转
            [transform translateXBy:0 yBy:NSHeight(self.bounds)];
            [transform scaleXBy:1.0 yBy:-1.0];
        }
        if (direction & QMArrowRight) {
            //水平翻转
            [transform translateXBy:NSWidth(self.bounds) yBy:0];
            [transform scaleXBy:-1.0 yBy:1.0];
        }
    } else {
        if (direction & QMArrowSideRight) {
            //水平翻转
            [transform translateXBy:NSWidth(self.bounds) yBy:0];
            [transform scaleXBy:-1.0 yBy:1.0];
        }
        if (direction & QMArrowBottom) {
            //上下翻转
            [transform translateXBy:0 yBy:NSHeight(self.bounds)];
            [transform scaleXBy:1.0 yBy:-1.0];
        }
    }
    
    [bezierPath transformUsingAffineTransform:transform];
    [bezierPath setLineJoinStyle:NSRoundLineJoinStyle];
    [bezierPath setLineCapStyle:NSRoundLineCapStyle];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    
    [self resetBezierPath];
    
    [backgroudColor set];
    [bezierPath fill];
    
    if (borderColor && borderWidth > 0)
    {
        [borderColor set];
        [bezierPath setLineWidth:borderWidth];
        [bezierPath stroke];
    }
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    
    if ([self.window hasShadow] && refreshShadow)
    {
        // 在下一次runloop中更新shadow, 以保证以这次画出来的view形状为画shadow的依据
        [self.window performSelector:@selector(invalidateShadow) withObject:nil afterDelay:0];
    }
    refreshShadow = NO;
}

- (void)setTitleMode:(QMBubbleTitleMode)titleMode
{
    if (_titleMode == titleMode) return;
    _titleMode = titleMode;
    drawArrow = (titleMode == QMBubbleTitleModeArrow);
    refreshShadow = YES;
    [self setNeedsDisplay:YES];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    if (self.draggable) {
        dragStartPoint = [theEvent locationInWindow];
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [super mouseDragged:theEvent];
    if (self.draggable) {
        NSPoint origin = self.window.frame.origin;
        NSPoint currentOrigin = [theEvent locationInWindow];
        
        NSPoint diff = NSMakePoint(currentOrigin.x - dragStartPoint.x, currentOrigin.y - dragStartPoint.y);

        if (_inRubberForce) {
            double dist = sqrt(diff.x * diff.x + diff.y * diff.y);
            if (dist < self.distance) {
                return;
            }
        }
        origin.x += (currentOrigin.x - dragStartPoint.x);
        origin.y += (currentOrigin.y - dragStartPoint.y);
        _inRubberForce = NO;
        [self.window setFrameOrigin:origin];
    }
}

@end
