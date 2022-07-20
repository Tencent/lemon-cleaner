//
//  PreferenceTabViewController.h
//  Lemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PreferenceWindowController.h"
#import <QMUICommon/QMBaseViewController.h>
NS_ASSUME_NONNULL_BEGIN

@interface LMPreferenceTabViewController : QMBaseViewController
@property (weak, nonatomic) PreferenceWindowController* myWC;


@end

NS_ASSUME_NONNULL_END
