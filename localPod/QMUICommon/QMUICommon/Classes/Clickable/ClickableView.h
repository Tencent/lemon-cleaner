//
//  ClickableView.h
//  QMUICommon
//
//  
//  Copyright © 2019年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ClickableView : NSView


NS_ASSUME_NONNULL_END

@property (nonatomic, copy) void(^mouseUpBlock)(void);
@property (nonatomic, copy) void(^mouseDownBlock)(void);
@end
