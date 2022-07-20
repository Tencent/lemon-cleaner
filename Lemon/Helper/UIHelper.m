//
//  UIHelper.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "UIHelper.h"

@implementation UIHelper

+(NSTextField *)createNormalLabelWithString:(NSString *)text color:(NSColor *)color fontSize:(NSInteger) fontSize{
    NSTextField *textField = [[NSTextField alloc] init];
    [textField setEditable:NO];
    [textField setBordered:NO];
    [textField setDrawsBackground:NO];
    
    [textField setStringValue:text];
    if (color != nil) {
        [textField setTextColor:color];
    }
    [textField setFont:[NSFont systemFontOfSize:fontSize]];
    
    return textField;
}

@end
