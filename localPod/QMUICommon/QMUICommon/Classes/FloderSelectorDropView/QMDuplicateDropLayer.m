//
//  QMDuplicateDropLayer.m
//  TestCrube
//
//  
//  Copyright (c) 2014年 zero. All rights reserved.
//

#import "QMDuplicateDropLayer.h"
#import "NSColor+Extension.h"
#import "LMiCloudPathHelper.h"

#define kItemWidth      100
#define kItemHegiht     100
#define kItemOffset     30
#define kTextHeight     20


@implementation QMDuplicateDropLayer

- (id)initWithFrame:(NSRect)rect
{
    if (self = [super init])
    {
        _startPoint = rect.origin;
        _pathArray = [[NSMutableArray alloc] init];
        _contentLayerArray = [[NSMutableArray alloc] init];
        [self setFrame:rect];
        
        CALayer * maskLayer = [CALayer layer];
        [maskLayer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
        [maskLayer setFrame:NSInsetRect(self.bounds, 1, 1)];
        [maskLayer setCornerRadius:maskLayer.bounds.size.width / 2];
        [self addSublayer:maskLayer];
        [self setMask:maskLayer];
        _maskLayer = maskLayer;
        
        _contentLayer = [CALayer layer];
        [_contentLayer setFrame:self.bounds];
        [self addSublayer:_contentLayer];
        
        // 文字 (几个文件夹    )
        CATextLayer * textLayer = [CATextLayer layer];
        textLayer.contentsScale = [[NSScreen mainScreen] backingScaleFactor];
        textLayer.frame = CGRectMake(0, 24, rect.size.width, kTextHeight);
        textLayer.string = @"";
        NSFont *font = [NSFont safeFontWithName:@"Hiragino Sans GB" size:11];
        textLayer.font = (__bridge CFTypeRef)font;
        textLayer.fontSize = 12;
        textLayer.foregroundColor = (__bridge CGColorRef)([NSColor createCGColorWithSRGB:165
                                                                                   green:176
                                                                                    blue:181
                                                                                   alpha:1]);
        textLayer.alignmentMode = kCAAlignmentCenter;
        textLayer.truncationMode = kCATruncationMiddle;
        [self addSublayer:textLayer];
        _totalCountLayer = textLayer;
        
        _removePathImage = [NSImage imageNamed:@"removePath" withClass:self.class];
        _removePathHoverImage = [NSImage imageNamed:@"removePath_hover" withClass:self.class];
    }
    return self;
}


- (void)addPathItem:(NSArray *)pathArray
{
    for (NSString * path in pathArray)
    {
        if ([_pathArray containsObject:path])
            return;
        [_pathArray addObject:path];
        
        float x = (_pathArray.count - 1) * (kItemWidth + kItemOffset);
        if (x == 0) x = (self.bounds.size.width - kItemWidth) * 0.5;
        else  x += kItemWidth * 0.5;
        x = (int)x;
        
        CALayer * pathLayer = [CALayer layer];
        //        pathLayer.backgroundColor = [NSColor blueColor].CGColor;
        [pathLayer setFrame:CGRectMake(x, (self.superlayer.bounds.size.height - kItemWidth) * 0.5 + 10, kItemWidth, kItemHegiht + kTextHeight)];
        
        // 图片
        CALayer * layer = [CALayer layer];
        [layer setFrame:CGRectMake(0, kTextHeight, kItemWidth, kItemHegiht)];
        NSImage * image = [[NSWorkspace sharedWorkspace] iconForFile:path];
        [image setSize:NSMakeSize(kItemWidth, kItemHegiht)];
        layer.contents = image;
        [pathLayer addSublayer:layer];
        
        // 文字
        CATextLayer * textLayer = [CATextLayer layer];
        textLayer.contentsScale = [[NSScreen mainScreen] backingScaleFactor];
        textLayer.frame = CGRectMake(layer.frame.origin.x, layer.frame.origin.y - kTextHeight, layer.bounds.size.width, kTextHeight);
//        textLayer.string = [[NSFileManager defaultManager] displayNameAtPath:path];
        // 对于iCloud 目录特殊处理.(因为选择iCloudPath 时会自动替换为~/Library/Mobile Documents
        if([LMiCloudPathHelper isICloudContanierPath:path] ){
            [textLayer setString:[LMiCloudPathHelper getICloudPathdisplayName]];
        }else{
            [textLayer setString:[[NSFileManager defaultManager] displayNameAtPath:path]];
        }
        NSFont *font = [NSFont safeFontWithName:@"Hiragino Sans GB" size:14];
        textLayer.font = (__bridge CFTypeRef)font;
        textLayer.fontSize = 14;
        textLayer.alignmentMode = kCAAlignmentCenter;
        textLayer.truncationMode = kCATruncationMiddle;
        textLayer.foregroundColor = [NSColor colorWithHex:0x333333].CGColor;
        [pathLayer addSublayer:textLayer];
        [pathLayer setValue:textLayer forKey:@"TextLayer"];
        
        // 删除按钮
        CALayer * removeLayer = [CALayer layer];
        removeLayer.frame = CGRectMake(NSMaxX(layer.frame) - 7, NSMaxY(layer.frame) - 27, 15, 15);
        removeLayer.contents = _removePathImage;
        [removeLayer setValue:path forKey:@"Path"];
        [pathLayer setValue:removeLayer forKey:@"removePath"];
        [pathLayer addSublayer:removeLayer];
        
        [_contentLayerArray addObject:pathLayer];
        [_contentLayer addSublayer:pathLayer];
    }
    [self resetContentBounds:YES];
}

- (void)resetContentBounds:(BOOL)showEnd
{
    float width = _pathArray.count * (kItemWidth + kItemOffset) + kItemWidth * 0.5 - kItemOffset;
    if (width > self.bounds.size.width)
    {
        width = width + kItemWidth * 0.5;
    }
    if (_pathArray.count == 1)
        width = self.bounds.size.width;
    
    [CATransaction setDisableActions:NO];
    NSRect rect = _contentLayer.frame;
    rect.size.width = width;
    if (showEnd)
    {
        rect.origin.x = self.bounds.size.width - rect.size.width;
    }
    else
    {
        rect.origin.x = MIN(rect.origin.x + kItemWidth + kItemOffset, 0);
    }
    [_contentLayer setFrame:rect];
    
    //    if (_contentLayerArray.count == 0)
    //        _totalCountLayer.string = @"";
    //    else
    //        _totalCountLayer.string = [NSString stringWithFormat:@"%ld个文件夹", _contentLayerArray.count];
}


- (void)removeItemWithPath:(NSString *)path
{
    NSUInteger index = [_pathArray indexOfObject:path];
    if (index == NSNotFound)
        return;
    
    [CATransaction setDisableActions:YES];
    // 移动剩下的Layer
    if (index < _contentLayerArray.count - 1)
    {
        for (NSUInteger i = index + 1; i < _contentLayerArray.count; i++)
        {
            CALayer * nextLayer = [_contentLayerArray objectAtIndex:i];
            CGRect rect = nextLayer.frame;
            rect.origin.x -= kItemWidth + kItemOffset;
            [nextLayer setFrame:rect];
        }
    }
    
    // 移除layer
    [[_contentLayerArray objectAtIndex:index] removeFromSuperlayer];
    [_pathArray removeObjectAtIndex:index];
    [_contentLayerArray removeObjectAtIndex:index];
    [self resetContentBounds:NO];
    
    [_dropDelegate duplicatePathRemove:path];
}
- (void)removeAllItems
{
    [CATransaction setDisableActions:YES];
    for (int i = 0; i < _contentLayerArray.count; i++)
    {
        CALayer * layer = [_contentLayerArray objectAtIndex:i];
        [layer removeFromSuperlayer];
    }
    [_contentLayerArray removeAllObjects];
    [_pathArray removeAllObjects];
    _totalCountLayer.string = @"";
    [_contentLayer setFrame:self.bounds];
}
- (void)enExpandItem:(void (^)(void))handler
{
    for (int i = 0; i < _contentLayerArray.count; i++)
    {
        CALayer * layer = [_contentLayerArray objectAtIndex:i];
        CGRect rect = layer.frame;
        rect.origin.x = [[_contentLayerArray objectAtIndex:0] frame].origin.x + i * (kItemWidth + kItemOffset);
        [layer setFrame:rect];
        [layer setOpacity:1];
        CATextLayer * textLayer = [layer valueForKey:@"TextLayer"];
        [textLayer setHidden:NO];
        if (i == 0)
        {
            if([LMiCloudPathHelper isICloudContanierPath:_pathArray[i]] ){
                [textLayer setString:[LMiCloudPathHelper getICloudPathdisplayName]];
            }else{
                [textLayer setString:[[NSFileManager defaultManager] displayNameAtPath:_pathArray[i]]];
            }
        }
        CALayer * removeLayer = [layer valueForKey:@"removePath"];
        [removeLayer setHidden:NO];
    }
    
    float width = _pathArray.count * (kItemWidth + kItemOffset) + 64 - kItemOffset;
    if (width > self.bounds.size.width)
    {
        width = width + kItemWidth * 0.5;
    }
    if (_pathArray.count == 1)
        width = self.bounds.size.width;
    
    NSRect rect = self.frame;
    rect.origin.x = 0;
    rect.size.width = width;
    [CATransaction setCompletionBlock:^{
        if (handler)
            handler();
    }];
    [_contentLayer setFrame:rect];
}
- (void)encloseItem:(void (^)(void))handler
{
    for (int i = 0; i < _contentLayerArray.count; i++)
    {
        CALayer * layer = [_contentLayerArray objectAtIndex:i];
        CGRect rect = layer.frame;
        rect.origin.x = [[_contentLayerArray objectAtIndex:0] frame].origin.x;
        [layer setFrame:rect];
        [layer setOpacity:0.5];
        CATextLayer * textLayer = [layer valueForKey:@"TextLayer"];
        [textLayer setHidden:(i != 0)];
        if (i == 0)
        {
            [textLayer setString:@"正在扫描中..."];
        }
        CALayer * removeLayer = [layer valueForKey:@"removePath"];
        [removeLayer setHidden:YES];
    }
    NSRect rect = self.frame;
    rect.origin.x = 0;
    rect.size.width = self.superlayer.bounds.size.width;
    [CATransaction setCompletionBlock:^{
        if (handler)
            handler();
    }];
    [_contentLayer setFrame:rect];
}

- (void)showCenterLayer
{
    NSPoint point = [_contentLayer frame].origin;
    int index = (point.x - 64) / (kItemWidth + kItemOffset);
    float x = index * (kItemWidth + kItemOffset);
    
    NSRect rect = _contentLayer.frame;
    rect.origin.x = x + _startPoint.x;
    [_contentLayer setFrame:rect];
}

- (void)startMouseDragged
{
    _lastDragPoint = _contentLayer.frame.origin;
}
- (void)mouseDragged:(NSPoint)point
{
    // _startPoint  整个 layer 的rect.origin
    // _lastDragPoint 开始drag 时候位置   _contentLayer.frame.origin
    CGRect rect = [_contentLayer frame];
    rect.origin.x = _lastDragPoint.x + (point.x - _startPoint.x);

    
    CGFloat MaxTolerateOffset = 20; // 允许用户多拖动多少距离,视觉上会有会弹效果
    if (rect.origin.x > MaxTolerateOffset){
        rect.origin.x = MaxTolerateOffset;
    }
    
    if (rect.origin.x + rect.size.width < self.superlayer.bounds.size.width - MaxTolerateOffset * 2 ){
        rect.origin.x = self.superlayer.bounds.size.width -  rect.size.width  - MaxTolerateOffset * 2 ;
    }

    //    NSLog(@"mouseDragged ... rect x is %f, event point.x is %f, rect size width %f, super size width %f",rect.origin.x, point.x, rect.size.width, self.superlayer.bounds.size.width );
    
    [CATransaction setDisableActions:YES];
    [_contentLayer setFrame:rect];
}
- (void)endMouseDragged
{
    [self showCenterLayer];
}

- (void)mouseDown:(NSPoint)point
{
    CALayer * layer = [self hitTest:point];
    NSString * path = [layer valueForKey:@"Path"];
    if (layer && path)
    {
        layer.contents = _removePathImage;
        //[self removeItemWithPath:path];
    }
}
- (void)mouseUp:(NSPoint)point
{
    NSLog(@"QMDuplicateDropLayer  mouseUp...");
    CALayer * layer = [self hitTest:point];
    NSString * path = [layer valueForKey:@"Path"];
    NSLog(@"QMDuplicateDropLayer  mouseUp... path:%@ layer:%@",path,layer);
    
    if (layer && path)
    {
        [self removeItemWithPath:path];
    }
}
- (void)mouseMoved:(NSPoint)point
{
    CALayer * layer = [self hitTest:point];
    NSString * path = [layer valueForKey:@"Path"]; // 证明这个 layer 保存了 path ,是 x 这个按钮
    if (layer != _highLayer)
        _highLayer.contents = _removePathImage;
    if (layer && path)
    {
        layer.contents = _removePathHoverImage;
        _highLayer = layer;
    }
}

@end


