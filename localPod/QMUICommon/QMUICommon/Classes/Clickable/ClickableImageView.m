//
//  ClickableImageView.m
//  QMUICommon
//
//  
//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "ClickableImageView.h"

@implementation ClickableImageView

- (BOOL)becomeFirstResponder{
    return YES;
}
- (BOOL)acceptsFirstMouse:(NSEvent *)event{
    return YES;
}

@end
