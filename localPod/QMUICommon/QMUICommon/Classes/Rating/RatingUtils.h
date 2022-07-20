//
//  RatingUtils.h
//  Lemon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "RatingViewController.h"
NS_ASSUME_NONNULL_BEGIN

@interface RatingUtils : NSObject

// 记录清理完成的动作
+ (void) recordCleanFinishAction;

+ (void)recordCleanTrashFinishAction;

+ (void) showRatingViewControllerIfNeededAt:(NSViewController *)viewController;

// 字典记录cancelAction. 字典 key: version,time,action
+ (void )recordCancelActionAtTucaoPage;

@end

NS_ASSUME_NONNULL_END
