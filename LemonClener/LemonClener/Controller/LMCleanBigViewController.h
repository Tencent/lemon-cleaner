//
//  LMCleanBigViewController.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseViewController.h>
@interface LMCleanBigViewController : QMBaseViewController

@property (nonatomic, assign) long long fileMoveTotalNum;

-(void)showScanBigView;

-(void)showCleanBigView;

//没有垃圾的初始化
-(void)setNoResultViewWithScanFileNum:(NSUInteger) fileNum  scanTime:(NSUInteger) scanTime;

- (void)showAnimate;

@end
