//
//  LMVisibleViewController.h
//  LemonMonitor
//

//  Copyright © 2021 Tencent. All rights reserved.
//

#import <QMUICommon/QMUICommon.h>
#import "QMBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LMVisibleViewControllerProtocol <NSObject>

- (void)LMVisibleViewControllerDidClose;

@end

typedef void (^LMVisibleViewControllerCompleteBlock)(void);

@interface LMVisibleViewController : QMBaseViewController

@property (nonatomic, assign) id<LMVisibleViewControllerProtocol> delegate;
@property (nonatomic, assign) BOOL needPrefence;

@end

NS_ASSUME_NONNULL_END
