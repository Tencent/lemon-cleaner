//
//  SafariPrivacyDataManager.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "SafariPrivacyDataManager.h"
#import <FMDB/FMDB.h>
#import <QMCoreFunction/QMFullDiskAccessManager.h>

@implementation SafariPrivacyDataManager


+(SafariPrivacyDataManager *)sharedManager{
    static SafariPrivacyDataManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SafariPrivacyDataManager alloc] init];
    });
    
    return manager;
}

- (NSString *)getBrowserDefaultPath {
    NSString *path = [self getUserHomeDirectory];
    NSString *chromeHistoryDefaultPath = [path stringByAppendingString:@"/Library/Safari"];
    return chromeHistoryDefaultPath;
}

- (PRIVACY_APP_TYPE)getBrowserDefaultType {
    return PRIVACY_APP_SAFARI;
}

- (BOOL)isHasDataAccessPrivilege {
    // 在10.14的机器上发现 文件所有者为 Tencent/Domain(网络账户服务器),而本机用户为v_rhtan,没有权限删除此文件,故过滤.
    // 对于Mac OS X 10.11 El Capitan用户，由于系统启用了SIP(System Integrity Protection), 导致root用户也没有权限修改/usr/bin目录。
    // 10.14 上 sip 扩展(扩展到了部分系统应用): The system directories that are protected and locked down by SIP in macOS include: /System/, /usr/ with the exception of /usr/local/, /sbin/, /bin/, and /Applications/ for apps that are preinstalled by default in macOS and necessary for the usage of the operating system including apps like Safari, Terminal, Console, Activity Monitor, Calendar, etc.
    // 更新 10.14有一个 full disk Access 权限,给予权限后即可扫描.
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    if(version.majorVersion == 10 && version.minorVersion >= 14 && [QMFullDiskAccessManager getFullDiskAuthorationStatus] == QMFullDiskAuthorationStatusAuthorized){
        return YES;
    }else{
        return NO;
    }
}

- (FMDatabase *)getDefaultCookieDb {
    NSString *homePath = [self getUserHomeDirectory];
    NSString *safariHistoryDbPath = [homePath stringByAppendingString:@"/Library/Safari/History.db"];
    NSLog(@"safariHistoryDbPath is %@", safariHistoryDbPath);
    FMDatabase *historyDb = [FMDatabase databaseWithPath:safariHistoryDbPath];
    if (historyDb && [historyDb open]) {
        NSLog(@"safari history db 打开成功");
        return historyDb;
    }
    return nil;
}

- (PrivacyCategoryData *)getHistoryWithRunning:(BOOL)running {
    NSString *homePath = [self getUserHomeDirectory];
    NSString *historyDbPath = [homePath stringByAppendingString:@"/Library/Safari/History.db"];

    PrivacyCategoryData *historyCategoryData = [[PrivacyCategoryData alloc] init];
    historyCategoryData.categoryType = PRIVACY_CATEGORY_TYPE_BROWSER_HISTORY;
    historyCategoryData.categoryName = getCategoryNameByType(historyCategoryData.categoryType);
    historyCategoryData.tips = getCategoryDescByType(historyCategoryData.categoryType);
    FMDatabase *historyDb = [self getReadableDBByPath:historyDbPath running:running];

    if (historyDb) {
        NSLog(@"safari read HistoryDbPath is %@", historyDb.databasePath);
        NSMutableArray *cookies = [[NSMutableArray alloc] init];
        FMResultSet *resultSet = [historyDb executeQuery:@"select history_items.url as browser_url ,count(history_visits.history_item) as count_url from history_items,history_visits where history_visits.history_item==history_items.id  group by history_visits.history_item  order by visit_time desc"];
        while ([resultSet next]) {
            PrivacyItemData *item = [[PrivacyItemData alloc] init];
            item.itemName = [resultSet stringForColumn:@"browser_url"];
            int valueNumber = [resultSet intForColumn:@"count_url"];
            item.totalSubNum = (NSInteger) valueNumber;
            [cookies addObject:item];
        }

        historyCategoryData.subItems = cookies;
        [historyDb close];
    } else {
        NSLog(@"history db open failed");
    }
    return historyCategoryData;
}


- (PrivacyCategoryData *)getLocalStorageWithRunning:(BOOL)running {

    PrivacyCategoryData *categoryData = [[PrivacyCategoryData alloc] init];
    categoryData.categoryType = PRIVACY_CATEGORY_TYPE_LOCAL_STORAGE;
    categoryData.categoryName = getCategoryNameByType(categoryData.categoryType);
    categoryData.tips = getCategoryDescByType(categoryData.categoryType);

    NSString *homePath = [self getUserHomeDirectory];
    NSString *localStoragePath = [homePath stringByAppendingString:@"/Library/Safari/LocalStorage"];
    NSArray *array = [self getPrivacyItemArrayByPath:localStoragePath fileLevel:2 scanApp:NO includeDir:NO];
    categoryData.subItems = array;
    return categoryData;
}

- (PrivacyCategoryData *)getAutofillFormWithRunning:(BOOL)running {

    if(![self isHasDataAccessPrivilege]){
        return nil;
    }

    PrivacyCategoryData *categoryData = [[PrivacyCategoryData alloc] init];
    categoryData.categoryType = PRIVACY_CATEGORY_TYPE_AUTOFILL;
    categoryData.categoryName = getCategoryNameByType(categoryData.categoryType);
    categoryData.tips = getCategoryDescByType(categoryData.categoryType);

    NSString *homePath = [self getUserHomeDirectory];
    NSString *formValuePath = [homePath stringByAppendingString:@"/Library/Safari/Form Values"];
    PrivacyFileItemData *formValueData = [self getItemDataByPath:formValuePath];

    NSMutableArray *array = [[NSMutableArray alloc] init];
    if (formValueData) {
        [array addObject:formValueData];
    }
    categoryData.subItems = array;
    return categoryData;
}

- (PrivacyCategoryData *)getSessionStorageWithRunning:(BOOL)running {
    
    // fix 10.14 上 LastSession.plist 文件无法删除的问题. 在10.14以后的机器上不展示 Safari 的 session
    if(![self isHasDataAccessPrivilege]){
        return nil;
    }
    
    PrivacyCategoryData *categoryData = [[PrivacyCategoryData alloc] init];
    categoryData.categoryType = PRIVACY_CATEGORY_TYPE_SESSION;
    categoryData.categoryName = getCategoryNameByType(categoryData.categoryType);
    categoryData.tips = getCategoryDescByType(categoryData.categoryType);

    NSString *homePath = [self getUserHomeDirectory];
    NSString *safariPath = [homePath stringByAppendingString:@"/Library/Safari/"];
    NSString *lastSessionPath = [safariPath stringByAppendingString:@"LastSession.plist"];
    PrivacyFileItemData *lastSessionData = [self getItemDataByPath:lastSessionPath];


    NSMutableArray *array = [[NSMutableArray alloc] init];
    if (lastSessionData) {
        [array addObject:lastSessionData];
    }

    categoryData.subItems = array;
    return categoryData;
}


// MARK : safari 浏览器 会定时清理下载纪录. safari 偏好设置中 ->通用 -> 移除下载列表项 可以选择移除的时机.
- (PrivacyCategoryData *)getDownloadHistoryWithRunning:(BOOL)running {

    NSMutableArray *subItems = [[NSMutableArray alloc] init];

    NSString *homePath = [self getUserHomeDirectory];
    NSString *downloadHistoryPath = [homePath stringByAppendingString:@"/Library/Safari/Downloads.plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isExist = [fileManager fileExistsAtPath:downloadHistoryPath];
    if (isExist) {
        NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:downloadHistoryPath];
        if (dictionary) {
            NSArray *array = dictionary[@"DownloadHistory"];
            if (array) {
                for (id item in array) {
                    if (![item isKindOfClass:NSDictionary.class]) {
                        continue;
                    }

                    NSDictionary *downloadItem = item;
                    NSString *downloadEntryPath = downloadItem[@"DownloadEntryPath"];
                    NSString *downloadEntryURL = downloadItem[@"DownloadEntryURL"];

                    if (!downloadEntryPath || [downloadEntryPath isEqualToString:@""] ||
                            !downloadEntryURL || [downloadEntryURL isEqualToString:@""]) {
                        continue;
                    }

                    PrivacyPlistItemData *plistItemData = [[PrivacyPlistItemData alloc] init];
                    plistItemData.itemName = downloadEntryPath;
                    plistItemData.path = downloadEntryURL;
                    plistItemData.totalSubNum = 1;

                    [subItems addObject:plistItemData];
                }
            }
        }

    }

    PrivacyCategoryData *categoryData = [[PrivacyCategoryData alloc] init];
    categoryData.categoryType = PRIVACY_CATEGORY_TYPE_DOWNLOAD_HISTORY;
    categoryData.categoryName = getCategoryNameByType(categoryData.categoryType);
    categoryData.tips = getCategoryDescByType(categoryData.categoryType);
    categoryData.subItems = subItems;
    return categoryData;
}


// 二进制文件, 可以按照 格式读取详细数据.
- (PrivacyCategoryData *)getCookiesWithRunning:(BOOL)running {
    PrivacyCategoryData *cookieCategoryData = [[PrivacyCategoryData alloc] init];
    cookieCategoryData.categoryType = PRIVACY_CATEGORY_TYPE_COOKIE;
    cookieCategoryData.categoryName = getCategoryNameByType(cookieCategoryData.categoryType);
    cookieCategoryData.tips = getCategoryDescByType(cookieCategoryData.categoryType);


//   简单的  使用 ~/Library/Cookies/Cookies.binaryCookies 文件作为 item 项
//    NSString *homePath = [PrivacyDataManager getUserHomeDirectory];
//    NSString *cookiePath = [homePath stringByAppendingString:@"/Library/Cookies/Cookies.binarycookies"];
//    PrivacyFileItemData *fileItemData = [PrivacyDataManager getItemDataByPath:cookiePath];
//    NSMutableArray *array = [[NSMutableArray alloc] init];
//    if (fileItemData) {
//        [array addObject:fileItemData];
//    }


//    使用 解析二进制文件的方式 解析 cookie.
//    NSData *cookieData = [NSData dataWithContentsOfFile:cookiePath];
//    NSArray *cookieArray = [BinaryCookiesParser parseWithData:cookieData];


    NSArray *cookieItems = [self getCookieItems];
    cookieCategoryData.subItems = cookieItems;
    return cookieCategoryData;
}

// 对于 沙盒应用,NSHTTPCookieStorage 应该就无效了, 这时候需要使用 BinaryCookiesParser 解析的方法
- (NSArray *)getCookieItems {
    NSArray<NSHTTPCookie *> *cookies;
    if (@available(macOS 10.11, *)) {
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:@"Cookies"];
         cookies = [cookieStorage cookies];
    } else {
         cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    }

    NSMutableDictionary *cookieDict = [[NSMutableDictionary alloc] init];

    for (NSHTTPCookie *entry in cookies) {
        NSString *domain = entry.domain;
        if (!domain) {
            continue;
        }
        PrivacyItemData *itemData = cookieDict[domain];
        if (itemData) {
            itemData.totalSubNum += 1;
        } else {
            itemData = [[PrivacyItemData alloc] init];
            itemData.itemName = domain;
            itemData.totalSubNum = 1;
            cookieDict[domain] = itemData;
        }
    }
    return [cookieDict allValues];
}


- (BOOL)cleanSessions:(PrivacyCategoryData *)categoryData {
    if (!categoryData || categoryData.selectedSubItemNum == 0) {
        return YES;
    }

    BOOL flag = [self cleanPrivacyFileArray:categoryData.subItems];
    return flag;
}

- (BOOL)cleanLocalStorage:(PrivacyCategoryData *)categoryData {
    if (!categoryData || categoryData.selectedSubItemNum == 0) {
        return YES;
    }

    BOOL flag = [self cleanPrivacyFileArray:categoryData.subItems];
    return flag;
}

- (BOOL)cleanAutoFillForm:(PrivacyCategoryData *)categoryData {
    if (!categoryData || categoryData.selectedSubItemNum == 0) {
        return YES;
    }

    BOOL flag = [self cleanPrivacyFileArray:categoryData.subItems];
    return flag;
}

- (BOOL)cleanDownloadHistory:(PrivacyCategoryData *)categoryData {
    if (!categoryData || categoryData.selectedSubItemNum == 0) {
        return YES;
    }

    NSString *homePath = [self getUserHomeDirectory];
    NSString *downloadHistoryPath = [homePath stringByAppendingString:@"/Library/Safari/Downloads.plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isExist = [fileManager fileExistsAtPath:downloadHistoryPath];
    BOOL isModifyData = NO;
    BOOL isModifyFile = NO;
    NSInteger modifyNum = 0;
    if (isExist) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:downloadHistoryPath];
        if (dictionary) {
            NSMutableArray *historyArray = dictionary[@"DownloadHistory"];
            if (historyArray) {

                for (PrivacyPlistItemData *downloadItem in categoryData.subItems) {

                    for (id item in historyArray) {

                        if (debugFlag && modifyNum >= 1) {
                            break;
                        }

                        if (![item isKindOfClass:NSDictionary.class]) {
                            continue;
                        }

                        NSDictionary *downloadDict = item;
                        NSString *downloadEntryPath = downloadDict[@"DownloadEntryPath"];
                        NSString *downloadEntryURL = downloadDict[@"DownloadEntryURL"];

                        if (!downloadEntryPath || [downloadEntryPath isEqualToString:@""] || !downloadEntryURL || [downloadEntryURL isEqualToString:@""]) {
                            continue;
                        }

                        if ([downloadEntryPath isEqualToString:downloadItem.itemName] && [downloadEntryURL isEqualToString:downloadItem.path]) {
                            [historyArray removeObject:downloadDict];
                            isModifyData = YES;
                            modifyNum++;
                            break;
                        }
                    }
                }

            }
        }

        if (isModifyData) {
            isModifyFile = [dictionary writeToFile:downloadHistoryPath atomically:YES];
        }

    }

    return isModifyFile;
}

- (BOOL)cleanCookieData:(PrivacyCategoryData *)categoryData {
    if (!categoryData || categoryData.selectedSubItemNum == 0) {
        return YES;
    }

    NSInteger deleteNum = 0;
    for (PrivacyItemData *itemData in categoryData.subItems) {
        if (itemData.state != NSControlStateValueOn) {
            continue;
        }

        NSHTTPCookieStorage *cookieStorage;
        if (@available(macOS 10.11, *)) {
            cookieStorage = [NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:@"Cookies"];
        } else {
            cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        }

        NSArray *cookies  = [cookieStorage cookies];
        for (NSHTTPCookie *cookie in cookies) {

            if (debugFlag && deleteNum > 0) {
                break;
            }
            if ([cookie.domain isEqualToString:itemData.itemName]) {
                [cookieStorage deleteCookie:cookie];
                deleteNum++;
            }
        }
    }

    return deleteNum > 0;
}


//NSString *homePath = [PrivacyDataManager getUserHomeDirectory];
//NSString *defaultDbPath = [homePath stringByAppendingString:@"/Library/Safari/History.db"];

// 如果应用正在运行,则拷贝 db 后再读取数据.


- (BOOL)cleanBrowserHistory:(PrivacyCategoryData *)categoryData {

    if (!categoryData || categoryData.selectedSubItemNum == 0) {
        return YES;
    }

    FMDatabase *historyDb = [self getDefaultCookieDb];
    if (!historyDb) {
        return false;
    }

    // 这里需不需要删除两个表中的数据
    //    delete  from history_visits where history_visits.history_item  in (
    //            select v.history_item from history_visits v
    //    inner join history_items u
    //    on(u.id==v.history_item)
    //    where u.url='http://bbs.ngacn.cc/'
    //    ); delete from history_items where history_items.url="http://bbs.ngacn.cc/"

    NSString *sqlString = @"delete  from history_visits where history_visits.history_item  in (\n"
                          "select v.history_item from history_visits v\n"
                          "inner join history_items u\n"
                          "on(u.id==v.history_item)\n"
                          "where u.url=?\n"
                          "); ";
    BOOL flag = [self cleanDataBy:historyDb executeSql:sqlString at:categoryData];
    return flag;
}
@end
