//
//  Owl2Manager+Guide.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2Manager+Guide.h"

// 需要留着，如果之前已经展示过，这两个值有一个为true，隐私保护横幅上需要展示新的文案
static NSString * const kOwl2ManagerOneClickGuideViewClosedKey_Old1 = @"kOwl2ManagerOneClickGuideViewClosedKey";
static NSString * const kOwl2ManagerOneClickGuideViewClosedKey_Old2 = @"kOwl2ManagerOneClickGuideViewClosedKey_5.1.15";
static NSString * const kOwl2ManagerOneClickGuideViewClickedKey_Old1 = @"kOwl2ManagerOneClickGuideViewClickedKey";
static NSString * const kOwl2ManagerOneClickGuideViewClickedKey_Old2 = @"kOwl2ManagerOneClickGuideViewClickedKey_5.1.15";

static NSString * const kOwl2ManagerOneClickGuideViewClosedKey = @"kOwl2ManagerOneClickGuideViewClosedKey_5.1.16";
static NSString * const kOwl2ManagerOneClickGuideViewClickedKey = @"kOwl2ManagerOneClickGuideViewClickedKey_5.1.16";

@implementation Owl2Manager (Guide)
@dynamic oneClickGuideViewClosed;
@dynamic oneClickGuideViewClicked;

- (void)initCurrentUserDidShowGuideInOldVersionCached {
    BOOL didClickClosed1 = [[NSUserDefaults standardUserDefaults] boolForKey:kOwl2ManagerOneClickGuideViewClosedKey_Old1];
    BOOL didClickClosed2 = [[NSUserDefaults standardUserDefaults] boolForKey:kOwl2ManagerOneClickGuideViewClosedKey_Old2];
    BOOL didClickOpenButton1 = [[NSUserDefaults standardUserDefaults] boolForKey:kOwl2ManagerOneClickGuideViewClickedKey_Old1];
    BOOL didClickOpenButton2 = [[NSUserDefaults standardUserDefaults] boolForKey:kOwl2ManagerOneClickGuideViewClickedKey_Old2];

    self.currentUserDidShowGuideInOldVersionCached = didClickClosed1 || didClickClosed2 || didClickOpenButton1 || didClickOpenButton2;
}

// 是否展示‘一键开启’引导视图视图, 这里有个逻辑，如果用户展示的是OWLShowGuideViewType_Special，然后手动点击自动糊的switch开关来开启，则也要去掉guideview，所以当手动开启automatic的时候，设置下oneClickGuideViewClicked
- (OWLShowGuideViewType)guideViewShowType {
    if (self.oneClickGuideViewClosed) {
        // 主动点了关闭
        return OWLShowGuideViewType_None;
    }
    
    if (self.oneClickGuideViewClicked) {
        // 主动点了‘一键开启’ / '开启'
        return OWLShowGuideViewType_None;
    }
    
    // 4个都开启
    if (self.isWatchAudio && self.isWatchVideo && self.isWatchScreen && self.isWatchAutomatic) {
        return OWLShowGuideViewType_None;
    }
    
    OWLShowGuideViewType type = OWLShowGuideViewType_Normal;
    if (self.currentUserDidShowGuideInOldVersionCached) {       // 老用户展示过
        type = OWLShowGuideViewType_Special;
    }
    return type;
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
