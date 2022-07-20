//
//  NSImage+Stretchable.h
//  Test
//
//  
//  Copyright (c) 2013 http://www.tanhao.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSImage (Stretchable)

- (NSImage *)stretchableImageWithSize:(NSSize)size edgeInsets:(NSEdgeInsets)insets;
- (NSImage *)stretchableImageWithLeftCapWidth:(float)leftWidth middleWidth:(float)middleWidth rightCapWidth:(float)rightWidth;

@end
