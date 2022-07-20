//
//  McFileEventData.m
//  McStat
//
//  Created by developer on 11-7-25.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import "McFileEvent.h"
//#import "McPipeClient.h"
#import "LMXpcClient.h"
#import "McCoreFunctionCommon.h"


@implementation McFileEventData
@synthesize eventPath;
@synthesize eventType;
@synthesize fsindex;
@synthesize renamedPath;

- (id)init
{
    if (self = [super init])
    {
        eventPath = nil;
        eventType = 0;
        renamedPath = nil;
        fsindex = 0;
    }
    return self;
}

@end


@implementation McFileEvent

- (id)init
{
    if (self = [super init])
    {
    }
    return self;
}

static void pack_fsmon_event(McFileEvent *object, NSMutableArray *fsData, kfs_result_Data *fs_data, int ret) {
    if (ret > 0)
    {
        for (int i = 0; i < ret; i++)
        {
            // do not record ourself
            if (fs_data[i].pid == getpid())
                continue;
            
            McFileEventData * fileEventData = [[McFileEventData alloc] init];
            fileEventData.eventType = fs_data[i].type;
            fileEventData.eventPath = [NSString stringWithUTF8String:fs_data[i].result_Detail1.path];
            if (fileEventData.eventType == FSE_RENAME)
            {
                fileEventData.renamedPath = [NSString stringWithUTF8String:fs_data[i].result_Detail2.path];
            }
            fileEventData.fsindex = fs_data[i].index;
            [fsData addObject:fileEventData];
        }
        // next index
        object->fsstart = fs_data[ret - 1].index;
    }
}

- (NSMutableArray *)fillFileEventData:(block_v_ma)block_a
{
    const int per_count = 100;
    kfs_result_Data *fs_data = malloc(sizeof(fs_data)*per_count);
    
    // 不能在Block中使用数组，用数组的指针代替： fs_data[per_count] 是在栈上申请内存. 异步回调时栈上的内存释放掉了,无法保证 block 是否对数组进行了复制.(c 中数组length 不可知)
    //    kfs_result_Data fs_data[per_count];

    __block NSMutableArray * fsData = [NSMutableArray array];

    if(block_a){
        
        block_v_i copyBlock = ^(int return_code) {
            pack_fsmon_event(self, fsData, fs_data, return_code);
            block_a(fsData);
            free(fs_data);
        };
        _dm_get_fsmon_event_aysnc(fsstart, per_count, fs_data, copyBlock);
        return nil;
    }else{
        int return_code = _dm_get_fsmon_event(fsstart, per_count, fs_data);
        pack_fsmon_event(self, fsData, fs_data, return_code);
        free(fs_data);
        return fsData;
    }
    
}
@end
