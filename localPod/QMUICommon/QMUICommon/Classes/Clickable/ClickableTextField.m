//
//  ClickableTextField.m
//  QMUICommon
//
//  
//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "ClickableTextField.h"

@implementation ClickableTextField

- (BOOL)becomeFirstResponder{
    return YES;
}
- (BOOL)acceptsFirstMouse:(NSEvent *)event{
    return YES;
}
@end
