//
//  McDetailOutlineGroupCellView.m
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "McDetailOutlineGroupCellView.h"
#import "NSColor+Extension.h"

@implementation McDetailOutlineGroupCellView


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self.groupName setTextColor:[NSColor colorWithHex:0x94979B]];
//        self.wantsLayer = true;
//        self.layer.backgroundColor = [NSColor whiteColor].CGColor;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
