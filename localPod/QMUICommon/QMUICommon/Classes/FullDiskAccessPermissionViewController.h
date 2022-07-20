//
//  FullDiskAccessPermissionViewController.h
//  Lemon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMAlertViewController.h"

#define IS_SHOW_REQUEST_FULL_DISK_PERMISSION_AT_BEGIN @"is_show_request_full_disk_permission_at_begin"

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    DEFAULT,
    MAIN_CLEANER_SMALL_VIEW,     //开始扫描首页检查权限
    SMALL_TOOLS_VIEW,            //小工具页面检查权限
    
}SourceType;


/// 用于完全磁盘访问权限检测，弹出“没有权限”的提示窗口
@interface FullDiskAccessPermissionViewController : LMAlertViewController



+ (BOOL) needShowRequestFullDiskAccessPermissionAlert;

/// 如果没有授权Lemon，则弹出引导窗口，采用通用的title
/// @param parentController parentController
//+ (BOOL)showFullDiskAccessRequestIfNeededWithParentController:(NSViewController *)parentController;

+(BOOL)showFullDiskAccessRequestIfNeededWithParentController:(NSViewController *)parentController sourceType: (SourceType)type;

+(BOOL)showFullDiskAccessRequestIfNeededWithParentController:(NSViewController *)parentController title:(NSString *)title sourceType:(SourceType)type;
//+(BOOL)showFullDiskAccessRequestIfNeededWithParentController:(NSViewController *)parentController title:(NSString *)title;

///  弹出引导提示窗口，该方法中没有对权限进行判断
/// @param parentController parentController
/// @param title 设置提示的title
//+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock;

+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock cancelBtnBlock:(SimpleCallback)cancelBtnBlock;

//+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title description: (NSString *)desc windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock;

+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title description: (NSString *)desc windowHeight: (CGFloat)height windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock;

+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title okBtnTitle: (NSString *)okBtnTitle windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock;

/// 弹出引导提示窗口，该方法中没有对权限进行判断
/// @param parentController parenController
/// @param title 提示的title
/// @param desc 副标题
/// @param okBtnTitle 确定按钮title
/// @param windowCloseblock 窗口关闭的世界
/// @param okBtnBlock 确定按钮点击事件
+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title description: (NSString *)desc okBtnTitle: (NSString *)okBtnTitle windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock;

+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title description: (NSString *)desc windowHeight: (CGFloat)height windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock cancelButtonBlock: (SimpleCallback)cancelBtnBlock;

+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title description: (NSString *)desc okBtnTitle: (NSString *)okBtnTitle okButtonBlock: (SimpleCallback) okBtnBlock cancelButtonBlock:(SimpleCallback) cancelBtnBlock;

+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title description: (NSString *)desc okBtnTitle: (NSString *)okBtnTitle windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock cancelButtonBlock:(SimpleCallback) cancelBtnBlock;

+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title description: (NSString *)desc okBtnTitle: (NSString *)okBtnTitle windowHeight:(CGFloat)height windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock cancelButtonBlock:(SimpleCallback) cancelBtnBlock;

@end

NS_ASSUME_NONNULL_END
