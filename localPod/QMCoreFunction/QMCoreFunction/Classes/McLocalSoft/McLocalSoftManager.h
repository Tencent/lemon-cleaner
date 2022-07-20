//
//  McLocalManager.h
//  McSoftware
//
//  Created by developer on 10/17/12.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *McLocalSoftManagerChangedNotification;  //Local soft list changed
extern NSString *McLocalSoftManagerListKey;              //NSArray  of McLocalSoft
extern NSString *McLocalSoftManagerUpdateListKey;        //NSArray  of McLocalSoft
extern NSString *McLocalSoftManagerFlagKey;              //NSNumber of NSInteger
extern NSString *McLocalSoftManagerFinishKey;            //NSNumber of BOOL

@class McLocalSoft;
@interface McLocalSoftManager : NSObject

+ (id)sharedManager;

- (void)monitorBundleID:(NSString *)bundleID;
- (void)removeSoftWithBundleID:(NSString *)bundleID;
- (NSArray *)submitSoftWithBundlePaths:(NSArray *)pathArray;

- (McLocalSoft *)softWithBundleID:(NSString *)bundleID;
- (NSArray *)softsWithFlag:(NSInteger)flag;
- (BOOL)loadingWithFlag:(NSInteger)flag;
- (void)refreshWithFlag:(NSInteger)flag;

@end
