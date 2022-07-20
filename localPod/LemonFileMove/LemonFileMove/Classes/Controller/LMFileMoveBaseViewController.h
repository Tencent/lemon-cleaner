//
//  LMFileMoveBaseViewController.h
//  LemonFileMove
//
//  
//

#import <Cocoa/Cocoa.h>

@protocol BigFileWndEvent <NSObject>

- (void)windowWillClose:(NSNotification *)notification;

@end


@interface LMFileMoveBaseViewController : NSViewController<BigFileWndEvent>
/**
 判断当前是否是暗黑主题
 
 @return true: 是
 */
- (Boolean)isDarkMode;

/**
 设置NSTextFields的文字颜色为 “title_color”
 
 @param textField 文本框
 */
- (void)setTitleColorForTextField:(NSTextField *)textField;

@end

