//
//  LMLineChartView.m
//  TestChart
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMLineChartView.h"
#import "NSColor+Extension.h"
#import <QMUICommon/LMAppThemeHelper.h>

@interface LMLineChartView() {
    CGFloat maxY;
    CGFloat kBuffer;
    CGFloat *__gridLineStyle;
    NSInteger __gridLineStyleLength;
    
    CGFloat *__axisLineStyle;
    NSInteger __axisLineStyleLength;
    NSMutableArray *pointCoordinaryCache;
    NSPoint mouseOnPoint;
    BOOL mouseOnSamplePoint;
}

@property (nonatomic, assign) NSRange xAxis;
@property (nonatomic, strong) NSMutableArray * dataSets;

@property (nonatomic, assign) NSArray<NSNumber *> *gridLineStyle;

@property (nonatomic, assign) NSArray<NSNumber *> *axisLineStyle;

@end

@implementation LMLineChartView


#define ERROR 10
- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        kBuffer = kBufferValue;
//        self.wantsLayer = YES;
//        self.layer.backgroundColor = [[NSColor whiteColor] CGColor];
//
        self.doesDrawGrid = NO;
        self.doesDrawXAxisLines = NO;
        self.doesDrawYAxisLines = NO;
        self.doesDrawXAxisTicks = NO;
        self.doesDrawYAxisTicks = NO;
        
        mouseOnSamplePoint = NO;
        
        self.axisLabelAttributes = @{NSFontAttributeName: [NSFont systemFontOfSize:14], NSForegroundColorAttributeName: [NSColor colorWithHex:0x949798]};
        self.axisLineColor = [NSColor lightGrayColor];
        self.gridLineColor = [NSColor colorWithRed:0xed/255.0 green:0xed/255.0 blue:0xed/255.0 alpha:1];
        //self.gridLineColor = [NSColor lightGrayColor];
        self.gridLineWidth = 1;
        
        self.gridLineStyle = nil;
        
        self.dataSets = [[NSMutableArray alloc] init];
        self.selectedPointRadius = 10;
        self.selectedPointLineWidth = 4;
        self.selectedPointColor = [NSColor colorWithRed:0xf3/255.0 green:0xcf/255.0 blue:0x31/255.0 alpha:1];
        if (@available(macOS 10.14, *)) {
            self.indicationBarColor = [NSColor colorNamed:@"linechartview_indicator_bar_color"];
        } else {
            self.indicationBarColor = [NSColor colorWithRed:0xff/255.0 green:0xe4/255.0 blue:0xae/255.0 alpha:0.3];
        }
        maxY = -MAXFLOAT;
        pointCoordinaryCache = [[NSMutableArray alloc] init];
        
        NSTrackingAreaOptions options = (NSTrackingActiveAlways | NSTrackingInVisibleRect |
                                         NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved);
        
        NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                            options:options
                                                              owner:self
                                                           userInfo:nil];
        [self addTrackingArea:area];
    }
    return self;
}

#pragma mark - Setters

- (void)setDoesDrawXAxisLines:(BOOL)doesDrawAxisXLines {
    _doesDrawXAxisLines = doesDrawAxisXLines;
    [self setNeedsDisplay:YES];
}

- (void)setDoesDrawYAxisLines:(BOOL)doesDrawAxisYLines {
    _doesDrawYAxisLines = doesDrawAxisYLines;
    [self setNeedsDisplay:YES];
}

- (void)setDoesDrawGrid:(BOOL)doesDrawGrid {
    _doesDrawGrid = doesDrawGrid;
    [self setNeedsDisplay:YES];
}

- (void)setAxisLineColor:(NSColor *)axisLineColor {
    _axisLineColor = axisLineColor;
    [self setNeedsDisplay:YES];
}

- (void)setAxisLabelAttributes:(NSDictionary *)axisLabelAttributes {
    _axisLabelAttributes = axisLabelAttributes;
    [self setNeedsDisplay:YES];
}

- (void)setGridLineColor:(NSColor *)gridLineColor{
    _gridLineColor = gridLineColor;
    [self setNeedsDisplay:YES];
}

- (void)setXAxis:(NSRange)xAxis {
    _xAxis = xAxis;
    [self setNeedsDisplay:YES];
}

- (void)setGridLineStyle:(NSArray<NSNumber *> *)dashLineStyle {
    if (__gridLineStyle)
    {
        free(__gridLineStyle);
        __gridLineStyle = nil;
        __gridLineStyleLength = 0;
    }
    if (dashLineStyle) {
        __gridLineStyleLength = dashLineStyle.count;
        __gridLineStyle = malloc(__gridLineStyleLength * sizeof(CGFloat));
        for (int i = 0; i<__gridLineStyleLength; i++)
        {
            __gridLineStyle[i] = [dashLineStyle[i] floatValue];
        }
    }
    [self setNeedsDisplay:YES];
}


- (void)setAxisLineStyle:(NSArray<NSNumber *> *)axisLineStyle {
    if (__axisLineStyle != nil) {
        free(__axisLineStyle);
        __axisLineStyle = nil;
        __axisLineStyleLength = 0;
    }
    if (axisLineStyle != nil) {
        __axisLineStyleLength =  axisLineStyle.count;
        __axisLineStyle = malloc(__axisLineStyleLength * sizeof(CGFloat));
        for (int i = 0; i<__axisLineStyleLength; i++)
        {
            __axisLineStyle[i] = [axisLineStyle[i] floatValue];
        }
    }
    [self setNeedsDisplay:YES];
}
#pragma mark - Managing Line(s)

- (void)removeDataSet:(LMDataSet *)dataSet {
    [self.dataSets removeObject:dataSet];
    if (self.dataSets.count == 0){
        maxY = -MAXFLOAT;
        [self setXAxis:NSMakeRange(0, 0)];
    }else{
        [self recalculateMaxY];
        // no need to recalculate xaxis if there is lines in the array, they should all have the same amount of values
    }
    [self setNeedsDisplay:YES];
}

- (void)clear{
    [self.dataSets removeAllObjects];
    maxY = -MAXFLOAT;
    [self setXAxis:NSMakeRange(0, 0)];
    [self setNeedsDisplay:YES];
}

- (void)addDataSet:(LMDataSet *)dataSet{
    
    if (self.dataSets.count > 0){
        NSAssert((dataSet.values.count == self.xAxis.length), @"Invalid additional line - different amount of values.");
    }else{
        [self setXAxis:NSMakeRange(0, dataSet.values.count)];
    }
    [self.dataSets addObject:dataSet];
    for (NSNumber * numb in dataSet.values){
        CGFloat y = [numb doubleValue];
        if (y > maxY){
            maxY = y;
        }
    }
    [self setNeedsDisplay:YES];
}

- (void)addDataSetWithYValues:(NSArray *)values{
    [self addDataSet:[[LMDataSet alloc] initWithValues:values withColor:[NSColor greenColor]]];
}

#pragma mark - Private -
#pragma mark C Math Functions
static inline CGFloat rounded(CGFloat value) {
    static const CGFloat preferred[10] = {1.25,  1.6,  2.0,  2.5,  3.15,  4.0,  5.0,  6.3,  8.0, 10.0};
    CGFloat mag = log10(value);
    CGFloat  power = pow(10,floor(mag));
    CGFloat msd = value/power;
    
    for (int i = 0; i < 10; i++){
        CGFloat h = preferred[i];
        if (h >= msd){
            return h * power;
        }
    }
    return 1.0 * power;
}

static inline CGFloat calculateAmountOfTicks(CGFloat heightOfView) { // 5 y labels per 200 points
    heightOfView -= 200;
    if (heightOfView < 200){
        return 5;
    }else{
        NSInteger ticks = 5;
        while (heightOfView >= 200) {
            heightOfView -= 200;
            ticks+=5;
        }
        return ticks;
    }
}

#pragma mark -

- (void)recalculateMaxY {
    maxY = -MAXFLOAT;
    for (LMDataSet *line in self.dataSets){
        for (NSNumber * numb in line.values){
            CGFloat y = [numb doubleValue];
            if (y > maxY){
                maxY = y;
            }
        }
    }
}

- (CGContextRef)_graphicsContext {
    return [[NSGraphicsContext currentContext] graphicsPort];
}

- (void)drawXAxisTicks:(CGFloat)numberOfXAxisTicks widthOffset:(CGFloat)widthOffset {
    for (NSInteger i = 0; i < numberOfXAxisTicks; i++) {
        NSString *xValueAtIndex = nil;
        if (self.xAxisLabels){
            xValueAtIndex = self.xAxisLabels[i];
        }else{
            xValueAtIndex = [NSString stringWithFormat:@"%ld", (long)i];
        }
        CGPoint point = CGPointMake([self xFory:i withLine:[(LMDataSet*)[self.dataSets firstObject] values]] + widthOffset, CGRectGetHeight(self.frame) - kBuffer+8);
        
        point.y = 0 + kBuffer - 16;
        
        [xValueAtIndex drawAtPoint:CGPointMake(point.x - [xValueAtIndex sizeWithAttributes:self.axisLabelAttributes].width/2, point.y) withAttributes:self.axisLabelAttributes];
    }
}

- (void)drawYAxisTicks:(CGFloat)distanceBetweenYAxisTicks numberOfYAxisTicks:(CGFloat)numberOfYAxisTicks representativeValueOfYAxisPerTick:(CGFloat)representativeValueOfYAxisPerTick showsDecimals:(BOOL)showsDecimals {
    for (int i = 0; i <= numberOfYAxisTicks; i++) {
        CGPoint point = CGPointMake(kBuffer , (self.frame.size.height - kBuffer) - (distanceBetweenYAxisTicks*i));
        
        point.y = 0 + kBuffer + (distanceBetweenYAxisTicks *i);
        
        CGFloat value = i*(CGFloat)representativeValueOfYAxisPerTick;
        NSString *intString = [NSString stringWithFormat:@"%0.0f", (CGFloat)value];
        if (showsDecimals){
            intString = [NSString stringWithFormat:@"%0.2f", i*(CGFloat)(representativeValueOfYAxisPerTick)];
        }
        
        CGSize sizeOfString = [intString sizeWithAttributes:self.axisLabelAttributes];
        [intString drawAtPoint:CGPointMake(point.x - sizeOfString.width - 8, point.y- [intString sizeWithAttributes:self.axisLabelAttributes].height/2) withAttributes:self.axisLabelAttributes];
        
    }
}

- (void)drawRect:(CGRect)rect {
    if (self.dataSets.count == 0) {
        return;
    }
    
    NSLog(@"draw %@", [NSThread currentThread]);
    [pointCoordinaryCache removeAllObjects];
    
    kBuffer = kBufferValue;
    CGFloat widthOffset = 0;
    
    CGFloat numberOfXAxisTicks = (self.xAxis.length);
    
    CGFloat numberOfYAxisTicks = calculateAmountOfTicks(CGRectGetHeight(self.frame));
    
    CGFloat maxYValue = rounded(maxY);
    
    if (maxYValue <= 0) {
        // nope. dont draw anything.
        return;
    }
    
    CGFloat representativeValueOfYAxisPerTick = maxYValue/numberOfYAxisTicks;
    
    
    CGFloat distanceBetweenYAxisTicks = (self.frame.size.height - kBuffer*2)/(numberOfYAxisTicks);
    
    BOOL showsDecimals = NO;
    if (maxYValue <= numberOfXAxisTicks){
        showsDecimals = YES;
    }
    
    if (self.doesDrawXAxisTicks) {
        
        [self drawXAxisTicks:numberOfXAxisTicks widthOffset:widthOffset];
        
    }
    
    if (self.doesDrawYAxisTicks) {
        [self drawYAxisTicks:distanceBetweenYAxisTicks numberOfYAxisTicks:numberOfYAxisTicks representativeValueOfYAxisPerTick:representativeValueOfYAxisPerTick showsDecimals:showsDecimals];
    }
    
    
    // draw axis line
    CGContextRef context = [self _graphicsContext];
    CGContextSetLineDash(context, 0, __axisLineStyle, __axisLineStyleLength);
    if (self.doesDrawXAxisLines){
        CGContextSetStrokeColorWithColor(context, [self.axisLineColor CGColor]);
        CGContextSetLineWidth(context, 1.0);
        
        CGFloat y = kBuffer;
        CGContextMoveToPoint(context, kBuffer,  y);
        CGContextAddLineToPoint(context, self.frame.size.width - kBuffer, y);
        CGContextDrawPath(context, kCGPathStroke);
    }
    
    if (self.doesDrawYAxisLines){
        CGContextSetStrokeColorWithColor(context, [self.axisLineColor CGColor]);
        CGContextSetLineWidth(context, 1.0);
        
        CGContextMoveToPoint(context, kBuffer,  CGRectGetHeight(self.frame) - kBuffer);
        CGFloat y = kBuffer;
        CGContextAddLineToPoint(context, kBuffer,  y);
        CGContextDrawPath(context, kCGPathStroke);
    }
    CGContextSetLineDash(context, 0, nil, 0);
    
    // draw grid
    if (self.doesDrawGrid) {
        //CGFloat lengths[] = {1,1};
        CGContextSetLineDash(context, 0, __gridLineStyle, __gridLineStyleLength);
        CGContextSetStrokeColorWithColor(context, [self.gridLineColor CGColor]);
        CGContextSetLineWidth(context, 1.0);
        
        // vertical grid line
        for (NSInteger i = 0; i < numberOfXAxisTicks; i++) {
            float x = [self xFory:i withLine:[(LMDataSet*)[self.dataSets firstObject] values]];
            CGContextMoveToPoint(context, x,  CGRectGetHeight(self.frame) - kBuffer);
            CGContextAddLineToPoint(context, x,  kBuffer);
            CGContextDrawPath(context, kCGPathStroke);
        }
        
        // horizontal grid line
        for (int i = 0; i <= numberOfYAxisTicks - 1; i++) {
            float y = 0 + kBuffer + (distanceBetweenYAxisTicks *i);
            CGContextMoveToPoint(context, kBuffer,  y);
            CGContextAddLineToPoint(context, self.frame.size.width - kBuffer,  y);
            CGContextDrawPath(context, kCGPathStroke);
        }
        
        CGContextSetLineDash(context, 0, nil, 0);
    }
    
    
    for (LMDataSet *dataSet in self.dataSets){
        [self drawLineForYValues:dataSet andMaxYValue:maxYValue onContext:context];
        
    }
    
    if (mouseOnSamplePoint) {
        [self drawIndicationBarAtX:mouseOnPoint.x onContext:context];
        [self drawPointAt:mouseOnPoint onContext:context];
    }
    
}

- (void) drawIndicationBarAtX:(CGFloat)x onContext:(CGContextRef)context {
    CGContextSetStrokeColorWithColor(context, [self.indicationBarColor CGColor]);
    //画线的宽度
    CGContextSetLineWidth(context, 0.25);
    CGContextSetFillColorWithColor(context, [self.indicationBarColor CGColor]);
    
    CGContextAddRect(context, CGRectMake(x - 25.0, kBuffer, 50, self.frame.size.height - 2 * kBuffer));
    CGContextDrawPath(context, kCGPathFillStroke);
    
}
- (void) drawPointAt:(NSPoint) point onContext:(CGContextRef)ctx  {
    CGContextSetStrokeColorWithColor(ctx, [self.selectedPointColor CGColor]);
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);//设置填充颜色
    CGContextSetLineWidth(ctx, self.selectedPointLineWidth); //设置线的宽度
    
    CGContextAddEllipseInRect(ctx, CGRectMake(point.x - self.selectedPointRadius / 2 , point.y - self.selectedPointRadius / 2, self.selectedPointRadius, self.selectedPointRadius)); //画一个椭圆或者圆
    CGContextDrawPath(ctx, kCGPathFillStroke);
}

- (void) cleanDrawPoint {
    [self setNeedsDisplay:YES];
}

- (void)moveInSamplePoint:(NSPoint) point atIndex:(NSInteger) i {
    NSLog(@"moveInSamplePoint x:%f, y:%f, i=%ld", point.x, point.y, i);
    [self.mouseOnLineEventDelegate mouseMoveOutSamplePoint:point atIndex:i];
    mouseOnPoint = point;
    [self setNeedsDisplay:YES];
    
}

- (void)moveOutSamplePoint {
    [self.mouseOnLineEventDelegate mouseMoveOutSamplePoint];
    [self cleanDrawPoint];
}


- (void)mouseMoved:(NSEvent *)event {
    NSPoint eventPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    //NSLog(@"x:%f, y:%f", eventPoint.x, eventPoint.y);
    // test is on the sample point
    for ( int i = 0; i < pointCoordinaryCache.count; i++) {
        NSValue * v = [pointCoordinaryCache objectAtIndex:i];
        NSPoint p = [v pointValue];
        //        if (fabs(p.x - eventPoint.x) < ERROR && fabs(p.y - eventPoint.y) < ERROR) {
        if (fabs(p.x - eventPoint.x) < ERROR && kBuffer < p.y < self.frame.size.height - kBuffer) {
            //            NSLog(@"on the sample point x:%f, y:%f", p.x, p.y);
            if (!mouseOnSamplePoint) {
                [self moveInSamplePoint:p atIndex:i];
            }
            mouseOnSamplePoint = YES;
            return;
        }
    }
    
    if (mouseOnSamplePoint) {
        [self moveOutSamplePoint];
    }
    mouseOnSamplePoint = NO;
    
}



- (void)getPathPoint:(CGContextRef)context toPointArray:(NSMutableArray **)array density:(float)density {
    CGFloat lengths[] = {density,0};
    CGContextSetLineDash(context, 0, lengths,2);
    
    CGPathRef myPath = CGContextCopyPath(context);
    CGPathRef dashPath = CGPathCreateCopyByDashingPath(myPath, nil, 0, lengths, 2);
    NSMutableArray *bezierPoints = *array;
    CGPathApply(dashPath, (__bridge void * _Nullable)(bezierPoints), MyCGPathApplierFunc);
    CFRelease(myPath);
}

- (void)drawLineForYValues:(LMDataSet *)dataSet andMaxYValue:(CGFloat)maxYValue onContext:(CGContextRef)context {
    CGContextSetStrokeColorWithColor(context, [dataSet.colorStart CGColor]);
    CGContextSetLineWidth(context, dataSet.lineWidth);
    CGPoint lastPoint;
    CGPoint cp1;
    CGPoint cp2;
    
    CGPoint point = [self pointWithIndex:0 andMaxValue:maxYValue withValues:dataSet.values];
    [pointCoordinaryCache addObject:[NSValue valueWithPoint:point]];
    CGContextMoveToPoint(context, point.x, point.y);
    lastPoint.x = point.x;
    lastPoint.y = point.y;
    cp1.x = point.x;
    cp1.y = point.y;
    
    for (NSInteger i = 1; i < dataSet.values.count; i++){
        CGPoint curPoint = [self pointWithIndex:i andMaxValue:maxYValue withValues:dataSet.values];
        
        float midx = (lastPoint.x + curPoint.x) / 2;
        
        cp2.x = midx;
        cp2.y = curPoint.y;
        
        CGContextAddCurveToPoint(context, cp1.x, cp1.y, cp2.x, cp2.y, curPoint.x, curPoint.y);
        [pointCoordinaryCache addObject:[NSValue valueWithPoint:curPoint]];
        cp1.x = 2 * curPoint.x - cp2.x;
        cp1.y = 2 * curPoint.y - cp2.y;
        lastPoint.x = curPoint.x;
        lastPoint.y = curPoint.y;
        
    }
    
    CGContextSetLineJoin(context, kCGLineJoinBevel);
    CGContextReplacePathWithStrokedPath(context);
    CGContextSaveGState(context);
    CGContextClip(context);
    CGGradientRef gradient = [self createGradientWithColorStart:dataSet.colorStart andColorEnd:dataSet.colorEnd andLocations:nil];
    CGPoint start = CGPointMake(kBuffer, kBuffer);
    CGPoint end = CGPointMake(self.frame.size.width - kBuffer, self.frame.size.height - kBuffer);
    //绘制渐变, 颜色的0对应start点,颜色的1对应end点,第四个参数是定义渐变是否超越起始点和终止点
    CGContextDrawLinearGradient(context, gradient, start, end, 0);
    CGGradientRelease(gradient);
    CGContextRestoreGState(context);
    
    if (dataSet.fillColorStart) {

        CGPoint point = [self pointWithIndex:0 andMaxValue:maxYValue withValues:dataSet.values];
        point.y = point.y - dataSet.lineWidth / 2; //减去线宽，避免阴影画在线上
        CGContextMoveToPoint(context, point.x, point.y);
        lastPoint.x = point.x;
        lastPoint.y = point.y;
        cp1.x = point.x;
        cp1.y = point.y;

        for (NSInteger i = 0; i < dataSet.values.count; i++){
            CGPoint curPoint = [self pointWithIndex:i andMaxValue:maxYValue withValues:dataSet.values];
            curPoint.y = curPoint.y - dataSet.lineWidth / 2; //减去线宽，避免阴影画在线上

            float midx = (lastPoint.x + curPoint.x) / 2;

            cp2.x = midx;
            cp2.y = curPoint.y;

            CGContextAddCurveToPoint(context, cp1.x, cp1.y, cp2.x, cp2.y, curPoint.x, curPoint.y);
            cp1.x = 2 * curPoint.x - cp2.x;
            cp1.y = 2 * curPoint.y - cp2.y;
            lastPoint.x = curPoint.x;
            lastPoint.y = curPoint.y;

        }


        CGContextSetLineWidth(context, 2);

        NSMutableArray *pathPoints = [[NSMutableArray alloc] init];

        [self getPathPoint:context toPointArray:&pathPoints density:2];

        //        CGFloat loc[3] = {0, 0.02, 1};
        //        CGGradientRef gradient = [self createGradientWith3ColorStart:dataSet.colorEnd andColorMid:dataSet.fillColorStart andColorEnd:dataSet.fillColorEnd andLocations:loc];

        CGFloat loc[2] = {0, 1};
        CGGradientRef gradient = [self createGradientWithColorStart:dataSet.fillColorStart andColorEnd:dataSet.fillColorEnd andLocations:loc];

        //        创建一个渐变的色值 1:颜色空间 2:渐变的色数组 3:位置数组,如果为NULL,则为平均渐变,否则颜色和位置一一对应
        CGContextBeginPath(context);
        for (int i = 0; i < pathPoints.count; i++) {
            CGPoint point = ((NSValue *)pathPoints[i]).pointValue;


            CGPoint start = CGPointMake(point.x, point.y);
            CGPoint end = CGPointMake(point.x, kBuffer);
            //绘制渐变, 颜色的0对应start点,颜色的1对应end点,第四个参数是定义渐变是否超越起始点和终止点
            CGContextMoveToPoint(context, start.x, start.y); //原点
            CGContextAddLineToPoint(context, end.x, end.y);
            CGContextSaveGState(context);
            CGContextReplacePathWithStrokedPath(context);
            CGContextClip(context);
            CGContextDrawLinearGradient(context, gradient, start, end, 0);
            CGContextRestoreGState(context);
        }

        CGGradientRelease(gradient);


    }
}

void MyCGPathApplierFunc (void *info, const CGPathElement *element) {
    NSMutableArray *pointsArray = (__bridge NSMutableArray *)info;
    CGPoint *points = element->points;
    CGPathElementType type = element->type;
    
    switch(type) {
        case kCGPathElementMoveToPoint: // contains 1 point
            [pointsArray addObject:[NSValue valueWithPoint:points[0]]];
            break;
            
        case kCGPathElementAddLineToPoint: // contains 1 point
            break;
            
        case kCGPathElementAddQuadCurveToPoint: // contains 2 points
            break;
            
        case kCGPathElementAddCurveToPoint: // contains 3 points
            break;
            
        case kCGPathElementCloseSubpath: // contains no point
            break;
    }
}

- (CGFloat)xFory:(CGFloat)y withLine:(NSArray *)lineValues{
    CGFloat widthAdjusted = CGRectGetWidth(self.frame) -( kBuffer*2);
    CGFloat perTick = (widthAdjusted/(CGFloat)(lineValues.count-1));
    CGFloat amountOver = y*perTick;
    return kBuffer + amountOver;
    
}

- (CGPoint)pointWithIndex:(NSInteger)i andMaxValue:(CGFloat)maxYValue withValues:(NSArray *)values {
    CGFloat yval = [(NSNumber *)values[i] doubleValue]/maxYValue;
    CGPoint point = [self pointForY:yval withI:i withLine:values];
    return point;
}

- (CGPoint)pointForY:(CGFloat)y withI:(NSInteger)i withLine:(NSArray *)lineValues {
    CGPoint point = CGPointMake( [self xFory:i withLine:lineValues],
                                (0 + kBuffer) + (y*(CGRectGetHeight(self.frame)-kBuffer*2)));
    return point;
}

- (CGGradientRef) createGradientWithColorStart:(NSColor* )colorStart andColorEnd:(NSColor *)colorEnd andLocations:(const CGFloat * __nullable )locations{
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    //定义渐变颜色数组
    
    CGColorRef colorStartRef = [colorStart convertToCGColor];
    CGColorRef colorEndRef = [colorEnd convertToCGColor];
    CFArrayRef colorArray = CFArrayCreate(kCFAllocatorDefault, (const void*[]){colorStartRef, colorEndRef}, 2, nil);
    
    //创建一个渐变的色值 1:颜色空间 2:渐变的色数组 3:位置数组,如果为NULL,则为平均渐变,否则颜色和位置一一对应
    CGGradientRef gradient = CGGradientCreateWithColors(rgb, colorArray, locations);
    
    CFRelease(colorArray);
    CGColorSpaceRelease(rgb);
    
    return gradient;
}

- (CGGradientRef) createGradientWith3ColorStart:(NSColor* )colorStart andColorMid:(NSColor *)colorMid andColorEnd:(NSColor *)colorEnd andLocations:(const CGFloat * __nullable )locations{
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    //定义渐变颜色数组
    
    CGColorRef colorStartRef = [colorStart convertToCGColor];
    CGColorRef colorMidRef = [colorMid  convertToCGColor];
    CGColorRef colorEndRef = [colorEnd  convertToCGColor];
    CFArrayRef colorArray = CFArrayCreate(kCFAllocatorDefault, (const void*[]){colorStartRef, colorMidRef, colorEndRef}, 3, nil);
    
    //创建一个渐变的色值 1:颜色空间 2:渐变的色数组 3:位置数组,如果为NULL,则为平均渐变,否则颜色和位置一一对应
    CGGradientRef gradient = CGGradientCreateWithColors(rgb, colorArray, locations);
    
    CFRelease(colorArray);
    CGColorSpaceRelease(rgb);
    
    return gradient;
}

- (void)dealloc {
    self.axisLabelAttributes = nil;
    self.xAxisLabels = nil;
    self.axisLineColor = nil;
    self.dataSets = nil;
    if (__gridLineStyle) {
        free(__gridLineStyle);
    }
    
    if (__axisLineStyle) {
        free(__axisLineStyle);
    }
}


@end
