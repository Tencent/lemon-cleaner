//
//  Owl2Manager+Guide.h
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <PrivacyProtect/PrivacyProtect.h>
#import "Owl2Manager.h"

NS_ASSUME_NONNULL_BEGIN

/// 清理大类
typedef NS_ENUM(NSInteger, OWLShowGuideViewType) {
    OWLShowGuideViewType_None,              // 不显示
    OWLShowGuideViewType_Normal,            // 显示基础版本
    OWLShowGuideViewType_Special,           // 提示当前版本的（自动化）
};

// UI层使用，请在主线程中调用
@interface Owl2Manager (Guide)

// ‘一键开启’引导视图视图 被用户关闭
@property (nonatomic) BOOL oneClickGuideViewClosed;
// ‘一键开启’ 被用户点击过
@property (nonatomic) BOOL oneClickGuideViewClicked;

- (void)initCurrentUserDidShowGuideInOldVersionCached;

// 是否展示‘一键开启’引导视图视图
- (OWLShowGuideViewType)guideViewShowType;



@end

NS_ASSUME_NONNULL_END
