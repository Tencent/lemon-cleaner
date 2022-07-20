//
//  CircleProportionView.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "CircleProportionView.h"
#import <QMCoreFunction/NSColor+Extension.h>

@interface CircleProportionView()
{
    CGFloat _progress;
    NSUInteger _sysFullSize;
    NSUInteger _appFullSize;
    NSUInteger _intFullSize;
    NSTrackingArea * _trackingArea;
    CGFloat sysStartAngle;
    CGFloat sysEndAngle;
    CGFloat appStartAngle;
    CGFloat appEndAngle;
    CGFloat intStartAngle;
    CGFloat intEndAngle;
    NSUInteger firstArc;//最开始停放的位置
    NSUInteger inArc;//在哪个arc里
    BOOL isPointInArc;
    NSTimeInterval firstTime;//最开始停留的时间
    NSTimer *timer;
}
@end

@implementation CircleProportionView

-(instancetype)initWithCoder:(NSCoder *)decoder{
    self = [super initWithCoder:decoder];
//    [self setWantsLayer:YES];
//
    
    return self;
}

-(void)setProgress:(CGFloat) progress{
    _progress = progress;
}

-(BOOL)isFlipped{
    return true;
}

-(void)setSysFullSize:(NSUInteger) sysFullSize appFullSize:(NSUInteger) appFullSize intFullSize:(NSUInteger) intFullSize{
//    [self.layer setAnchorPoint:CGPointMake(1, 1)];
//    [self.layer setBackgroundColor:[NSColor redColor].CGColor];
//    self.layer setpo
//    [self.layer setAffineTransform:CGAffineTransformMakeRotation(M_PI_2)];
    _sysFullSize = sysFullSize;
    _appFullSize = appFullSize;
    _intFullSize = intFullSize;
    [self setNeedsDisplay:YES];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    if(_trackingArea) {
        [self removeTrackingArea:_trackingArea];
    }
    _trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                 options:NSTrackingActiveAlways|NSTrackingMouseMoved
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

-(void)startTimer{
    timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(processAnimate) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

-(void)processAnimate{
//    inArc = firstArc;
//    [self setNeedsDisplay:YES];
//    [self.delegate selectCategory:inArc];
//
////    CGEventRef ourEvent = CGEventCreate(NULL);
////    NSPoint point = CGEventGetLocation(ourEvent);
////    CFRelease(ourEvent);
//
    NSPoint point = [NSEvent mouseLocationInView:self];

//    NSLog(@"Location? x= %f, y = %f", (float)point.x, (float)point.y);
    [self processTheArcWidth:point];
    
}

-(void)stopTimer{
    [timer invalidate];
    timer = nil;
}

- (void)mouseMoved:(NSEvent *)event{
//    NSLog(@"mouseMoved .......");
    NSPoint locationInWindowPoint = [event locationInWindow];
    NSPoint localPoint = [self convertPoint:locationInWindowPoint fromView:nil];
    
    [self processTheArcWidth:localPoint];
}

-(void)processTheArcWidth:(NSPoint) locationPoint{
    NSPoint originPoint = NSZeroPoint;
    if (self.isFlipped) {
        originPoint = NSMakePoint(locationPoint.x, self.frame.size.height - locationPoint.y);
    }
    
    //首先判断是否落在圆弧内
    BOOL isPointInCircle = NO;
    NSPoint centerPoint = NSMakePoint(self.bounds.size.width / 2, self.bounds.size.width / 2);
    NSPoint circlePoint = NSMakePoint(originPoint.x - centerPoint.x, originPoint.y - centerPoint.y);
    CGFloat bigCircleWidth = (self.bounds.size.width - 24) / 2;
    CGFloat samllCircleWidth = bigCircleWidth - 20;
    CGFloat r = sqrtf(pow(circlePoint.x, 2) + pow(circlePoint.y, 2));
    
    //    NSLog(@"originPoint = %@ circlePoint=%@ r = %f big = %f small = %f", NSStringFromPoint(originPoint), NSStringFromPoint(circlePoint), r, bigCircleWidth, samllCircleWidth);
    if ((bigCircleWidth >= r) && (r >= samllCircleWidth)) {
        isPointInCircle = YES;
    }
    
    if (isPointInCircle) {
        CGFloat angle = 0;
        //先判断该点在哪个象限 在计算该点所在角度
        if ((circlePoint.x > 0) && (circlePoint.y > 0)) { //1
            angle = acos(fabs(circlePoint.y / r)) * (180 / M_PI);
        }else if ((circlePoint.x > 0) && (circlePoint.y < 0)){//2
            angle = asin(fabs(circlePoint.y / r))* (180 / M_PI) + 90;
        }else if ((circlePoint.x < 0) && (circlePoint.y < 0)){//3
            angle = acos(fabs(circlePoint.y / r))* (180 / M_PI) + 180;
        }else if ((circlePoint.x < 0) && (circlePoint.y > 0)){//4
            angle = asin(fabs(circlePoint.y / r))* (180 / M_PI) + 270;
        }
        
        //判断该交度在哪个弧段内
        BOOL needDrawRect = NO;
        if ((angle > sysStartAngle) && (sysEndAngle > angle)) {
            if (firstArc != 1) {
                [self stopTimer];
                [self startTimer];
                firstArc = 1;
                firstTime = [[NSDate date] timeIntervalSince1970];
            }else{
                CGFloat period = [self getPeriodInMouseMove];
                if (period > 0.3) {
                    inArc = 1;
                    isPointInArc = YES;
                    needDrawRect = YES;
                }
            }
            
        }else if ((angle > appStartAngle) && (appEndAngle > angle)){
            if (firstArc != 2) {
                [self stopTimer];
                [self startTimer];
                firstArc = 2;
                firstTime = [[NSDate date] timeIntervalSince1970];
            }else{
                CGFloat period = [self getPeriodInMouseMove];
                if (period > 0.3) {
                    inArc = 2;
                    isPointInArc = YES;
                    needDrawRect = YES;
                }
            }
            
        }else if ((angle > intStartAngle) && (intEndAngle > angle)){
            if (firstArc != 3) {
                [self stopTimer];
                [self startTimer];
                firstArc = 3;
                firstTime = [[NSDate date] timeIntervalSince1970];
            }else{
                CGFloat period = [self getPeriodInMouseMove];
                if (period > 0.3) {
                    inArc = 3;
                    isPointInArc = YES;
                    needDrawRect = YES;
                }
            }
            
        }else{
            [self stopTimer];
            needDrawRect = YES;
            firstArc = 0;
            firstTime = [[NSDate date] timeIntervalSince1970];
            inArc = 0;
        }
        
        if (needDrawRect) {
            [self setNeedsDisplay:YES];
            [self.delegate selectCategory:inArc];
        }
        
        //        NSLog(@"seiTa = %f 所在的弧段 = %ld", angle, inArc);
    }else{
        [self stopTimer];
        if (isPointInArc) {
            inArc = 0;
            isPointInArc = NO;
            [self setNeedsDisplay:YES];
            [self.delegate selectCategory:0];
        }
        firstArc = 0;
        firstTime = [[NSDate date] timeIntervalSince1970];
    }
}

-(CGFloat) getPeriodInMouseMove{
    NSTimeInterval nowTime = [[ NSDate date] timeIntervalSince1970];
    CGFloat period = nowTime - firstTime;
    return period;
}

//93F555绿色  F9EA0F黄色 21DB8A蓝色 18 36
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSUInteger totalSize = _sysFullSize + _appFullSize + _intFullSize;
    if(totalSize == 0)
        return;
    
    CGFloat sysProgress = ((CGFloat)_sysFullSize)/totalSize;
    CGFloat appProgress = ((CGFloat)_appFullSize)/totalSize;
    CGFloat intProgress = ((CGFloat)_intFullSize)/totalSize;
    //获取最大的那个比例
    CGFloat extraValue = 0.0;
    if (sysProgress > appProgress) {
        if (sysProgress > intProgress) {
            if ((appProgress > 0) &&  (appProgress < 0.03)){
                extraValue += (0.03 - appProgress);
                appProgress = 0.03;
            }
            if ((intProgress > 0) && (intProgress < 0.03)){
                extraValue += (0.03 - intProgress);
                intProgress = 0.03;
            }
            
            sysProgress -= extraValue;
        }else{
            if ((appProgress > 0) &&  (appProgress < 0.03)){
                extraValue += (0.03 - appProgress);
                appProgress = 0.03;
            }
            if ((sysProgress > 0) &&  (sysProgress < 0.03)){
                extraValue += (0.03 - sysProgress);
                sysProgress = 0.03;
            }
            
            intProgress -= extraValue;
        }
    }else{
        if (appProgress > intProgress) {
            if ((sysProgress > 0) &&  (sysProgress < 0.03)){
                extraValue += (0.03 - sysProgress);
                sysProgress = 0.03;
            }
            if ((intProgress > 0) &&  (intProgress < 0.03)){
                extraValue += (0.03 - intProgress);
                intProgress = 0.03;
            }
            
            appProgress -= extraValue;
        }else{
            if ((sysProgress > 0) &&  (sysProgress < 0.03)){
                extraValue += (0.03 - sysProgress);
                sysProgress = 0.03;
            }
            if ((appProgress > 0) &&  (appProgress < 0.03)){
                extraValue += (0.03 - appProgress);
                appProgress = 0.03;
            }
            
            intProgress -= extraValue;
        }
    }
    
    
//    CGFloat sysProgress = 0;
//    CGFloat appProgress = 0;
//    CGFloat intProgress = 1;
    
    NSInteger zeroCount = 0;
    if (sysProgress == 0) {
        zeroCount ++;
    }
    if (appProgress == 0) {
        zeroCount++;
    }
    if (intProgress == 0) {
        zeroCount++;
    }
    
    CGFloat circleDegree = 360;
    if (zeroCount < 2) {
        circleDegree -= (3 - zeroCount) * 4;
    }
    
    // Drawing code here.
    CGFloat width = self.bounds.size.width - 40;
    CGFloat radius = (width - 10) / 2;
    
    NSPoint centerPoint = NSMakePoint(self.bounds.size.width / 2, self.bounds.size.width / 2);
    
    CGFloat startAngle = 0;
    CGFloat endAngle = -90;
    if (sysProgress > 0) {
        if((appProgress == 0) && (intProgress == 0)){
            startAngle = -90;
            endAngle = sysProgress * 360 - 90;
        }else{
            startAngle = -88;
            endAngle = sysProgress * circleDegree - 88;
        }
        
        sysStartAngle = startAngle + 90;
        sysEndAngle = endAngle + 90;
        
        NSBezierPath *sysPathArch = [NSBezierPath bezierPath];
        NSColor *color1 = nil;
        if ((inArc == 1) || (inArc == 0)) {
            if (inArc == 0) {
                sysPathArch.lineWidth = 20.0;
            }else{
                sysPathArch.lineWidth = 30.0;
            }
            color1 = [NSColor colorWithHex:0xFFA10F];
        }else{
            sysPathArch.lineWidth = 20.0;
            color1 = [NSColor colorWithHex:0xFFA10F alpha:0.5];
        }
        
        [sysPathArch appendBezierPathWithArcWithCenter:centerPoint radius:radius startAngle:startAngle endAngle:endAngle clockwise:NO];
        
        [color1 setStroke];
        [sysPathArch stroke];
        [sysPathArch closePath];
    }else{
        sysStartAngle = 0;
        sysEndAngle = 0;
    }
    
    if(appProgress > 0){
        if((sysProgress == 0) && (intProgress == 0)){
            startAngle = endAngle;
            endAngle = (sysProgress + appProgress) * 360 - 90;
        }else{
            if (sysProgress == 0) {
                startAngle = -88;
            }else{
                startAngle = endAngle + 4;
            }
            if (intProgress == 0) {
                endAngle = 268;
            }else{
                endAngle = appProgress * circleDegree + startAngle;
            }
            
        }
        
        appStartAngle = startAngle + 90;
        appEndAngle = endAngle + 90;
        
        NSBezierPath *appPathArch = [NSBezierPath bezierPath];
        NSColor *color2 = nil;
        if ((inArc == 2) || (inArc == 0)) {
            if (inArc == 0) {
                appPathArch.lineWidth = 20.0;
            }else{
                appPathArch.lineWidth = 30.0;
            }
            color2 = [NSColor colorWithHex:0xFFD410];
        }else{
            appPathArch.lineWidth = 20.0;
            color2 = [NSColor colorWithHex:0xFFD410 alpha:0.5];
        }
        [appPathArch appendBezierPathWithArcWithCenter:centerPoint radius:radius startAngle:startAngle endAngle:endAngle clockwise:NO];
        
        [color2 setStroke];
        [appPathArch stroke];
        [appPathArch closePath];
    }else{
        appStartAngle = 0;
        appEndAngle = 0;
    }
    
    if(intProgress > 0){
        if((sysProgress == 0) && (appProgress == 0)){
            startAngle = endAngle;
            endAngle = 270;
        }else{
            startAngle = endAngle + 4;
            endAngle = intProgress * circleDegree + startAngle;
        }
        
        intStartAngle = startAngle + 90;
        intEndAngle = endAngle + 90;
        
        NSColor *color3 = nil;
        NSBezierPath *intPathArch = [NSBezierPath bezierPath];
        if ((inArc == 3) || (inArc == 0)) {
            if (inArc == 0) {
                intPathArch.lineWidth = 20.0;
            }else{
                intPathArch.lineWidth = 30.0;
            }
            color3 = [NSColor colorWithHex:0xFFC046];
        }else{
            intPathArch.lineWidth = 20.0;
            color3 = [NSColor colorWithHex:0xFFC046 alpha:0.5];
        }
        [intPathArch appendBezierPathWithArcWithCenter:centerPoint radius:radius startAngle:startAngle endAngle:endAngle clockwise:NO];
        
        [color3 setStroke];
        [intPathArch stroke];
        [intPathArch closePath];
    }else{
        intStartAngle = 0;
        intStartAngle = 0;
    }
    
//    if((_sysSelectSize != 0) && ((_appSelectSize + _intSelectSize) == 0)){
//        NSBezierPath *sysSelectPathArch = [NSBezierPath bezierPath];
//        sysSelectPathArch.lineWidth = 20.0;
//        [sysSelectPathArch appendBezierPathWithArcWithCenter:centerPoint radius:width / 2 startAngle:-90 endAngle:sysProgress * 360 - 90 clockwise:NO];
//        NSColor *color4 = [NSColor colorWithHex:0xFFA10F];
//        [color4 setStroke];
//        [sysSelectPathArch stroke];
//        [sysSelectPathArch closePath];
//    }else if((_appSelectSize != 0) && ((_sysSelectSize + _intSelectSize) == 0)){
//        NSBezierPath *appSelectPathArch = [NSBezierPath bezierPath];
//        appSelectPathArch.lineWidth = 20.0;
//        [appSelectPathArch appendBezierPathWithArcWithCenter:centerPoint radius:width / 2 startAngle:sysProgress * 360 - 90 endAngle:(sysProgress + appProgress) * 360 - 90 clockwise:NO];
//        NSColor *color5 = [NSColor colorWithHex:0xFFD410];
//        [color5 setStroke];
//        [appSelectPathArch stroke];
//        [appSelectPathArch closePath];
//    }else if((_intSelectSize != 0) && ((_sysSelectSize + _appSelectSize) == 0)){
//        NSBezierPath *intSelectPathArch = [NSBezierPath bezierPath];
//        intSelectPathArch.lineWidth = 20.0;
//        [intSelectPathArch appendBezierPathWithArcWithCenter:centerPoint radius:width / 2 startAngle:(sysProgress + appProgress) * 360 - 90 endAngle:270 clockwise:NO];
//        NSColor *color6 = [NSColor colorWithHex:0xFFC046];
//        [color6 setStroke];
//        [intSelectPathArch stroke];
//        [intSelectPathArch closePath];
//    }
}

@end
