//
//  McProcessInfo.h
//  ProcessInfo
//
//  Created by developer on 11-3-23.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "McPipeClient.h"
#import "McCoreFunctionCommon.h"
#import "McProcessInfoData.h"
#import "LMXpcClient.h"

@interface McProcessInfo : NSObject
{
    NSMutableArray *previousProcArray;
    
    float cpuTotal;
    uint64 memoryTotal;
}

-(NSMutableArray *)GetProcessInfo:(ORDER_TYPE) orderType 
                            count:(int)count 
                        isReverse:(Boolean)isReverse
                            block:(block_v_a)block_a;


- (void)calcCpuUsage:(McProcessInfoData *)processData;

//- (void)getProcessIcon:(McProcessInfoData *)processData;

- (void)sortProcess:(NSMutableArray *) array 
          orderEnum:(ProcessOrderEnum) orderEnum 
              isAsc:(BOOL) isAsc;

- (void)getTotalCPU:(float *)totalCPU totalMemory:(uint64 *)memory;

@end
