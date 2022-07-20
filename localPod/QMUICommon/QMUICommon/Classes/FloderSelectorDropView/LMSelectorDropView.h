//
//  LMSelectorDropView.h
//  TestCrube
//
//  
//  Copyright (c) 2014年 zero. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol LMFloderSelectorDropViewDelegate <NSObject>

- (NSArray *)duplicateViewAllowFilePaths:(NSArray *)filePaths;
- (void)duplicateChoosePathChanged:(NSString *)path isRemove:(BOOL)remove;
- (void)removeAllChoosePath;
- (void)addFloderAction;
- (void)cancelAddAction;

@end

@interface LMSelectorDropView : NSView
{
    NSMenu * cancelSelectedMenu;
    NSPoint totalScrollDelta_;
}
@property (assign) id<LMFloderSelectorDropViewDelegate> delegagte;
@property (nonatomic, assign) BOOL enableDragDrop;
@property (nonatomic) NSString *addFilesTipString; // 注意多语言

- (NSArray *)duplicateChoosePaths;

- (void)addFilePathToView:(NSString *)path;
- (void)removeFilePathFromView:(NSString *)path;

- (void)startScanAnimation:(void (^)(void))handler;
- (void)stopScanAnimation:(BOOL)result;

- (void)showRemoveEndState;
- (void)showRemoveState:(NSArray *)array;
- (void)showDefatulsState:(BOOL)animation;

- (void)setProgressValue:(CGFloat)value;

@end

