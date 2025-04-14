//
//  LMToastContentView.h
//  Lemon
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, LMToastViewStyle) {
    LMToastViewStyleSuccess  = 0,
    LMToastViewStyleInfo     = 1,
    LMToastViewStyleWarning  = 2,
    LMToastViewStyleError    = 3,
};

NS_ASSUME_NONNULL_BEGIN

@interface LMToastContentView : NSView

@property (nonatomic, strong, readonly) NSView *backgroundView;
@property (nonatomic, strong, readonly) NSImageView *imageView;
@property (nonatomic, strong, readonly) NSTextField *textLabel;

// 是否适配暗黑模式，默认YES
@property (nonatomic, assign) BOOL isDarkModeSupported;

- (void)updateImageViewWithStyle:(LMToastViewStyle)style;

@end

NS_ASSUME_NONNULL_END
