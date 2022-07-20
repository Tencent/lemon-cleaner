//
//  PhotoCleanerBlurView.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PhotoCleanerBlurView : NSObject

+ (NSImage *)blur:(NSView*)view frame:(CGRect) frame;

@end
