//
//  MMDrawingUtils.m
//  MiniMail
//
//  Created by DINH Viêt Hoà on 21/02/10.
//  Copyright 2011 Sparrow SAS. All rights reserved.
//

#import "MMDrawingUtils.h"

void MMFillRoundedRect(NSRect rect, CGFloat x, CGFloat y)
{
    NSBezierPath* thePath = [NSBezierPath bezierPath];
	
    [thePath appendBezierPathWithRoundedRect:rect xRadius:x yRadius:y];
    [thePath fill];
}

void MMStrokeRoundedRect(NSRect rect, CGFloat x, CGFloat y)
{
    NSBezierPath* thePath = [NSBezierPath bezierPath];
	
	[thePath setLineWidth:1];
    [thePath appendBezierPathWithRoundedRect:rect xRadius:x yRadius:y];
    [thePath stroke];
}

static void MMDrawPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    float fw, fh;
    
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    
    CGContextSaveGState(context);
    
    CGContextTranslateCTM (context, CGRectGetMinX(rect),
                           CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    CGContextClosePath(context);
    
    CGContextRestoreGState(context);
}

void MMCGContextFillRoundRect(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    MMDrawPath(context, rect, ovalWidth, ovalHeight);
    CGContextEOFillPath(context);
}

void MMCGContextStrokeRoundRect(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    MMDrawPath(context, rect, ovalWidth, ovalHeight);
    CGContextStrokePath(context);
}
