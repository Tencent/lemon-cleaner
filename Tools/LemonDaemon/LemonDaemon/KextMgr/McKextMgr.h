//
//  McKextMgr.h
//  McFireWallCtl
//

//  Copyright (c) 2011 Magican Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

int startKext(const char *origKextPath);
int stopKext(const char *kextBundle);
