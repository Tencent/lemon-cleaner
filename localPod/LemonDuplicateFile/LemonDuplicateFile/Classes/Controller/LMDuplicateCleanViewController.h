//
//  LMDuplicateCleanViewController.h
//  LemonDuplicateFile
//
//  Created by tencent on 2024/3/11.
//

#import <Cocoa/Cocoa.h>
#import "LMDuplicateWindowController.h"
#import <QMUICommon/QMBaseViewController.h>
#import "QMDuplicateItemManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMDuplicateCleanViewController : QMBaseViewController <QMDuplicateItemManagerDelegate>

@end

NS_ASSUME_NONNULL_END
