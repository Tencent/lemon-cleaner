//
//  QMLaunchpadClean.m
//  CocoaApp
//

//  Copyright (c) 2015年 Tencent. All rights reserved.
//

#import "QMLaunchpadClean.h"
#import "FMDB.h"
@implementation QMLaunchpadClean

+ (BOOL)cleanLaunchpad
{
    SInt32 major = 0;
    SInt32 minor = 0;
    Gestalt( gestaltSystemVersionMajor, &major );
    if (major != 10) return NO;
    Gestalt( gestaltSystemVersionMinor, &minor );
    
    NSString *databaseDirectoryPath = nil;
    if (minor >= 7 && minor <= 9)
    {
        databaseDirectoryPath = [@"~/Library/Application Support/Dock/" stringByStandardizingPath];
    }
    else if (minor == 10)
    {
        NSString *tempDirectoryPath = NSTemporaryDirectory();
        NSString *tempDirectoryPath_pre = [tempDirectoryPath stringByDeletingLastPathComponent];
        databaseDirectoryPath = [tempDirectoryPath_pre stringByAppendingPathComponent:@"/0/com.apple.dock.launchpad/db"];
    }
    
    if (!databaseDirectoryPath || ![[NSFileManager defaultManager] fileExistsAtPath:databaseDirectoryPath])
        return NO;
    
    NSString *databasePath = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *files = [fileManager contentsOfDirectoryAtPath:databaseDirectoryPath error:&error];
    
    if (error || !files || [files count] == 0)
        return NO;
    
    for (NSString *fileName in files)
    {
        if (([[fileName pathExtension] isEqualToString:@"db"] && ![fileName isEqualToString:@"desktoppicture.db"]) || [fileName isEqualToString:@"db"])
        {
            databasePath = [databaseDirectoryPath stringByAppendingPathComponent:fileName];
        }
    }
    
    if (!databasePath)
        return NO;
    
    FMDatabase *db = [FMDatabase databaseWithPath:databasePath];
    if (![db open])
        return NO;
    
    FMResultSet *result = [db executeQuery:@"SELECT rowid,parent_id,uuid,flags,type,ordering,apps.title,groups.title,apps.bundleid FROM items LEFT JOIN apps ON ABS(rowid) = apps.item_id LEFT JOIN groups ON ABS(rowid) = groups.item_id ORDER BY parent_id,ordering;"];
    
    NSMutableArray *items = [NSMutableArray array];
    
    while ([result next])
    {
        NSString *name = [result stringForColumnIndex:6];
        if ([name isEqualToString:@"WireLurker专杀"] || [name isEqualToString:@"文件清理助手"] || [name isEqualToString:@"重复文件查找"] || [name isEqualToString:@"网络测速"])
        {
            int rowid = [result intForColumnIndex:0];
            [items addObject:[NSNumber numberWithInt:rowid]];
        }
        
    }
    
    if (items.count == 0)
        return NO;
    
    NSString *sql;
    for (int i = 0; i < [items count]; i++)
    {
        int rowid = [[items objectAtIndex:i] intValue];
        sql = [NSString stringWithFormat:@"delete from apps where rowid = %li",(long)rowid];
        [db executeUpdate:sql];
        sql = [NSString stringWithFormat:@"delete from items where rowid = %li",(long)rowid];
        [db executeUpdate:sql];
    }
    
    [db close];
    
    system("killall Dock");
    return YES;
}

@end
