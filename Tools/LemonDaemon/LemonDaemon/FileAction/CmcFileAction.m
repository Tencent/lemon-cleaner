//
//  CmcFileAction.m
//  McDaemon
//
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import "CmcFileAction.h"
#import "CutBinary.h"
#import "McPipeStruct.h"
#import <sys/stat.h>
#import <errno.h>
#import <fcntl.h>
#import <unistd.h>

#pragma mark - Path Security Validation

// 路径黑名单：绝对禁止操作的系统关键路径
static NSArray *_pathBlacklist(void) {
    static NSArray *list = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        list = @[
            @"/System",
            @"/usr",
            @"/bin",
            @"/sbin",
            @"/private/var/run",
            @"/var/run",
            @"/Library/LaunchDaemons/com.tencent.LemonDaemon.plist",
        ];
    });
    return list;
}

// 路径白名单：Lemon 业务操作允许的目录前缀
static NSArray *_pathWhitelist(void) {
    static NSArray *list = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        list = @[
            @"/Applications/",
            @"/Library/LaunchDaemons/",
            @"/Library/LaunchAgents/",
            @"/Library/Application Support/",
            @"/Library/Caches/",
            @"/Library/Logs/",
            @"/Library/Preferences/",
            @"/Library/Extensions/",
            @"/Users/",
            @"/private/var/folders/",
            @"/private/var/log/",
            @"/private/var/db/receipts/",
            @"/private/tmp/",
            @"/tmp/",
            @"/var/folders/",
            @"/var/log/",
            @"/var/db/receipts/",
        ];
    });
    return list;
}

static BOOL _isSystemPathAlias(NSString *prefix) {
    return [prefix isEqualToString:@"/tmp"] ||
           [prefix isEqualToString:@"/var"] ||
           [prefix isEqualToString:@"/etc"];
}

BOOL pathHasUnsafeSymlinkComponent(NSString *path) {
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
            // 后续 remove / open / fileExists 会拦；这里不能当成 symlink 拒绝，否则正常已删目标会被误报。
            if (errno == ENOENT || errno == ENOTDIR) {
                return NO;
            }
            NSLog(@"[security] lstat failed for %@ errno=%d", prefix, errno);
            return YES;
        }
        if (S_ISLNK(st.st_mode) && !_isSystemPathAlias(prefix)) {
            NSLog(@"[security] reject symlink component: %@", prefix);
            return YES;
        }
    }
    return NO;
}

/// 通用路径安全校验：白名单 + 黑名单 + 非系统 symlink 拒绝 + 路径穿越检测
/// 返回 YES 表示允许操作，NO 表示拒绝
BOOL isPathAllowedForFileOp(NSString *path) {
    if (!path || path.length == 0) {
        return NO;
    }
    
    // 禁止根路径
    if ([path isEqualToString:@"/"]) {
        return NO;
    }
    
    // 路径穿越检测
    if ([path containsString:@".."]) {
        NSLog(@"[security] reject path with traversal: %@", path);
        return NO;
    }

    // 拒绝控制字符与引号，避免后续命令拼接或异常路径
    static NSCharacterSet *unsafeChars = nil;
    static dispatch_once_t onceTokenUnsafe;
    dispatch_once(&onceTokenUnsafe, ^{
        NSMutableCharacterSet *set = [NSMutableCharacterSet characterSetWithCharactersInString:@"\"`$|&;\n\r"];
        [set formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];
        unsafeChars = [set copy];
    });
    if ([path rangeOfCharacterFromSet:unsafeChars].location != NSNotFound) {
        NSLog(@"[security] reject path with unsafe characters: %@", path);
        return NO;
    }

    // 校验用的是原始路径的每一层：中间若是用户 symlink，resolved 会落到白名单里，执行却会跟过去
    if (pathHasUnsafeSymlinkComponent(path)) {
        NSLog(@"[security] reject path with unsafe symlink: %@", path);
        return NO;
    }
    
    // 标准化并解析 symlink（此处仅剩 /tmp /var /etc 等系统别名）
    NSString *standardized = [path stringByStandardizingPath];
    NSString *resolved = [standardized stringByResolvingSymlinksInPath];
    
    // 黑名单检查
    for (NSString *blackPrefix in _pathBlacklist()) {
        if ([resolved isEqualToString:blackPrefix] ||
            [resolved hasPrefix:[blackPrefix stringByAppendingString:@"/"]]) {
            NSLog(@"[security] reject blacklisted path: %@ (resolved: %@)", path, resolved);
            return NO;
        }
    }
    
    // 自我保护：禁止操作 Lemon 自身
    if ([resolved hasPrefix:@"/Applications/Tencent Lemon.app"]) {
        NSLog(@"[security] reject self-protection path: %@", path);
        return NO;
    }
    
    // 白名单检查
    for (NSString *whitePrefix in _pathWhitelist()) {
        if ([resolved hasPrefix:whitePrefix]) {
            return YES;
        }
    }
    
    NSLog(@"[security] reject path not in whitelist: %@ (resolved: %@)", path, resolved);
    return NO;
}

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
            NSString *pathStr = [NSString stringWithUTF8String:path];
            // 安全校验：路径白名单 + 黑名单
            if (!isPathAllowedForFileOp(pathStr)) {
                NSLog(@"[security] filesRemove: reject path: %@", pathStr);
                path += (strlen(path) + 1);
                continue;
            }
            // remove
            if (![fileMgr removeItemAtPath:pathStr error:&error]) {
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
        if (strlen(path) > 0) {
            NSString *pathStr = [NSString stringWithUTF8String:path];
            // 安全校验
            if (!isPathAllowedForFileOp(pathStr)) {
                NSLog(@"[security] fileCutContent: reject path: %@", pathStr);
                path += (strlen(path) + 1);
                continue;
            }
            // remove
            if (!cutFileArch(pathStr, arch)) {
                NSLog(@"[ERR] cut binary [%s] fail", path);
            }
            NSLog(@"cut path: %s", path);
        }
        path += (strlen(path) + 1);
    }
    //NSLog(@"cut path total size: %d", path - data_start);

    return 0;
}

// delete ppc arch for mach-o files
int fileCutBinaries(char *data_start, int count) {
    char *path = data_start;
    for (int i = 0; i < count; i++) {
        if (strlen(path) > 0) {
            NSString *pathStr = [NSString stringWithUTF8String:path];
            // 安全校验
            if (!isPathAllowedForFileOp(pathStr)) {
                NSLog(@"[security] fileCutBinaries: reject path: %@", pathStr);
                path += (strlen(path) + 1);
                continue;
            }
            if (!removeFileArch(pathStr)) {
                //NSLog(@"[ERR] cut binary [%s] fail", path);
            }
            //NSLog(@"cut path: %s", path);
        }
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
            NSString *pathStr = [NSString stringWithUTF8String:path];
            // 安全校验：路径白名单 + 黑名单
            if (!isPathAllowedForFileOp(pathStr)) {
                NSLog(@"[security] fileMoveToTrash: reject path: %@", pathStr);
                path += (strlen(path) + 1);
                continue;
            }
            // move to trash
            if (!RemoveToUserTrash(pathStr, userName)) {
                //NSLog(@"[ERR] file [%s] move to trash fail", path);
            }
        }

        path += (strlen(path) + 1);
    }

    return 0;
}

// move file
int fileMoveTo(char *src_path, char *dst_path, int action) {
    NSString *srcPathStr = src_path ? [NSString stringWithUTF8String:src_path] : nil;
    NSString *dstPathStr = dst_path ? [NSString stringWithUTF8String:dst_path] : nil;
    // 不能套 isPathAllowedForFileOp：安装/更新会把 dst 写成 Lemon.app，自保护会误拒
    if (pathHasUnsafeSymlinkComponent(srcPathStr) || pathHasUnsafeSymlinkComponent(dstPathStr)) {
        NSLog(@"[security] fileMoveTo: reject symlink src=%@ dst=%@", srcPathStr, dstPathStr);
        return -1;
    }

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
            NSString *pathStr = [NSString stringWithUTF8String:path];
            // 安全校验：路径白名单 + 黑名单
            if (!isPathAllowedForFileOp(pathStr)) {
                NSLog(@"[security] fileClearContent: reject path: %@", pathStr);
                path += (strlen(path) + 1);
                continue;
            }
            int fd = open([pathStr fileSystemRepresentation], O_WRONLY | O_NOFOLLOW);
            if (fd < 0) {
                if (errno != ENOENT) {
                    NSLog(@"[security] fileClearContent: open failed path=%@ errno=%d", pathStr, errno);
                }
            } else {
                if (ftruncate(fd, 0) != 0) {
                    NSLog(@"[ERR] file [%s] clear content fail errno=%d", path, errno);
                }
                close(fd);
            }
        }

        path += (strlen(path) + 1);
    }
    return 0;
}
