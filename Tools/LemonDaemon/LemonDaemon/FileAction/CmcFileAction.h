//
//  CmcFileAction.h
//  McDaemon
//
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/// 路径任一层为非系统别名（/tmp /var /etc）的 symlink 则返回 YES，调用方应拒绝
BOOL pathHasUnsafeSymlinkComponent(NSString *path);

/// 通用路径安全校验：白名单 + 黑名单 + 非系统 symlink 拒绝 + 路径穿越检测
/// 返回 YES 表示允许操作，NO 表示拒绝
BOOL isPathAllowedForFileOp(NSString *path);

// delete files on disk
int filesRemove(char *data_start, int fileCount);

// delete ppc arch for mach-o files
int fileCutBinaries(char *data_start, int count);

// remove file to trash
int fileMoveToTrash(char *data_start, int count);

// set castle plist
BOOL setCastleShowDock(BOOL show);

// move file
int fileMoveTo(char *src_path, char *dst_path, int action);

// just clear file data
int fileClearContent(char *data_start, int count);

//
int fileCutContent(char *data_start, int count,int arch);
