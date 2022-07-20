//
//  MacDeviceHelper.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MacDeviceHelper : NSObject

//获取屏幕宽度 -- main
+(CGFloat)getScreenWidth;

//获取屏幕高度 -- main
+(CGFloat)getScreenHeight;

//获取origin x -- main
+(CGFloat)getScreenOriginX;

//获取origin y -- main
+(CGFloat)getScreenOriginY;

//大窗口收缩  切换到小窗口的origin
+(CGPoint)getScreenOriginSmall:(CGPoint) nowPoint;

//小窗口增大  切换到大窗口的origin
+(CGPoint)getScreenOriginBig:(CGPoint) nowPoint;

//通过当前point来或者当前screen frame
+(CGRect)getCurrentPointScreenFrame:(CGPoint) nowPoint  isBigWindow:(BOOL) isBig;

@end
