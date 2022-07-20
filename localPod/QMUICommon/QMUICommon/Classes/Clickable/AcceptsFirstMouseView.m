//
//  AcceptsFirstMouseView.m
//  QMUICommon
//
//  
//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "AcceptsFirstMouseView.h"

@implementation AcceptsFirstMouseView

- (BOOL)becomeFirstResponder{
    return YES;
}
- (BOOL)acceptsFirstMouse:(NSEvent *)event{
    return YES;
}
@end
