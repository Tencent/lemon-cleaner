//
//  Owl2DeviceProtectionSwitchView.h
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, Owl2DPSwitchType) {
    Owl2DPSwitchTypeWatchVideo = 1,
    Owl2DPSwitchTypeWatchAudio = 2,
    Owl2DPSwitchTypeWatchScreen = 3,
};

@interface Owl2DeviceProtectionSwitchConfig : NSObject

@property (nonatomic) Owl2DPSwitchType type;

@property (nonatomic, copy) NSString *imageNameOn;

@property (nonatomic, copy) NSString *imageNameOff;

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *desc;

@property (nonatomic) BOOL on; // 开关状态

@end

@protocol Owl2DeviceProtectionSwitchDelegate <NSObject>

@optional

- (void)owl2DeviceProtectionSwitchDidClicked:(Owl2DeviceProtectionSwitchConfig *)config;

- (void)owl2DeviceProtectionSwitchValueDidChange:(Owl2DeviceProtectionSwitchConfig *)config;

@end

@interface Owl2DeviceProtectionSwitchView : NSView

- (instancetype)initWithFrame:(NSRect)frame config:(Owl2DeviceProtectionSwitchConfig *)config;

@property (nonatomic, weak) id<Owl2DeviceProtectionSwitchDelegate> delegate;

@property (nonatomic, strong) Owl2DeviceProtectionSwitchConfig *config;

- (void)updateUI; // 更新config后调用，首次初始化时不需要调用

@end

NS_ASSUME_NONNULL_END
