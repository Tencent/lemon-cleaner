//
//  LMSelectorDropView.m
//  TestCrube
//
//  
//  Copyright (c) 2014年 zero. All rights reserved.
//

#import "LMSelectorDropView.h"
#import <Quartz/Quartz.h>
#import "QMDuplicateDropLayer.h"
#import "QMDuplicateProgressLayer.h"
#import "NSBezierPath+Extension.h"
#import "QMDuplicateCoverLayer.h"

// MARK : Back Layer
@interface QMDuplicateBackLayer : CALayer
{
    CAShapeLayer * _progressLayer;
    CAShapeLayer * _backLayer;
    CGFloat _progressValue;
    
}

- (id)initWithFrame:(NSRect)rect;

- (void)setProgressValue:(CGFloat)progressValue animation:(BOOL)animation;

@end

@implementation QMDuplicateBackLayer

- (id)initWithFrame:(NSRect)rect
{
    if (self = [super init])
    {
        [self setFrame:rect];
        
        // 添加2个 Border 的意义在哪?
        _backLayer = [self borderLayer:[NSColor colorWithHex:0xFFBE46]];
        //        _backLayer = [self borderLayer:[NSColor whiteColor]];
        [self addSublayer:_backLayer];
        
        
        //        _progressLayer = [self borderLayer:[NSColor colorWithHex:0x50b465]];
        _progressLayer = [self borderLayer:[NSColor colorWithHex:0xFFBE46]];
        _progressLayer.strokeEnd = 0;
        [self addSublayer:_progressLayer];
    }
    return self;
}

- (CAShapeLayer *)borderLayer:(NSColor *)color
{
    CAShapeLayer * layer = [CAShapeLayer layer];
    NSBezierPath * path = [NSBezierPath bezierPath];
    [path appendBezierPathWithArcWithCenter: NSMakePoint( NSMidX(self.bounds),  NSMidY(self.bounds))
                                     radius: self.frame.size.width * 0.5 - 2
                                 startAngle: 90
                                   endAngle: -270
                                  clockwise: YES];
    CGPathRef pathRef = [path copyQuartzPath];
    layer.path = pathRef;
    layer.lineWidth = 2;
    layer.strokeColor = [color convertToCGColor];
    CGColorRef clearColorRef = CGColorCreateGenericGray(1, 1);
    layer.fillColor = clearColorRef;
    CGPathRelease(pathRef);
    // TODO stroke 的属性的作用.
    layer.strokeStart = 0;
    layer.strokeEnd = 1;
    CGColorRelease(clearColorRef);
    return layer;
}
- (void)setProgressValue:(CGFloat)progressValue animation:(BOOL)animation
{
    if (_progressValue == progressValue)
        return;
    _progressValue = progressValue;
    if (_progressValue == 0)
    {
        [_progressLayer setHidden:YES];
        [_progressLayer setStrokeEnd:0];
    }
    else
    {
        [_progressLayer setHidden:NO];
        [CATransaction setAnimationDuration:2];
        [CATransaction setDisableActions:!animation];
        [_progressLayer setStrokeEnd:progressValue];
    }
}

@end







typedef enum
{
    QMDuplicateStartState = 0,
    QMDuplicateAddFileState,
    QMDuplicateScanState,
    QMDuplicateScanEndState,
    QMDuplicateRemoveState
}QMDuplicateViewState;








// MARK:LMSelectorDropView  -- start

@interface LMSelectorDropView()<NSOpenSavePanelDelegate>
{
    QMDuplicateBackLayer * _duplicateBackLayer;
    QMDuplicateDropLayer * _duplicateDropLayer;
    
    QMDuplicateProgressLayer * _duplicateProgressLayer;
    
    QMDuplicateCoverLayer * _chooseFileLayer;
    
    NSMutableArray * _pathArray;
    NSArray * _tempPathArray;
    
    // 进度信息
    CGFloat _progressValue;
    NSTimer * _refreshProgressTime;
    
    QMDuplicateViewState _duplicateViewState;
    
    int _timeCount;
    
    NSBezierPath * _backBezierPath;
    
    NSTrackingArea *trackingArea;
    
}
@end

@implementation LMSelectorDropView

- (void)awakeFromNib
{
    // TODO 这个 Menu 触发条件
    cancelSelectedMenu = [[NSMenu alloc] init];
    NSMenuItem * menuItem = [cancelSelectedMenu addItemWithTitle:@"取消选择"
                                                          action:@selector(cancelSelectedPath:)
                                                   keyEquivalent:@""];
    [menuItem setTarget:self];
    // 圆区域
    _backBezierPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:self.bounds.size.width/2 yRadius:self.bounds.size.width/2];
    // 启动拖动功能
    _enableDragDrop = YES;
    _pathArray = [NSMutableArray array];
    
    [self setLayer:[CALayer layer]];
    [self setWantsLayer:YES];
    //register NSPasteboardType // drag
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    
    // back
    self.layer.backgroundColor = [[NSColor whiteColor] convertToCGColor];
    
    // 动画
    // 四个 layer : back Layer, drop Layer, choose Layer, progress Layer
    _duplicateBackLayer = [[QMDuplicateBackLayer alloc] initWithFrame:self.bounds];
    [self.layer addSublayer:_duplicateBackLayer];
    
    // 文件夹 icon name 的 layer.
    NSRect inner1PxRect = NSInsetRect(_duplicateBackLayer.bounds, 1, 1);
    _duplicateDropLayer = [[QMDuplicateDropLayer alloc] initWithFrame:inner1PxRect];
    [_duplicateDropLayer setDropDelegate:(id<QMDuplicateDropLayerDelegate>)self];
    [self.layer addSublayer:_duplicateDropLayer];
    
    // 指的 带有添加按钮 的 layer
    _chooseFileLayer = [[QMDuplicateCoverLayer alloc] initWithFrame:NSInsetRect(_duplicateBackLayer.frame, 1, 1) addTips:self.addFilesTipString]; // 防止遮挡边框.
    [self.layer addSublayer:_chooseFileLayer];
    
    // TODO 这个 layer 为什么没有 被add
    _duplicateProgressLayer = [[QMDuplicateProgressLayer alloc] initWithFrame:_duplicateBackLayer.frame];
    //    [self.layer addSublayer:_duplicateProgressLayer];
    
}



//响应双指滑动
- (BOOL)wantsScrollEventsForSwipeTrackingOnAxis:(NSEventGestureAxis)axis{
    return axis == NSEventGestureAxisHorizontal;
    
}

- (void)scrollWheel:(NSEvent *)event{
    //    NSLog(@"scrollWheel ... event is %@", event);
    [super scrollWheel:event];
    
    NSEventPhase phase = [event phase];
    BOOL shouldTrackSwipe = NO;
    
    
    if (event.phase == NSEventPhaseNone){
        return;
    }
    
    if(fabs(event.scrollingDeltaX) < fabs(event.scrollingDeltaY)){  //不能是 <= 因为 end 时,就是 ==
        NSLog(@"not horizontal scroll...");
        return;
    }
    
    
    if (phase == NSEventPhaseBegan) {
        NSLog(@"scroll event began ....");
        totalScrollDelta_ = NSZeroPoint;
        [_duplicateDropLayer startMouseDragged];
        
    } else if (phase == NSEventPhaseChanged) {
        shouldTrackSwipe = YES;
        totalScrollDelta_.x += [event scrollingDeltaX];
        totalScrollDelta_.y += [event scrollingDeltaY];
        [_duplicateDropLayer mouseDragged:NSMakePoint(totalScrollDelta_.x , totalScrollDelta_.y )];
        
        //        NSLog(@"totalScrollDelta_.x is %f", totalScrollDelta_.x);
    }else if (phase == NSEventPhaseEnded || phase == NSEventPhaseCancelled){
        NSLog(@"scroll event end ....");
        [_duplicateDropLayer endMouseDragged];
    }
    
    
    NSLog(@"scroll event is  ....%lu", (unsigned long)phase);
    
    
    
    
    //调用trackSwipeEventWithOptions 会带来新问题, 1. 之后的事件不会调用scrollWheel 方法了,而是触发自定义的 handler,而 handler 中无法拿到 具体的滑动 距离, 只有gestureAmount 这个小数级别的数值.
    
    // dampen 抑制
    //    __block BOOL animationCancelled = NO;
    //    [event trackSwipeEventWithOptions:NSEventSwipeTrackingLockDirection dampenAmountThresholdMin:0 max:0 usingHandler:^(CGFloat gestureAmount, NSEventPhase phase, BOOL isComplete, BOOL * _Nonnull stop) {
    //
    //        // gestureAmount 向前 向后
    //
    //        if(animationCancelled){
    //            *stop = YES;
    //        }
    //
    //        if(phase == NSEventPhaseBegan){
    //            NSLog(@"NSEventPhaseBegan .....");
    //        }else if(phase == NSEventPhaseEnded){
    //            NSLog(@"NSEventPhaseEnded .....");
    //        }else if(phase == NSEventPhaseChanged){
    //            NSPoint mouseLoc = [self convertPoint:[event locationInWindow] fromView:nil];
    ////            NSLog(@"NSEventPhaseChanged .....mouseLoc is %f",mouseLoc.x );
    //            NSLog(@"NSEventPhaseChanged .....gestureAmount is %f",gestureAmount );
    //
    ////            CGFloat deltaX = event.deltaX;
    //        }else if(phase == NSEventPhaseCancelled){
    //            NSLog(@"NSEventPhaseCancelled .....");
    //            animationCancelled = true;
    //        }
    //    }];
    
    
    //    [_duplicateDropLayer startMouseDragged];
    //
    //    while ((theEvent = [NSApp nextEventMatchingMask:NSLeftMouseDownMask | NSLeftMouseDraggedMask | NSLeftMouseUpMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES]) && ([theEvent type] != NSLeftMouseUp)) {
    //        @autoreleasepool {
    //            NSPoint now = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    //            [_duplicateDropLayer mouseDragged:NSMakePoint(now.x - mouseLoc.x, now.y - mouseLoc.y)];
    //        }
    //    }
    //    [_duplicateDropLayer endMouseDragged];
    
}

    
    
    
- (void)addResultPathArray
{
    [_pathArray addObjectsFromArray:_tempPathArray];
    //
    [_duplicateDropLayer addPathItem:_tempPathArray];
    _duplicateViewState = QMDuplicateAddFileState;
    // 添加文件委托
    for (NSString * path in _tempPathArray) {
        [_delegagte duplicateChoosePathChanged:path isRemove:NO];
    }
}

- (void)cancelSelectedPath:(id)sender
{
    [_pathArray removeAllObjects];
    [_duplicateDropLayer removeAllItems];
    [_chooseFileLayer setHidden:NO];
    [self showChooseLayerAnimation];
    _duplicateViewState = QMDuplicateStartState;
    [_delegagte removeAllChoosePath];
}

#pragma mark-
#pragma mark choose file

- (void)hiddeChooseLayerAnimation
{
    if (_duplicateViewState == QMDuplicateStartState)
    {
        [self addResultPathArray];
        [_chooseFileLayer showAnimationState2];  //chooseLayer hide
    }
    else
    {
        [self addResultPathArray];
    }
}
- (void)showChooseLayerAnimation
{
    if (_duplicateViewState != QMDuplicateStartState)
    {
        [_chooseFileLayer resetAnimation];
        _duplicateViewState = QMDuplicateStartState;
    }
}

- (BOOL)addFilePath:(id)sender
{
    NSArray * pathArray = nil;
    if ([sender isKindOfClass:[NSString class]])
    {
        if ([_pathArray containsObject:sender])
            return NO;
        pathArray = [NSArray arrayWithObject:sender];
    }
    else if ([sender isKindOfClass:[NSArray class]])
    {
        pathArray = sender;
    }
    
    if (!pathArray)
        return NO;
    
//    NSString *photoPath = [NSString stringWithFormat:@"%@/Pictures",NSUserName()];
//    NSMutableArray *mutableArray = [NSMutableArray new];
//    for(NSString *path in pathArray){
//        NSArray *array = [path componentsSeparatedByString:@"/"];
//        BOOL isPhotoslibraryPath = [array.lastObject containsString:@"photoslibrary"] && [path containsString:photoPath];
//        if(isPhotoslibraryPath){
//            NSString *newPath = @"";
//            for (NSInteger index = 0;index <array.count - 1;index ++) {
//                newPath = [newPath stringByAppendingString:@"/"];
//                newPath = [newPath stringByAppendingString:array[index]];
//            }
//            [mutableArray addObject:newPath];
//        } else {
//            [mutableArray addObject:path];
//        }
//    }
    
    pathArray = [_delegagte duplicateViewAllowFilePaths:pathArray];
    if (pathArray.count == 0)
    {
        if ([_pathArray count] == 0)
            [_chooseFileLayer resetAnimation];
        return NO;
    }
    NSMutableArray * tempArray = [NSMutableArray array];
    for (NSString * path in pathArray)
    {
        if ([_pathArray containsObject:path])
            continue;
        [tempArray addObject:path];
    }
    _tempPathArray = tempArray;
    if (_tempPathArray.count == 0)
        return NO;
    [self hiddeChooseLayerAnimation]; //这一行把 folder 的路径添加到了 view 显示了.
    return YES;
}


#pragma mark-
#pragma mark drop Layer delegate

- (void)duplicatePathRemove:(NSString *)path
{
    [_pathArray removeObject:path];
    [_delegagte duplicateChoosePathChanged:path isRemove:YES];
    if (_pathArray.count == 0)
        [self showChooseLayerAnimation];
}

#pragma mark-
#pragma mark mouse event

//- (void)updateTrackingAreas
//{
//    NSArray *areaArray = [self trackingAreas];
//    for (NSTrackingArea *area in areaArray)
//    {
//        [self removeTrackingArea:area];
//    }
//    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
//                                                                options:NSTrackingMouseMoved|NSTrackingActiveInActiveApp
//                                                                  owner:self
//                                                               userInfo:nil];
//    [self addTrackingArea:trackingArea];
//}

- (void)updateTrackingAreas {
    
    
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:trackingArea]) {
        [self addTrackingArea:trackingArea];
    }
}

- (void)ensureTrackingArea {
    if (trackingArea == nil) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved owner:self userInfo:nil];
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSLog(@ "QMDuplicateBackLayer mouseDown ...");
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    if (![_backBezierPath containsPoint:mouseLoc]){
        NSLog(@ "QMDuplicateBackLayer mouseDown return because _backBezierPath contains %f,%f",mouseLoc.x,mouseLoc.y);
        return;
    }

    // 小的  add 按钮 的 按压 态
    if((_duplicateViewState == QMDuplicateAddFileState) && [_chooseFileLayer ->_smallAddContainerLayer hitTest:mouseLoc]){
        [_chooseFileLayer showSmallAddButtonDownState];
    }
    

    
    [_duplicateDropLayer mouseDown:mouseLoc];
    while ((theEvent = [NSApp nextEventMatchingMask:NSLeftMouseDownMask | NSLeftMouseUpMask | NSLeftMouseDraggedMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES])) {
        @autoreleasepool {
            NSLog(@ "QMDuplicateBackLayer next mouse event is %@", theEvent);

            NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
            
            if (![_backBezierPath containsPoint:mouseLoc])
                return;
            if (([self.layer hitTest:mouseLoc] || [_duplicateBackLayer hitTest:mouseLoc])
                && (
                    (_duplicateViewState == QMDuplicateStartState )
                    || ((_duplicateViewState == QMDuplicateAddFileState) && [_chooseFileLayer ->_smallAddContainerLayer hitTest:mouseLoc])
                    )
                )
            {
                NSOpenPanel * openPanel = [NSOpenPanel openPanel];
                [openPanel setCanChooseFiles:NO];
                [openPanel setCanChooseDirectories:YES];
                [openPanel setCanCreateDirectories:NO];
                openPanel.delegate = self;
                
                NSString* language = [[NSLocale preferredLanguages] objectAtIndex:0];
                if(language && [language containsString:@"zh"]){
                    [openPanel setPrompt:@"添加"];
                }else{
                    [openPanel setPrompt:@"Add"];
                }
                
                if([_delegagte respondsToSelector:@selector(addFloderAction)]){
                    [_delegagte addFloderAction];
                }

                __weak LMSelectorDropView *weakSelf = self;
                [openPanel beginSheetModalForWindow:[self window]
                                  completionHandler:^(NSInteger result) {
                                      if (result == NSModalResponseOK)
                                      {
                                          NSString * filePath = [[openPanel URL] path];
                                          [weakSelf addFilePath:filePath];
                                      } else {
                                          if([self->_delegagte respondsToSelector:@selector(cancelAddAction)]){
                                              [self->_delegagte cancelAddAction];
                                          }
                                      }
                                  }];
            }
            
            // fix 鼠标点击 x 号时有时候不响应的问题, 有可能是 down 的下一个事件是drag 事件而非 up 事件
            if ([theEvent type] == NSLeftMouseUp || [theEvent type] ==  NSLeftMouseDragged ){
                [_duplicateDropLayer mouseUp:mouseLoc];
            }
            
            if((_duplicateViewState == QMDuplicateAddFileState) && [_chooseFileLayer ->_smallAddContainerLayer hitTest:mouseLoc]){
                [_chooseFileLayer showSmallAddButtonNoramlState];
            }

            break;
        }
    }
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    if (![_backBezierPath containsPoint:mouseLoc])
        return;
    [_duplicateDropLayer mouseMoved:mouseLoc];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    if (![_backBezierPath containsPoint:mouseLoc])
        return;
    if (_duplicateViewState == QMDuplicateAddFileState)
    {
        [cancelSelectedMenu popUpMenuPositioningItem:nil atLocation:mouseLoc inView:self];
    }
}

#pragma mark-
#pragma mark mouse drage

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    return YES;//so source doesn't have to be the active window
}

- (BOOL)mouseDownCanMoveWindow
{
    return NO;
}

//Move the mouse while pressing the button  NSLeftMouseDragged
// 自己 view 中点击拖动也会触发这个方法
- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if ([_backBezierPath containsPoint:mouseLoc])
    {
        
        [_duplicateDropLayer startMouseDragged];
        
        while ((theEvent = [NSApp nextEventMatchingMask:NSLeftMouseDownMask | NSLeftMouseDraggedMask | NSLeftMouseUpMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES]) && ([theEvent type] != NSLeftMouseUp)) {
            @autoreleasepool {
                NSPoint now = [self convertPoint:[theEvent locationInWindow] fromView:nil];
                [_duplicateDropLayer mouseDragged:NSMakePoint(now.x - mouseLoc.x, now.y - mouseLoc.y)];
            }
        }
        [_duplicateDropLayer endMouseDragged];
    }
    else
    {
        [super mouseDragged:theEvent];
    }
}

#pragma mark-
#pragma mark drag drop delegate

// NSDraggingDestination

//Destination Operations
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if (_duplicateViewState == QMDuplicateStartState)
        [_chooseFileLayer showAnimationState1];
    return NSDragOperationCopy;
}
- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    if (_duplicateViewState == QMDuplicateStartState)
        [_chooseFileLayer resetAnimation];
}
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    if ([sender draggingSource]!=self)
    {
        if (!_enableDragDrop)
            return NO;
        
        if (_duplicateViewState != QMDuplicateStartState
            && _duplicateViewState != QMDuplicateAddFileState)
            return NO;
        
        NSArray *files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
        if (![self addFilePath:files])
        {
            //            if (_duplicateViewState == QMDuplicateStartState)
            //                _chooseFileLayer.contents = [NSImage imageNamed:@"duplicate_chooseFile"];
            return NO;
        }
    }
    return YES;
}

#pragma mark-
#pragma mark 扫描操作

- (void)startScanAnimation:(void (^)(void))handler
{
    _timeCount = 0;
    [_duplicateDropLayer encloseItem:^{
        
        self->_progressValue = 0;
        CGPoint point = self->_duplicateProgressLayer.progressImagePostion;
        point.y = 110;
        [self->_duplicateProgressLayer setProgressImagePostion:point];
        [self _showProgressLayer];
        
        self->_duplicateViewState = QMDuplicateScanState;
        
        if (handler)
            handler();
    }];
}
- (void)stopScanAnimation:(BOOL)result
{
    ////    [self showDefatulsState:NO];
    //    if (_refreshProgressTime)
    //    {
    //        [_refreshProgressTime invalidate];
    //        _refreshProgressTime = nil;
    //    }
    //
    //    [self _closeProgressLayer];
    ////    [_chooseFileLayer showNormalState:NO];
    //    if (!result)
    //    {
    //        [_duplicateLayer enExpandItem:^{
    //            _duplicateViewState = QMDuplicateAddFileState;
    //        }];
    //    }
    //    else
    //    {
    //        [_chooseFileLayer showNormalState:NO];
    //        [_pathArray removeAllObjects];
    //        _duplicateViewState = QMDuplicateStartState;
    //        [_duplicateLayer removeAllItems];
    //        [_chooseFileLayer setHidden:NO];
    //        [_chooseFileLayer setTransform:CATransform3DMakeRotation(0,1,0,0)];
    //    }
}

#pragma mark-
#pragma mark 显示状态

- (void)showRemoveState:(NSArray *)array
{
    _duplicateViewState = QMDuplicateRemoveState;
    [_chooseFileLayer showRemoveFile:array];
    [self _showProgressLayer];
    CGPoint point = _duplicateProgressLayer.progressImagePostion;
    point.y = 100;
    [_duplicateProgressLayer setProgressImagePostion:point];
}
- (void)showRemoveEndState
{
    [self _closeProgressLayer];
    [_chooseFileLayer showCompleteState:NO];
}
- (void)showDefatulsState:(BOOL)animation
{
    [_chooseFileLayer showNormalState:YES];
}

#pragma mark-
#pragma mark 进度信息

- (void)_showProgressLayer
{
    [_duplicateProgressLayer showProgressValue:0];
    [self.layer addSublayer:_duplicateProgressLayer];
    [_duplicateProgressLayer startLoadingAnimation];
    
    if (_refreshProgressTime)
        [_refreshProgressTime invalidate];
    _refreshProgressTime = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                            target:self
                                                          selector:@selector(refreshProgressInfo)
                                                          userInfo:nil
                                                           repeats:YES];
}
- (void)_closeProgressLayer
{
    [CATransaction setDisableActions:YES];
    [_duplicateBackLayer setProgressValue:0 animation:NO];
    [_duplicateProgressLayer showProgressValue:0];
    [_duplicateProgressLayer removeFromSuperlayer];
}
- (void)setProgressValue:(CGFloat)value
{
    _progressValue = value;
    [_duplicateBackLayer setProgressValue:value animation:YES];
}

- (void)refreshProgressInfo
{
    if (_timeCount < 5)
    {
        _timeCount++;
        [_duplicateProgressLayer showProgressValue:_progressValue * ((_timeCount + 0.0) / 5)];
    }
    else
    {
        [_duplicateProgressLayer showProgressValue:_progressValue];
    }
}

#pragma mark-
#pragma mark 用户选择路径

- (void)addFilePathToView:(NSString *)path
{
    [self addFilePath:path];
}
- (void)removeFilePathFromView:(NSString *)path
{
    [_duplicateDropLayer removeItemWithPath:path];
}

- (NSArray *)duplicateChoosePaths
{
    return _pathArray;
}

// MARK: panel delegate
#pragma mark -- NSOpenSavePanelDelegate
#pragma mark -- - 获取权限选择方法回调
- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url NS_AVAILABLE_MAC(10_6){
    
    NSString* path = [url path];
    NSLog(@"user select shouldEnableURL = %@", path);
    if(!path){
        return NO;
    }
    if([path isEqualToString:@"/"]){
        return NO;
    }
    
    NSArray *pathArray = @[path];
    if(self.delegagte ){
        NSArray *allowPathArray = [self.delegagte duplicateViewAllowFilePaths:pathArray];
        if(allowPathArray && allowPathArray.count > 0){
            return YES;
        }
    }
    return NO;
}

@end

