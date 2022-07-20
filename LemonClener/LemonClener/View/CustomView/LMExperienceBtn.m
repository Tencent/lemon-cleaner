//
//  LMExperienceBtn.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMExperienceBtn.h"

@implementation LMExperienceBtn

-(void)setUp{
    NSBundle* bundle = [NSBundle bundleForClass:self.class];
    self.defaultImage = [bundle imageForResource:@"experience_btn_normal"];
    self.hoverImage = [bundle imageForResource:@"experience_btn_hover"];
    self.downImage = [bundle imageForResource:@"experience_btn_down"];
    
    self.defaultTitleColor = [NSColor colorWithHex:0x94979b];
    self.hoverTitleColor = [NSColor colorWithHex:0xafafaf];
    self.downTitleColor = [NSColor colorWithHex:0x7e7e7e];
    
    [super setUp];
}

@end
