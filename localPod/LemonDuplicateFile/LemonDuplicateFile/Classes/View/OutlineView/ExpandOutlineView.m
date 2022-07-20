//
//  ExpandOutlineView.m
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/22.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "ExpandOutlineView.h"

@implementation ExpandOutlineView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

//- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row{
//
//    NSRect superFrame = [super frameOfCellAtColumn:column row:row];
//    if ((column == 0) /* && isGroupRow */) {
//        return NSMakeRect(0, superFrame.origin.y, [self bounds].size.width, superFrame.size.height);
//    }
////    return superFrame;
//    return NSZeroRect;
//}
//- (instancetype)initWithFrame:(NSRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        CGRect eyeBox = CGRectMake(0, 0, 400, 400);
////        eyeBox = self.bounds;
//        NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:eyeBox options:(NSTrackingMouseEnteredAndExited|NSTrackingActiveInKeyWindow|NSTrackingMouseMoved) owner:self userInfo:nil];
//        [self addTrackingArea:trackingArea];
//    }
//    return self;
//}


// Removing the disclosure triangle: 
- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row{
        return NSZeroRect;
}
@end
