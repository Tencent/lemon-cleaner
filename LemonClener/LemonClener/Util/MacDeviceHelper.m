//
//  MacDeviceHelper.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "MacDeviceHelper.h"

@implementation MacDeviceHelper

//获取屏幕宽度
+(CGFloat)getScreenWidth{
    NSRect screenRect = [[NSScreen mainScreen] frame];
    
    CGFloat width = screenRect.size.width;
    return width;
}

//获取屏幕高度
+(CGFloat)getScreenHeight{
    NSRect screenRect = [[NSScreen mainScreen] frame];
    CGFloat height = screenRect.size.height;
    return height;
}

//获取origin x
+(CGFloat)getScreenOriginX{
    NSRect screenRect = [[NSScreen mainScreen] frame];
    CGFloat originX = screenRect.origin.x;
    return originX;
}

//获取origin y
+(CGFloat)getScreenOriginY{
    NSRect screenRect = [[NSScreen mainScreen] frame];
    CGFloat originY = screenRect.origin.y;
    return originY;
}

//大窗口收缩  切换到小窗口的origin
+(CGPoint)getScreenOriginSmall:(CGPoint) nowPoint{
    NSLog(@"getScreenOriginSmall oldOrigin = %@", NSStringFromPoint(nowPoint));
    CGPoint newPoint = nowPoint;
    CGFloat originX = nowPoint.x;
    CGRect currentScreenFrame = [MacDeviceHelper getCurrentPointScreenFrame:nowPoint isBigWindow:YES];
    CGFloat screenWidth = currentScreenFrame.size.width;
    if ((screenWidth - (originX - currentScreenFrame.origin.x)) < 428) {// 428 = 小界面宽度 383 + 贴边距离45
        newPoint.x = screenWidth - 428 + currentScreenFrame.origin.x;
    }
    if((originX - currentScreenFrame.origin.x) < 45) {//贴边45
        newPoint.x = 45 + currentScreenFrame.origin.x;
    }
    
    return newPoint;
}

//小窗口增大  切换到大窗口的origin
+(CGPoint)getScreenOriginBig:(CGPoint) nowPoint{
    NSLog(@"getScreenOriginHeight oldOrigin = %@", NSStringFromPoint(nowPoint));
    CGPoint newPoint = nowPoint;
    CGFloat originX = nowPoint.x;
    CGRect currentScreenFrame = [MacDeviceHelper getCurrentPointScreenFrame:nowPoint isBigWindow:NO];
    CGFloat screenWidth = currentScreenFrame.size.width;
    if ((screenWidth - (originX - currentScreenFrame.origin.x)) < 1045) {//1045 = 大界面宽度 1000 + 贴边距离45
        newPoint.x = screenWidth - 1045 + currentScreenFrame.origin.x;
    }
    if((originX - currentScreenFrame.origin.x) < 45) {//贴边45
        newPoint.x = 45 + currentScreenFrame.origin.x;
    }
    
    return newPoint;
}

//通过当前point来或者当前screen frame
+(CGRect)getCurrentPointScreenFrame:(CGPoint) nowPoint isBigWindow:(BOOL) isBig{
    NSScreen *mainScreen = [NSScreen mainScreen];
    NSRect mainFrame = mainScreen.frame;
    CGFloat windowSize = 0;
    if (isBig) {
        windowSize = 1000;
    }else{
        windowSize = 383;
    }
    if (((mainFrame.origin.x - windowSize) <= nowPoint.x) && (nowPoint.x <= (mainFrame.origin.x + mainFrame.size.width + windowSize)) && (mainFrame.origin.y <= nowPoint.y) && (nowPoint.y <= (mainFrame.origin.y + mainFrame.size.height))) {//落在主屏幕内
        return mainFrame;
    }else{
        NSArray *screenArray = [NSScreen screens];
        for (NSScreen *screen in screenArray) {
            if ([screen isEqual:mainScreen]) {
                continue;
            }
            CGRect screenFrame = screen.frame;
            if ((screenFrame.origin.x <= nowPoint.x) && (nowPoint.x <= (screenFrame.origin.x + screenFrame.size.width)) && (screenFrame.origin.y <= nowPoint.y) && (nowPoint.y <= (screenFrame.origin.y + screenFrame.size.height))) {//落在该屏幕内
                return screenFrame;
            }
        }
    }
    
    return mainFrame;
}

@end
