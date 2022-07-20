//
//  QMBaseViewController.h
//  QMUICommon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface QMBaseViewController : NSViewController
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

NS_ASSUME_NONNULL_END
