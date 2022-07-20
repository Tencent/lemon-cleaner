//
//  CGPath+Extension.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "CGPath+Extension.h"

struct _CGPathCopyInfo {
    CGMutablePathRef path;
    CGPoint lastPoint;
};

static void removeVerticalBorder(struct _CGPathCopyInfo *info, const CGPathElement *element);


CGMutablePathRef CGPathCopyByRemovingVerticalLine(CGPathRef const path)
{
    CGMutablePathRef result = CGPathCreateMutable();
    struct _CGPathCopyInfo info = {.path = result, .lastPoint = CGPointZero};
    CGPathApplierFunction function = (CGPathApplierFunction)removeVerticalBorder;
    CGPathApply(path, &info, function);
    return  result;
}

// 以下_CGPathCopyInfo与fuction用于去掉CGPathRef中的垂直线
static void removeVerticalBorder(struct _CGPathCopyInfo *info, const CGPathElement *element)
{
    CGPoint *p = element->points;
    CGMutablePathRef path = info->path;
    switch(element->type) {
        case kCGPathElementMoveToPoint:
            CGPathMoveToPoint(path, 0, p[0].x, p[0].y);
            info->lastPoint = p[0];
            break;
        case kCGPathElementAddCurveToPoint:
            CGPathAddCurveToPoint(path, 0, p[0].x, p[0].y, p[1].x, p[1].y, p[2].x, p[2].y);
            info->lastPoint = p[2];
            break;
        case kCGPathElementAddLineToPoint:
            if (p[0].x == info->lastPoint.x) {
                CGPathMoveToPoint(path, 0, p[0].x, p[0].y);
            } else {
                CGPathAddLineToPoint(path, 0, p[0].x, p[0].y);
            }
            break;
        case kCGPathElementAddQuadCurveToPoint:
            CGPathAddQuadCurveToPoint(path, NULL, p[0].x, p[0].y, p[1].x, p[1].y);
            break;
        case kCGPathElementCloseSubpath:
            CGPathCloseSubpath(path);
            break;
        default:
            break;
    }
}

