//
//  QMDuplicateCoverLayer.m
//  QMDuplicateFile
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMDuplicateCoverLayer.h"
#import "NSBezierPath+Extension.h"

#define kLineShaperWidth   48

// 加号 , 拖拽语句, 背景色 的 Layer.
@implementation QMDuplicateCoverLayer

- (id)initWithFrame:(NSRect)rect addTips:(NSString *)tips{
    if (self = [super init])
    {
        [self setFrame:rect];
        
        // back layer 和 自身一样大. 呈现颜色 和 整体的收缩效果.
        _backLayer = [CALayer layer];
        _backLayer.frame = self.bounds;
        [_backLayer setCornerRadius:rect.size.width * 0.5];
        //        [_backLayer setBackgroundColor:[NSColor colorWithHex:0xFF0000].CGColor];
        [self addSublayer:_backLayer];
        
        _descTextLayer = [CATextLayer layer];
        _descTextLayer.autoresizingMask = (kCALayerWidthSizable|kCALayerMinYMargin);
        _descTextLayer.frame = CGRectMake(0, 53, rect.size.width, 20);
        _descTextLayer.contentsScale = [[NSScreen mainScreen] backingScaleFactor];
        NSFont *font = [NSFont safeFontWithName:@"Hiragino Sans GB" size:12];
        _descTextLayer.font = (__bridge CFTypeRef)font;
        _descTextLayer.fontSize = 12;
        _descTextLayer.alignmentMode = kCAAlignmentCenter;
        _descTextLayer.truncationMode = kCATruncationMiddle;
        if(tips){
            _descTextLayer.string = tips;
        }else{
            _descTextLayer.string = @"";
        }
        _descTextLayer.foregroundColor = ([NSColor colorWithHex:0x7E7E7E]).CGColor;
        
        [self addSublayer:_descTextLayer];
        
        
        // 标签的背景（+号）
        _flagsLayer = [CALayer layer];
        //        [_flagsLayer setBackgroundColor:[[NSColor blackColor] CGColor]];
        [_flagsLayer setFrame:CGRectMake((rect.size.width - kLineShaperWidth) * 0.5 , (rect.size.height - kLineShaperWidth) * 0.5 + 10, kLineShaperWidth, kLineShaperWidth)];
        _flagsLayer.autoresizingMask = (kCALayerMinXMargin | kCALayerMaxYMargin | kCALayerMaxXMargin);
        [self addSublayer:_flagsLayer];
        
        NSColor * color = [NSColor colorWithHex:0xFFC450];
        NSPoint pointArray[2];
        
        // 这里画的是对勾,经过旋转变成了 +号
        // 上部分（ / )
        pointArray[0] = NSMakePoint(0, 0);
        pointArray[1] = NSMakePoint(kLineShaperWidth, kLineShaperWidth);
        NSBezierPath * path = [NSBezierPath bezierPath];
        [path appendBezierPathWithPoints:pointArray count:2];
        _line1ShapeLayer = [self lineTopShaperLayer:color path:path];
        _line1ShapeLayer.frame = CGRectMake(0, 0, kLineShaperWidth, kLineShaperWidth);
        [_flagsLayer addSublayer:_line1ShapeLayer];
        
        
        //下部分 （ \ )
        pointArray[0] = NSMakePoint(0, kLineShaperWidth);
        pointArray[1] = NSMakePoint(kLineShaperWidth, 0);
        path = [NSBezierPath bezierPath];
        [path appendBezierPathWithPoints:pointArray count:2];
        _line2ShapeLayer = [self lineTopShaperLayer:color path:path];
        _line2ShapeLayer.frame = CGRectMake(0, 0, kLineShaperWidth, kLineShaperWidth);
        [_flagsLayer addSublayer:_line2ShapeLayer];
        
        //        [self showCompleteState:NO];
        //
        //        double delayInSeconds = 2.0;
        //        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        //        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        //            [self showNormalState:YES];
        //        });
        
        
        // 添加按钮 和文字(小的).
        _smallAddContainerLayer = [CALayer layer];
        _addTextLayer = [CATextLayer layer];
        NSString *addString = NSLocalizedStringFromTableInBundle(@"DropViewContinueAdd", nil, [NSBundle bundleForClass:[self class]], @"");
        NSRect addStringRect = [addString boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:nil];
        
        CGFloat offsetIcon = 6;
        CGFloat iconW = 15;
        CGFloat iconH = 15;
        
        CGFloat containerW = addStringRect.size.width + iconW + offsetIcon;
        CGFloat containerH = 20;
        
        
        _addTextLayer.frame = CGRectMake(iconW + offsetIcon, (containerH - addStringRect.size.height) / 2, addStringRect.size.width, addStringRect.size.height);
        _addTextLayer.contentsScale = [[NSScreen mainScreen] backingScaleFactor];
        NSFont *addfont = [NSFont systemFontOfSize:12];
        _addTextLayer.font = (__bridge CFTypeRef)addfont;
        _addTextLayer.fontSize = 12;
        _addTextLayer.alignmentMode = kCAAlignmentCenter;
        _addTextLayer.string = addString;
        _addTextLayer.foregroundColor = (__bridge CGColorRef)([NSColor colorWithHex:0x7E7E7E]);
        [_smallAddContainerLayer addSublayer:_addTextLayer];
        
        
        
        _addIconLayer = [CALayer layer];
        _addIconLayer.frame = CGRectMake(0, (containerH - iconH) / 2.0, iconW, iconH);
        
        _addIconLayer.contents = [NSImage imageNamed:@"add_file_button_normal" withClass:self.class];
        [_smallAddContainerLayer addSublayer:_addIconLayer];
        
        
        CGFloat xOffset = (self.bounds.size.width - containerW) / 2;
        _smallAddContainerLayer.frame = CGRectMake(xOffset, 40, containerW, containerH);
        [self addSublayer:_smallAddContainerLayer];
        _smallAddContainerLayer.hidden = YES;
        
        
    }
    return self;
}

- (CAShapeLayer *)lineTopShaperLayer:(NSColor *)color path:(NSBezierPath *)path;
{
    CGPathRef pathRef = [path copyQuartzPath]; // path -> pathRef
    CAShapeLayer * layer = [CAShapeLayer layer];
    layer.path = pathRef;
    layer.lineWidth = 2;
    layer.strokeColor = [color convertToCGColor];
    CGColorRef clearColorRef = CGColorCreateGenericGray(1, 0);
    layer.fillColor = clearColorRef;
    CGPathRelease(pathRef);
    layer.strokeStart = 0;
    layer.strokeEnd = 1;
    CGColorRelease(clearColorRef);
    return layer;
}

- (void)showNormalState:(BOOL)animation
{
    [self _reset:NO];
    //    [CATransaction setDisableActions:!animation];
    //    [CATransaction setAnimationDuration:.5];
    //    [CATransaction begin];
    _line1ShapeLayer.strokeStart = 0.15;
    _line1ShapeLayer.strokeEnd = 0.85;
    _line2ShapeLayer.strokeEnd = 0.85;
    _line2ShapeLayer.strokeStart = 0.15;
    
    //    这里进行旋转了, 为什么不直接画竖线 (为了 progress 结束的时候 打个对勾,然后对勾做动画变成 加号)
    _line1ShapeLayer.affineTransform =  CGAffineTransformMakeRotation(M_PI * 0.25);
    _line2ShapeLayer.affineTransform =  CGAffineTransformMakeRotation(M_PI * 0.25);
    
    NSRect rect = _flagsLayer.frame;
    rect.origin.y = round((self.frame.size.height - kLineShaperWidth) * 0.5) + 6;
    rect.origin.x = round((self.frame.size.width - kLineShaperWidth) * 0.5);
    [_flagsLayer setFrame:rect];
    [CATransaction commit];
}
- (void)showCompleteState:(BOOL)animation
{
    [self _reset:NO];
    [_descTextLayer setHidden:YES];
    [_contentLayer removeFromSuperlayer];
    _contentLayer = nil;
    [CATransaction setDisableActions:!animation];
    [CATransaction begin];
    //    _line1ShapeLayer.strokeStart = 0.5;
    //    _line1ShapeLayer.strokeEnd = 1;
    //    _line2ShapeLayer.strokeEnd = 0.5;
    //    _line2ShapeLayer.strokeStart = 0.25;
    //    _line1ShapeLayer.affineTransform =  CGAffineTransformMakeRotation(0);
    //    _line2ShapeLayer.affineTransform =  CGAffineTransformMakeRotation(0);
    
    NSRect rect = _flagsLayer.frame;
    rect.origin.y =  round((self.frame.size.height - kLineShaperWidth) * 0.5) - 12;
    rect.origin.x = round((self.frame.size.width - kLineShaperWidth) * 0.5) - 3;
    [_flagsLayer setFrame:rect];
    [CATransaction commit];
}

- (void)_reset:(BOOL)animation
{
    [CATransaction setDisableActions:!animation];
    [CATransaction setAnimationDuration:0.5];
    [_backLayer setHidden:NO];
    [_flagsLayer setHidden:NO];
    _backLayer.frame = self.bounds;
    [_backLayer setCornerRadius:_backLayer.frame.size.width * 0.5];
    [_flagsLayer setOpacity:1];
    [_descTextLayer setOpacity:1];
    [_descTextLayer setHidden:NO];
    [_smallAddContainerLayer setHidden:YES];
}
- (void)resetAnimation
{
    [self _reset:YES];
}

// 将文件夹拖进来的时候, backLayer 有收缩的效果.
- (void)showAnimationState1
{
    [CATransaction setAnimationDuration:0.5];
    _backLayer.frame = NSInsetRect(_backLayer.frame, 10, 10);
    [_backLayer setCornerRadius:_backLayer.frame.size.width * 0.5];
}

//收缩背景 Layer 到最小.
- (void)showAnimationState2
{
    [CATransaction setAnimationDuration:0.5];
    _backLayer.frame = NSInsetRect(_backLayer.frame, _backLayer.frame.size.width * 0.5, _backLayer.frame.size.height * 0.5);
    [_backLayer setCornerRadius:_backLayer.frame.size.width * 0.5];
    [_flagsLayer setOpacity:0];
    [_descTextLayer setOpacity:0];
    
    //    [_smallAddContainerLayer setOpacity:1];
    [_smallAddContainerLayer setHidden:NO];
}

- (void)showRemoveFile:(NSArray *)array
{
    [CATransaction setDisableActions:YES];
    [_backLayer setHidden:YES];
    [_flagsLayer setHidden:YES];
    [_descTextLayer setHidden:YES];
    [_smallAddContainerLayer setHidden:NO];
    
    if (_contentLayer)
    {
        [_contentLayer removeFromSuperlayer];
        _contentLayer = nil;
    }
    _contentLayer = [CALayer layer];
    [_contentLayer setFrame:self.bounds];
    [_contentLayer setOpacity:0.5];
    [self addSublayer:_contentLayer];
    
    for (int i = 0; i < MIN(array.count, 3); i++)
    {
        CALayer * layer = [CALayer layer];
        [layer setFrame:CGRectMake((int)((self.bounds.size.width - 128) / 2),
                                   (int)((self.bounds.size.height - 128) / 2), 128, 128)];
        NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:[array objectAtIndex:i]];
        [image setSize:NSMakeSize(128, 128)];
        layer.contents = image;
        [_contentLayer addSublayer:layer];
    }
}

- (void)showSmallAddButtonDownState{
    _addTextLayer.foregroundColor = (__bridge CGColorRef)([NSColor colorWithHex:0x515151]);
    _addIconLayer.contents = [NSImage imageNamed:@"add_file_button_down" withClass:self.class];
}

- (void)showSmallAddButtonNoramlState{
    _addTextLayer.foregroundColor = (__bridge CGColorRef)([NSColor colorWithHex:0x7E7E7E]);
    _addIconLayer.contents = [NSImage imageNamed:@"add_file_button_normal" withClass:self.class];
    
}

@end

