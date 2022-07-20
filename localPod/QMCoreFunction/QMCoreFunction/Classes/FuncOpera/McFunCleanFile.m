//
//  McFunCleanFile.m
//  McCoreFunction
//
//  Created by developer on 12-1-12.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import "McFunCleanFile.h"
//#import "McPipeClient.h"
#import "LMXpcClient.h"

#define MAXRemoveLength 1000

@implementation McFunCleanFile

/*
 移动到回收站（root权限）
 filePaths:需要移动的路径
 */
- (void)removeFilesTrashByDaemon:(NSArray *)filePaths
{
    NSMutableArray *fileArray = [NSMutableArray arrayWithArray:filePaths];
    // tell daemon user name
    [fileArray insertObject:NSUserName() atIndex:0];
    
    int total_size = 0;
    for (NSString *path in fileArray)
    {
        total_size += (strlen([path UTF8String]) + 1);
    }
    if (total_size == 0)
        return;
    
    // call daemon to remove
    char *data = malloc(total_size);
    int index = 0;
    for (NSString *path in fileArray)
    {
        strcpy(data + index, [path UTF8String]);
        NSUInteger length = strlen([path UTF8String]);
        index += (length + 1);
        data[index - 1] = '\0';
    }
    
    _dm_file_action(MC_FILE_RECYCLE, (int)[fileArray count], data, total_size);
    free(data);
}

/*
 删除文件（root权限）
 filePaths:需要移动的路径
 */
- (void)removeFilesByDaemon:(NSArray *)filePaths
{
    int total_size = 0;
    for (NSString *path in filePaths)
    {
        total_size += (strlen([path UTF8String]) + 1);
    }
    if (total_size == 0)
        return;
    
    // call daemon to remove
    char *data = malloc(total_size);
    int index = 0;
    for (NSString *path in filePaths)
    {
        strcpy(data + index, [path UTF8String]);
        NSUInteger length = strlen([path UTF8String]);
        index += (length + 1);
        data[index - 1] = '\0';
    }
    
    _dm_file_action(MC_FILE_DEL, (int)[filePaths count], data, total_size);
    free(data);
}


/*
 删除无用的二进制
 filePaths:需要删除无用的二进制的路径
 */
- (void)cutBinariesByDaemon:(NSArray *)filePaths
{
    int total_size = 0;
    for (NSString *path in filePaths)
    {
        total_size += (strlen([path UTF8String]) + 1);
    }
    if (total_size == 0)
        return;
    
    // call daemon to remove
    char *data = malloc(total_size);
    int index = 0;
    for (NSString *path in filePaths)
    {
        strcpy(data + index, [path UTF8String]);
        NSUInteger length = strlen([path UTF8String]);
        index += (length + 1);
        data[index - 1] = '\0';
    }
    
    _dm_file_action(MC_FILE_BIN_CUT, (int)[filePaths count], data, total_size);
    free(data);
}

/*
 移动到回收站（低权限）
 返回值:YES成功，NO失败
 path:需要移动的路径
 */
- (BOOL)removeFileToTrash:(NSString *)path
{
    NSFileManager * fm = [NSFileManager defaultManager];
    BOOL isSuccess = YES;
    if (![fm fileExistsAtPath:path])
        return isSuccess;
    
    isSuccess = [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
                                                             source:[path stringByDeletingLastPathComponent]
                                                        destination:@""
                                                              files:[NSArray arrayWithObject:[path lastPathComponent]]
                                                                tag:nil];
    return isSuccess;
}

/*
 将文件置空（低权限）
 返回值:YES成功，NO失败
 path:需要移动的路径
 */
- (BOOL)truncateFileToZero:(NSString *)path
{
    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:path];
    if (file != nil)
    {
        [file truncateFileAtOffset:0];
        [file closeFile];
        return YES;
    }
    return NO;
}

/*
 将文件置空（高权限）
 filePaths:需要移动的路径
 */
- (void)truncateFileToZeroByDaemon:(NSArray *)filePaths
{
    int total_size = 0;
    for (NSString *path in filePaths)
    {
        total_size += (strlen([path UTF8String]) + 1);
    }
    if (total_size == 0)
        return;
    
    // call daemon to remove
    char *data = malloc(total_size);
    int index = 0;
    for (NSString *path in filePaths)
    {
        strcpy(data + index, [path UTF8String]);
        NSUInteger length = strlen([path UTF8String]);
        index += (length + 1);
        data[index - 1] = '\0';
    }
    
    _dm_file_action(MC_FILE_TRUNCATE, (int)[filePaths count], data, total_size);
    free(data);
}

/*
 低权限删除文件
 返回值:YES成功，NO失败
 path:需要移动的路径
 type:需要删除的方式
 */
- (BOOL)cleanItemAtPathByUser:(NSString *)path removeType:(McCleanRemoveType)type
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    BOOL retValue = YES;
    switch (type)
    {
        case McCleanMoveTrash:
        case McCleanMoveTrashRoot:
            retValue = [self removeFileToTrash:path];
            break;
        case McCleanRemove:
        case McCleanRemoveRoot:
            retValue = [fileMgr removeItemAtPath:path error:nil];
            break;
        case McCleanCutBinary:
        case McCleanCutBinaryRoot:
            retValue = removeFileArch(path);
            break;
        case McCleanTruncate:
        case McCleanTruncateRoot:
            retValue = [self truncateFileToZero:path];
            break;
        default:
            break;
    }
    return retValue;
}

-(void)removeFileByDaemonWithPath: (NSString *)path{
    [self cleanItemAtPathByDaemon:path array:nil removeType:McCleanRemoveRoot];
}

/*
 高权限删除文件
 path:需要移动的路径
 type:需要删除的方式
 */
- (void)cleanItemAtPathByDaemon:(NSString *)path array:(NSArray *)pathArray  removeType:(McCleanRemoveType)type
{
    NSArray * array = nil;
    if (path)
        array = [NSArray arrayWithObject:path];
    else
        array = pathArray;
    switch (type)
    {
        case McCleanRemoveRoot:
            [self removeFilesByDaemon:array];
            break;
        case McCleanMoveTrashRoot:
            [self removeFilesTrashByDaemon:array];
            break;
        case McCleanTruncateRoot:
            [self truncateFileToZeroByDaemon:array];
            break;
        case McCleanCutBinaryRoot:
            [self cutBinariesByDaemon:array];
            break;
        default:
            break;
    }
}

- (void)cutunlessBinary:(NSArray *)filePaths
             removeType:(int)type {
    int total_size = 0;
    for (NSString *path in filePaths)
    {
        total_size += (strlen([path UTF8String]) + 1);
    }
    if (total_size == 0)
        return;
    
    char *data = malloc(total_size);
    int index = 0;
    for (NSString *path in filePaths)
    {
        strcpy(data + index, [path UTF8String]);
        NSUInteger length = strlen([path UTF8String]);
        index += (length + 1);
        data[index - 1] = '\0';
    }
    
    NSLog(@"MC_FILE_CUT-->%@-->%d-->%d",filePaths,total_size,type);
    _dm_cut_action(MC_FILE_CUT, (int)[filePaths count], data, total_size, type);
    free(data);
}

- (BOOL)cleanItemAtPath:(NSString *)path
                  array:(NSArray *)pathArray
               delegate:(id<McCleanDelegate>)cleanDelegate
             removeType:(McCleanRemoveType)type
{
    BOOL retValue = YES;
    if (type <= kCleanRootFlags)
    {
        // 低权限删除
        if (path)
        {
            retValue = [self cleanItemAtPathByUser:path removeType:type];
        }
        else
        {
            int i = 0;
            for (NSString * pathStr in pathArray)
            {
                if (![self cleanItemAtPathByUser:pathStr removeType:type])
                    retValue = NO;
                i++;
                if (cleanDelegate)
                    [cleanDelegate cleanProgressRate:(i + 0.0) / [pathArray count]];
            }
        }
    }
    else
    {
        // 高权限删除，先用低权限删除，失败再调用Daemon
        if (path)
        {
            retValue = [self cleanItemAtPathByUser:path removeType:type];
            if (!retValue)
                [self cleanItemAtPathByDaemon:path array:nil removeType:type];
        }
        else
        {
            int i = 0;
            NSMutableArray *failPathArray = [NSMutableArray array];
            for (NSString * pathStr in pathArray)
            {
                if (![self cleanItemAtPathByUser:pathStr removeType:type])
                {
                    [failPathArray addObject:pathStr];
                }
                else
                {
                    i++;
                    if (cleanDelegate)
                        [cleanDelegate cleanProgressRate:(i + 0.0) / [pathArray count]];
                }
            }
            if ([failPathArray count] > 0)
            {
                NSInteger count = [failPathArray count];
                if (count > MAXRemoveLength)
                {
                    int startIndex = 0;
                    while (YES)
                    {
                        NSArray * tempArray = nil;
                        if (count > MAXRemoveLength)
                            tempArray = [failPathArray subarrayWithRange:NSMakeRange(startIndex, MAXRemoveLength)];
                        else
                            tempArray = [failPathArray subarrayWithRange:NSMakeRange(startIndex, count)];
                        [self cleanItemAtPathByDaemon:nil array:tempArray removeType:type];
                        count = count - [tempArray count];
                        if (count == 0)
                            break;
                        startIndex += [tempArray count];
                    }
                }
                else
                {
                    [self cleanItemAtPathByDaemon:nil array:failPathArray removeType:type];
                }
            }
            if (cleanDelegate)
                [cleanDelegate cleanProgressRate:1];
        }
        retValue = YES;

    }
    return retValue;
}

/*
 删除文件/移动到回收站，并删除无用的二进制
 path1:需要删除的路径
 path2:需要删除无用的二进制的路径
 cleanDelegate:删除文件委托
 type:删除文件方式（删除/移动到回收站/采用高权限）
 */
- (void)startClean:(NSArray *)path1
         cutBinary:(NSArray *)path2
          delegate:(id<McCleanDelegate>)cleanDelegate
        removeType:(McCleanRemoveType)type
{
    NSMutableArray * removePaths = nil;
    NSMutableArray * cutBinPaths = nil;
    removePaths = [path1 mutableCopy];
    cutBinPaths = [path2 mutableCopy];
    
    NSUInteger total_count = [removePaths count] + [cutBinPaths count];
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSError *error;
    BOOL result = NO;
    NSMutableArray *failPathArray = [NSMutableArray arrayWithCapacity:total_count];
    
    // test log
    //NSLog(@"to remove: %@", removePaths);
    //NSLog(@"to cut: %@", cutBinPaths);
    
    float sleepFlags = 0;
    if (total_count != 0)
        sleepFlags = 2 / total_count;
    
    // files to remove
    for (NSString *path in removePaths)
    {
        // try remove first
        if (type == McCleanMoveTrash || type == McCleanMoveTrashRoot)
        {
            result = [self removeFileToTrash:path];
        }
        else
        {
            result = [fileMgr removeItemAtPath:path error:&error];
        }
        if (!result)
        {
            NSLog(@"[ERR] remove item fail: [%ld] %@", [error code], [error localizedDescription]);
            
            // access denied
            NSUInteger length = strlen([path UTF8String]);
            if (length > 0)
            {
                [failPathArray addObject:path];
            }
        }
        else
        {
            if (cleanDelegate != nil)
            {
                // set progress
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cleanDelegate cleanProgressRate:1.0f/(float)total_count];
                });
                [NSThread sleepForTimeInterval:sleepFlags];
            }
        }
    }
    
    if ([failPathArray count] != 0)
    {
        if (type == McCleanRemoveRoot)
            [self removeFilesByDaemon:failPathArray];
        else if (type == McCleanMoveTrashRoot)
            [self removeFilesTrashByDaemon:failPathArray];
            
        // set progress
        if (cleanDelegate != nil)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [cleanDelegate cleanProgressRate:1.0f/(float)total_count];
            });
            [NSThread sleepForTimeInterval:sleepFlags];
        }
    }
    
    [failPathArray removeAllObjects];
    // cut binaries
    for (NSString *path in cutBinPaths)
    {
        if (![fileMgr isWritableFileAtPath:path])
        {
            // access denied
            NSUInteger length = strlen([path UTF8String]);
            if (length > 0)
            {
                [failPathArray addObject:path];
            }
        }
        else
        {
            if (!removeFileArch(path))
            {
                // try use daemon to cut
                NSUInteger length = strlen([path UTF8String]);
                if (length > 0)
                {
                    [failPathArray addObject:path];
                }
                continue;
            }
            
            if (cleanDelegate != nil)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cleanDelegate cleanProgressRate:1.0f/(float)total_count];
                });
                [NSThread sleepForTimeInterval:sleepFlags];
            }
        }
    }
    
    if ([failPathArray count] != 0)
    {
        [self cutBinariesByDaemon:failPathArray];
        
        // set progress
        if (cleanDelegate != nil)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [cleanDelegate cleanProgressRate:1.0f/(float)total_count];
            });
            [NSThread sleepForTimeInterval:sleepFlags];
        }
    }
    
    removePaths = nil;
    cutBinPaths = nil;
    
    if (cleanDelegate != nil)
        dispatch_async(dispatch_get_main_queue(), ^{
            [cleanDelegate cleanEnd];
        });
}

/*
 moveFileItem移动文件，copyFileItem拷贝文件（root权限）
 返回值:其他值成功，-1失败
 path1:原路径
 path2:目标路径
 */
- (int)moveFileItem:(NSString *)path1 toPath:(NSString *)path2
{
    return _dm_moveto_file([path1 UTF8String], [path2 UTF8String], MCCMD_MOVEFILE_MOVE);
}
- (int)copyFileItem:(NSString *)path1 toPath:(NSString *)path2
{
    return _dm_moveto_file([path1 UTF8String], [path2 UTF8String], MCCMD_MOVEFILE_COPY);
}

@end
