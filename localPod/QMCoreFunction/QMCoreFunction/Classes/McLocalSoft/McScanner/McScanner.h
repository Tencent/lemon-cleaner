//
//  McScanner.h
//  McSoftware
//
//  Created by developer on 10/17/12.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "McLocalSoft.h"

@interface McScanner : NSObject

+ (id)scanner;

- (NSArray *)results;

- (BOOL)scanning;
- (void)stopScan;
- (void)scanWithHandler:(void(^)(NSArray *updates,BOOL finished))handler;

//override
- (NSArray *)scanPaths;
- (McLocalType)scanType;
- (BOOL)fileVaild:(NSString *)filePath;
- (BOOL)bundleVaild:(NSBundle *)bundle;

@end
