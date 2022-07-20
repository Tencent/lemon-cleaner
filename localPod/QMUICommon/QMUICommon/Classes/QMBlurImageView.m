//
//  QMBlurImageView.m
//  TestAutoLayer
//
//  
//  Copyright (c) 2014年 ZERO. All rights reserved.
//

#import "QMBlurImageView.h"
#import "QMMoveImageView.h"
#import "QMCoreFunction/NSImage+Extension.h"

@implementation QMBlurImageView

- (void)setImage:(NSImage *)image
{
    if (_image == image)
        return;
    _image = image;
    [_imageView1 removeFromSuperview];
//    [_imageView2 removeFromSuperview];
    _imageView1 = [self _createImageView:[image imageWithBlur:4]];
//    _imageView2 = [self _createImageView:image];
//    [_imageView2 setAlphaValue:0];
}

- (void)setImageAlignment:(NSImageAlignment)imageAlignment
{
    if (_imageAlignment == imageAlignment)
        return;
    _imageAlignment = imageAlignment;
    [_imageView1 setImageAlignment:_imageAlignment];
//    [_imageView2 setImageAlignment:_imageAlignment];
}

- (NSImageView *)_createImageView:(NSImage *)image
{
    NSImageView *newImageView = [[QMMoveImageView alloc] initWithFrame:[self bounds]];
    [newImageView setImageFrameStyle:NSImageFrameNone];
    [newImageView setImageAlignment:_imageAlignment];
    // anything else you need to copy properties from the old image view
    // ...or unarchive it from a nib
    
    [newImageView setImage:image];
    [newImageView setWantsLayer:YES];
    [self addSubview: newImageView];
    return newImageView;
}

/*
- (void)updateTrackingAreas
{
    NSArray *areaArray = [self trackingAreas];
    for (NSTrackingArea *area in areaArray)
    {
        [self removeTrackingArea:area];
    }
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                                options:NSTrackingMouseEnteredAndExited|NSTrackingActiveInActiveApp
                                                                  owner:self
                                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)_startAnimation:(NSView *)fromView toView:(NSView *)toView
{
    if (fromView && toView)
    {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:2];
        [[toView animator] setAlphaValue: 1];
        [[fromView animator] setAlphaValue: 0];
        [NSAnimationContext endGrouping];
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [self _startAnimation:_imageView2 toView:_imageView1];
}
- (void)mouseEntered:(NSEvent *)theEvent
{
    [self _startAnimation:_imageView1 toView:_imageView2];
}
*/
@end
