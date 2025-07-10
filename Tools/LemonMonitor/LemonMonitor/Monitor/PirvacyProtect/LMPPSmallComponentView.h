//
//  LMPPSmallComponentView.h
//  LemonMonitor
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LMPPComponentType) {
    LMPPComponentType_Unknown,        // 系统垃圾
    LMPPComponentType_Video,         // 摄像头
    LMPPComponentType_Audio,     // 麦克风
    LMPPComponentType_Screen,         // 屏幕
    LMPPComponentType_Automatic,      // 自动化
};

typedef void (^DidClickSwitchHandler)(BOOL on);

@interface LMPPSmallComponentView : NSView

@property (nonatomic, copy) dispatch_block_t onClickBackgroundHandler;
@property (nonatomic, copy) DidClickSwitchHandler onClickSwitchHandler;

- (instancetype)initWithType:(LMPPComponentType)type
                       title:(NSString *)title
                 enableImage:(NSImage *)enableImage
                disableImage:(NSImage *)disableImage;

- (void)updateUI;

@end

NS_ASSUME_NONNULL_END
