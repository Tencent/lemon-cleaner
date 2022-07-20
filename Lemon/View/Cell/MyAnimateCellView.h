//
//  MyAnimateCellView.h
//  Lemon
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MyAnimateCellViewDelegate <NSObject>

- (void)delegateMouseEntered;
- (void)delegateMouseExited;

@end

@interface MyAnimateCellView : NSView

@property(nonatomic, weak) id<MyAnimateCellViewDelegate> delegate;

@end
