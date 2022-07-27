//
//  QMRenderLayerView.h
//  QMUICommon
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface QMRenderLayerView : NSView
@property (nonatomic, assign) BOOL staticMode;

- (instancetype)initWithLayer:(CALayer *)layer;

@end
