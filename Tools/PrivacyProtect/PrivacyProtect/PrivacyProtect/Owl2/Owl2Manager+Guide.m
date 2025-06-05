//
//  Owl2Manager+Guide.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2Manager+Guide.h"

static NSString * const kOwl2ManagerOneClickGuideViewClosedKey = @"kOwl2ManagerOneClickGuideViewClosedKey_5.1.15";
static NSString * const kOwl2ManagerOneClickGuideViewClickedKey = @"kOwl2ManagerOneClickGuideViewClickedKey_5.1.15";

@implementation Owl2Manager (Guide)
@dynamic oneClickGuideViewClosed;
@dynamic oneClickGuideViewClicked;

- (BOOL)showOneClickGuideView {
    
    if (self.oneClickGuideViewClosed) {
        // 主动点了关闭
        return NO;
    }
    
    if (self.oneClickGuideViewClicked) {
        // 主动点了‘一键开启’
        return NO;
    }
    
    // 3个都开启
    if (self.isWatchAudio && self.isWatchVideo && self.isWatchScreen) {
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


@end
