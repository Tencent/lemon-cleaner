//
//  GetFullDiskPopViewController.h
//  QMUICommon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QMBaseViewController.h"

typedef void(^CLoseBLock)(void);

@interface GetFullDiskPopViewController : QMBaseViewController

@property (nonatomic, assign) BOOL isLemonMonitor;

-(id)initWithCLoseSetting:(CLoseBLock) closeBlock;

@end
