//
//  LMPermissionGuideViewController.h
//  QMUICommon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMPermissionGuideWndController.h"
#import "QMBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 权限引导设置界面
 
 目前用于照片访问权限、自动化权限
 */
@interface LMPermissionGuideViewController : QMBaseViewController

@property NSString *tipsTitle;   //提示标题
@property NSString *descText; //提示副标题
@property NSImage *image;  //显示的图片
@property SettingButtonEvent okButtonEvent; //确定按钮点击事件
@property FinishButtonEvent finishButtonEvent;
@property FinishButtonEvent cancelButtonEvent;
@property BOOL needCheckMonitorFullDiskAuthorizationStatus;//需要根据权限状态更新button
@property NSInteger guidImageViewHeight;
@property(nonatomic) NSString *settingButtonTitle;
@property(nonatomic) NSString *cancelButtonTitle;
@property(nonatomic) NSString *confirmTitle; //授权后的确认按钮


@end

NS_ASSUME_NONNULL_END
