//
//  QMNetworkPlotView.m
//  LemonMonitor
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMNetworkPlotView.h"
#import <QuartzCore/QuartzCore.h>


#define NetworkMinMaxValue 50 * 1024  // 坐标轴的最大值 能取的做小值 ,单位 Byte

@interface QMNetworkPlotContentView : NSView
@property (assign, nonatomic) NSUInteger maxCount;
@property (assign, nonatomic) CGFloat vSpacing;
@property (strong, nonatomic) NSColor *upColor;
@property (strong, nonatomic) NSColor *downColor;
@property (assign, nonatomic) BOOL upsideDown;

@property (assign, nonatomic) CGFloat startAlpha;
@property (assign, nonatomic) CGFloat endAlpha;
@property (assign, nonatomic) CGFloat baseY;
@property (assign, readonly) PointType maxValue;
@property (assign, nonatomic) PointType displayMax;

- (void)replaceDataWithHistory:(NSArray *)history;
- (void)feed:(PointType)value;
@end












@implementation QMNetworkPlotView
{
    QMNetworkPlotContentView *_contentView;
}

@dynamic maxCount, vSpacing, upColor, downColor, upsideDown, startAlpha, endAlpha;
@dynamic baseY, displayMax;
@synthesize maxValue = _maxValue;

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _init];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
    }
    return self;
}

- (void)dealloc
{
    [_contentView removeObserver:self forKeyPath:@"maxValue"];
}

- (void)_init
{
    self.wantsLayer = YES;
    self.layer.masksToBounds = YES;
    NSRect frame = self.bounds;
    frame.size.width = frame.size.width / 30 * 31;
    _contentView = [[QMNetworkPlotContentView alloc] initWithFrame:frame];
    _maxValue = _contentView.maxValue;
    [_contentView addObserver:self forKeyPath:@"maxValue" options:NSKeyValueObservingOptionNew context:NULL];
    [self addSubview:_contentView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self willChangeValueForKey:@"maxValue"];
    _maxValue = _contentView.maxValue;
    [self didChangeValueForKey:@"maxValue"];
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    NSRect frame = self.bounds;
    CGFloat dx = frame.size.width / 30;
    frame.origin.x -= dx;
    frame.size.width += dx;
    _contentView.frame = frame;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return _contentView;
}

// 做值的中继.
- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    @try {
        [_contentView setValue:value forKey:key];
    } @catch (NSException *e) {
        
    }
}

- (void)replaceDataWithHistory:(NSArray *)history
{
    [_contentView replaceDataWithHistory:history];
}

- (void)feed:(PointType)value
{
    [_contentView feed:value];
}

@end










@implementation QMNetworkPlotContentView
{
    NSMutableArray *_points;
    PointType _maxValue;
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _points = [NSMutableArray arrayWithCapacity:32];
    _maxCount = 32;
    _maxValue = 1;
    _displayMax = _maxValue;
    self.baseY = 5;
    self.startAlpha = 0.1;
    self.endAlpha = 0.05;
    [self setWantsLayer:YES];

    /*
    [self setWantsLayer:YES];
    CALayer *layer = self.layer;
    CAGradientLayer *mask = [CAGradientLayer layer];
    mask.frame = self.bounds;
    mask.colors = @[(__bridge id)[[NSColor colorWithHex:0 alpha:0] convertToCGColor],
                    (__bridge id)[[NSColor colorWithHex:0 alpha:1] convertToCGColor],
                    (__bridge id)[[NSColor colorWithHex:0 alpha:1] convertToCGColor]];
    mask.locations = @[@0, @0.5, @1];
    mask.startPoint =  CGPointMake(0, 0.5);
    mask.endPoint =  CGPointMake(1, 0.5);
    
    [layer setMask: mask];
     */
}

- (void)replaceDataWithHistory:(NSArray *)history
{
    if (history.count > _maxCount) {
        _points = [[history subarrayWithRange:NSMakeRange(history.count - _maxCount, _maxCount)] mutableCopy];
    } else {
        _points = [history mutableCopy];
    }
    
    [self willChangeValueForKey:@"maxValue"];
    if (_points.count > 0) {
        _maxValue = [[_points valueForKeyPath:@"@max.self"] unsignedLongLongValue];
    } else {
        _maxValue = 1;
    }
    [self didChangeValueForKey:@"maxValue"];
}

- (void)feed:(PointType)value
{
    [_points addObject:@(value)];
    [self willChangeValueForKey:@"maxValue"];
    if (value > _maxValue) {
        _maxValue = value;
        self.displayMax = value;
    }
    if ([_points count] > _maxCount) {
        PointType p = (PointType)[_points[0] unsignedLongLongValue];
        [_points removeObjectAtIndex:0];

        if (p >= _maxValue) {
            if (_points.count > 0) {
                _maxValue = (PointType)[[_points valueForKeyPath:@"@max.self"] unsignedLongLongValue];
                if (_maxValue == 0) {
                    _maxValue = 1;
                }
            } else {
                _maxValue = 1;
            }
            if (p >= _displayMax) {
                self.displayMax = _maxValue;
            }
        }
    }
    [self didChangeValueForKey:@"maxValue"];
    
    [self setNeedsDisplay:YES];
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
       
    }];
    CGFloat dx = CGRectGetWidth(self.bounds) / (_maxCount - 1);
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    anim.fromValue = @(dx);
    anim.toValue = @(0);
    [self.layer addAnimation:anim forKey:@"offset"];
    [CATransaction commit];
}

// 保证两个 view 的坐标轴最大值一致.
// 1. 从自己的数据中找出最大的replaceDataWithHistory ->修改 maxValue
// 2. 两个 view 都有 maxValue观察. 不管哪个触发,observe 都触发, 同时修改两个的 displayMax. 绘制的时候只利用 displayMax 进行绘制.
- (void)setDisplayMax:(PointType)displayMax
{
    if (_displayMax == displayMax) return;
    if(displayMax < NetworkMinMaxValue){
        _displayMax = NetworkMinMaxValue;
    }else{
        _displayMax = displayMax;
    }
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    if (_points.count < 2) return;
    CGFloat maxValue = _displayMax;
    if (maxValue == 0) maxValue = 1;
    
    CGFloat baseY = self.baseY;
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat heightRef = height - baseY - 1;
    double hSpacing = CGRectGetWidth(self.bounds) / (_maxCount - 1);
    
    CGContextRef ctx = [NSGraphicsContext currentContext].graphicsPort;
    CGContextSaveGState(ctx);
    if (self.upsideDown) {
        CGContextConcatCTM(ctx, CGAffineTransformMake(1, 0, 0, -1, 0, height));
    }
    CGContextSetLineWidth(ctx, 1);
    CGMutablePathRef path = CGPathCreateMutable();

    NSUInteger count = _points.count;
    CGFloat x, y;
    UInt32 strokeColorHex;
    UInt32 fillColorHex;
    if (self.upsideDown) {
        strokeColorHex = 0x06D99A;
        fillColorHex = 0x65FFD2;
    } else {
        strokeColorHex = 0x1A83F7;
        fillColorHex = 0x50A8FF;
    }
    
    x = CGRectGetWidth(self.bounds) - (count - 1) * hSpacing;
    y = baseY + [_points[0] doubleValue] / maxValue * heightRef;

    CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithHex:strokeColorHex] convertToCGColor]);

    CGFloat startX = x;
    CGPathMoveToPoint(path, NULL, x, y);

    for (NSUInteger i = 1; i < count; ++i) {
        x += hSpacing;

        CGPathAddLineToPoint(path, NULL, x, (CGFloat)[_points[i] unsignedLongLongValue] / maxValue * heightRef+baseY);
    }

    CGContextAddPath(ctx, path);
    CGContextSetLineWidth(ctx, 2);
    CGContextStrokePath(ctx);
    
    CGPathAddLineToPoint(path, NULL, CGRectGetWidth(self.bounds), 0);
    CGPathAddLineToPoint(path, NULL, startX, 0);

    CGPathCloseSubpath(path);
    
/*
    [[NSColor whiteColor] set];
    CGContextAddPath(ctx, path);
    CGContextStrokePath(ctx);
 */

    NSGradient *gradient = [[NSGradient alloc] initWithColors:@[[NSColor colorWithHex:fillColorHex alpha:0.35], [NSColor colorWithHex:fillColorHex alpha:0.35]]];
    
    CGContextAddPath(ctx, path);
    CGContextSaveGState(ctx);
    CGContextClip(ctx);
    [gradient drawInRect:self.bounds angle: 90];
    CGPathRelease(path);
    CGContextRestoreGState(ctx);
 
    CGContextRestoreGState(ctx);
}

@end
