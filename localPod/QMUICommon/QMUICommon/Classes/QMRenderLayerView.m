//
//  QMRenderLayerView.m
//  QMUICommon
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMRenderLayerView.h"
#import "QMMoveImageView.h"
#import <QMCoreFunction/CALayer+Extension.h>

@interface QMRenderLayerView ()
{
    CALayer *showLayer;
    NSImageView *imageView;
}
@end

@implementation QMRenderLayerView
@synthesize staticMode;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setUp];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self)
    {
        [self setUp];
    }
    return self;
}

- (id)initWithLayer:(CALayer *)layer
{
    self = [self initWithFrame:layer.bounds];
    if (self)
    {
        [self setLayer:layer];
    }
    return self;
}

- (void)setUp
{
    [super setWantsLayer:YES];
    
    imageView = [[QMMoveImageView alloc] initWithFrame:self.bounds];
    imageView.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
    [self addSubview:imageView];
}

- (void)setWantsLayer:(BOOL)flag
{
    //
}

- (void)setLayer:(CALayer *)newLayer
{
    [super setLayer:newLayer];
    showLayer = newLayer;
}

- (BOOL)staticMode
{
    return staticMode;
}

- (void)setStaticMode:(BOOL)value
{
    if (staticMode == value)
        return;
    
    staticMode = value;
    if (staticMode)
    {
        CGImageRef imageRef = [showLayer createCGImage];
        if (imageRef)
        {
            NSSize imageSize = NSMakeSize(NSWidth(showLayer.bounds), NSHeight(showLayer.bounds));
            NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:imageSize];
            CGImageRelease(imageRef);
            [imageView setImage:image];
        }
        [super setWantsLayer:NO];
    }else
    {
        [super setWantsLayer:YES];
        [self setLayer:showLayer];
        [imageView setImage:nil];
        [self display];
    }
}

@end
