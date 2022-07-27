//
//  LMButtonCell.m
//  LemonClener
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMButtonCell.h"

@implementation LMButtonCell

-(instancetype) init {
    self = [super init];
    if (self) {
    }
    return self;
}

-(instancetype) initWithCoder:(NSCoder *)decoder {
    return [super initWithCoder:decoder];
}
-(instancetype) initImageCell:(NSImage *)image {
    return [super initImageCell:image];
}
-(instancetype) initTextCell:(NSString *)string {
    return [super initTextCell:string];
}

- (NSRect)titleRectForBounds:(NSRect)theRect {
    NSRect titleFrame = [super titleRectForBounds:theRect];
    NSSize titleSize = [[self attributedStringValue] size];
    
    titleFrame.origin.y = theRect.origin.y-(theRect.size.height-titleSize.height)*0.15;
    
    return titleFrame;
}

@end
