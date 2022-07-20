//
//  LMNetSpeedAniView.m
//  LemonNetSpeed
//
//  
//  Copyright © 2019年 tencent. All rights reserved.
//

#import "LMNetSpeedAniView.h"
#import <QMCoreFunction/NSColor+Extension.h>

@interface LMNetSpeedAniView()

@property (assign, nonatomic) NSInteger showViewNums;
//@property (weak, nonatomic) CAGradientLayer *gradintLayer;

@end

@implementation LMNetSpeedAniView

-(void)awakeFromNib{
    [super awakeFromNib];
    [self setWantsLayer:YES];
//    [self.layer setBackgroundColor:[NSColor whiteColor].CGColor];
}

//圆弧总共260度，总共27个小view，超过27M 全部点亮
-(void)updateAniViewByspeedValueString:(NSString *)speedValueString{
    
    double speedValue = [speedValueString doubleValue];
    
    //NOTE:该行必须放在if之前，否则if兜底无效，showViewNums有几率出现大数。
    self.showViewNums = [speedValueString integerValue] / (1024 * 1024);
    
    if (speedValue < 1024) {//小于1KB 全部不显示
        self.showViewNums = 0;
    }
    if (speedValue < 1024 * 1024) {//如果小于1M 只亮一个view
        self.showViewNums = 1;
    }
    if (speedValue > 28 * 1024 * 1024) {//大于28M直接全部点亮
        self.showViewNums = 28;
    }
    
    [self setNeedsDisplay:YES];
}

- (BOOL)isFlipped{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    NSPoint centerPoint = NSMakePoint(self.bounds.size.width / 2, self.bounds.size.width / 2);
    CGFloat radius = (self.bounds.size.width - 10) / 2;
    
    //先画背景圆弧
    NSBezierPath *backCirclePath = [NSBezierPath bezierPath];
    [backCirclePath appendBezierPathWithArcWithCenter:centerPoint radius:radius startAngle:-228 endAngle:48 clockwise:NO];
    backCirclePath.lineWidth = 8;
    NSColor *backCircleColor = [NSColor colorWithHex:0xe8e8e8];
    [backCircleColor setStroke];
    [backCirclePath stroke];
    [backCirclePath closePath];
    
    //再画当前进度圆弧
    NSBezierPath *currentCirclePath = [NSBezierPath bezierPath];
    float netRadius = self.showViewNums * 10 - 224;
    [currentCirclePath appendBezierPathWithArcWithCenter:centerPoint radius:radius startAngle:-228 endAngle:netRadius clockwise:NO];
    currentCirclePath.lineWidth = 8;
    
    NSColor *currentCircleColor = [NSColor colorWithHex:0xFFBE46];
    [currentCircleColor setStroke];
    [currentCirclePath stroke];

//    if (self.gradintLayer) {
//        [self.gradintLayer removeFromSuperlayer];
//    }
//    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
//    shapeLayer.frame = self.bounds;
//    shapeLayer.path = (__bridge CGPathRef _Nullable)(currentCirclePath);
//    shapeLayer.fillColor = [NSColor clearColor].CGColor;
//    shapeLayer.strokeColor = [NSColor blackColor].CGColor;
//    shapeLayer.strokeStart = 0;
//    shapeLayer.strokeEnd = 1;
//    shapeLayer.lineWidth = 8;
//    shapeLayer.lineCap = kCALineCapRound;
//
//    CAGradientLayer *layer = [[CAGradientLayer alloc] init];
//    layer.frame = self.bounds;
//    layer.colors = @[(__bridge id)[NSColor redColor].CGColor, (__bridge id)[NSColor blueColor].CGColor];
//    layer.locations = @[@0, @1];
//    layer.startPoint = CGPointMake(0, 0);
//    layer.endPoint = CGPointMake(1, 0);
//    layer.mask = shapeLayer;
    //    [self.layer addSublayer:layer];
//    self.gradintLayer = layer;
    
    [currentCirclePath closePath];
    
    NSInteger startR = self.bounds.size.width / 2 - 14;
    NSInteger endR = self.bounds.size.width / 2 - 28;
    //画出所有的小view
    for (NSInteger i = 0; i < 28; i++) {//拿到所有的点
        //第一个点的角度
        double theta = -225 + i * 10;
        //先计算y
        double yStart;
        double yEnd;
        yStart = startR * sin(theta / 180 * M_PI);
        yEnd = endR * sin(theta / 180 * M_PI);
        //在计算x
        double xStart;
        double xEnd;
        xStart = startR * cos(theta / 180 * M_PI);
        xEnd = endR * cos(theta / 180 * M_PI);
        
//        NSLog(@"theta = %f,sinQ= %f, cosQ = %f, ys = %f, ye = %f, xs = %f, xe = %f",theta, sin(theta/ 180 * M_PI), cos(theta/ 180 * M_PI),yStart, yEnd, xStart, xEnd);
        //起始点
        NSPoint start = NSMakePoint(centerPoint.x + xStart, centerPoint.y + yStart);
        NSPoint end = NSMakePoint(centerPoint.x + xEnd, centerPoint.y + yEnd);
        NSBezierPath *path = [NSBezierPath bezierPath];
//        [path appendBezierPathWithArcFromPoint:start toPoint:end radius:0];
        [path moveToPoint:start];
        [path lineToPoint:end];
        path.lineWidth = 4;
        NSColor *pathColor;
        if (i <= self.showViewNums) {
            pathColor = [NSColor colorWithHex:0xFFBE46];
        }else{
            pathColor = [NSColor colorWithHex:0xe8e8e8];
        }
        
        [pathColor setStroke];
        [path stroke];
        [path closePath];
    }
}

@end
