//
//  Owl2Manager+Guide.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2Manager+Guide.h"

static NSString * const kOwl2ManagerOneClickGuideViewClosedKey = @"kOwl2ManagerOneClickGuideViewClosedKey";
static NSString * const kOwl2ManagerOneClickGuideViewClickedKey = @"kOwl2ManagerOneClickGuideViewClickedKey";
static NSString * const kOwl2ManagerIsPreviouslyEnabledKey = @"kOwl2ManagerIsPreviouslyEnabledKey";

@implementation Owl2Manager (Guide)
@dynamic oneClickGuideViewClosed;
@dynamic oneClickGuideViewClicked;
@dynamic isPreviouslyEnabled;

- (BOOL)showOneClickGuideView {
    if (self.isWatchAudio) {
        return NO;
    }
    
    if (self.isWatchVideo) {
        return NO;
    }
    
    if (self.isPreviouslyEnabled) {
        // 设置过开启
        return NO;
    }
    
    if (self.oneClickGuideViewClosed) {
        // 主动点了关闭
        return NO;
    }
    
    if (self.oneClickGuideViewClicked) {
        // 主动点了‘一键开启’
        return NO;
    }
    
    return YES;
}

- (BOOL)oneClickGuideViewClosed {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kOwl2ManagerOneClickGuideViewClosedKey];
}

- (void)setOneClickGuideViewClosed:(BOOL)oneClickGuideViewClosed {
    [[NSUserDefaults standardUserDefaults] setBool:oneClickGuideViewClosed forKey:kOwl2ManagerOneClickGuideViewClosedKey];
}

- (BOOL)oneClickGuideViewClicked {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kOwl2ManagerOneClickGuideViewClickedKey];
}

- (void)setOneClickGuideViewClicked:(BOOL)oneClickGuideViewClicked {
    [[NSUserDefaults standardUserDefaults] setBool:oneClickGuideViewClicked forKey:kOwl2ManagerOneClickGuideViewClickedKey];
}

- (BOOL)isPreviouslyEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kOwl2ManagerIsPreviouslyEnabledKey];
}

- (void)setIsPreviouslyEnabled:(BOOL)isPreviouslyEnabled {
    [[NSUserDefaults standardUserDefaults] setBool:isPreviouslyEnabled forKey:kOwl2ManagerIsPreviouslyEnabledKey];
}

@end
