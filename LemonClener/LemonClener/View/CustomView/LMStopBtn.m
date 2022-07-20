//
//  LMStopBtn.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMStopBtn.h"

@interface LMStopBtn()

@end

@implementation LMStopBtn

-(void)setUp{
    NSBundle* bundle = [NSBundle bundleForClass:self.class];
    self.defaultImage = [bundle imageForResource:@"stop_scan_img_normal"];
    self.hoverImage = [bundle imageForResource:@"stop_scan_img_hover"];
    self.downImage = [bundle imageForResource:@"stop_scan_img_down"];
    
    self.defaultTitleColor = [NSColor colorWithHex:0xFFFFFF];
    
    [super setUp];
}

@end
