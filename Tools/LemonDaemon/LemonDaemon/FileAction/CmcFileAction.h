//
//  CmcFileAction.h
//  McDaemon
//
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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
