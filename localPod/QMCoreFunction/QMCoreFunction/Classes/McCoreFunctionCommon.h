//
//  McCoreFunctionCommon.h
//  McCoreFunction
//
//  Created by developer on 12-1-12.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#ifndef McCoreFunction_McCoreFunctionCommon_h
#define McCoreFunction_McCoreFunctionCommon_h

#ifndef FSE_INVALID
#define FSE_INVALID             -1
#define FSE_CREATE_FILE          0
#define FSE_DELETE               1
#define FSE_STAT_CHANGED         2
#define FSE_RENAME               3
#define FSE_CONTENT_MODIFIED     4
#define FSE_EXCHANGE             5
#define FSE_FINDER_INFO_CHANGED  6
#define FSE_CREATE_DIR           7
#define FSE_CHOWN                8
#define FSE_XATTR_MODIFIED       9
#define FSE_XATTR_REMOVED       10
#endif

#import "McProcessInfoData.h"

typedef void(^block_v_i)(int);
typedef void(^block_v_b)(BOOL);
typedef void(^block_v_d)(NSDictionary*);
typedef void(^block_v_a)(NSArray*);
typedef void(^block_v_ma)(NSMutableArray*);

// file event data define
typedef enum
{
    Timer,
    FullPath,
    FileEventType,
    FsProcessName
}FileEventOrderEnum;

@interface McFileEventData : NSObject
{
    unsigned int fsindex;
    NSString * eventPath;
    NSString * renamedPath;
    int  eventType;
}
@property (assign) unsigned int fsindex;
@property (copy) NSString * eventPath;
@property (strong) NSString * renamedPath;
@property (assign) int  eventType;

@end


// process info define

typedef enum
{
    Pid,
    ProcessName,
    Cpu,
    Thread,
    Memory,
    User,
    Kind,
    CpuTime
}ProcessOrderEnum;


// clean
#define kCleanRootFlags 99
typedef enum
{
    McCleanMoveTrash = 0,
    McCleanRemove,
    McCleanCutBinary,
    McCleanTruncate = kCleanRootFlags,
    McCleanMoveTrashRoot,
    McCleanRemoveRoot,
    McCleanCutBinaryRoot,
    McCleanTruncateRoot,
}McCleanRemoveType;

@protocol McCleanDelegate <NSObject>

- (BOOL)cleanProgressRate:(float)value;
- (void)cleanEnd;

@end

#endif
