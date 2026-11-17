//
//  BasePrivacyDataManager.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2018 tencent. All rights reserved.
//

#import "BaseBrowserPrivacyDataManager.h"
#import <QMCoreFunction/McCoreFunction.h>
#import <sys/stat.h>
#import <errno.h>

static BOOL LMPrivacyIsSystemPathAlias(NSString *prefix) {
    return [prefix isEqualToString:@"/tmp"] ||
           [prefix isEqualToString:@"/var"] ||
           [prefix isEqualToString:@"/etc"];
}

static BOOL LMPrivacyPathHasUnsafeSymlink(NSString *path) {
    if (path.length == 0) {
        return YES;
    }
    NSString *standardized = [path stringByStandardizingPath];
    if (standardized.length == 0 || ![standardized hasPrefix:@"/"] || [standardized isEqualToString:@"/"]) {
        return YES;
    }

    NSArray<NSString *> *parts = [standardized pathComponents];
    NSMutableString *prefix = [NSMutableString string];
    for (NSString *part in parts) {
        if ([part isEqualToString:@"/"]) {
            [prefix setString:@"/"];
            continue;
        }
        if ([prefix isEqualToString:@"/"]) {
            [prefix appendString:part];
        } else {
            [prefix appendFormat:@"/%@", part];
        }

        struct stat st;
        if (lstat([prefix fileSystemRepresentation], &st) != 0) {
            // 路径不存在时提前返回「没有不安全 symlink」是安全的：
            // 后续枚举 / 删除会拦；这里不能当成 symlink 拒绝，否则正常已删目标会被误报。
            if (errno == ENOENT || errno == ENOTDIR) {
                return NO;
            }
            NSLog(@"[security] privacy lstat failed for %@ errno=%d", prefix, errno);
            return YES;
        }
        if (S_ISLNK(st.st_mode) && !LMPrivacyIsSystemPathAlias(prefix)) {
            NSLog(@"[security] privacy reject symlink component: %@", prefix);
            return YES;
        }
    }
    return NO;
}

static NSString *LMPrivacyContainmentKey(NSString *path) {
    if (path.length == 0) {
        return nil;
    }
    NSString *s = [path stringByStandardizingPath];
    if (s.length == 0 || ![s hasPrefix:@"/"]) {
        return nil;
    }
    if ([s isEqualToString:@"/tmp"] || [s hasPrefix:@"/tmp/"]) {
        s = [@"/private" stringByAppendingString:s];
    } else if ([s isEqualToString:@"/var"] || [s hasPrefix:@"/var/"]) {
        s = [@"/private" stringByAppendingString:s];
    } else if ([s isEqualToString:@"/etc"] || [s hasPrefix:@"/etc/"]) {
        s = [@"/private" stringByAppendingString:s];
    }
    if (s.length > 1 && [s hasSuffix:@"/"]) {
        s = [s substringToIndex:s.length - 1];
    }
    return s;
}

static BOOL LMPrivacyPathKeyStaysUnderVenueKey(NSString *pathKey, NSString *venueKey) {
    if (pathKey.length == 0 || venueKey.length == 0) {
        return NO;
    }
    if ([pathKey isEqualToString:venueKey]) {
        return YES;
    }
    return [pathKey hasPrefix:[venueKey stringByAppendingString:@"/"]];
}

/// 仅在 walk 已通过后使用：不再 resolve，避免每个子项再走一遍逐级 lstat
static BOOL LMPrivacyPathStaysUnderVenue(NSString *path, NSString *venue) {
    return LMPrivacyPathKeyStaysUnderVenueKey(LMPrivacyContainmentKey(path), LMPrivacyContainmentKey(venue));
}

@implementation BaseBrowserPrivacyDataManager

- (NSString *)getBrowserDefaultPath{
    @throw [NSException exceptionWithName:@"method not implementation"
                                   reason:@"sub class need rewrite this method "
                                 userInfo:nil];
}

- (PrivacyAppData *)getBrowserDataWithManager:(PrivacyDataManager *)manager running:(BOOL)isRunning processRate:(double)processRate processStart:(double)startValue {
    double categoryNum = 7.0;
    double itemProcess = (1.0 / categoryNum) * processRate;
    double startProcessValue = startValue;

    PRIVACY_APP_TYPE appType = [self getBrowserDefaultType];
    NSString *appName = getAppNameByType(appType);

    PrivacyCategoryData *cookieCategoryData = [self getCookiesWithRunning:isRunning];
    if (manager.delegate) {
        NSString *progressText = [appName stringByAppendingString:@"/Cookie"];
        [manager.delegate scanProcess:startProcessValue + itemProcess text:progressText];
    }
    startProcessValue += itemProcess;


//    PrivacyCategoryData *downloadCategoryData = [self getHistoryWithRunning:isRunning];
    PrivacyCategoryData *downloadCategoryData = [self getDownloadHistoryWithRunning:isRunning];
    if (manager.delegate) {
        NSString *progressText = [appName stringByAppendingString:@"/Download History"];
        [manager.delegate scanProcess:startProcessValue + itemProcess text:progressText];
    }
    startProcessValue += itemProcess;


    PrivacyCategoryData *browserHistoryCategoryData = [self getHistoryWithRunning:isRunning];
    if (manager.delegate) {
        NSString *progressText = [appName stringByAppendingString:@"/Browser History"];
        [manager.delegate scanProcess:startProcessValue + itemProcess text:progressText];
    }
    startProcessValue += itemProcess;

    PrivacyCategoryData *savedPasswordsCategory = [self getSavedPasswordWithRunning:isRunning];
    if (manager.delegate) {
        NSString *progressText = [appName stringByAppendingString:@"/Saved Passwords"];
        [manager.delegate scanProcess:startProcessValue + itemProcess text:progressText];
    }
    startProcessValue += itemProcess;


    PrivacyCategoryData *localStorageCategory = [self getLocalStorageWithRunning:isRunning];
    if (manager.delegate) {
        NSString *progressText = [appName stringByAppendingString:@"/Local Storage"];
        [manager.delegate scanProcess:startProcessValue + itemProcess text:progressText];
    }
    startProcessValue += itemProcess;


    PrivacyCategoryData *sessionCategory = [self getSessionStorageWithRunning:isRunning];
    if (manager.delegate) {
        NSString *progressText = [appName stringByAppendingString:@"/Session"];
        [manager.delegate scanProcess:startProcessValue + itemProcess text:progressText];
    }
    startProcessValue += itemProcess;

    PrivacyCategoryData *autofillCategory = [self getAutofillFormWithRunning:isRunning];
    if (manager.delegate) {
        NSString *progressText = [appName stringByAppendingString:@"/Autofill Form"];
        [manager.delegate scanProcess:startProcessValue + itemProcess text:progressText];
    }
//    startProcessValue += itemProcess;


    PrivacyAppData *appData = [[PrivacyAppData alloc] init];
    appData.appType = appType;
    appData.appName = appName;
    appData.dataPath = [self getBrowserDefaultPath];
    
    NSMutableArray *categories = [[NSMutableArray alloc] init];
    if (cookieCategoryData) {
        [categories addObject:cookieCategoryData];
    }
    if (browserHistoryCategoryData) {
        [categories addObject:browserHistoryCategoryData];
    }
    if (downloadCategoryData) {
        [categories addObject:downloadCategoryData];
    }
    if (savedPasswordsCategory) {
        [categories addObject:savedPasswordsCategory];
    }
    if (localStorageCategory) {
        [categories addObject:localStorageCategory];
    }
    if (sessionCategory) {
        [categories addObject:sessionCategory];
    }
    if (autofillCategory) {
        [categories addObject:autofillCategory];
    }

    appData.subItems = categories;
    return appData;
}


- (BOOL)cleanBrowserDataWithManger:(PrivacyDataManager *)manager data:(PrivacyAppData *)appData processRate:(double)processRate processStart:(double)startValue {

    if (!appData || appData.selectedSubItemNum == 0) {
        return YES;
    }
    if (appData.appType != [self getBrowserDefaultType]) {
        NSLog(@"not  app ,can't process clean");
        return NO;
    }

    double processStart = startValue;
    double categoryNum = appData.subItems.count;
    double itemProcess = processRate * 1.0 / categoryNum;
    BOOL returnSuccess = YES;
    
    PRIVACY_APP_TYPE appType = [self getBrowserDefaultType];
    NSString *appName = getAppNameByType(appType);
    NSString *progressText;

    for (PrivacyCategoryData *categoryItem in appData.subItems) {
        switch (categoryItem.categoryType) {
            case PRIVACY_CATEGORY_TYPE_COOKIE:
                progressText = [appName stringByAppendingString:@"/Cookie"];
                returnSuccess &= [self cleanCookieData:categoryItem];
                break;

            case PRIVACY_CATEGORY_TYPE_BROWSER_HISTORY:
                progressText = [appName stringByAppendingString:@"/Browser History"];
                returnSuccess &= [self cleanBrowserHistory:categoryItem];
                break;

            case PRIVACY_CATEGORY_TYPE_DOWNLOAD_HISTORY:
                progressText = [appName stringByAppendingString:@"/Download History"];
                returnSuccess &= [self cleanDownloadHistory:categoryItem];
                break;

            case PRIVACY_CATEGORY_TYPE_SAVE_PASSWORD:
                progressText = [appName stringByAppendingString:@"/Saved Passwords"];
                returnSuccess &= [self cleanSavedPasswords:categoryItem];
                break;

            case PRIVACY_CATEGORY_TYPE_SESSION:
                progressText = [appName stringByAppendingString:@"/Session"];
                returnSuccess &= [self cleanSessions:categoryItem];
                break;

            case PRIVACY_CATEGORY_TYPE_LOCAL_STORAGE:
                progressText = [appName stringByAppendingString:@"/Local Storage"];
                returnSuccess &= [self cleanLocalStorage:categoryItem];
                break;
            case PRIVACY_CATEGORY_TYPE_AUTOFILL:
                progressText = [appName stringByAppendingString:@"/Autofill Form"];
                returnSuccess &= [self cleanAutoFillForm:categoryItem];
                break;
            default:
                progressText = nil;
                NSLog(@"%@ can't clean this category type : %lu", appName, (unsigned long) categoryItem.categoryType);
                break;
        }

        processStart += itemProcess;
        if (manager.delegate) {
            [manager.delegate scanProcess:itemProcess + processStart text:progressText];
        }
    }
    return returnSuccess;
}


- (PRIVACY_APP_TYPE)getBrowserDefaultType {
    @throw [NSException exceptionWithName:@"need implement" reason:@"method getBrowserDefaultType need implement at sub class" userInfo:nil];
}


- (PrivacyCategoryData *)getCookiesWithRunning:(BOOL)running {
    return nil;
}

- (PrivacyCategoryData *)getAutofillFormWithRunning:(BOOL)running {
    return nil;
}

- (PrivacyCategoryData *)getDownloadHistoryWithRunning:(BOOL)running {
    return nil;
}

- (PrivacyCategoryData *)getSessionStorageWithRunning:(BOOL)running {
    return nil;
}

- (PrivacyCategoryData *)getSavedPasswordWithRunning:(BOOL)running {
    return nil;
}

- (PrivacyCategoryData *)getHistoryWithRunning:(BOOL)running {
    return nil;
}

- (PrivacyCategoryData *)getLocalStorageWithRunning:(BOOL)running {
    return nil;
}


- (BOOL)cleanCookieData:(PrivacyCategoryData *)categoryData {
    return YES;
}

- (BOOL)cleanBrowserHistory:(PrivacyCategoryData *)categoryData {
    return YES;
}

- (BOOL)cleanDownloadHistory:(PrivacyCategoryData *)categoryData {
    return YES;
}

- (BOOL)cleanSavedPasswords:(PrivacyCategoryData *)categoryData {
    return YES;
}

- (BOOL)cleanSessions:(PrivacyCategoryData *)categoryData {
    return YES;
}

- (BOOL)cleanLocalStorage:(PrivacyCategoryData *)categoryData {
    return YES;
}

- (BOOL)cleanAutoFillForm:(PrivacyCategoryData *)categoryData {
    return YES;
}


- (BOOL)cleanDataBy:(FMDatabase *)db executeSql:(NSString *)sqlString at:(PrivacyCategoryData *)categoryData {
    NSInteger executeNum = 0;
    NSInteger cleanNum = 0;
    
    [db beginTransaction];
    for (PrivacyItemData *item in categoryData.subItems) {
        
        if (debugFlag && executeNum >= 1) {
            break;
        }
        
        if (item.state != NSOnState) {
            break;
        }
        
        BOOL success = [db executeUpdate:sqlString, item.itemName];
        if (!success) {
            NSLog(@"Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        } else {
            //            NSLog(@"clean chrome cookie %@ ", item.itemName); // item 可能为 nil? itemName可能为 nil?
            cleanNum += item.totalSubNum;
        }
        
        
        executeNum += 1;
    }
    
    [db commit];
    [db close];
    NSLog(@"clean success %ld items", cleanNum);
    return YES;
}


// level : 文件系统递归的深度, -1递归到最后一层
- (NSArray *)getPrivacyItemArrayByPath:(NSString *)path fileLevel:(NSInteger)level scanApp:(BOOL)scanApp includeDir:(BOOL)includeDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (path.length == 0 || LMPrivacyPathHasUnsafeSymlink(path)) {
        NSLog(@"[security] privacy skip enum root: %@", path);
        return @[];
    }
    NSString *venueKey = LMPrivacyContainmentKey(path);

    NSURL *url = [NSURL fileURLWithPath:path];
    if(!url){
        return nil;
    }
    NSDirectoryEnumerationOptions directoryEnum = 0;
    if (scanApp) directoryEnum = NSDirectoryEnumerationSkipsPackageDescendants;
    NSArray *propertiesKey = @[NSURLIsAliasFileKey];
    NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtURL:url includingPropertiesForKeys:propertiesKey options:directoryEnum errorHandler:nil];
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NSURL *pathURL in directoryEnumerator) {
        NSNumber *flag = nil;
        [pathURL getResourceValue:&flag forKey:NSURLIsAliasFileKey error:nil];
        if (flag && [flag boolValue]) {
            continue;
        }
        if (level != -1 && [directoryEnumerator level] == level) {
            [directoryEnumerator skipDescendants];
        }

        NSString *itemPath = pathURL.path;
        if (LMPrivacyPathHasUnsafeSymlink(itemPath) ||
            !LMPrivacyPathKeyStaysUnderVenueKey(LMPrivacyContainmentKey(itemPath), venueKey)) {
            continue;
        }
        
        NSNumber *isDirectory;
        [pathURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        
        // 只有可以删除的 在显示在 LocalStorage 中.
        BOOL isDeletable = [fileManager isDeletableFileAtPath:itemPath];
        
        if (isDirectory == nil || ([isDirectory boolValue] && !includeDirectory && !isDeletable)) {
            continue;
        } else {
            PrivacyFileItemData *itemData = [[PrivacyFileItemData alloc] init];
            itemData.isDirectory = [isDirectory boolValue];
            itemData.itemName = [self getFileNameByPath:itemPath];
            itemData.path = itemPath;
            itemData.totalSubNum = 1;
            [array addObject:itemData];
        }
    }
    
    return array;
}

- (BOOL)cleanPrivacyFileArray:(NSArray *)array {
    if (!array) {
        return YES;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSInteger successNum = 0;
    NSInteger needDealNum = 0;
    NSString *venueKey = LMPrivacyContainmentKey([self getBrowserDefaultPath]);
    
    for (PrivacyFileItemData *fileItemData in array) {
        if (debugFlag && successNum >= 1) {
            continue;
        }
        
        if (!fileItemData || !fileItemData.path || fileItemData.state != NSControlStateValueOn) {
            continue;
        }
        
        needDealNum += 1;
        NSString *itemPath = fileItemData.path;
        if (LMPrivacyPathHasUnsafeSymlink(itemPath) ||
            !LMPrivacyPathKeyStaysUnderVenueKey(LMPrivacyContainmentKey(itemPath), venueKey)) {
            NSLog(@"[security] privacy skip clean outside venue: %@", itemPath);
            continue;
        }
        // 浏览器的 local storage 可能无法删除 (权限是-rw-------@)
        // 低权失败不能单独构成 root 代删的充分条件：路径必须仍在本次浏览器数据目录内
        BOOL isDeletable = [fileManager isDeletableFileAtPath:itemPath];
        if (isDeletable) {
            NSError *error;
            BOOL success = [fileManager removeItemAtPath:itemPath error:&error];
            if (!success) {
                NSLog(@"Error removing file at path: %@, error is %@", itemPath, error ? error.localizedDescription : @"nil");
            } else {
                successNum += 1;
            }
        } else {
            BOOL success = [[McCoreFunction shareCoreFuction] cleanItemAtPath:nil array:@[itemPath] removeType:McCleanRemoveRoot];
            if (!success) {
                NSLog(@"Error removing file by McCoreFunction#cleanItemAtPath at path: %@", itemPath);
            } else {
                successNum += 1;
            }
        }
    }
    
    return successNum == needDealNum;
}


- (PrivacyFileItemData *)getItemDataByPath:(NSString *)path {
    if (path.length == 0 || LMPrivacyPathHasUnsafeSymlink(path) ||
        !LMPrivacyPathStaysUnderVenue(path, [self getBrowserDefaultPath])) {
        return nil;
    }
    struct stat st;
    if (lstat([path fileSystemRepresentation], &st) != 0) {
        return nil;
    }
    PrivacyFileItemData *itemData = [[PrivacyFileItemData alloc] init];
    itemData.totalSubNum = 1;
    itemData.itemName = [self getFileNameByPath:path];
    itemData.path = path;
    itemData.isDirectory = S_ISDIR(st.st_mode);
    return itemData;
}

- (FMDatabase *)getReadableDBByPath:(NSString *)defaultDbPath running:(BOOL)running {
    
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL defaultDbExistFlag = [fileManager fileExistsAtPath:defaultDbPath];
    if (!defaultDbExistFlag) {
        return nil;
    }
    
    //stringByAppendingPathExtension 是加后缀的意思(会自动添加.)
    //stringByAppendingPathComponent 是添加/号，使之变成一个完整的路径
    NSString *folderPath = [defaultDbPath stringByDeletingLastPathComponent];
    NSString *fileName = [defaultDbPath lastPathComponent];
    NSString *backFileName = [NSString stringWithFormat:@"lemon_back_%@", fileName];
    NSString *backDBPath = [folderPath stringByAppendingPathComponent:backFileName];
    
    BOOL useBackDbFlag = NO;
    if (running) {
        useBackDbFlag = TRUE;
        BOOL backDbExistFlag = [fileManager fileExistsAtPath:backDBPath];
        
        // remove old back file
        if (backDbExistFlag) {
            NSError *error = nil;
            BOOL backDBRemoveFlag = [fileManager removeItemAtPath:backDBPath error:&error];
            if (!backDBRemoveFlag) {
                useBackDbFlag = FALSE;
                NSString *errorDesc = error == nil ? @"nil" : error.localizedDescription;
                NSLog(@"remove back path: %@ failed, error : %@", backDBPath, errorDesc);
            }
        }
        
        // copy file
        if ([fileManager isReadableFileAtPath:defaultDbPath]) {
            NSError *error = nil;
            BOOL copyDBFlag = [fileManager copyItemAtPath:defaultDbPath toPath:backDBPath error:&error];
            if (!copyDBFlag) {
                useBackDbFlag = FALSE;
                NSString *errorDesc = error == nil ? @"nil" : error.localizedDescription;
                NSLog(@"copy db %@ to  %@ failed, error : %@", defaultDbPath, backDBPath, errorDesc);
            }
        }
    }
    
    FMDatabase *db;
    if (useBackDbFlag) {
        db = [FMDatabase databaseWithPath:backDBPath];
    } else {
        db = [FMDatabase databaseWithPath:defaultDbPath];
    }
    NSLog(@"getReadableDBByPath db path is %@", db.databasePath);
    if (db && [db open]) {
        NSLog(@"getReadableDBByPath db 打开成功");
        return db;
    }
    
    return nil;
}


- (NSString *)getFileNameByPath:(NSString *)filepath {
    NSArray *array = [filepath componentsSeparatedByString:@"/"];
    if (array.count == 0) return filepath;
    return array[array.count - 1];
}


+ (NSString *)getUserHomeDirectory {
    if (@available(macOS 10.12, *)) {
        NSURL *url = NSFileManager.defaultManager.homeDirectoryForCurrentUser;
        NSString *path = [url path];
        return path;
    } else {
        return NSHomeDirectory();
    }
}

- (NSString *)getUserHomeDirectory {
    return [BaseBrowserPrivacyDataManager getUserHomeDirectory];
}

@end
