//
//  Owl2Manager+Guide.h
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <PrivacyProtect/PrivacyProtect.h>
#import "Owl2Manager.h"

NS_ASSUME_NONNULL_BEGIN

// UI层使用，请在主线程中调用
@interface Owl2Manager (Guide)
// 展示‘一键开启’引导视图视图
@property (nonatomic, readonly) BOOL showOneClickGuideView;
// ‘一键开启’引导视图视图 被用户关闭
@property (nonatomic) BOOL oneClickGuideViewClosed;
// ‘一键开启’ 被用户点击过
@property (nonatomic) BOOL oneClickGuideViewClicked;

@end

NS_ASSUME_NONNULL_END
