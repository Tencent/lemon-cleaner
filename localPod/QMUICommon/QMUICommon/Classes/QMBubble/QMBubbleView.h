//
//  QMBubbleView.h
//  QQMacMgrMonitor
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QMBubbleViewTypes.h"

@interface QMBubbleView : NSView
@property (nonatomic, assign) QMArrowDirection direction;
@property (nonatomic, assign) BOOL drawArrow;
@property (nonatomic, assign) double arrowHeight;
@property (nonatomic, assign) double arrowWidth;
@property (nonatomic, assign) double arrowDistance;
@property (nonatomic, assign) double cornerRadius;

@property (nonatomic, assign) double borderWidth;
@property (nonatomic, strong) NSColor *borderColor;
@property (nonatomic, strong) NSColor *backgroudColor;

@property (nonatomic, assign) QMArrowDirection faceDirection;
@property (nonatomic, assign) QMArrowDirection offsetDirection;
@property (nonatomic, assign) double drawDistance;

@property (nonatomic, assign) QMBubbleTitleMode titleMode;
@property (nonatomic, assign) double distance;
@property (nonatomic, assign) BOOL draggable;

- (NSPoint)arrowPoint;

- (void)refreshShadow;
- (BOOL)mouseInPath;

- (void)resetDragStartToCurrentPosition;

@end
