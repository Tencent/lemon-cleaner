//
//  QMDuplicateDropLayer.h
//  TestCrube
//
//  
//  Copyright (c) 2014年 zero. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@protocol QMDuplicateDropLayerDelegate <NSObject>

- (void)duplicatePathRemove:(NSString *)path;

@end


@interface QMDuplicateDropLayer : CALayer
{
    NSMutableArray * _pathArray;
    NSMutableArray * _contentLayerArray;
    NSPoint _lastDragPoint;
    NSPoint _startPoint;
    
    CATextLayer * _totalCountLayer;
    
    CALayer * _maskLayer;
    CALayer * _contentLayer;
    
    NSImage * _removePathImage;
    NSImage * _removePathHoverImage;
    CALayer * _highLayer;
    
    int _viewWidth;
}
@property (assign) id<QMDuplicateDropLayerDelegate> dropDelegate;

- (id)initWithFrame:(NSRect)rect;

- (void)addPathItem:(NSArray *)pathArray;

- (void)startMouseDragged;
- (void)mouseDragged:(NSPoint)point;
- (void)endMouseDragged;

- (void)removeAllItems;
- (void)removeItemWithPath:(NSString *)path;
- (void)enExpandItem:(void (^)(void))handler;
- (void)encloseItem:(void (^)(void))handler;

- (void)mouseDown:(NSPoint)point;
- (void)mouseUp:(NSPoint)point;
- (void)mouseMoved:(NSPoint)point;

@end

