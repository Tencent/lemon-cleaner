//
//  LMCloseButton.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMCloseButton.h"

@implementation LMCloseButton

-(void)setUp{
    NSBundle* bundle = [NSBundle bundleForClass:self.class];
    self.defaultImage = [bundle imageForResource:@"close_btn_normal"];
    self.hoverImage = [bundle imageForResource:@"close_btn_hover"];
    self.downImage = [bundle imageForResource:@"close_btn_down"];
    
    self.defaultTitleColor = [NSColor colorWithHex:0xFFFFFF];
    
    [super setUp];
}

@end
