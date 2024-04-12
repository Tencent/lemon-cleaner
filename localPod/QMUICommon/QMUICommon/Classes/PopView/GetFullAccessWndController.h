//
//  GetFullAccessWndController.h
//  LemonClener
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GetFullDiskPopViewController.h"

typedef void(^SuccessSettingBlock)(void);

/// 完全磁盘访问权限引导窗口 ( 单例)
@interface GetFullAccessWndController : NSWindowController

@property (nonatomic, assign) GetFullDiskPopVCStyle style;

-(void)closeWindow;

+(GetFullAccessWndController *)shareInstance;

/// 设置窗口显示所需的参数
/// @param centerPos 显示的位置
/// @param successSettingBlock 点击完成按钮的回调方法
-(void)setParaentCenterPos:(CGPoint)centerPos suceessSeting:(SuccessSettingBlock) successSettingBlock;

@end
