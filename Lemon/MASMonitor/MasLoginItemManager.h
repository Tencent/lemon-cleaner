//
//  MasLoginItemManager.h
//  Lemon
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MASXpcInterface.h"

#define IS_USER_REGISTER_LOGIN_ITEM @"is_user_register_login_item"
#define IS_OPEN_REGISTER_LOGIN_ITEM @"is_open_register_login_item"
#define OPEN_LOGIN_ITEM_PREFRENCE @"open_login_item_prefrence"

@interface MasLoginItemManager : NSObject<MASXPCAgent>

+ (id)sharedManager;

-(BOOL) enableLoginItemAndXpcAtGuidePage;
//通知托盘自动退出
-(void) notiMonitorExit;
-(void) setupMASXpcWhenLogItemRunning;
-(BOOL) disAbleLoginItem;
-(BOOL)isMASLoginItemRunning;
@end
