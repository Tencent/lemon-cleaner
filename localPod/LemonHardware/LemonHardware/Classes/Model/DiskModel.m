//
//  DiskModel.m
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "DiskModel.h"

#define DISK_PLIST @"disk.plist"

@implementation DiskZoneModel

-(NSString *)description{
    return [NSString stringWithFormat:@"diskName = %@, maxSize= %lld, leftSize = %lld, isMaindisk = %d", self.diskName, self.maxSize, self.leftSize, self.isMainDisk];
}

@end

@implementation DiskModel

-(instancetype)init{
    self = [super init];
    if (self) {
        self.diskZoneArr = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(BOOL)getHardWareInfo{
//    __weak DiskModel *weakSelf = self;
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self writeInfoToToFile];
        [self readFromFile];
        self.isInit = YES;
//    });
    
    return YES;
}

-(float)getAllUsableBytes{
    if (@available(macOS 10.13, *)) {
        NSError *error = nil;
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:NSHomeDirectory()];
        NSDictionary *results = [fileURL resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForImportantUsageKey] error:&error];
        if (!results) {
            NSLog(@"Error retrieving resource keys");
            return 0;
        }
        //    NSLog(@"float Available capacity for important usage: %lf",[[results objectForKey:NSURLVolumeAvailableCapacityForImportantUsageKey] floatValue]);
        return [[results objectForKey:NSURLVolumeAvailableCapacityForImportantUsageKey] floatValue];
    }else{
        return 0;
    }
}

-(void)writeInfoToToFile{
    NSString *pathName = [self getHardWareInfoPathByName:DISK_PLIST];
    NSString *tempPathName = [self getHardWareInfoTempPathByName:DISK_PLIST];
    
    // 先输出到临时文件，再原子性覆盖目标文件.确保多线程下文件安全
    // mv 读取线程安全​​：其他线程要么看到旧文件，要么看到新文件，不会读到损坏的中间状态。
    NSString *shellString = [NSString stringWithFormat:@"system_profiler SPStorageDataType -xml > \"%@\" && mv \"%@\" \"%@\"", tempPathName, tempPathName, pathName];
    @try{
        [QMShellExcuteHelper excuteCmd:shellString];
    }
    @catch(NSException *exception){
        NSLog(@"exception = %@", exception);
    }
}

-(BOOL)readFromFile{
    NSString *fileName = [self getHardWareInfoPathByName:DISK_PLIST];
    
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:fileName options:0 error:&error];
    if (!data) {
        NSLog(@"Failed to read file: %@, error: %@", fileName, error);
        return NO;
    }
    
    // 使用NSPropertyListSerialization解析
    id propertyList = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
    if (!propertyList) {
        NSLog(@"Failed to parse plist: %@", error);
        return NO;
    }
    
    // 检查解析结果是否为数组
    if (![propertyList isKindOfClass:[NSArray class]]) {
        NSLog(@"Plist root is not an array");
        return NO;
    }
    NSArray *diskArr = (NSArray *)propertyList;
    if ([diskArr count] == 0) {
        NSLog(@"Empty diskArr");
        return NO;
    }

    NSDictionary *diskDic = [diskArr objectAtIndex:0];
    if (diskDic == nil) {
        NSLog(@"%s, diskDic is nil", __FUNCTION__);
        return NO;
    }
    NSArray *_items = [diskDic objectForKey:@"_items"];
    if([_items count] == 0){
        NSLog(@"%s, _items is nil", __FUNCTION__);
        return NO;
    }
    
    for (NSDictionary *itemDic in _items) {
        NSString *mountPoint = [itemDic objectForKey:@"mount_point"];
        if ([itemDic[@"writable"] isEqualToString:@"no"]) {
            continue;
        }
        NSDictionary *physDic = [itemDic objectForKey:@"physical_drive"];
        NSString *diskName = [physDic objectForKey:@"device_name"];
        if ([diskName isEqualToString:@"Disk Image"] || [diskName isEqualToString:@"Recovery"]) {
            continue;
        }
        DiskZoneModel *zoneModel = [[DiskZoneModel alloc] init];
        zoneModel.diskName = [itemDic objectForKey:@"_name"];
        zoneModel.maxSize = [[itemDic objectForKey:@"size_in_bytes"] longLongValue];
        zoneModel.leftSize = [[itemDic objectForKey:@"free_space_in_bytes"] longLongValue];
        zoneModel.isMainDisk = NO;
        if ([mountPoint isEqualToString:@"/"] || [mountPoint isEqualToString:@"/System/Volumes/Data"]) {
            float newLeftSize = [self getAllUsableBytes];
            if (newLeftSize > 0) {
                zoneModel.leftSize = newLeftSize;
            }
            zoneModel.isMainDisk = YES;
//            NSLog(@"%s, maindisk zoneModel: %@", __FUNCTION__, zoneModel);
        }
        
        [self.diskZoneArr addObject:zoneModel];
    }
    
//    NSLog(@"diskmodel = %@", self);
    
    return YES;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"diskZoneArr arr =[%@]", self.diskZoneArr];
}

@end
