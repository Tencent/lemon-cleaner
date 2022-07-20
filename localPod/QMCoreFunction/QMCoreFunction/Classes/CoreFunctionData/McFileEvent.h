//
//  McFileEventData.h
//  McStat
//
//  Created by developer on 11-7-25.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "McCoreFunctionCommon.h"

@interface McFileEvent :NSObject
{
    int fsstart;
}

// block 为 nil 时, 同步返回, block 不为 nil 时,异步返回.
- (NSMutableArray *)fillFileEventData:(block_v_ma)block_a;

@end
