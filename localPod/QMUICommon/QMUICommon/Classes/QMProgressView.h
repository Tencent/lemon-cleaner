//
//  QMProgressView.h
//  QMUICommon
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

typedef enum {
    QMProgressViewTypeNormal = 0,
    QMProgressViewTypeGradiant,
}QMProgressViewType;

#import <Cocoa/Cocoa.h>

@interface QMProgressView : NSView

@property (nonatomic, retain) NSColor * backColor;
@property (nonatomic, retain) NSColor * fillColor;
@property (nonatomic, retain) NSColor * borderColor;

@property (nonatomic, assign) float value;
@property (nonatomic, assign) float maxValue;
@property (nonatomic, assign) float minValue;

@property (nonatomic, assign) CGFloat border;

@property (nonatomic, assign) BOOL animation;
@property (nonatomic, assign) CGFloat animationTime;

@property (nonatomic, assign) BOOL actionEnd;

- (void)setupView;

-(CALayer *)getFillLayer:(NSRect) layerRect;

@end
