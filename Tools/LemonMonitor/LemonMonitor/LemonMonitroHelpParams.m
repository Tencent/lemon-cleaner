//
//  LemonMonitroHelpParams.m
//  LemonMonitor
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "LemonMonitroHelpParams.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>

@interface LemonMonitroHelpParams ()
@property (nonatomic, strong) NSTimer *memTopTimer;
@end

@implementation LemonMonitroHelpParams
+ (LemonMonitroHelpParams*)sharedInstance
{
    static LemonMonitroHelpParams* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}
- (void)startStatMemory
{
    self.memTopTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(memoryTopRepeater) userInfo:nil repeats:YES];
    [self.memTopTimer fire];
}
- (void)stopStatMemory
{
    [self.memTopTimer invalidate];
    self.memTopTimer = nil;
}
- (UInt64)getMemorySizeFromString:(NSString*)strVal{
    UInt64 memSize = 0;
    int per = 1000;
    if ([strVal hasSuffix:@"B+"] || [strVal hasSuffix:@"B"]) {
        if ([strVal hasSuffix:@"B+"]) {
            memSize = [[strVal substringToIndex:[strVal length] - [@"B+" length]] longLongValue];
        } else {
            memSize = [[strVal substringToIndex:[strVal length] - [@"B" length]] longLongValue];
        }
        memSize = memSize;
    } else if ([strVal hasSuffix:@"K+"] || [strVal hasSuffix:@"K"]) {
        if ([strVal hasSuffix:@"K+"]) {
            memSize = [[strVal substringToIndex:[strVal length] - [@"K+" length]] longLongValue];
        } else {
            memSize = [[strVal substringToIndex:[strVal length] - [@"K" length]] longLongValue];
        }
        memSize = memSize * (per);
    } else if ([strVal hasSuffix:@"M+"] || [strVal hasSuffix:@"M"]) {
        if ([strVal hasSuffix:@"M+"]) {
            memSize = [[strVal substringToIndex:[strVal length] - [@"M+" length]] longLongValue];
            if (memSize > 1000) {
                NSLog(@"%@", strVal);
            }
        } else {
            memSize = [[strVal substringToIndex:[strVal length] - [@"M" length]] longLongValue];
        }
        memSize = memSize * (per * per);
    } else if ([strVal hasSuffix:@"G+"] || [strVal hasSuffix:@"G"]) {
        if ([strVal hasSuffix:@"G+"]) {
            memSize = [[strVal substringToIndex:[strVal length] - [@"G+" length]] longLongValue];
        } else {
            memSize = [[strVal substringToIndex:[strVal length] - [@"G" length]] longLongValue];
        }
        memSize = memSize * (per * per * per);
    } else if ([strVal hasSuffix:@"+"]) {
        memSize = [[strVal substringToIndex:[strVal length] - [@"+" length]] longLongValue];
    }
    return memSize;
}
- (void)memoryTopRepeater{
    __weak LemonMonitroHelpParams *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @autoreleasepool{
            //第二个appName会有空格，无法按指定的位置获取值
            //NSString *outputStr = [QMShellExcuteHelper excuteCmd:@"top -l 1 |awk '{print \"PID=\"$1\"  MEM=\"$8\"  PURG=\"$9\"  CMPRS=\"$12}'"];
            NSString *outputStr = [QMShellExcuteHelper excuteCmd:@"top -l 1  -o -mem"];
            //outputStr = [NSString stringWithContentsOfFile:@"/Users/torsysmeng/Desktop/top.log" encoding:NSUTF8StringEncoding error:nil];
            NSArray *portArr = [outputStr componentsSeparatedByString:@"\n"];
            NSMutableArray<McProcessInfoData *> *resArray = [NSMutableArray array];
            
            BOOL start = NO;
            for (NSString *portItem in portArr) {
                
                if (!start && [portItem hasPrefix:@"PID"]) {
                    start = YES;
                    continue;
                }
                if (!start) {
                    continue;
                }
                NSRange cpuR = [portItem rangeOfString:@"0.0"];
                if (cpuR.location == NSNotFound) {
                    continue;
                }
                NSString *pidAndAppname = [portItem substringWithRange:NSMakeRange(0, cpuR.location)];
                int pid = -1;
                NSArray *pidArray = [pidAndAppname componentsSeparatedByString:@" "];
                if (pidArray.count > 0) {
                    pid = [[pidArray objectAtIndex:0] intValue];
                }
                if (pid < 0) {
                    continue;
                }
                NSString *strMem = [portItem substringWithRange:NSMakeRange(cpuR.location + cpuR.length, portItem.length-(cpuR.location + cpuR.length))];
                NSError* error;
                NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[^ ]+" options:0 error:&error];
                NSArray *tempArr = [regex matchesInString:strMem options:0 range:NSMakeRange(0, [strMem length])];
                NSMutableArray *reArr = [NSMutableArray arrayWithArray:tempArr];
                
                UInt64 totalMemory = 0;
                McProcessInfoData *data = [[McProcessInfoData alloc] init];
                for (int i = 0; i < reArr.count; i++) {
                    NSTextCheckingResult *res = [reArr objectAtIndex:i];
                    NSString *strVal = [strMem substringWithRange:res.range];
                    if (i == 4){
                        // MEM
                        UInt64 memSize = [self getMemorySizeFromString:strVal];
                        totalMemory += memSize;
                        //[dic setObject:@(memSize) forKey:@"mem"];
                    } else if (i == 5){
                        //[dic setObject:strVal forKey:@"purg"];
                    } else if (i == 6){
                        // CMPRS (Compressed Memory)
//                        UInt64 compressedMem = [self getMemorySizeFromString:strVal];
                        
                        // 使用 Top命令时可能有两种状态,  状态一: Activity Monitor 中的 Memory 大约等于 top 中的 Memory
                        // 状态二: Activity Monitor 中的 Memory 大约等于  top 中的 (Memory  + CMPRS (Compressed Memory)) .
                        // 状态二的特点是. 一般 top命令结果的 MEM < CMPRS
                        
//                        if(totalMemory < compressedMem){
//                            totalMemory += compressedMem;
//                        }
                        //[dic setObject:@(memSize) forKey:@"cmprs"];
                    }
                }
                

                
                
                if (totalMemory > 0) {
                    //[dic setObject:@(totalMemory) forKey:@"totalMemory"];
                    data.pid = pid;
                    data.resident_size = totalMemory;
                    [resArray addObject:data];
                }
            }
            NSLog(@"%s topMemoryArrayCount: %lu", __FUNCTION__, (unsigned long)resArray.count);
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.topMemoryArray = resArray;
            });
        }
    });
}

@end
