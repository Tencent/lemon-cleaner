//
//  LMGSView.h
//  LemonClener
//

//  Copyright © 2022 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LMGSViewDelegete <NSObject>

- (void)GSViewDidMoveIn;
- (void)GSViewDidMoveOut;

@end

@interface LMGSView : NSView

@property (nonatomic, weak) id<LMGSViewDelegete> mouseDelegate;

@end

NS_ASSUME_NONNULL_END
