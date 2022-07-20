//
//  BasePrivacyDataManager.h
//  LemonPrivacyClean
//
//  
//  Copyright © 2018 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PrivacyData.h"
#import "PrivacyDataManager.h"
#import <FMDB/FMDB.h>

@interface BaseBrowserPrivacyDataManager : NSObject

- (NSString *)getBrowserDefaultPath;

- (PRIVACY_APP_TYPE)getBrowserDefaultType;

- (PrivacyAppData *)getBrowserDataWithManager:(PrivacyDataManager *)manager running:(BOOL)isRunning processRate:(double)processRate processStart:(double)startValue;

- (BOOL)cleanBrowserDataWithManger:(PrivacyDataManager *)manager data:(PrivacyAppData *)chromeData processRate:(double)processRate processStart:(double)startValue;

- (PrivacyCategoryData *)getCookiesWithRunning:(BOOL)running;

- (PrivacyCategoryData *)getHistoryWithRunning:(BOOL)running;

- (PrivacyCategoryData *)getDownloadHistoryWithRunning:(BOOL)running;

- (PrivacyCategoryData *)getSessionStorageWithRunning:(BOOL)running;

- (PrivacyCategoryData *)getSavedPasswordWithRunning:(BOOL)running;

- (PrivacyCategoryData *)getLocalStorageWithRunning:(BOOL)running;

- (PrivacyCategoryData *)getAutofillFormWithRunning:(BOOL)running;

- (BOOL)cleanCookieData:(PrivacyCategoryData *)categoryData;

- (BOOL)cleanBrowserHistory:(PrivacyCategoryData *)categoryData;

- (BOOL)cleanDownloadHistory:(PrivacyCategoryData *)categoryData;

- (BOOL)cleanSavedPasswords:(PrivacyCategoryData *)categoryData;

- (BOOL)cleanSessions:(PrivacyCategoryData *)categoryData;

- (BOOL)cleanLocalStorage:(PrivacyCategoryData *)categoryData;

- (BOOL)cleanAutoFillForm:(PrivacyCategoryData *)categoryData;


- (BOOL)cleanDataBy:(FMDatabase *)db executeSql:(NSString *)sqlString at:(PrivacyCategoryData *)categoryData;

- (NSArray *)getPrivacyItemArrayByPath:(NSString *)path fileLevel:(NSInteger)level scanApp:(BOOL)scanApp includeDir:(BOOL)includeDirectory;

- (BOOL)cleanPrivacyFileArray:(NSArray *)array;

- (PrivacyFileItemData *)getItemDataByPath:(NSString *)path;

- (FMDatabase *)getReadableDBByPath:(NSString *)defaultDbPath running:(BOOL)running;

- (NSString *)getUserHomeDirectory;

+ (NSString *)getUserHomeDirectory;

- (NSString *)getFileNameByPath:(NSString *)filepath;
@end

