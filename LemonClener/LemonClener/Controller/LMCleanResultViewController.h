//
//  LMCleanResultViewController.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseViewController.h>
@class LMRectangleButton;

@interface LMCleanResultViewController : QMBaseViewController
{
    __weak IBOutlet LMRectangleButton *doneButton;
    __weak IBOutlet NSTableView *outlineView;
    
}

//有垃圾的初始化
-(void)setResultViewWithCleanFileSize:(NSUInteger)fileSize fileNum:(NSUInteger) fileNum cleanTime:(NSUInteger) cleanTime;

- (void)showAnimate;

@end
