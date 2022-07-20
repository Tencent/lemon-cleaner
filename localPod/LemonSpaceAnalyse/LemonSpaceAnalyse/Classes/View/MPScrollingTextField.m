//
//  MPScrollingTextField.m
//  MiniPlay
//
//  
//  Copyright (c) 2014 Denis Stas. All rights reserved.
//

#import "MPScrollingTextField.h"

@import QuartzCore;


@interface MPScrollingTextField ()<CAAnimationDelegate>

@property (nonatomic, strong) CALayer *rootLayer;
@property (nonatomic, strong) CATextLayer *firstLayer;
@property (nonatomic, strong) CATextLayer *secondLayer;
@property (nonatomic, strong) CAGradientLayer *maskLayer;

@property (nonatomic, assign) CGFloat stringWidth;

@property (nonatomic, assign, getter=isScrolling) BOOL scrolling;

@end

@implementation MPScrollingTextField

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.wantsLayer = YES;
    
    _scrollingRate = 20.f;
    _scrollingOffset = 100.0f;
    
    _rootLayer = [CALayer layer];
    _rootLayer.frame = self.bounds;
    
    _maskLayer = [CAGradientLayer layer];
    _maskLayer.frame = self.bounds;
    _maskLayer.colors = @[ (id)[NSColor clearColor].CGColor, (id)[NSColor whiteColor].CGColor,
                           (id)[NSColor whiteColor].CGColor, (id)[NSColor clearColor].CGColor ];
    _maskLayer.locations = @[ @(.0f), @(.05f), @(.95f), @(1.f) ];
    _maskLayer.startPoint = CGPointMake(0, 1);
    _maskLayer.endPoint = CGPointMake(1, 1);
    
    _rootLayer.mask = _maskLayer;
    
    
    float m_strWidth;

    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",self.stringValue] attributes:nil];
    m_strWidth = attrStr.size.width;
    
    
    _firstLayer = [CATextLayer layer];
    _firstLayer.string = self.stringValue;
    _firstLayer.fontSize = self.font.pointSize;
    _firstLayer.font = (__bridge CFTypeRef)(self.font);
    
    
    _firstLayer.frame = self.bounds;
    _firstLayer.alignmentMode = kCAAlignmentLeft;
    _firstLayer.foregroundColor = self.textColor.CGColor;
    
    _secondLayer = [CATextLayer layer];
    _secondLayer.string = self.stringValue;
    _secondLayer.fontSize = self.font.pointSize;
    _secondLayer.font = (__bridge CFTypeRef)(self.font);
    _secondLayer.frame = self.bounds;
    _secondLayer.alignmentMode = kCAAlignmentLeft;
    _secondLayer.foregroundColor = self.textColor.CGColor;
    _secondLayer.hidden = YES;
    
    [_rootLayer addSublayer:_firstLayer];
    [_rootLayer addSublayer:_secondLayer];
    
    self.layer = _rootLayer;
    
    [self updateLayerFrames];
}

- (void)drawRect:(NSRect)dirtyRect
{
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    
    if (![self isScrolling])
    {
        _firstLayer.frame = self.bounds;
        _secondLayer.frame = self.bounds;
    }
    
    _maskLayer.frame = self.bounds;
}

- (void)setBounds:(NSRect)bounds
{
    [super setBounds:bounds];
    
    if (![self isScrolling])
    {
        _firstLayer.frame = self.bounds;
        _secondLayer.frame = self.bounds;
    }
    
    _maskLayer.frame = self.bounds;
}

- (void)setTextColor:(NSColor *)textColor
{
    [super setTextColor:textColor];
    
    self.firstLayer.foregroundColor = textColor.CGColor;
    self.secondLayer.foregroundColor = textColor.CGColor;
}

- (CGFloat)boundingWidthForAttributedString:(NSAttributedString *)attributedString
{
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString( (CFMutableAttributedStringRef) attributedString);
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX), NULL);
    CFRelease(framesetter);
    
    return suggestedSize.width;
}

- (void)setStringValue:(NSString *)stringValue
{
    NSString *oldStringValue = [self.stringValue copy];
    
    [super setStringValue:stringValue];
    
    if ([oldStringValue isEqualToString:stringValue])
    {
        return;
    }
    
    _firstLayer.string = stringValue;
    _secondLayer.string = stringValue;
    
    [self updateLayerFrames];
}

- (void)setScrollingRate:(CGFloat)scrollingRate
{
    _scrollingRate = scrollingRate;
    
    [self updateLayerFrames];
}

- (void)setScrollingOffset:(CGFloat)scrollingOffset
{
    _scrollingOffset = scrollingOffset;
    
    [self updateLayerFrames];
}

- (void)updateLayerFrames
{
    self.stringWidth = [self boundingWidthForAttributedString:self.attributedStringValue];

    if (self.stringWidth > self.bounds.size.width)
    {
        _maskLayer.locations = @[ @(.0f), @(.0f), @(.95f), @(1.f) ];
        _secondLayer.hidden = NO;
        
        [_firstLayer removeAllAnimations];
        [_secondLayer removeAllAnimations];
        
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        
        NSRect firstBounds = self.bounds;
        NSRect secondBounds = self.bounds;
        firstBounds.size.width = self.stringWidth;
        secondBounds.origin.x = self.stringWidth + self.scrollingOffset;
        secondBounds.size.width = self.stringWidth;
        
        _firstLayer.frame = firstBounds;
        _secondLayer.frame = secondBounds;
        
        [CATransaction commit];
        
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong __typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            NSDictionary * nameDict = @{
                                    NSFontAttributeName:[NSFont systemFontOfSize:12.0]
                                    };
            NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"/%@", strongSelf.stringValue] attributes:nameDict];
            float strWidth = attrStr.size.width;
            if (strWidth > 137) {
                [strongSelf scrollTextField];
            }
        });
    }
    else
    {
        _maskLayer.locations = @[ @(.0f), @(.0f), @(1.f), @(1.f) ];
        
        [_firstLayer removeAllAnimations];
        [_secondLayer removeAllAnimations];
        
        _firstLayer.frame = self.bounds;
        _secondLayer.frame = self.bounds;
        _secondLayer.hidden = YES;
    }
}

- (void)scrollTextField
{
    _maskLayer.locations = @[ @(.0f), @(.05f), @(.95f), @(1.f) ];
    
    self.scrolling = YES;
    
    CGFloat animationDuration = (self.stringWidth + self.scrollingOffset) / self.scrollingRate;
    
    CABasicAnimation *firstAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    firstAnimation.fromValue = [NSValue valueWithPoint:_firstLayer.position];
    firstAnimation.toValue = [NSValue valueWithPoint:NSMakePoint(_firstLayer.position.x - self.stringWidth - self.scrollingOffset, _firstLayer.position.y)];
    firstAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    firstAnimation.duration = animationDuration;
    
    [_firstLayer addAnimation:firstAnimation forKey:@"frameAnimation"];
    
    CABasicAnimation *secondAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    secondAnimation.delegate = self;
    [secondAnimation setValue:_secondLayer forKey:@"targetLayer"];
    secondAnimation.fromValue = [NSValue valueWithPoint:_secondLayer.position];
    secondAnimation.toValue = [NSValue valueWithPoint:NSMakePoint(_secondLayer.position.x - self.stringWidth - self.scrollingOffset, _secondLayer.position.y)];
    secondAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    secondAnimation.duration = animationDuration;
    
    [_secondLayer addAnimation:secondAnimation forKey:@"frameAnimation"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if ([anim valueForKey:@"targetLayer"] == _secondLayer && flag)
    {
        self.scrolling = NO;
        _maskLayer.locations = @[ @(.0f), @(.0f), @(.95f), @(1.f) ];
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong __typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            [strongSelf updateLayerFrames];
        });
    }
}

- (void)viewDidChangeBackingProperties
{
    CGFloat backingScale = [self.window backingScaleFactor];
    if (backingScale > 0)
    {
        for (CALayer *layer in [self.rootLayer sublayers])
        {
            layer.contentsScale = backingScale;
        }
    }
}

@end
