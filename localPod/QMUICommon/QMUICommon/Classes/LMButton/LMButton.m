//
//  LMButton.m
//  LemonClener
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMButton.h"
#import "LMButtonCell.h"

@interface LMButton()

@end

@implementation LMButton

-(void)setUp{
    NSBundle* bundle = [NSBundle bundleForClass:self.class];
    self.defaultImage = [bundle imageForResource:@"start_scan_btn_down_bg"];
    self.hoverImage = [bundle imageForResource:@"start_scan_btn_hover_bg"];
    self.downImage = [bundle imageForResource:@"start_scan_btn_normal_bg"];
    
    self.defaultTitleColor = [NSColor colorWithHex:0xFFFFFF];
    
    [super setUp];
}

@end
