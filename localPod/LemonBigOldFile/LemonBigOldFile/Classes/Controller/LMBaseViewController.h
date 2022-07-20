//
//  LMBaseViewController.h
//  LemonBigOldFile
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol BigFileWndEvent <NSObject>

- (void)windowWillClose:(NSNotification *)notification;

@end

@interface LMBaseViewController : NSViewController<BigFileWndEvent>
/**
 判断当前是否是暗黑主题
 
 @return true: 是
 */
-(Boolean)isDarkMode;

/**
 设置NSTextFields的文字颜色为 “title_color”
 
 @param textField <#textField description#>
 */
-(void)setTitleColorForTextField:(NSTextField *)textField;

@end
