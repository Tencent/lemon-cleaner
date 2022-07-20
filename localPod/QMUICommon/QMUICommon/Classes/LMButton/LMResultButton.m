//
//  LMResultButton.m
//  LemonClener
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMResultButton.h"

@implementation LMResultButton

- (void)setUp
{
    NSBundle* bundle = [NSBundle bundleForClass:self.class];
    self.defaultImage = [bundle imageForResource:@"result_btn_normal"];
    self.hoverImage = [bundle imageForResource:@"result_btn_hover"];
    self.downImage = [bundle imageForResource:@"result_btn_down"];
    
    self.defaultTitleColor = [NSColor colorWithHex:0x717171];
    self.hoverTitleColor = [NSColor colorWithHex:0x4cd19b];
    self.downTitleColor = [NSColor colorWithHex:0x4cd19b];
    
    [super setUp];
}

@end
