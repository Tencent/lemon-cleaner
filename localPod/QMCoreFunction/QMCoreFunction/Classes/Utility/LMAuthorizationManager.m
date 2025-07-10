//
//  LMAuthorizationManager.m
//  QMCoreFunction
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMAuthorizationManager.h"
#import "NSString+Extension.h"
#import "QMShellExcuteHelper.h"
#import <sqlite3.h>

#define LM_System_TCC_DB  @"/Library/Application Support/com.apple.TCC/TCC.db"

@implementation LMAuthorizationManager

+(PhotoAccessState)checkAuthorizationForAccessAlbum{
    NSString *photoPath = [NSString stringWithFormat:@"%@/Pictures/Photos Library.photoslibrary", [NSString getUserHomePath]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:photoPath];
    if(!isExist){
        photoPath = [NSString stringWithFormat:@"%@/Pictures/照片图库.photoslibrary",[NSString getUserHomePath]];
        isExist = [fileManager fileExistsAtPath:photoPath];
    }
    if(!isExist){
        return PhotoNotExist;
    }
    
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:photoPath];
    if([dirEnum nextObject]){
        return PhotoAccessed;
    }
    return PhotoDenied;
}


+(Boolean)checkAuthorizationForCreateAlbum{
    NSString *fileName = [[NSUUID new] UUIDString];
    NSString* creatAlbum = [NSString stringWithFormat:@"tell application \"Photos\" \n"
                            "make new album named \"%@\" \n"
                            "return \"succeed\" \n"
                            "end tell",fileName];
    NSString* deleteAlbum = [NSString stringWithFormat:@"tell application \"Photos\" \n"
                             "delete album named \"%@\" \n"
                             "return \"succeed\" \n"
                             "end tell",fileName];
    NSAppleScript *script = [[NSAppleScript alloc]initWithSource:creatAlbum];
    NSDictionary *dict = nil;
    @try{
        NSAppleEventDescriptor *result = [script executeAndReturnError:&dict];
        if (dict || !result) {
            NSLog(@"checkAuthorizationForCreateAlbum_dict create error =%@", dict);
            return false;
        }else{
            script = [[NSAppleScript alloc]initWithSource:deleteAlbum];
            [script executeAndReturnError:&dict];
            NSLog(@"checkAuthorizationForCreateAlbum_dict_dict delete error =%@", dict);
            return true;
        }
    }
    @catch(NSException *exception){
        NSLog(@"checkAuthorizationForCreateAlbum_dict_dict addAlbumsWith exception = %@", exception);
        return false;
    }
    
}

+ (BOOL)checkAuthorizationForFinder {
    NSString *testScript = @"tell application \"Finder\"\n"
                           @"set desktopPath to (path to desktop folder as text)\n"
                           @"return desktopPath\n"
                           @"end tell";
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:testScript];
    NSDictionary *errorDict = nil;
    NSAppleEventDescriptor *result = [script executeAndReturnError:&errorDict];
    
    if (errorDict || !result) {
        return NO;
    }
    return YES;
}

+(void)openPrivacyAutomationPreference{
    NSURL *URL = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"];
    [[NSWorkspace sharedWorkspace] openURL:URL];
}

+(void)openPrivacyPhotoPreference{
    NSURL *URL = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Photos"];
    [[NSWorkspace sharedWorkspace] openURL:URL];
}


+ (NSDictionary<NSString *, NSArray<NSString *> *> *)getAllApplicationsWithAutomationPermission {
    NSString *dbPath = [NSHomeDirectory() stringByAppendingPathComponent:LM_System_TCC_DB];
    sqlite3 *db;
    NSMutableDictionary *permissionsDict = [NSMutableDictionary dictionary];
    
    int result = sqlite3_open_v2([dbPath UTF8String], &db, SQLITE_OPEN_READONLY, NULL);
    if (result != SQLITE_OK) {
        NSLog(@"open TCC.db failed: %s", sqlite3_errstr(result));
        return @{};
    }
    
    const char *sql = "SELECT client, indirect_object_identifier "
                      "FROM access "
                      "WHERE service = 'kTCCServiceAppleEvents' "
                      "AND auth_value = 2";  // 2 表示已授权
    
    sqlite3_stmt *stmt;
    result = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        NSLog(@"SQL prepare failed: %s", sqlite3_errstr(result));
        sqlite3_close(db);
        return @{};
    }
    
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        const char *controller = (const char *)sqlite3_column_text(stmt, 0);
        const char *controlled = (const char *)sqlite3_column_text(stmt, 1);
        
        if (controller && controlled) {
            NSString *controllerID = [NSString stringWithUTF8String:controller];
            NSString *controlledID = [NSString stringWithUTF8String:controlled];
            
            if (!permissionsDict[controllerID]) {
                permissionsDict[controllerID] = [NSMutableArray array];
            }
            [permissionsDict[controllerID] addObject:controlledID];
        }
    }
    
    sqlite3_finalize(stmt);
    sqlite3_close(db);
    
    return permissionsDict;
}

+ (NSArray<NSDictionary *> *)getAllApplicationsWithAccessibilityPermission {
    const char * dbPath = [LM_System_TCC_DB UTF8String];
    sqlite3 *db;
    NSMutableArray *authorizedApps = [NSMutableArray array];
    
    int result = sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, NULL);
    if (result != SQLITE_OK) {
        NSLog(@"open TCC.db failed: %s", sqlite3_errstr(result));
        return @[];
    }
    
    const char *sql = "SELECT client, client_type, auth_value, last_modified FROM access WHERE service='kTCCServiceAccessibility' AND auth_value=2";
    
    sqlite3_stmt *statement;
    result = sqlite3_prepare_v2(db, sql, -1, &statement, NULL);
    if (result != SQLITE_OK) {
        NSLog(@"SQL prepare failed: %s", sqlite3_errstr(result));
        sqlite3_close(db);
        return @[];
    }
    
    while (sqlite3_step(statement) == SQLITE_ROW) {
        const unsigned char *bundleID = sqlite3_column_text(statement, 0);
        if (bundleID == NULL) continue;
        
        NSString *appBundleID = [NSString stringWithUTF8String:(const char *)bundleID];
        if (appBundleID.length == 0) continue;
        
        int clientType = sqlite3_column_int(statement, 1);
        int authValue = sqlite3_column_int(statement, 2);
        int64_t lastModified = sqlite3_column_int64(statement, 3);
        
        NSDictionary *appInfo = @{
            @"bundleID": appBundleID,
            @"clientType": @(clientType),
            @"authValue": @(authValue),
            @"lastModified": [NSDate dateWithTimeIntervalSince1970:lastModified]
        };
        
        [authorizedApps addObject:appInfo];
    }
    
    sqlite3_finalize(statement);
    sqlite3_close(db);
    
    return authorizedApps;
}

@end
