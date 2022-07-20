//
//  RatingUtils.m
//  Lemon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//


#import "RatingUtils.h"

#define LEMON_AS_CLEAN_ACTION_USAGE @"lemon_as_clean_actin_usage"   // 所有清理的次数
#define LEMON_AS_CLEAN_TRASH_ACTION_USAGE @"lemon_as_clean_trash_actin_usage"   // 清理垃圾的次数(主界面清理)
#define LEMON_AS_RATING_ACTION_CANCEL @"lemon_as_rating_actin_cancel"
#define LEMON_AS_SHOW_RATING_PAGE @"lemon_as_show_rating_page"
#define LEMON_AS_RATING_SHOW_THRESHOLD 2


typedef enum {
    RatingCancelActionUnKnown = 0,
    RatingCancelActionTucao = 1,
    RatingCancelActionApplestoreRating = 2,
}RatingCancelAction;


static BOOL hasCleanFinishAction = false;
static NSInteger page_show_count = 0;

// 用于用户评分/反馈
@implementation RatingUtils{
    NSInteger page_show_count;
}

+ (void) showRatingViewControllerIfNeededAt:(NSViewController *)viewController{
    if(page_show_count > 0){ //防止每次读取 userdefaults
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // 主界面垃圾清理完 2 次时显示弹窗(并且当次有清理完成的操作,并且用户没有过取消的操作.
    NSInteger clean_count = [defaults integerForKey:LEMON_AS_CLEAN_TRASH_ACTION_USAGE];
    NSObject  *cancelAction = nil;
#ifndef DEBUG
    page_show_count = [defaults integerForKey:LEMON_AS_SHOW_RATING_PAGE];
    if(page_show_count > 0 ){
        NSLog(@"%s has show rating page", __FUNCTION__);
        return;
    }
    cancelAction = [defaults objectForKey:LEMON_AS_RATING_ACTION_CANCEL];
#endif


    if (clean_count >= LEMON_AS_RATING_SHOW_THRESHOLD  && cancelAction == nil && hasCleanFinishAction ){
        [self showRatingGuideViewAt:viewController];
    }else{
        NSLog(@"%s stop show rating guide page:clean_count:%ld,hasCleanFinishAction:%d,cancelAction:%@", __FUNCTION__, (long)clean_count, hasCleanFinishAction, cancelAction);
    }
}


+(void)recordCleanFinishAction{
    hasCleanFinishAction = true;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger clean_count = [defaults integerForKey:LEMON_AS_CLEAN_ACTION_USAGE];
    [defaults setInteger:(clean_count + 1) forKey:LEMON_AS_CLEAN_ACTION_USAGE];
}

+(void)recordCleanTrashFinishAction{
    hasCleanFinishAction = true;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger clean_trash_count = [defaults integerForKey:LEMON_AS_CLEAN_TRASH_ACTION_USAGE];
    [defaults setInteger:(clean_trash_count + 1) forKey:LEMON_AS_CLEAN_TRASH_ACTION_USAGE];
    [self recordCleanFinishAction];
}

+(void)recordRatingPageShow{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger rating_show_count = [defaults integerForKey:LEMON_AS_SHOW_RATING_PAGE];
    [defaults setInteger:(rating_show_count + 1) forKey:LEMON_AS_SHOW_RATING_PAGE];
}


// 字典记录cancelAction. 字典 key: version,time,action
+ (void)recordCancelActionAtTucaoPage{
    NSInteger version = 1;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    RatingCancelAction action = RatingCancelActionTucao;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [dict setObject:@(version) forKey:@"version"];
    [dict setObject:@(now) forKey:@"time"];
    [dict setObject:@(action) forKey:@"action"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:dict forKey:LEMON_AS_RATING_ACTION_CANCEL];
    
}


+ (void)showRatingGuideViewAt:(NSViewController *)viewController{
    RatingViewController *controller = [[RatingViewController alloc]init];
    if(viewController){
        controller.parentViewController = viewController;
        [viewController presentViewControllerAsModalWindow:controller];
        [self recordRatingPageShow];
    }
}

#ifdef APPSTORE_VERSION
#endif


@end
