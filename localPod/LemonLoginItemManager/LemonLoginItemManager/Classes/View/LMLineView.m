//
//  LMLineView.m
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "LMLineView.h"

@implementation LMLineView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.wantsLayer = YES;
    self.layer.backgroundColor = self.backgroundColor1.CGColor;
}

- (void)setBackgroundColor1:(NSColor *)backgroundColor1 {
    _backgroundColor1 = backgroundColor1;
    self.wantsLayer = YES;
    self.layer.backgroundColor = backgroundColor1.CGColor;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
