//
//  LMBaseLineSegmentedControl.m
//  Lemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMBaseLineSegmentedControl.h"
#import "LMBaseLineSegmentedCell.h"

@implementation LMBaseLineSegmentedControl

+ (Class)cellClass{
    return [LMBaseLineSegmentedCell class];
}

- (NSRect)segmentFrameForIndex:(NSInteger)index {
    CGFloat segmentWidth = [self widthForSegment:index];
    NSRect segmentRect = NSMakeRect(index * segmentWidth, 0, segmentWidth, self.bounds.size.height);
    return segmentRect;
}

- (void)mouseDown:(NSEvent *)event {
    // 获取点击位置
    NSPoint point = [event locationInWindow];
    // 转换为控件坐标系
    NSPoint transformedPoint = [self convertPoint:point fromView:nil];
    
    // 确定点击的分段
    for (NSInteger index = 0; index < self.segmentCount; index++) {
        NSRect segmentRect = [self segmentFrameForIndex:index];
        if (NSPointInRect(transformedPoint, segmentRect)) {
            // 设置选中分段
            self.selectedSegment = index;
            // 触发点击事件
            [self sendAction:self.action to:self.target];
            break;
        }
    }
}

@end
