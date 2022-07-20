//
//  LMPermissionGuideWndController.h
//  QMUICommon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum{
    LMPermissionForAccessPhoto,  //访问相册的权限
    LMPermissionForCreateAlbum,  //自动化权限，用户创建相册
}LMPermissionType;

/**
 按钮为“前往设置”状态时的点击事件
 */
typedef void(^SettingButtonEvent)(void);
/**
 按钮为“完成”状态时的点击事件
 */
typedef void(^FinishButtonEvent)(void);    //(1)

/**
 权限引导设置窗口
 
 目前用于相册访问权限、自动化权限
 
 创建时需要设置提示的标题、副标题、图片以及按钮为“前往设置”状态下的的点击事件
 
 注意：创建完成后需要调用loadWindow方法！
 
 如果有需要可以设置按钮为“完成”时的点击事件
 */
@interface LMPermissionGuideWndController : NSWindowController

@property NSString *tipsTitle;   //提示标题
@property NSString *descText; //提示副标题
@property NSImage *image;  //显示的图片
@property(nonatomic) NSString *settingButtonTitle;
@property(nonatomic) NSString *cancelButtonTitle;
@property SettingButtonEvent settingButtonEvent;
@property FinishButtonEvent finishButtonEvent;
@property FinishButtonEvent cancelButtonEvent;
@property(nonatomic) NSString *confirmTitle; //授权后的确认按钮
@property BOOL needCheckMonitorFullDiskAuthorizationStatus;

-(id)initWithParaentCenterPos:(CGPoint)centerPos title:(NSString *)title descText:(NSString *) desc image:(NSImage *) image;

-(void)closeWindow;
-(void)loadWindow;

-(id)initWithParaentCenterPos:(CGPoint)centerPos title:(NSString *)title descText:(NSString *) desc image:(NSImage *) image guideImageViewHeight: (NSInteger) height;
@end

NS_ASSUME_NONNULL_END
