//
//  HardwareDataCenter.m
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "HardwareDataCenter.h"
#import "MachineModel.h"
#import "DisplayModel.h"
#import "MemoryModel.h"
#import "BatteryModel.h"
#import <QMCoreFunction/NSString+Extension.h>
#import <QMCoreFunction/LanguageHelper.h>
#import "HardwareModel.h"

@interface HardwareDataCenter()

@property (nonatomic, strong) MachineModel *machineModel;
@property (nonatomic, strong) DisplayModel *displayModel;
@property (nonatomic, strong) MemoryModel *memoryModel;
@property (nonatomic, strong) BatteryModel *batteryModel;
@property (nonatomic, strong) DiskModel *diskModel;

@property BOOL isReportBatteryCycleCount;

@end

@implementation HardwareDataCenter

-(instancetype)init{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

+(HardwareDataCenter *)shareInstance{
    static HardwareDataCenter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HardwareDataCenter alloc] init];
        instance.isReportBatteryCycleCount = NO;
    });
    
    return instance;
}

//获取所有的总信息
-(void)getAllHardwareInfoWithBlock:(InfoBlock) infoBlock{
    self.machineModel = [[MachineModel alloc] init];
    self.displayModel = [[DisplayModel alloc] init];
    self.memoryModel = [[MemoryModel alloc] init];
    self.batteryModel = [[BatteryModel alloc] init];
    self.diskModel = [[DiskModel alloc] init];
    
    dispatch_queue_t hardwareQueue = dispatch_queue_create("hardwareQueue", DISPATCH_QUEUE_CONCURRENT);
    //判断所有的数据是否初始化
    //磁盘信息
    dispatch_async(hardwareQueue, ^{
        //        if(!self.diskModel.isInit)
        [self.diskModel getHardWareInfo];
    });
    //机器信息
    dispatch_async(hardwareQueue, ^{
//        if(!self.machineModel.isInit)
            [self.machineModel getHardWareInfo];
    });
    //显卡信息
    dispatch_async(hardwareQueue, ^{
//        if(!self.displayModel.isInit)
            [self.displayModel getHardWareInfo];
    });
    //内存信息
    dispatch_async(hardwareQueue, ^{
//        if(!self.memoryModel.isInit)
            [self.memoryModel getHardWareInfo];
    });
    //电池信息
    dispatch_async(hardwareQueue, ^{
//        if(!self.batteryModel.isInit)
            [self.batteryModel getHardWareInfo];
    });
    
    //栅栏函数
    dispatch_barrier_async(hardwareQueue, ^{
//        NSLog(@"获取所有信息结束");
//        NSLog(@"machineModel = %@", self.machineModel);
//        NSLog(@"displayModel = %@", self.displayModel);
//        NSLog(@"memoryModel = %@", self.memoryModel);
//        NSLog(@"batteryModel = %@", self.batteryModel);
//        NSLog(@"diskModel = %@", self.diskModel);
        //组装信息回调
        
        NSMutableArray *infoArr = [[NSMutableArray alloc] initWithCapacity:5];
        //硬盘信息组装
        HardwareModel *diskModel = [[HardwareModel alloc] init];
        diskModel.iconName = @"disk";
        diskModel.hardwareType = HardwareTypeDisk;
        diskModel.categoryName = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_1", nil, [NSBundle bundleForClass:[self class]], @"");
        NSInteger diskIndex = 1;
        for (DiskZoneModel *zoneModel in self.diskModel.diskZoneArr) {
            HardwareInfoModel *diskinfoModel = [[HardwareInfoModel alloc] init];
            diskinfoModel.name1 = [NSString stringWithFormat:@"%@%ld",NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_1", nil, [NSBundle bundleForClass:[self class]], @""), diskIndex];
            diskinfoModel.value1 = zoneModel.diskName == nil ? @"" : zoneModel.diskName;
            diskinfoModel.name2 = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_2", nil, [NSBundle bundleForClass:[self class]], @"");
            diskinfoModel.value2 = [NSString stringFromDiskSize:zoneModel.leftSize];
            diskinfoModel.name3 = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_3", nil, [NSBundle bundleForClass:[self class]], @"");
            diskinfoModel.value3 = [NSString stringFromDiskSize:zoneModel.maxSize];
            [diskModel addHardwareInfoModel:diskinfoModel];
            diskIndex++;
        }
        [infoArr addObject:diskModel];
        
        //处理器信息组装
        HardwareModel *processorModel = [[HardwareModel alloc] init];
        processorModel.iconName = @"processor";
        processorModel.hardwareType = HardwareTypeProcessor;
        processorModel.categoryName = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_4", nil, [NSBundle bundleForClass:[self class]], @"");
        HardwareInfoModel *processerInfoModel = [[HardwareInfoModel alloc] init];
        processerInfoModel.name1 = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_5", nil, [NSBundle bundleForClass:[self class]], @"");
        processerInfoModel.value1 = self.machineModel.cpuName == nil ? @"" : self.machineModel.cpuName;
        //App M1新机器无法获取CPU速度
        if (self.machineModel.cpuSpeed) {
            processerInfoModel.name2 = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_6", nil, [NSBundle bundleForClass:[self class]], @"");
            processerInfoModel.value2 = self.machineModel.cpuSpeed;
        }
        processerInfoModel.name3 = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_7", nil, [NSBundle bundleForClass:[self class]], @"");
        processerInfoModel.value3 = self.machineModel.cpuCores == nil ? @"" : self.machineModel.cpuCores;
        [processorModel addHardwareInfoModel:processerInfoModel];
        //App M1新机器无法获取CPU信息，直接隐藏该行
        if (self.machineModel.cpuName && ![[self.machineModel.cpuName lowercaseString] containsString:@"unknown"]) {
            [infoArr addObject:processorModel];
        } else {
            NSLog(@"%s, self.machineModel.cpuName = %@", __FUNCTION__, self.machineModel.cpuName);
        }
        //显卡信息
        HardwareModel *displayModel = [[HardwareModel alloc] init];
        displayModel.iconName = @"graphic";
        displayModel.hardwareType = HardwareTypeDisplay;
        displayModel.categoryName = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_8", nil, [NSBundle bundleForClass:[self class]], @"");
        for (GraphicModel *graphicModel in self.displayModel.grapicArr) {
            HardwareInfoModel *grapicInfoModel = [[HardwareInfoModel alloc] init];
            grapicInfoModel.name1 = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_9", nil, [NSBundle bundleForClass:[self class]], @"");
            grapicInfoModel.value1 = graphicModel.graphicModel == nil ? @"" : graphicModel.graphicModel;
            //App M1新机器无法获取显存大小
            if (graphicModel.graphicSize) {
                grapicInfoModel.name2 = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_10", nil, [NSBundle bundleForClass:[self class]], @"");
                grapicInfoModel.value2 = graphicModel.graphicSize;
            }
            for (ScreenModel *model in graphicModel.screenArr) {
                if(model.isMainScreen){
                    grapicInfoModel.name3 = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_11", nil, [NSBundle bundleForClass:[self class]], @"");
                    grapicInfoModel.value3 = model.resolution == nil ? @"" : model.resolution;
                }
            }
            [displayModel addHardwareInfoModel:grapicInfoModel];
        }
        [infoArr addObject:displayModel];
        
        //内存信息
        HardwareModel *memModel = [[HardwareModel alloc] init];
        memModel.iconName = @"memory";
        memModel.hardwareType = HardwareTypeMemory;
        memModel.categoryName = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_12", nil, [NSBundle bundleForClass:[self class]], @"");
        NSInteger memCount = [self.memoryModel.memBankArr count];
        NSInteger loopCount = memCount / 2;
        
        for (NSInteger memIndex = 0; memIndex < loopCount; memIndex = memIndex + 1) {
            //每次取两个出来组装
            NSInteger arrIndex = memIndex * 2;
            if ((arrIndex + 1) < memCount) {
                HardwareInfoModel *memInfoModel = [[HardwareInfoModel alloc] init];
                MemBankModel *memBankModel1 = [self.memoryModel.memBankArr objectAtIndex:arrIndex];
                MemBankModel *memBankModel2 = [self.memoryModel.memBankArr objectAtIndex:arrIndex + 1];
                memInfoModel.name1 = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_NSString_13", nil, [NSBundle bundleForClass:[self class]], @""), arrIndex+1];
                memInfoModel.value1 = [NSString stringWithFormat:@"%@ %@(%@)", memBankModel1.memSize, memBankModel1.memBankType, memBankModel1.memSpeed];
                memInfoModel.name2 = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_NSString_13", nil, [NSBundle bundleForClass:[self class]], @""), arrIndex+2];
                memInfoModel.value2 = [NSString stringWithFormat:@"%@ %@(%@)", memBankModel2.memSize, memBankModel2.memBankType, memBankModel2.memSpeed];
                [memModel addHardwareInfoModel:memInfoModel];
            }
        }
        MemBankModel *memBankModel1 = [self.memoryModel.memBankArr lastObject];
        if ((memCount > 0) && (memCount == (loopCount * 2 + 1))) {
            HardwareInfoModel *memInfoModel = [[HardwareInfoModel alloc] init];
            memInfoModel.name1 = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_NSString_13", nil, [NSBundle bundleForClass:[self class]], @""), memCount];
            if (memBankModel1.memBankType) {
                memInfoModel.value1 = [NSString stringWithFormat:@"%@ %@(%@)", memBankModel1.memSize, memBankModel1.memBankType, memBankModel1.memSpeed];
            } else {
                //适配AppM1新机器，只显示内存大小
                memInfoModel.value1 = [NSString stringWithFormat:@"%@", memBankModel1.memSize];
            }
            [memModel addHardwareInfoModel:memInfoModel];
        }
        //App M1新机器无法获取CPU信息，直接隐藏该行
        if (memBankModel1.memSize) {
            [infoArr addObject:memModel];
        } else {
            NSLog(@"%s, memBankModel1.memSize = %@", __FUNCTION__, memBankModel1.memSize);
        }
        //电池信息
        if(self.batteryModel.isExistBattery){
            HardwareModel *battModel = [self assembleBattModel:self.batteryModel];
            
            [infoArr addObject:battModel];
        }
        
        NSString *macName = self.machineModel.machineName;
        NSString *systemVersion = self.machineModel.systemVersion;
        if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
            systemVersion = [systemVersion stringByReplacingOccurrencesOfString:@"Version" withString:@"版本"];
            systemVersion = [systemVersion stringByReplacingOccurrencesOfString:@"Build" withString:@"版号"];
        }else{
            systemVersion = [systemVersion stringByReplacingOccurrencesOfString:@"版本" withString:@"Version"];
            systemVersion = [systemVersion stringByReplacingOccurrencesOfString:@"版号" withString:@"Build"];
        }
        NSString *value = nil;
        if (self.machineModel.yearString == nil) {
            value = [NSString stringWithFormat:@"(%@)", systemVersion];;
        }else{
            value = [NSString stringWithFormat:@"(%@,%@)", self.machineModel.yearString, systemVersion];
        }
        
        NSMutableDictionary *infoDic = [[NSMutableDictionary alloc] init];
        if(macName != nil){
            [infoDic setObject:macName forKey:@"name"];
        }
        if(value != nil){
            [infoDic setObject:value forKey:@"value"];
        }
        
        infoBlock(infoArr, infoDic);
    });
}

//获取机器是否有电池
-(BOOL)getIsHaveBattery{
    if (self.batteryModel == nil) {
        return NO;
    }
    return self.batteryModel.haveBattery;
}

-(HardwareModel *)assembleBattModel:(BatteryModel *)batteryModel{
    HardwareModel *battModel = [[HardwareModel alloc] init];
    battModel.iconName = @"battery";
    battModel.hardwareType = HardwareTypeElectroic;
    battModel.isCharge = batteryModel.ischarge;
    battModel.isExternalCharge = batteryModel.batExternalCharge;
    battModel.elecPercentage = batteryModel.percentage;
    battModel.categoryName = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_14", nil, [NSBundle bundleForClass:[self class]], @"");
    HardwareInfoModel *battInfoModel = [[HardwareInfoModel alloc] init];
    battInfoModel.name1 = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_15", nil, [NSBundle bundleForClass:[self class]], @"");
    if (batteryModel.currentCapacity) {
        battInfoModel.value1 = [NSString stringWithFormat:@"%@ (%@mAh/%@mAh)",batteryModel.percentage, batteryModel.currentCapacity, batteryModel.maxCapacity];
    } else {
        //苹果M1机器没有具体容量信息
        battInfoModel.value1 = [NSString stringWithFormat:@"%@",batteryModel.percentage];
    }
    
    battInfoModel.name2 = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_16", nil, [NSBundle bundleForClass:[self class]], @"");
    battInfoModel.value2 = batteryModel.loopCount == nil ? @"" : batteryModel.loopCount;
    
    NSString *status = nil;
    if([batteryModel.status isEqualToString:@"Good"]){
        status = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_17", nil, [NSBundle bundleForClass:[self class]], @"");
    }else{
        status = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_18", nil, [NSBundle bundleForClass:[self class]], @"");
    }
    battInfoModel.name3 = NSLocalizedStringFromTableInBundle(@"HardwareDataCenter_getAllHardwareInfoWithBlock_1558009402_19", nil, [NSBundle bundleForClass:[self class]], @"");
    if (batteryModel.healthMaxCapacity) {
        battInfoModel.value3 = [status stringByAppendingFormat:@"(%@)",batteryModel.healthMaxCapacity];
    } else {
        battInfoModel.value3 = status;
    }
    [battModel addHardwareInfoModel:battInfoModel];
    
    return battModel;
}

-(void)addDicWithName:(NSString *)name value:(NSString *)value arr:(NSMutableArray *)arr{
    if(value == nil){
        [arr addObject:@{@"name":name, @"value":@""}];
    }else{
        [arr addObject:@{@"name":name, @"value":value}];
    }
}

//获取机器信息
-(BOOL)getMachineInfo{
    BOOL ret = [self.machineModel getHardWareInfo];
    return ret;
}

//获取显卡信息
-(BOOL)getDisplayInfo{
    BOOL ret = [self.displayModel getHardWareInfo];
    return ret;
}

//获取内存信息
-(BOOL)getMemoryInfo{
    BOOL ret = [self.memoryModel getHardWareInfo];
    return ret;
}

//获取电池信息
-(void)getBatteryInfo:(GetBattInfoBlock) infoBlock{
    BatteryModel *battModel = [[BatteryModel alloc] init];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL ret = [battModel getHardWareInfo];
        HardwareModel *hardModel = [self assembleBattModel:battModel];
        infoBlock(ret, hardModel);
    });
}

@end
