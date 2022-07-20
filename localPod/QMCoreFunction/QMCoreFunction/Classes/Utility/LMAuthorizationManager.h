//
//  LMAuthorizationManager.h
//  QMCoreFunction
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    PhotoAccessed,   //具有访问权限
    PhotoDenied,   //不具有访问权限
    PhotoNotExist,   //相册不存在
}PhotoAccessState;  //相册访问状态

/**
 用户授权管理
 */
@interface LMAuthorizationManager : NSObject
/**
 检查是否有访问相册的权限
 
 检查方法：尝试读取系统相册目录，如果能够成功读取说明有权访问

 @return Yes:有权限
 */
+(PhotoAccessState)checkAuthorizationForAccessAlbum;
/**
 检查是否有创建相册的权限
 
 检查方法：尝试创建一个相册，通过返回值或异常信息判断是否创建成功，如果创建成功则说明有权限，然后将创建的相册删除

 @return Yes:有权限
 */
+(Boolean)checkAuthorizationForCreateAlbum;

/**
 打开自动化权限设置窗口
 
 @return
 */
+(void)openPrivacyAutomationPreference;

/**
 打开照片权限设置窗口
 */
+(void)openPrivacyPhotoPreference;
@end


