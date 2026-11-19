//
//  LMPlistHelper.h
//  LemonDaemon
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>


NSString *getErrorStr(int returnno);


NSArray<NSNumber *> * getCurrentLogInUserId(void);
NSArray<NSString *> * getCurrentLogInUserName(void);


int unloadPlistByLable(NSString *plistLable);

int unloadAgentPlistByLabel(NSString *plistLable, uid_t uid);

int unloadAgentPlistByLableForAllUser(NSString *plistLable);

int unloadPlist(NSString *plist);

int unloadAgentPlist(NSString *plist, uid_t uid);

/// 跨用户 unload Agent plist（root 权限下通过 bsexec 在目标用户上下文中执行）
int unloadAgentPlistForUser(NSString *plist, int userPid, NSString *userName);

int loadPlist(NSString *plist);
