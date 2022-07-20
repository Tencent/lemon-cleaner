//
//  McUninstall.h
//  McDaemon
//
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int UpdateCastle(char *newAppPath, const char *szUserName, const char *szVersion, int nUserPid);

int InstallCastle(const char *szUserName, const char *szVersion, int nUserPid);

void uninstallCastle(void);

void uninstallSub(void);

int copyFileIfNeed(void);

void removeAllFiles(void);

void reloadListenPlist(void);
