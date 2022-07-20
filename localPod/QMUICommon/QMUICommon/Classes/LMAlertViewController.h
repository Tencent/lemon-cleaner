//
//  LMAlertViewController.h
//  Lemon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QMBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^SimpleCallback)(void);

// 显示一行 title + 两个 Button, 窗口大小为420, 133
// button 的回调方法为 onOkButtonClicked()  onCancelButtonClicked 需复写.
@interface LMAlertViewController : QMBaseViewController

@property BOOL  showDesc;// 是否显示副标题
@property NSButton*  okButton;
@property NSButton*  cancelButton;
@property NSTextField*  titleLabel;
@property NSTextField*  descLabel;
@property CGFloat windowHeigh;
- (void)showAlertViewAsModalStypeAt:(NSViewController *)viewController;

NS_ASSUME_NONNULL_END

@property SimpleCallback _Nullable  okButtonCallback;
@property SimpleCallback _Nullable  cancelButtonCallback;
@property SimpleCallback _Nullable  windowCloseCallback;  //窗口关闭时的 callback
@property SimpleCallback _Nullable  windowShowCallback;   //窗口打开时的 callback
@property(nonatomic, weak)  NSViewController * _Nullable parentViewController;




@end

