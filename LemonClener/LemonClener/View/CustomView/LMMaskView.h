//
//  LMMaskView.h
//  LemonClener
//

//  Copyright © 2022 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol LMMaskViewDelegete <NSObject>

- (void)maskViewDidMoveIn;
- (void)maskViewDidMoveOut;

@end

@interface LMMaskView : NSView

@property (nonatomic, assign) BOOL handCursor;
@property (nonatomic, weak) id<LMMaskViewDelegete> mouseDelegate;

@end

