//
//  NSViewGaussianBlur.h
//  QMUICommon
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSViewGaussianBlur : NSObject

+ (NSImage *)blur:(NSView*)view frame:(CGRect) frame;

@end

NS_ASSUME_NONNULL_END
