//
//  FirefoxPrivacyManager.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2018 tencent. All rights reserved.
//

#import <FMDB/FMDB.h>
#import "FirefoxPrivacyManager.h"

NSString *firefoxProfilePath = nil;

@interface FirefoxPrivacyManager ()


@end

/**
 *  Firefox 浏览器详细数据信息 可以看 https://support.mozilla.org/en-US/kb/profiles-where-firefox-stores-user-data
 *
 *  Passwords:       Your passwords are stored in the key4.db and logins.json files. For more information, see Password Manager - Remember, delete, change and import saved passwords in Firefox.
 *  Cookies:         A cookie is a bit of information stored on your computer by a website you’ve visited. Usually this is something like your site preferences or login status. Cookies are all stored in the cookies.sqlite file.
 *  Stored session:           The sessionstore.jsonlz4 file stores the currently open tabs and windows. For more information, see Restore previous session - Configure when Firefox shows your most recent tabs and windows.
 *  AutoComplete history:       The formhistory.sqlite file remembers what you have searched for in the Firefox search bar and what information you’ve entered into forms on websites. For more information, see Control whether Firefox automatically fills in forms.
 *  Downloads and Browsing History:       The places.sqlite file contains all your Firefox bookmarks and lists of all the files you've downloaded and websites you’ve visited. The bookmarkbackups folder stores bookmark backup files, which can be used to restore your bookmarks. For more information, see Bookmarks in Firefox and Restore bookmarks from backup or move them to another computer.
 *
 *3
 */

//59hizvlb.default-release
@implementation FirefoxPrivacyManager


+(FirefoxPrivacyManager *)sharedManager{
    static FirefoxPrivacyManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[FirefoxPrivacyManager alloc] init];
    });
    
    return manager;
}

- (NSString *)getBrowserDefaultPath {

    if (firefoxProfilePath == nil) {
        firefoxProfilePath = [self getFirefoxProfilesPath];
    }
    return firefoxProfilePath;
}

- (PRIVACY_APP_TYPE)getBrowserDefaultType {
    return PRIVACY_APP_FIREFOX;
}


- (NSString *)getFirefoxProfilesPath {
    NSString *path = [self getUserHomeDirectory];
    NSString *firefoxPath = [path stringByAppendingString:@"/Library/Application Support/Firefox/Profiles"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *> *dirFiles = [fileManager contentsOfDirectoryAtPath:firefoxPath error:nil];
    // NSPredicate 类似于正则，Firefox升级后有.default 和 .default-release两个文件，老版本只有.default文件
    NSArray<NSString *> *arrayUsingPredicate = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self CONTAINS '.default' "]];
    NSString *fileName;
    for (NSString *dir in arrayUsingPredicate) {
        BOOL isDir = NO;
        NSString *fullDirPath = [firefoxPath stringByAppendingPathComponent:dir];
        BOOL success = [fileManager fileExistsAtPath:fullDirPath isDirectory:&isDir];
        if (success && isDir) {
            NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:fullDirPath];
            while (fileName = [enumerator nextObject]) {
                if ([fileName containsString:@"places.sqlite"]) {
                    return fullDirPath;
                }
            }
            return fullDirPath;
        }
    }
    return nil;
}


- (PrivacyCategoryData *)getCookiesWithRunning:(BOOL)running {

    PrivacyCategoryData *cookieCategoryData = [[PrivacyCategoryData alloc] init];
    cookieCategoryData.categoryType = PRIVACY_CATEGORY_TYPE_COOKIE;
    cookieCategoryData.categoryName = getCategoryNameByType(cookieCategoryData.categoryType);
    cookieCategoryData.tips = getCategoryDescByType(cookieCategoryData.categoryType);
    
    NSString *profilePath = [self getBrowserDefaultPath];
    if (!profilePath) {
        return cookieCategoryData;
    }

    NSString *cookieDbPath = [profilePath stringByAppendingString:@"/cookies.sqlite"];
    FMDatabase *cookieDb = [self getReadableDBByPath:cookieDbPath running:running];

    if (cookieDb) {
        NSMutableArray *cookies = [[NSMutableArray alloc] init];
        FMResultSet *resultSet = [cookieDb executeQuery:@"SELECT baseDomain,count"
                                                        "(baseDomain) as count_name FROM moz_cookies group by baseDomain"];
        while ([resultSet next]) {
            PrivacyItemData *item = [[PrivacyItemData alloc] init];
            item.itemName = [resultSet stringForColumn:@"baseDomain"];
            int valueNumber = [resultSet intForColumn:@"count_name"];
            item.totalSubNum = valueNumber;
            [cookies addObject:item];
        }
        cookieCategoryData.subItems = cookies;

        [cookieDb close];
    }

    return cookieCategoryData;
}

- (PrivacyCategoryData *)getHistoryWithRunning:(BOOL)running {

    PrivacyCategoryData *cookieCategoryData = [[PrivacyCategoryData alloc] init];
    cookieCategoryData.categoryType = PRIVACY_CATEGORY_TYPE_BROWSER_HISTORY;
    cookieCategoryData.categoryName = getCategoryNameByType(cookieCategoryData.categoryType);
    cookieCategoryData.tips = getCategoryDescByType(cookieCategoryData.categoryType);

    NSString *profilePath = [self getBrowserDefaultPath];
    if (!profilePath) {
        return cookieCategoryData;
    }
    NSString *placesDbPath = [profilePath stringByAppendingString:@"/places.sqlite"];
    FMDatabase *placesDb = [self getReadableDBByPath:placesDbPath running:running];

    if (placesDb) {
        NSMutableArray *cookies = [[NSMutableArray alloc] init];
        FMResultSet *resultSet = [placesDb executeQuery:@"select moz_places.url as browser_url, count(moz_historyvisits.place_id) as count_url from moz_places,moz_historyvisits"
                                                        " where  moz_places.id==moz_historyvisits.place_id "
                                                        "group by moz_historyvisits.place_id order by moz_historyvisits.visit_date desc"];
        while ([resultSet next]) {
            PrivacyItemData *item = [[PrivacyItemData alloc] init];
            item.itemName = [resultSet stringForColumn:@"browser_url"];
            int valueNumber = [resultSet intForColumn:@"count_url"];
            item.totalSubNum = valueNumber;
            [cookies addObject:item];
        }
        cookieCategoryData.subItems = cookies;

        [placesDb close];
    }

    return cookieCategoryData;
}

// 如果 firefox 下载文件后并未关闭 firefox, 下载纪录不会存储.
- (PrivacyCategoryData *)getDownloadHistoryWithRunning:(BOOL)running {

    PrivacyCategoryData *dowanloadCategoryData = [[PrivacyCategoryData alloc] init];
    dowanloadCategoryData.categoryType = PRIVACY_CATEGORY_TYPE_DOWNLOAD_HISTORY;
    dowanloadCategoryData.categoryName = getCategoryNameByType(dowanloadCategoryData.categoryType);
    dowanloadCategoryData.tips = getCategoryDescByType(dowanloadCategoryData.categoryType);

    NSString *profilePath = [self getBrowserDefaultPath];
    if (!profilePath) {
        return dowanloadCategoryData;
    }

    NSString *placesPath = [profilePath stringByAppendingString:@"/places.sqlite"];
    FMDatabase *placesDb = [self getReadableDBByPath:placesPath running:running];

    if (placesDb) {
        NSMutableArray *histories = [[NSMutableArray alloc] init];
        // anno : annotation: 注解注释
        // anno_attribute_id = 2 : 在 moz_anno_attributes表中 代表 downloads/destinationFileURI
        FMResultSet *resultSet = [placesDb executeQuery:@"select content from moz_annos where moz_annos.anno_attribute_id==2 "];
        while ([resultSet next]) {
            PrivacyItemData *item = [[PrivacyItemData alloc] init];
            item.itemName = [resultSet stringForColumn:@"content"];
            item.totalSubNum = 1;
            [histories addObject:item];
        }
        dowanloadCategoryData.subItems = histories;

        [placesDb close];
    }

    return dowanloadCategoryData;
}

- (PrivacyCategoryData *)getSessionStorageWithRunning:(BOOL)running {
    PrivacyCategoryData *categoryData = [[PrivacyCategoryData alloc] init];
    categoryData.categoryType = PRIVACY_CATEGORY_TYPE_SESSION;
    categoryData.categoryName = getCategoryNameByType(categoryData.categoryType);
    categoryData.tips = getCategoryDescByType(categoryData.categoryType);
    
    NSString *profilePath = [self getBrowserDefaultPath];
    if (!profilePath) {
        return categoryData;
    }

    NSMutableArray *array = [[NSMutableArray alloc] init];
    PrivacyFileItemData *currentSession = [self getItemDataByPath:[profilePath
            stringByAppendingString:@"/sessionstore.jsonlz4"]];

    if (currentSession) {
        [array addObject:currentSession];
    }


    categoryData.subItems = array;
    return categoryData;
}

- (PrivacyCategoryData *)getAutofillFormWithRunning:(BOOL)running{
    
    PrivacyCategoryData *categoryData = [[PrivacyCategoryData alloc] init];
    categoryData.categoryType = PRIVACY_CATEGORY_TYPE_AUTOFILL;
    categoryData.categoryName = getCategoryNameByType(categoryData.categoryType);
    categoryData.tips = getCategoryDescByType(categoryData.categoryType);
    
    NSString *profilePath = [self getBrowserDefaultPath];
    if (!profilePath) {
        return categoryData;
    }

    NSString *formDbPath = [profilePath stringByAppendingString:@"/formhistory.sqlite"];
    FMDatabase *formDb = [self getReadableDBByPath:formDbPath running:running];

    if (formDb) {
        NSLog(@"firefox finally db path is %@", formDb.databasePath);
        NSMutableArray *array = [[NSMutableArray alloc] init];
        // anno : annotation: 注解注释
        // anno_attribute_id = 2 : 在 moz_anno_attributes表中 代表 downloads/destinationFileURI
        FMResultSet *resultSet = [formDb executeQuery:@"select value from moz_formhistory"];
        while ([resultSet next]) {
            PrivacyItemData *item = [[PrivacyItemData alloc] init];
            item.itemName = [resultSet stringForColumn:@"value"];
            item.totalSubNum = 1;
            [array addObject:item];
        }
        categoryData.subItems = array;

        [formDb close];
    }

    return categoryData;
}

- (PrivacyCategoryData *)getSavedPasswordWithRunning:(BOOL)running {
    PrivacyCategoryData *categoryData = [[PrivacyCategoryData alloc] init];
    categoryData.categoryType = PRIVACY_CATEGORY_TYPE_SAVE_PASSWORD;
    categoryData.categoryName = getCategoryNameByType(categoryData.categoryType);
    categoryData.tips = getCategoryDescByType(categoryData.categoryType);
    
    NSString *profilePath = [self getBrowserDefaultPath];
    if (!profilePath) {
        return categoryData;
    }

    NSMutableArray *privacyItemArray = [[NSMutableArray alloc] init];
    NSString *loginJsonPath = [profilePath stringByAppendingString:@"/logins.json"];
    NSData *data = [NSData dataWithContentsOfFile:loginJsonPath];
    if (data) {
        NSError *error = nil;

        /* JSON数据格式和OC对象的一一对应关系
         {} -> 字典
         [] -> 数组
         "" -> 字符串
         10/10.1 -> NSNumber
         true/false -> NSNumber
         null -> NSNull
        */

        id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        if ([obj isKindOfClass:NSDictionary.class]) {
            NSDictionary *dict = obj;
            id loginArray = dict[@"logins"];
            if ([loginArray isKindOfClass:NSArray.class]) {

                NSArray *itemArray = loginArray;
                for (id loginItem in itemArray) {
                    if ([loginItem isKindOfClass:NSDictionary.class]) {
                        NSDictionary *loginDict = loginItem;

                        NSString *hostname = loginDict[@"hostname"];
                        if (!hostname) {
                            continue;
                        }

                        PrivacyItemData *privacyItemData = [[PrivacyItemData alloc] init];
                        privacyItemData.itemName = hostname;
                        privacyItemData.totalSubNum = 1;
                        [privacyItemArray addObject:privacyItemData];
                    }
                }
            }
        }
    }

    categoryData.subItems = privacyItemArray;
    return categoryData;
}


- (FMDatabase *)getDefaultDbByPath:(NSString *)dbPath {

    FMDatabase *historyDb = [FMDatabase databaseWithPath:dbPath];
    if ([historyDb open]) {
        NSLog(@"firefox db 打开成功");
        return historyDb;
    } else {
        return nil;
    }

}

- (BOOL)cleanCookieData:(PrivacyCategoryData *)categoryData {

    if (!categoryData || categoryData.selectedSubItemNum <= 0) {
        return YES;
    }

    NSString *profilePath = [self getBrowserDefaultPath];
    if (!profilePath) {
        return FALSE;
    }

    NSString *cookieDbPath = [profilePath stringByAppendingString:@"/cookies.sqlite"];
    FMDatabase *cookieDb = [self getDefaultDbByPath:cookieDbPath];
    if (cookieDb) {

        NSString *sqlString = @"delete from moz_cookies where baseDomain = ?";
        BOOL flag = [self cleanDataBy:cookieDb executeSql:sqlString at:categoryData];
        return flag;

    }

    return NO;
}

- (BOOL)cleanBrowserHistory:(PrivacyCategoryData *)categoryData {
    if (!categoryData || categoryData.selectedSubItemNum <= 0) {
        return YES;
    }

    NSString *profilePath = [self getBrowserDefaultPath];
    if (!profilePath) {
        return FALSE;
    }

    NSString *placesDbPath = [profilePath stringByAppendingString:@"/places.sqlite"];
    FMDatabase *placesDb = [self getDefaultDbByPath:placesDbPath];
    if (placesDb) {

        NSString *sqlString = @"delete from moz_historyvisits where moz_historyvisits.place_id in ( select v.place_id from moz_historyvisits v inner join moz_places u on(u.id==v.place_id) where u.url = ? )";
        BOOL flag = [self cleanDataBy:placesDb executeSql:sqlString at:categoryData];
        return flag;
    }

    return NO;
}


- (BOOL)cleanDownloadHistory:(PrivacyCategoryData *)categoryData {
    if (!categoryData || categoryData.selectedSubItemNum <= 0) {
        return YES;
    }

    NSString *profilePath = [self getBrowserDefaultPath];
    if (!profilePath) {
        return FALSE;
    }

    NSString *placesDbPath = [profilePath stringByAppendingString:@"/places.sqlite"];
    FMDatabase *placesDb = [self getDefaultDbByPath:placesDbPath];
    if (placesDb) {
        NSString *sqlString = @"delete from moz_annos where place_id in ( select place_id from moz_annos where  content = ? )";
        BOOL flag = [self cleanDataBy:placesDb executeSql:sqlString at:categoryData];
        return flag;
    }
    return NO;
}

- (BOOL)cleanSavedPasswords:(PrivacyCategoryData *)categoryData {

    if (!categoryData || categoryData.selectedSubItemNum <= 0) {
        return YES;
    }

    NSString *profilePath = [self getBrowserDefaultPath];
    if (!profilePath) {
        return FALSE;
    }

    NSString *loginJsonPath = [profilePath stringByAppendingString:@"/logins.json"];
    NSData *data = [NSData dataWithContentsOfFile:loginJsonPath];
    if (data) {
        NSError *error = nil;

        id initObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];

        NSMutableArray *eligibleDictArray = [[NSMutableArray alloc] init]; // 纪录所有含有 hostname 的 array
        NSMutableArray *waitToChangeArray = nil;  // 保存 json 中 array 的指针

        if ([initObj isKindOfClass:NSDictionary.class]) {
            NSDictionary *dict = initObj;
            id loginInJson = dict[@"logins"];
            if ([loginInJson isKindOfClass:NSMutableArray.class]) {

                NSMutableArray *loginArray = loginInJson;
                waitToChangeArray = loginArray;

                for (id loginItem in loginArray) {

                    if ([loginItem isKindOfClass:NSMutableDictionary.class]) {
                        NSMutableDictionary *loginDict = loginItem;

                        NSString *hostname = loginDict[@"hostname"];
                        if (!hostname) {
                            continue;
                        }
                        [eligibleDictArray addObject:loginDict];
                    }
                }
            }
        }

        NSMutableArray *waitToDeleteArray = [[NSMutableArray alloc] init]; // 储存需要删除的

        for (PrivacyItemData *privacyItemData in categoryData.subItems) {
            if (privacyItemData.state != NSControlStateValueOn) {
                continue;
            }

            for (NSMutableDictionary *dict in eligibleDictArray) {
                NSString *hostname = dict[@"hostname"];
                if ([hostname isEqualToString:privacyItemData.itemName]) {
                    [waitToDeleteArray addObject:dict];
                }
            }
        }

        // 真正删除
        if (waitToChangeArray && waitToChangeArray.count > 0) {
            [waitToChangeArray removeObjectsInArray:waitToDeleteArray];
        }


        NSOutputStream *os = [[NSOutputStream alloc] initToFileAtPath:loginJsonPath append:NO];

        [os open];
        [NSJSONSerialization writeJSONObject:initObj toStream:os options:0 error:nil];
        [os close];
    }

    return NO;
}

- (BOOL)cleanSessions:(PrivacyCategoryData *)categoryData {

    if (!categoryData || categoryData.selectedSubItemNum <= 0) {
        return YES;
    }
    BOOL success = [self cleanPrivacyFileArray:categoryData.subItems];
    return success;
}


- (BOOL)cleanAutoFillForm:(PrivacyCategoryData *)categoryData{
    if (!categoryData || categoryData.selectedSubItemNum <= 0) {
        return YES;
    }

    NSString *profilePath = [self getBrowserDefaultPath];
    if (!profilePath) {
        return FALSE;
    }

    NSString *formDbPath = [profilePath stringByAppendingString:@"/formhistory.sqlite"];
    FMDatabase *formDb = [self getDefaultDbByPath:formDbPath];
    if (formDb) {
        NSString *sqlString = @"delete from moz_formhistory where value = ?";
        BOOL flag = [self cleanDataBy:formDb executeSql:sqlString at:categoryData];
        return flag;
    }
    return NO;
}
@end
