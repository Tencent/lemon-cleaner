//
//  QMBlurImageView.h
//  TestAutoLayer
//
//  
//  Copyright (c) 2014年 ZERO. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QMBlurImageView : NSView
{
    NSImageView * _imageView1;
//    NSImageView * _imageView2;
}
@property (nonatomic, retain) NSImage * image;
@property (nonatomic, assign) NSImageAlignment imageAlignment;

@end
