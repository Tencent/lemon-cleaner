//
//  NSTextAttachment+Addition.m
//  MQQSecure
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "NSTextAttachment+Addition.h"
#import "LMFileMoveCommonDefines.h"
#import "NSFont+LineHeight.h"

@implementation NSTextAttachment (Addition)

+ (NSTextAttachment *)mqqAttachmentWithImage:(NSImage *)image size:(CGSize)size font:(NSFont *)font {
    CGFloat y = font.descender + 0.5 * (font.lineHeight - size.height);
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = image;
    attachment.bounds = CGRectMake(0, y, size.width, size.height);
    return attachment;
}

@end
