//
//  LMCleanerScroller.m
//  LemonClener
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMCleanerScroller.h"

@implementation LMCleanerScroller


// 是否 overlay : 使用了这行代码,引入了一个坑爹的问题: 在 系统偏好设置->通用->修改 show scroll bars 选项的值为 always. 会引发 scrollbar 不绘制的问题.
// (触发的情况是配合下面的scrollerStyle 为 NSScrollerStyleOverlay)
+ (BOOL)isCompatibleWithOverlayScrollers{
    return YES;
}

- (NSScrollerStyle)scrollerStyle{
    return NSScrollerStyleOverlay;  //坑底的bug:使用这个但不开启isCompatibleWithOverlayScrollers, 会造成滚动条无法拖动.
//    return NSScrollerStyleLegacy;
    
}


@end
