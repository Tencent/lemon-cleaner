//
//  LMFileMoveIntroduceVC.h
//  LemonClener
//

//  Copyright © 2022 Tencent. All rights reserved.
//

#import <QMUICommon/QMUICommon.h>
#import <QMUICommon/QMBaseViewController.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LMFileMoveIntroduceVCDelegate <NSObject>

- (void)fileMoveIntroduceVCDidStart;

@end

@interface LMFileMoveIntroduceVC : QMBaseViewController

@property (nonatomic, weak) id <LMFileMoveIntroduceVCDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
