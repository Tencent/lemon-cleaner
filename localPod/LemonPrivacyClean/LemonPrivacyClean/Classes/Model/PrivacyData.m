//
//  PrivacyData.m
//  FMDBDemo
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <objc/Object.h>
#import "PrivacyData.h"
#import <QMUICommon/LMViewHelper.h>
#import <QMCoreFunction/NSImage+Extension.h>

@implementation BasePrivacyData

- (instancetype)init {
    self = [super init];
    if (self) {
//        [_state addObserver]
        [self addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }

    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"state"];
}

+(NSString *)getCategoryNameByType:(PRIVACY_CATEGORY_TYPE) type{
    switch (type) {
        case PRIVACY_CATEGORY_TYPE_COOKIE:
            return @"Cookie";
        case PRIVACY_CATEGORY_TYPE_BROWSER_HISTORY:
            return NSLocalizedStringFromTableInBundle(@"PrivacyData_calculateSubItemsTotalNum_1553135349_1", nil, [NSBundle bundleForClass:[self class]], @"");
        case PRIVACY_CATEGORY_TYPE_DOWNLOAD_HISTORY:
            return NSLocalizedStringFromTableInBundle(@"PrivacyData_calculateSubItemsTotalNum_1553135349_2", nil, [NSBundle bundleForClass:[self class]], @"");
        case PRIVACY_CATEGORY_TYPE_SESSION:
            return @"Session";
        case PRIVACY_CATEGORY_TYPE_LOCAL_STORAGE:
            return NSLocalizedStringFromTableInBundle(@"PrivacyData_calculateSubItemsTotalNum_1553135349_3", nil, [NSBundle bundleForClass:[self class]], @"");
        case PRIVACY_CATEGORY_TYPE_SAVE_PASSWORD:
            return NSLocalizedStringFromTableInBundle(@"PrivacyData_calculateSubItemsTotalNum_1553135349_4", nil, [NSBundle bundleForClass:[self class]], @"");
        case PRIVACY_CATEGORY_TYPE_AUTOFILL:
            return NSLocalizedStringFromTableInBundle(@"PrivacyData_calculateSubItemsTotalNum_1553135349_5", nil, [NSBundle bundleForClass:[self class]], @"");
        default:
            return @"unKnown";
    }
}

+(NSString *)getCategoryDescByType:(PRIVACY_CATEGORY_TYPE) type{
    switch (type) {
        case PRIVACY_CATEGORY_TYPE_COOKIE:
            return NSLocalizedStringFromTableInBundle(@"PrivacyData_calculateSubItemsTotalNum_1553135349_6", nil, [NSBundle bundleForClass:[self class]], @"");
        case PRIVACY_CATEGORY_TYPE_BROWSER_HISTORY:
            return NSLocalizedStringFromTableInBundle(@"PrivacyData_calculateSubItemsTotalNum_1553135349_7", nil, [NSBundle bundleForClass:[self class]], @"");
        case PRIVACY_CATEGORY_TYPE_DOWNLOAD_HISTORY:
            return NSLocalizedStringFromTableInBundle(@"PrivacyData_calculateSubItemsTotalNum_1553135349_8", nil, [NSBundle bundleForClass:[self class]], @"");
        case PRIVACY_CATEGORY_TYPE_SESSION:
            return NSLocalizedStringFromTableInBundle(@"PrivacyData_calculateSubItemsTotalNum_1553135349_9", nil, [NSBundle bundleForClass:[self class]], @"");
        case PRIVACY_CATEGORY_TYPE_SAVE_PASSWORD:
            return NSLocalizedStringFromTableInBundle(@"PrivacyData_calculateSubItemsTotalNum_1553135349_10", nil, [NSBundle bundleForClass:[self class]], @"");
        case PRIVACY_CATEGORY_TYPE_LOCAL_STORAGE:
            return NSLocalizedStringFromTableInBundle(@"PrivacyData_calculateSubItemsTotalNum_1553135349_11", nil, [NSBundle bundleForClass:[self class]], @"");
        case PRIVACY_CATEGORY_TYPE_AUTOFILL:
            return NSLocalizedStringFromTableInBundle(@"PrivacyData_calculateSubItemsTotalNum_1553135349_12", nil, [NSBundle bundleForClass:[self class]], @"");
        default:
            return NSLocalizedStringFromTableInBundle(@"PrivacyData_calculateSubItemsTotalNum_1553135349_13", nil, [NSBundle bundleForClass:[self class]], @"");
    }
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context {

    if ([keyPath isEqualToString:@"state"]) {
        NSControlStateValue newValue = [change[NSKeyValueChangeNewKey] intValue];
        NSControlStateValue oldValue = [change[NSKeyValueChangeOldKey] intValue];
        [self changeSelectedNumBy:newValue old:oldValue];
    }
}

// 通过优先更改 子 item 的 state, 先计算出了 子 item 的 selectNum, 不用继续向下递归.
- (void)changeSelectedNumBy:(NSControlStateValue)newValue old:(NSControlStateValue)oldValue {

    if (newValue == oldValue && newValue != NSControlStateValueMixed) {
        // no need change select count
    } else {
        if (!self.subItems) {
            _selectedSubItemNum = (self.state == NSOnState ? self.totalSubNum : 0);
            return;
        }

        NSInteger totalSelectedNum = 0;
        for (BasePrivacyData *item in self.subItems) {
            // MARK : get Ivar value for object
            // object_getInstanceVariable 这个方法不能用了, 被 ARC forbidden 了
            // object_getInstanceVariable(item, "_someDouble", (void**)&itemSelectedNum);
            totalSelectedNum += [[item valueForKey:@"_selectedSubItemNum"] intValue];
        }

        _selectedSubItemNum = totalSelectedNum;
    }

}


- (void)refreshItemStateValue {

    if (!self.subItems) self.state = (self.state != NSOffState ? NSOnState : NSOffState);

    int totalSubNum = 0;
    int totalMixStateNum = 0;
    int totalOnStateNum = 0;

    totalSubNum = (int) self.subItems.count;

    for (BasePrivacyData *subItemData in self.subItems) {
        if(subItemData.totalSubNum == 0){
            totalSubNum--;
            continue;
        }
        if (subItemData.state == NSOnState) totalOnStateNum++;
        if (subItemData.state == NSMixedState) totalMixStateNum++;
      
    }


    if (totalSubNum == 0) {
        // 无子item,由自身决定, 并且不应该出现 mix state
        self.state = self.state != NSOffState ? NSOnState : NSOffState;
    } else if (totalOnStateNum == totalSubNum) {
        self.state = NSOnState;
    } else if (totalOnStateNum == 0 && totalMixStateNum == 0) {
        self.state = NSOffState;
    } else {
        self.state = NSMixedState;
    }
}

// TODO 貌似有问题.
// 注意 这个方法会 recursive 子 item, 所以需要 先计算 子 item 的,再去计算父 节点的数据.
- (NSInteger)resultSelectedCountByRecursive {
//    @throw([NSException exceptionWithName:@"no implement " reason:@"resultSelectedCount no implement" userInfo:nil]);

    NSInteger resultCount = 0;
    if (!self.subItems) {
        if (self.state != NSOffState) {
            resultCount = self.totalSubNum;
        } else {
            resultCount = 0;
        }
    } else {
        for (BasePrivacyData *subItem in self.subItems) {
            if (subItem.state != NSOffState) {
                resultCount += [subItem resultSelectedCountByRecursive];
            }
        }
    }

    self.selectedSubItemNum = resultCount;
    return resultCount;
}

// 这个方法 也会recursive, 保证先更改叶子节点 最终更改自己的
- (void)setStateWithSubItemsIfHave:(NSControlStateValue)stateValue {
//    @throw([NSException exceptionWithName:@"no implement " reason:@"setStateWithSubItemsIfHave no implement" userInfo:nil]);
    if (self.subItems) {
        for (BasePrivacyData *item in self.subItems) {

            // 注意: 这里需要使用stateValue 而不是 self.state, 因为 self.state 还未改变.
            [item setStateWithSubItemsIfHave:stateValue];
        }
    }

    self.state = stateValue;

}


- (void)calculateSubItemsTotalNum {
    NSInteger calculateTotalNum = 0;

    if (self.subItems != nil) {
        for (BasePrivacyData *item in self.subItems) {

            // 注意: 这里需要使用stateValue 而不是 self.state, 因为 self.state 还未改变.
            if (item.totalSubNum == 0) {
                [item calculateSubItemsTotalNum];
            }

            calculateTotalNum += item.totalSubNum;
        }
    }

    // 非叶子节点的 item,才需要计算子 item 的数量.
    if (self.totalSubNum == 0 && calculateTotalNum > 0) {
        self.totalSubNum = calculateTotalNum;
    }
}
@end


@implementation PrivacyData

@end


@implementation PrivacyAppData

@end


@implementation PrivacyCategoryData

@end


@implementation PrivacyItemData

@end

@implementation PrivacyFileItemData

@end

@implementation PrivacyPlistItemData

@end


NSString *getAppNameByType(PRIVACY_APP_TYPE type) {
    switch (type) {
        case PRIVACY_APP_SAFARI:
            return @"Safari";
        case PRIVACY_APP_CHROME:
            return @"Chrome";
        case PRIVACY_APP_FIREFOX:
            return @"Firefox";
        case PRIVACY_APP_QQ_BROWSER:
            return @"QQBrowser";
        case PRIVACY_APP_OPERA:
            return @"Opera";
        case PRIVACY_APP_CHROMIUM:
            return @"Chromium";
        case PRIVACY_APP_MICROSOFT_EDGE_BETA:
            return @"Microsoft Edge Beta";
        case PRIVACY_APP_MICROSOFT_EDGE_DEV:
            return @"Microsoft Edge Dev";
        case PRIVACY_APP_MICROSOFT_EDGE_CANARY:
            return @"Microsoft Edge Canary";
        case PRIVACY_APP_MICROSOFT_EDGE:
            return @"Microsoft Edge";
        default:
            return @"unKnown";
    }
}

NSString *getDefaultAppNameByType(PRIVACY_APP_TYPE type) {
    switch (type) {
        case PRIVACY_APP_SAFARI:
            return @"Safari";
        case PRIVACY_APP_CHROME:
            return @"Google Chrome";
        case PRIVACY_APP_FIREFOX:
            return @"Firefox";
        case PRIVACY_APP_QQ_BROWSER:
            return @"QQBrowser";
        case PRIVACY_APP_OPERA:
            return @"Opera";
        case PRIVACY_APP_CHROMIUM:
            return @"Chromium";
        case PRIVACY_APP_MICROSOFT_EDGE_BETA:
            return @"Microsoft Edge Beta";
        case PRIVACY_APP_MICROSOFT_EDGE_DEV:
            return @"Microsoft Edge Dev";
        case PRIVACY_APP_MICROSOFT_EDGE_CANARY:
            return @"Microsoft Edge Canary";
        case PRIVACY_APP_MICROSOFT_EDGE:
            return @"Microsoft Edge";
        default:
            return @"unKnown";
    }
}

NSString *getAppIdentifierByType(PRIVACY_APP_TYPE type) {
    switch (type) {
        case PRIVACY_APP_SAFARI:
            return @"com.apple.Safari";
        case PRIVACY_APP_CHROME:
            return @"com.google.Chrome";
        case PRIVACY_APP_FIREFOX:
            return @"org.mozilla.firefox";
        case PRIVACY_APP_QQ_BROWSER:
            return @"com.tencent.QQBrowser";
        case PRIVACY_APP_OPERA:
            return @"com.operasoftware.Opera";
        case PRIVACY_APP_CHROMIUM:
            return @"org.chromium.Chromium";
        case PRIVACY_APP_MICROSOFT_EDGE_BETA:
            return @"com.microsoft.edgemac.Beta";
        case PRIVACY_APP_MICROSOFT_EDGE_DEV:
            return @"com.microsoft.edgemac.Dev";
        case PRIVACY_APP_MICROSOFT_EDGE_CANARY:
            return @"com.microsoft.edgemac.Canary";
        case PRIVACY_APP_MICROSOFT_EDGE:
            return @"com.microsoft.edgemac";
        default:
            return nil;
    }
}


NSString *getCategoryNameByType(PRIVACY_CATEGORY_TYPE type) {
    return [BasePrivacyData getCategoryNameByType:type];
}

NSString *getCategoryDescByType(PRIVACY_CATEGORY_TYPE type) {
    return [BasePrivacyData getCategoryDescByType:type];
}


NSImage *getCategoryImageByType(PRIVACY_CATEGORY_TYPE type) {

    switch (type) {
        case PRIVACY_CATEGORY_TYPE_COOKIE:
            return [NSImage imageNamed:@"privacy_cookie" withClass:BasePrivacyData.class];
        case PRIVACY_CATEGORY_TYPE_BROWSER_HISTORY:
            return [NSImage imageNamed:@"privacy_history" withClass:BasePrivacyData.class];
        case PRIVACY_CATEGORY_TYPE_DOWNLOAD_HISTORY:
            return [NSImage imageNamed:@"privacy_download_history" withClass:BasePrivacyData.class];
        case PRIVACY_CATEGORY_TYPE_SESSION:
            return [NSImage imageNamed:@"privacy_session" withClass:BasePrivacyData.class];
        case PRIVACY_CATEGORY_TYPE_SAVE_PASSWORD:
            return [NSImage imageNamed:@"privacy_save_password" withClass:BasePrivacyData.class];
        case PRIVACY_CATEGORY_TYPE_LOCAL_STORAGE:
            return [NSImage imageNamed:@"privacy_local_storage" withClass:BasePrivacyData.class];
        case PRIVACY_CATEGORY_TYPE_AUTOFILL:
            return [NSImage imageNamed:@"privacy_autofill" withClass:BasePrivacyData.class];
        default:
            return [NSImage imageNamed:@"privacy_default" withClass:BasePrivacyData.class];
    }
}
