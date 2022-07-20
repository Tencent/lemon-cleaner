//
// 
// Copyright (c) 2018 tencent. All rights reserved.
//

#import <FMDB/FMDB.h>
#import "PrivacyDataManager.h"
#import "ChromePrivacyDataManager.h"

@implementation ChromePrivacyDataManager{
    NSString *_dataPath;
}


+(ChromePrivacyDataManager *)sharedManagerWithDataPath:(NSString*)dataPath{
    static ChromePrivacyDataManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ChromePrivacyDataManager alloc] init];
    });
    manager->_dataPath = dataPath;
    return manager;
}

- (NSString *)getBrowserDefaultPath {
    return _dataPath;
}

+ (NSString *)getChromeDataDefaultPath {
    NSString *path = [self getUserHomeDirectory];
    NSString *chromeDataPath = [path stringByAppendingString:@"/Library/Application Support/Google/Chrome"];
    NSString *chromeDefaultPath = [chromeDataPath stringByAppendingPathComponent:@"Default"];
    return chromeDefaultPath;
}

// TODO  兼容多用户模式
// chrome 可以开启多用户模式. 不一定有 Default 目录. 相反可能含有 System Profile等类似的目录. 这些目录下都含有History,Cookie 等
+ (NSArray<NSString *> *)getBrowserDataPathArray {
    
    NSString *path = [self getUserHomeDirectory];
    NSString *chromeDataPath = [path stringByAppendingString:@"/Library/Application Support/Google/Chrome"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSMutableArray * dataPathArray = [[NSMutableArray alloc]init];
    
    // default目录(不一定存在) 即使不存在,也要生成数据(防止安装了 Chrome 浏览器但没有任何一条数据的情况)
    NSString *chromeDefaultPath = [self getChromeDataDefaultPath];
    if(chromeDataPath){
        [dataPathArray addObject:chromeDefaultPath];
    }

    
    // 找出所有的profile 目录, 然后判断目录下是否有 History 这个 DB.
    NSError *error = nil;    
    NSArray *properties = [NSArray arrayWithObjects: NSURLLocalizedNameKey, NSURLIsDirectoryKey,
                           NSURLCreationDateKey, NSURLLocalizedTypeDescriptionKey, nil];
    //  [NSURL URLWithString:]  string不合理的时候,有可能返回 nil
    NSURL *chromeDataUrl = [NSURL fileURLWithPath:chromeDataPath];
    if (!chromeDataUrl){
        return [dataPathArray copy];
    }
    NSArray *subDirArr = [[NSFileManager defaultManager]
                           contentsOfDirectoryAtURL:chromeDataUrl
                           includingPropertiesForKeys:properties
                           options:(NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants)
                           error:&error];
    for (NSURL *subDir in subDirArr) {
        NSNumber *isDirectory;
        [subDir getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        if ( ![isDirectory boolValue]) {
            continue;
        }
        if([[subDir relativeString] containsString:@"Profile"]){
            NSURL *tempHistoryURL = [subDir URLByAppendingPathComponent:@"History"];
            BOOL isDirectory;
            // 注意千万别使用 [url absoluteString] ,因为会带上 "file///" 这样的 string fileManager不能识别.
            if([fileManager fileExistsAtPath:[tempHistoryURL path] isDirectory:&isDirectory]){
                if(!isDirectory){
                    [dataPathArray addObject:[subDir path]];
                }
            }
        }
    }
    
    return [dataPathArray copy];
}

- (PRIVACY_APP_TYPE)getBrowserDefaultType {
    return PRIVACY_APP_CHROME;
}

- (FMDatabase *)getSavedPasswordDb {
    NSString *chromeSavePasswordDbPath = [[self getBrowserDefaultPath] stringByAppendingString:@"/Login Data"];

    NSLog(@"chrome password DbPath is %@", chromeSavePasswordDbPath);
    FMDatabase *historyDb = [FMDatabase databaseWithPath:chromeSavePasswordDbPath];
    if ([historyDb open]) {
        NSLog(@"chrome password db 打开成功");
        return historyDb;
    } else {
        return nil;
    }
}

- (PrivacyCategoryData *)getDownloadHistoryWithRunning:(BOOL)running {

    PrivacyCategoryData *downloadCategoryData = [[PrivacyCategoryData alloc] init];
    downloadCategoryData.categoryType = PRIVACY_CATEGORY_TYPE_DOWNLOAD_HISTORY;
    downloadCategoryData.categoryName = getCategoryNameByType(downloadCategoryData.categoryType);
    downloadCategoryData.tips = getCategoryDescByType(downloadCategoryData.categoryType);

    NSString *chromeHistoryDbPath = [[self getBrowserDefaultPath] stringByAppendingString:@"/History"];
    FMDatabase *historyDb = [self getReadableDBByPath:chromeHistoryDbPath running:running];

    if (historyDb) {
        NSLog(@"chrome history db finally path : %@", historyDb.databasePath);
        NSMutableArray *downloads = [[NSMutableArray alloc] init];
        FMResultSet *downloadHistoryResultSet = [historyDb executeQuery:@"SELECT target_path FROM downloads"];
        while ([downloadHistoryResultSet next]) {
            NSString *key = [downloadHistoryResultSet stringForColumn:@"target_path"];
            if (key) {
                PrivacyItemData *item = [[PrivacyItemData alloc] init];
                item.itemName = key;
                item.totalSubNum = 1;
                [downloads addObject:item];
            }
        }
        [historyDb close];
        downloadCategoryData.subItems = downloads;
    }
    return downloadCategoryData;
}

- (FMDatabase *)getDefaultHistoryDb {
    NSString *chromeHistoryDbPath = [[self getBrowserDefaultPath] stringByAppendingString:@"/History"];

    NSLog(@"chrome historyDbPath is %@", chromeHistoryDbPath);
    FMDatabase *historyDb = [FMDatabase databaseWithPath:chromeHistoryDbPath];
    if ([historyDb open]) {
        NSLog(@"download db 打开成功");
        return historyDb;
    } else {
        return nil;
    }
}

- (PrivacyCategoryData *)getCookiesWithRunning:(BOOL)running {

    PrivacyCategoryData *cookieCategoryData = [[PrivacyCategoryData alloc] init];
    cookieCategoryData.categoryType = PRIVACY_CATEGORY_TYPE_COOKIE;
    cookieCategoryData.categoryName = getCategoryNameByType(cookieCategoryData.categoryType);
    cookieCategoryData.tips = getCategoryDescByType(cookieCategoryData.categoryType);

    NSString *chromeCookieDbPath = [[self getBrowserDefaultPath] stringByAppendingString:@"/Cookies"];

    FMDatabase *cookieDb = [self getReadableDBByPath:chromeCookieDbPath running:running];

    if (cookieDb) {
        NSMutableArray *cookies = [[NSMutableArray alloc] init];
        FMResultSet *resultSet = [cookieDb executeQuery:@"SELECT host_key,count"
                                                        "(name) as count_name FROM cookies group by host_key"];
        while ([resultSet next]) {
            PrivacyItemData *item = [[PrivacyItemData alloc] init];
            item.itemName = [resultSet stringForColumn:@"host_key"];
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

    PrivacyCategoryData *browserHistoryCategoryData = [[PrivacyCategoryData alloc] init];
    browserHistoryCategoryData.categoryType = PRIVACY_CATEGORY_TYPE_BROWSER_HISTORY;
    browserHistoryCategoryData.categoryName = getCategoryNameByType(browserHistoryCategoryData.categoryType);
    browserHistoryCategoryData.tips = getCategoryDescByType(browserHistoryCategoryData.categoryType);

    NSString *chromeHistoryDbPath = [[self getBrowserDefaultPath] stringByAppendingString:@"/History"];

    FMDatabase *historyDb = [self getReadableDBByPath:chromeHistoryDbPath running:running];
    if (historyDb) {
        NSMutableArray *browser_history_array = [[NSMutableArray alloc] init];
        FMResultSet *historyResultSet = [historyDb executeQuery:@"SELECT urls.url as browser_url ,count(visits.url) as count_url FROM urls, visits WHERE urls.id==visits.url group by visits.url order by urls.last_visit_time desc"];
        while ([historyResultSet next]) {
            PrivacyItemData *item = [[PrivacyItemData alloc] init];
            item.itemName = [historyResultSet stringForColumn:@"browser_url"];
            item.totalSubNum = [historyResultSet intForColumn:@"count_url"];
            [browser_history_array addObject:item];
        }
        [historyDb close];

        browserHistoryCategoryData.subItems = browser_history_array;
    }

    return browserHistoryCategoryData;
}

- (PrivacyCategoryData *)getLocalStorageWithRunning:(BOOL)running {
    NSString *localDataPath = [[self getBrowserDefaultPath] stringByAppendingString:@"/Local Storage"];
    // 获取目录下的所有文件及文件夹(注意 directory 是指的 path,而不是结果时 directory.

    NSArray *array = [self getPrivacyItemArrayByPath:localDataPath fileLevel:3 scanApp:NO includeDir:NO];

    PrivacyCategoryData *categoryData = [[PrivacyCategoryData alloc] init];
    categoryData.categoryType = PRIVACY_CATEGORY_TYPE_LOCAL_STORAGE;
    categoryData.categoryName = getCategoryNameByType(categoryData.categoryType);
    categoryData.tips = getCategoryDescByType(categoryData.categoryType);
    categoryData.subItems = array;
    return categoryData;
}


- (PrivacyCategoryData *)getSessionStorageWithRunning:(BOOL)running {
    NSString *chromeDataPath = [self getBrowserDefaultPath];

    NSMutableArray *array = [[NSMutableArray alloc] init];
    PrivacyFileItemData *currentSession = [self getItemDataByPath:[chromeDataPath stringByAppendingString:@"/Current Session"]];
    PrivacyFileItemData *lastSession = [self getItemDataByPath:[chromeDataPath stringByAppendingString:@"/Last Session"]];
    PrivacyFileItemData *sessionStorage = [self getItemDataByPath:[chromeDataPath stringByAppendingString:@"/Session Storage"]];
    if (currentSession) {
        [array addObject:currentSession];
    }
    if (lastSession) {
        [array addObject:lastSession];
    }
    if (sessionStorage) {
        [array addObject:sessionStorage];
    }

    PrivacyCategoryData *categoryData = [[PrivacyCategoryData alloc] init];
    categoryData.categoryType = PRIVACY_CATEGORY_TYPE_SESSION;
    categoryData.categoryName = getCategoryNameByType(categoryData.categoryType);
    categoryData.tips = getCategoryDescByType(categoryData.categoryType);
    categoryData.subItems = array;
    return categoryData;
}


- (PrivacyCategoryData *)getSavedPasswordWithRunning:(BOOL)running {

    PrivacyCategoryData *categoryData = [[PrivacyCategoryData alloc] init];
    categoryData.categoryType = PRIVACY_CATEGORY_TYPE_SAVE_PASSWORD;
    categoryData.categoryName = getCategoryNameByType(categoryData.categoryType);
    categoryData.tips = getCategoryDescByType(categoryData.categoryType);

    NSString *chromeSavePasswordDbPath = [[self getBrowserDefaultPath] stringByAppendingString:@"/Login Data"];
    
//    NSArray *dataArray = [self getBrowserDataPathArray];

    FMDatabase *db = [self getReadableDBByPath:chromeSavePasswordDbPath running:running];
    if (!db) {
        return categoryData;
    }

    NSMutableArray *savedPasswords = [[NSMutableArray alloc] init];
    FMResultSet *savedPasswordResultSet = [db executeQuery:@"select origin_url from logins"];
    while ([savedPasswordResultSet next]) {
        NSString *key = [savedPasswordResultSet stringForColumn:@"origin_url"];
        if (key) {
            PrivacyItemData *item = [[PrivacyItemData alloc] init];
            item.itemName = key;
            item.totalSubNum = 1;
            [savedPasswords addObject:item];
        }
    }
    categoryData.subItems = savedPasswords;

    [db close];
    return categoryData;
}

- (BOOL)cleanSessions:(PrivacyCategoryData *)categoryData {
    if (!categoryData || categoryData.selectedSubItemNum == 0) {
        return YES;
    }

    if (debugFlag) {
        return YES;
    }

    BOOL success = [self cleanPrivacyFileArray:categoryData.subItems];
    return success;
}


// MARK 谨慎删除 localStorage 下面的文件. chrome 插件保存的数据 保存在这里!
- (BOOL)cleanLocalStorage:(PrivacyCategoryData *)categoryData {
    if (!categoryData || categoryData.selectedSubItemNum == 0) {
        return YES;
    }

    BOOL success = [self cleanPrivacyFileArray:categoryData.subItems];
    return success;
}

- (BOOL)cleanSavedPasswords:(PrivacyCategoryData *)categoryData {
    if (!categoryData || categoryData.selectedSubItemNum == 0) {
        return YES;
    }

    FMDatabase *db = [self getSavedPasswordDb];
    if (!db) {
        NSLog(@"chrome save password db open failed");
        return NO;
    }

    NSString *sqlString = @"delete from logins where origin_url = ?";
    BOOL flag = [self cleanDataBy:db executeSql:sqlString at:categoryData];
    return flag;

}


- (BOOL)cleanCookieData:(PrivacyCategoryData *)categoryData {

    if (!categoryData || categoryData.selectedSubItemNum == 0) {
        return YES;
    }

    NSString *chromeCookieDbPath = [[self getBrowserDefaultPath] stringByAppendingString:@"/Cookies"];
    NSLog(@"clean cookie path is %@", chromeCookieDbPath);
    FMDatabase *cookieDb = [FMDatabase databaseWithPath:chromeCookieDbPath];
    if (cookieDb && [cookieDb open]) {
        NSLog(@" cookie db 打开成功");
    } else {
        return FALSE;
    }

    NSString *sqlString = @"delete from cookies where host_key = ?";
    [self cleanDataBy:cookieDb executeSql:sqlString at:categoryData];

    return YES;
}

- (BOOL)cleanDownloadHistory:(PrivacyCategoryData *)categoryData {
    if (!categoryData || categoryData.selectedSubItemNum == 0) {
        return YES;
    }

    FMDatabase *historyDb = [self getDefaultHistoryDb];
    if (!historyDb) {
        return FALSE;
    }

    NSString *sqlString = @"delete from downloads where target_path = ?";
    BOOL flag = [self cleanDataBy:historyDb executeSql:sqlString at:categoryData];
    return flag;
}

- (BOOL)cleanBrowserHistory:(PrivacyCategoryData *)categoryData {
    if (!categoryData || categoryData.selectedSubItemNum == 0) {
        return YES;
    }


    FMDatabase *historyDb = [self getDefaultHistoryDb];
    if (!historyDb) {
        return FALSE;
    }

//    SELECT urls.url as browser_url ,count(visits.url) as count_url FROM urls, visits WHERE urls.id==visits.url group by visits.url order by urls.last_visit_time desc

//    delete from visits where visits.id in (
//                                           select v.id from visits v
//                                           inner join urls u
//                                           on(u.id==v.url)
//                                           where u.url='chrome-extension://chphlpgkkbolifaimnlloiipkdnihall/onetab.html');
    NSString *sqlString = @"delete from visits where visits.id in ( select v.id from visits v inner join urls u on(u.id==v.url) where u.url = ? )";
    BOOL flag = [self cleanDataBy:historyDb executeSql:sqlString at:categoryData];
    return flag;
}


+(NSString *) tryGetAccountNameByPath:(NSString*)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *preferencePath = [path stringByAppendingPathComponent:@"Preferences"];
    BOOL isExist = [fileManager fileExistsAtPath:preferencePath];
    if(isExist){
        NSData *preferenceData = [NSData dataWithContentsOfFile:preferencePath];
        if(preferenceData){
            
            NSError *error = nil;
            id object = [NSJSONSerialization
                         JSONObjectWithData:preferenceData
                         options:0
                         error:&error];
            
            if(error) {
                NSLog(@"%s decode json error :%@", __FUNCTION__, error);
                return nil;
            }

            if([object isKindOfClass:[NSDictionary class]]){
                id profile = object[@"profile"];
                
                if([profile isKindOfClass:[NSDictionary class]]){
                    id name = profile[@"name"];
                    
                    if([name isKindOfClass:[NSString class]]){
                        return name;
                    }
                }
            }
        }
    }
    
    return nil;
}

@end
