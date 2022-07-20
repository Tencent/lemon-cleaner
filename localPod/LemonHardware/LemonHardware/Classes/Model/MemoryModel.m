//
//  MemoryModel.m
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "MemoryModel.h"

#define MEM_PLIST @"mem.plist"

@implementation MemBankModel

-(NSString *)description{
    return [NSString stringWithFormat:@"memBankType = %@, memSize = %@, memSpeed = %@, memStatus = %@", self.memBankType, self.memSize, self.memSpeed, self.memStatus];
}

@end

@implementation MemoryModel

-(instancetype)init{
    self = [super init];
    if (self) {
        self.memBankArr = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(BOOL)getHardWareInfo{
    //    __weak MemoryModel *weakSelf = self;
    //    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    [self writeToFile];
    [self readFromFile];
    self.isInit = YES;
    //    });
    
    return YES;
}

-(void)writeToFile{
    NSString *pathName = [self getHardWareInfoPathByName:MEM_PLIST];
    pathName = [pathName stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
    NSString *shellString = [NSString stringWithFormat:@"system_profiler SPMemoryDataType -xml > %@", pathName];
    @try{
        [QMShellExcuteHelper excuteCmd:shellString];
    }
    @catch(NSException *exception){
        NSLog(@"exception = %@", exception);
    }
}

-(BOOL)readFromFile{
    NSString *fileName = [self getHardWareInfoPathByName:MEM_PLIST];
    NSArray *memArr = [[NSArray alloc] initWithContentsOfFile:fileName];
    if ([memArr count] == 0) {
        return NO;
    }
    NSDictionary *memDic = [memArr objectAtIndex:0];
    if (memDic == nil) {
        return NO;
    }
    NSArray *_itemsArr0 =memDic[@"_items"];
    if ([_itemsArr0 count] == 0) {
        return NO;
    }
    NSDictionary *itemDic = [_itemsArr0 objectAtIndex:0];
    if (itemDic == nil) {
        return NO;
    }
    NSArray *_itemsArr1 = [itemDic objectForKey:@"_items"];
    if ([_itemsArr1 count] == 0) {
        //适配 AppleM1 新机器，只显示有内存大小：16GB
        NSString *memSize = itemDic[@"SPMemoryDataType"];
        if (memSize) {
            MemBankModel *bankModel = [[MemBankModel alloc] init];
            bankModel.memSize = memSize;
            [self.memBankArr addObject:bankModel];
            return YES;
        } else {
            return NO;
        }
    }
    for (NSDictionary *memBankDic in _itemsArr1) {
        NSString *dimmType = memBankDic[@"dimm_type"];
        if([dimmType isEqualToString:@"empty"]){
            continue;
        }
        MemBankModel *bankModel = [[MemBankModel alloc] init];
        bankModel.memBankType = memBankDic[@"dimm_type"];
        bankModel.memSize = memBankDic[@"dimm_size"];
        bankModel.memSpeed = memBankDic[@"dimm_speed"];
        bankModel.memStatus = memBankDic[@"dimm_status"];
        [self.memBankArr addObject:bankModel];
    }
    
    return YES;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"memBankArr = %@", self.memBankArr];
}

@end
