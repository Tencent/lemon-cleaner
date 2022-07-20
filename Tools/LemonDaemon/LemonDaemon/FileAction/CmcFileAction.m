//
//  CmcFileAction.m
//  McDaemon
//
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import "CmcFileAction.h"
#import "CutBinary.h"
#import "McPipeStruct.h"

// delete files on disk
// char[]数组的结构是这样的 "str1"\0"str2"\0 "str3"\0.... 相对于这是一个 string 数组,数组间以\0 分隔, 所以这个函数可以删除多个字符串.
int filesRemove(char *data_start, int fileCount) {
    if ([[NSString stringWithUTF8String:data_start] isEqualToString:@"/"]) {
        NSLog(@"can't remove the root path: %s", data_start);
        return -1;
    }
    NSError *error;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    char *path = data_start;
    for (int i = 0; i < fileCount; i++) {
        if (strlen(path) > 0) {
            // remove
            if (![fileMgr removeItemAtPath:[NSString stringWithUTF8String:path] error:&error]) {
                NSLog(@"[ERR] file [%s] remove fail: %@", path, [error localizedDescription]);
            } else {
                NSLog(@"%s remove path: %s", __FUNCTION__, path);
            }
        }

        path += (strlen(path) + 1);
    }

    return 0;
}

// delete ppc arch for mach-o files
int fileCutContent(char *data_start, int count,int arch) {
    char *path = data_start;
    for (int i = 0; i < count; i++) {
        // remove
        if (!cutFileArch([NSString stringWithUTF8String:path],arch)) {
            NSLog(@"[ERR] cut binary [%s] fail", path);
        }
        NSLog(@"cut path: %s", path);
        path += (strlen(path) + 1);
    }
    //NSLog(@"cut path total size: %d", path - data_start);

    return 0;
}

// delete ppc arch for mach-o files
int fileCutBinaries(char *data_start, int count) {
    char *path = data_start;
    for (int i = 0; i < count; i++) {
        // remove
        if (!removeFileArch([NSString stringWithUTF8String:path])) {
            //NSLog(@"[ERR] cut binary [%s] fail", path);
        }
        //NSLog(@"cut path: %s", path);

        path += (strlen(path) + 1);
    }
    //NSLog(@"cut path total size: %d", path - data_start);

    return 0;
}

BOOL RemoveToUserTrash(NSString *removeFile, NSString *userName) {
    // .Trash path
    // get current user name path
    NSString *trashPath = [NSHomeDirectoryForUser(userName) stringByAppendingPathComponent:@".Trash"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err = nil;

    NSString *trashFilePath = nil;
    NSString *lastComponent = [[removeFile lastPathComponent] stringByDeletingPathExtension];
    NSString *fileExtension = [removeFile pathExtension];
    NSString *trashLastComponent = lastComponent;
    int index = 0;

    // get target path, rename type like finder
    while (YES) {
        trashFilePath = [[trashPath stringByAppendingPathComponent:trashLastComponent]
                stringByAppendingPathExtension:fileExtension];
        if (![fm fileExistsAtPath:trashFilePath])
            break;

        NSDate *now = [NSDate date];
        NSString *str = [NSDateFormatter localizedStringFromDate:now
                                                       dateStyle:NSDateFormatterNoStyle
                                                       timeStyle:NSDateFormatterMediumStyle];
        str = [str stringByReplacingOccurrencesOfString:@":" withString:@"."];
        if (index == 0)
            trashLastComponent = [lastComponent stringByAppendingFormat:@" %@", str];
        else
            trashLastComponent = [lastComponent stringByAppendingFormat:@" %@ %d", str, index];
        index++;
    }

    if (trashFilePath != nil) {
        return [fm moveItemAtPath:removeFile toPath:trashFilePath error:&err];
    } else {
        return NO;
    }
}

// remove file to trash
int fileMoveToTrash(char *data_start, int count) {
    // get user name
    char *user_name = data_start;
    char *path = data_start + strlen(user_name) + 1;

    NSString *userName = [NSString stringWithUTF8String:user_name];
    for (int i = 1; i < count; i++) {
        if (strlen(path) > 0) {
            // move to trash
            if (!RemoveToUserTrash([NSString stringWithUTF8String:path], userName)) {
                //NSLog(@"[ERR] file [%s] move to trash fail", path);
            }
        }

        path += (strlen(path) + 1);
    }

    return 0;
}

// move file
int fileMoveTo(char *src_path, char *dst_path, int action) {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSError *err = nil;
    switch (action) {
        case MCCMD_MOVEFILE_MOVE: {
            if (![fileMgr replaceItemAtURL:[NSURL fileURLWithPath:[NSString stringWithUTF8String:dst_path]]
                             withItemAtURL:[NSURL fileURLWithPath:[NSString stringWithUTF8String:src_path]]
                            backupItemName:nil
                                   options:NSFileManagerItemReplacementUsingNewMetadataOnly
                          resultingItemURL:nil
                                     error:&err]) {
                NSLog(@"[ERR] move file from %s to %s fail %@", src_path, dst_path, err);
                return -1;
            }
            break;
        }
        case MCCMD_MOVEFILE_COPY: {
            NSString *dstPathStr = [NSString stringWithUTF8String:dst_path];
            if ([fileMgr fileExistsAtPath:dstPathStr]) {
                if (![fileMgr removeItemAtPath:dstPathStr error:&err]) {
                    NSLog(@"[ERR] remove Item from %@ fail %@", dstPathStr, err);
                    return -1;
                }
            }
            if (![fileMgr copyItemAtPath:[NSString stringWithUTF8String:src_path]
                                  toPath:[NSString stringWithUTF8String:dst_path]
                                   error:&err]) {
                NSLog(@"[ERR] copy file from %s to %s fail %@", src_path, dst_path, err);
                return -1;
            }
            break;
        }

        default:
            return -1;
    }

    return 0;
}

// set castle plist
BOOL setCastleShowDock(BOOL show) {
    NSString *plistPath = [NSString stringWithFormat:@"%@/Contents/Info.plist", DEFAULT_APP_PATH];
    NSMutableDictionary *infoDic = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    if (infoDic == nil)
        return -1;

    infoDic[@"LSUIElement"] = @(show);
    return [infoDic writeToFile:plistPath atomically:YES];
}

// just clear file data
int fileClearContent(char *data_start, int count) {
    char *path = data_start;
    for (int i = 0; i < count; i++) {
        if (strlen(path) > 0) {
            NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:[NSString stringWithUTF8String:path]];
            if (file == nil) {
                //NSLog(@"[ERR] file [%s] clear content fail", path);
            } else {
                [file truncateFileAtOffset:0];
                [file closeFile];
            }
        }

        path += (strlen(path) + 1);
    }
    return 0;
}
