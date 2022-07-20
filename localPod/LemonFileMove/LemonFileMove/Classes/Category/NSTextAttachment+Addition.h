//
//  NSTextAttachment+Addition.h
//  MQQSecure
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTextAttachment (Addition)

/// 图片在attributed string中居中
+ (NSTextAttachment *)mqqAttachmentWithImage:(NSImage *)image size:(CGSize)size font:(NSFont *)font;

@end

NS_ASSUME_NONNULL_END
