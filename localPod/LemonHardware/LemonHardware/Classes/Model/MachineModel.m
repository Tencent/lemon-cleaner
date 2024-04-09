//
//  MacthineModel.m
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "MachineModel.h"
#include <sys/sysctl.h>
#import "HardwareHeader.h"
#import <QMUICommon/SharedPrefrenceManager.h>
#import "BatteryModel.h"

#define kSIMachineAttributesPath    @"/System/Library/PrivateFrameworks/ServerInformation.framework/Versions/A/Resources/English.lproj/SIMachineAttributes.plist"
#define HARDWARE_PLIST @"hardware.plist"

@interface MachineModel()
{
    NSDictionary * _machineAttributesDict;
}

@end

@implementation MachineModel

-(instancetype)init{
    self = [super init];
    if (self) {
        self.machineName=@"Unknown Mac";
        size_t len=0;
        sysctlbyname("hw.model", NULL, &len, NULL, 0);
        if (len) {
            NSMutableData *data=[NSMutableData dataWithLength:len];
            sysctlbyname("hw.model", [data mutableBytes], &len, NULL, 0);
            self.machineName=[NSString stringWithUTF8String:[data bytes]];
        }
    }
    
    return self;
}

-(BOOL)getHardWareInfo{
    //    NSOperationQueue *machineInfoQueue = [[NSOperationQueue alloc] init];
    //    machineInfoQueue.maxConcurrentOperationCount = 2;
    
    //外部来开多线程
    [self getSystemVersion];
    [self getMachineInfo];
    NSString *yearString = [SharedPrefrenceManager getString:MAC_MODEL_DETAIL_INFO];
    if (yearString != nil) {
        self.yearString = yearString;
    }else{
        yearString = [self _macModelDetailInfo];
        if (yearString != nil) {
            yearString  = [yearString stringByReplacingOccurrencesOfString:@"(" withString:@""];
            yearString  = [yearString stringByReplacingOccurrencesOfString:@")" withString:@""];
            self.yearString = yearString;
            [SharedPrefrenceManager putString:self.yearString withKey:MAC_MODEL_DETAIL_INFO];
        }
    }
    self.isInit = YES;
    
    //    __weak MachineModel *weakSelf = self;
    //    NSBlockOperation *machineInfoOp = [NSBlockOperation blockOperationWithBlock:^{
    //        [weakSelf getMachineInfo];
    //    }];
    //
    ////    NSBlockOperation *thunderInfoOp = [NSBlockOperation blockOperationWithBlock:^{
    //////        [weakSelf getThunderInfo];
    ////        [weakSelf getSystemVersion];
    ////    }];
    //
    //    NSBlockOperation *yearStringOp = [NSBlockOperation blockOperationWithBlock:^{
    //        NSString *yearString = [SharedPrefrenceManager getString:MAC_MODEL_DETAIL_INFO];
    //        if (yearString != nil) {
    //            weakSelf.yearString = yearString;
    //        }else{
    //            weakSelf.yearString = [weakSelf _macModelDetailInfo];
    //            if (weakSelf != nil) {
    //                [SharedPrefrenceManager putString:weakSelf.yearString withKey:MAC_MODEL_DETAIL_INFO];
    //            }
    //        }
    //
    //    }];
    //    [yearStringOp setCompletionBlock:^{
    //        NSLog(@"%@ = %@", [weakSelf class], weakSelf);
    //    }];
    //
    //    [yearStringOp addDependency:machineInfoOp];
    ////    [yearStringOp addDependency:thunderInfoOp];
    //
    //    [machineInfoQueue addOperation:machineInfoOp];
    ////    [machineInfoQueue addOperation:thunderInfoOp];
    //    [machineInfoQueue addOperation:yearStringOp];
    
    
    return YES;
}

-(void)getSystemVersion{
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    NSString *sysVersion = [processInfo operatingSystemVersionString];
//    NSLog(@"sysVersion = %@", sysVersion);
    self.systemVersion = sysVersion;
//    NSLog(@"getSystemVersion = %@", sysVersion);
}

-(BOOL)getMachineInfo{
    [self writeToFile];
    [self readFromFile];
    
//    NSLog(@"getMachineInfo = %@", self);
    
    return YES;
}

-(void)writeToFile{
    NSString *pathName = [self getHardWareInfoPathByName:HARDWARE_PLIST];
    pathName = [pathName stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
    NSTask * task = [[NSTask alloc] init];
    // apply settings for task
    [task setLaunchPath: @"/bin/bash"];
    [task setArguments: [NSArray arrayWithObjects:@"-c", [@"system_profiler SPHardwareDataType SPMemoryDataType SPDisplaysDataType -xml > " stringByAppendingString:pathName], nil]];
    
    @try
    {
        // set it off
        [task launch];
        
        // read data and convert NSArray
        [task waitUntilExit];
    }
    @catch(NSException *exception)
    {
    }
}

-(BOOL)readFromFile{
    NSString *fileName = [self getHardWareInfoPathByName:HARDWARE_PLIST];
    NSArray *hardwareArr = [[NSArray alloc] initWithContentsOfFile:fileName];
    if ([hardwareArr count] == 0) {
        return NO;
    }
    NSDictionary *hardwareDic = [hardwareArr objectAtIndex:0];
    if (hardwareDic == nil) {
        return NO;
    }
    if (![[hardwareDic allKeys] containsObject:@"_items"]) {
        return NO;
    }
    NSArray *_itemsArr = [hardwareDic objectForKey:@"_items"];
    if ([_itemsArr count] == 0) {
        return NO;
    }
    
    NSDictionary *hardwareInfoDic = [_itemsArr objectAtIndex:0];
    //拿机器名
    self.machineName = hardwareInfoDic[@"machine_name"];
    
    //拿处理器名
    if(hardwareInfoDic[@"cpu_type"] != nil){
        self.cpuName = hardwareInfoDic[@"cpu_type"];
    } else if (hardwareInfoDic[@"chip_type"] != nil) {
        self.cpuName = hardwareInfoDic[@"chip_type"];
    } else{
        self.cpuName = [self getCpuName];
    }
    
    //拿cpu速度
    self.cpuSpeed = hardwareInfoDic[@"current_processor_speed"];
    
    //拿核心数
    self.cpuCores = hardwareInfoDic[@"number_processors"];
    
    //拿二级缓存
    self.L2Cache = hardwareInfoDic[@"l2_cache_core"];
    
    //拿三级缓存
    self.L3Cache = hardwareInfoDic[@"l3_cache"];
    
    return YES;
}

#pragma mark-
#pragma mark cpu info

- (NSString *)getCpuName
{
    char cpumodel[64];
    size_t size = sizeof(cpumodel);
    if (sysctlbyname("machdep.cpu.brand_string", cpumodel, &size, NULL, 0))
    {
        cpumodel[0] = '\0';
    }
    NSString * cpuName = [NSString stringWithUTF8String:cpumodel];
    cpuName = [cpuName stringByReplacingOccurrencesOfString:@"(R)" withString:@""];
    cpuName = [cpuName stringByReplacingOccurrencesOfString:@"(TM)" withString:@""];
    NSRange range = [cpuName rangeOfString:@"-"];
    if (range.length != 0)
    {
        return [cpuName substringToIndex:range.location];
    }
    return @"Intel";
}

-(BOOL)getThunderInfo{
    NSString *shellString = @"system_profiler SPThunderboltDataType";
    NSString *retString = [QMShellExcuteHelper excuteCmd:shellString];
//    NSLog(@"retString = %@", retString);
    if ((retString == nil) || ([retString isEqualToString:@""])) {
        return NO;
    }
    if ([retString containsString:THUNDERBOLT]) {
        //通过range来拿数量
        self.thunderbolts = [self getSubstringCountBySubString:THUNDERBOLT withString:retString];
    }
    if ([retString containsString:PORT]) {
        //通过range来拿数量
        self.ports = [self getSubstringCountBySubString:PORT withString:retString];
    }
    
//    NSLog(@"getThunderInfo = %@", self);
    
    return YES;
}

-(NSInteger)getSubstringCountBySubString:(NSString *)subString withString:(NSString *)string{
    NSUInteger count = 0, length = [string length];
    @try{
        NSRange range = NSMakeRange(0, length);
        while(range.location != NSNotFound)
        {
            range = [string rangeOfString:subString options:0 range:range];
            if(range.location != NSNotFound)
            {
                range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
                count++;
            }
        }
    }@catch(NSException *exception){
//        NSLog(@"getSubstringCountBySubString exception is = %@", exception);
    }
    
    
    return count;
}

- (NSString *)_macModelDetailInfo
{
    NSString * serial = getSerialNumber();
    
    // 获取信息
    NSString * macModel = getMacModelInfo(serial);
    if (macModel)
    {
        NSRange range = [macModel rangeOfString:@"("];
        if (range.length != 0 && range.location != 0)
        {
            macModel = [macModel substringFromIndex:range.location];
        }
        return macModel;
    }
    
    return nil;
    
    //    // 读取配置信息
    //    NSDictionary * attributesDict = [_machineAttributesDict objectForKey:self.machineName];
    //    if (attributesDict)
    //    {
    //        NSString * marketingModel = [[attributesDict objectForKey:@"_LOCALIZABLE_"] objectForKey:@"marketingModel"];
    //        return marketingModel;
    //    }
    //    // 如果没有配置
    //    NSDate * date = manufacureDate(serial);
    //    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    //    [format setDateFormat:@"yyyy/MMMM/"];
    //    NSString * str = [format stringFromDate:date];
    //
    //    NSDateFormatter *formatWeek = [[NSDateFormatter alloc] init];
    //    [formatWeek setDateFormat:@"F"];
    //    str = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"MachineModel__macModelDetailInfo_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""), str, [formatWeek stringFromDate:date]];
    //
    //    macModel = [NSString stringWithFormat:@"(%@)", str];
    //    return macModel;
}

NSString * getSerialNumber()
{
    CFStringRef serialNumber = NULL;
    io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                                 IOServiceMatching("IOPlatformExpertDevice"));
    
    if (platformExpert) {
        CFTypeRef serialNumberAsCFString =
        IORegistryEntryCreateCFProperty(platformExpert,
                                        CFSTR(kIOPlatformSerialNumberKey),
                                        kCFAllocatorDefault, 0);
        if (serialNumberAsCFString) {
            serialNumber = serialNumberAsCFString;
        }
        
        IOObjectRelease(platformExpert);
    }
    
    return (__bridge_transfer NSString *)(serialNumber);
}

NSString * getMacModelInfo(NSString * serial)
{
    NSUInteger length = serial.length;
    if (10 < length && length  < 13)
    {
        // model key
        NSString * modelKey = [serial substringFromIndex:serial.length - (length == 11 ? 3 : 4)];
        if (!modelKey)
            return nil;
        NSArray * laungageArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
        NSString * languageKey = @"en";
        if (laungageArray.count > 0)
            languageKey = [laungageArray objectAtIndex:0];
        // local cache
        NSString * path = [@"~/library/preferences/com.apple.systemprofiler.plist" stringByStandardizingPath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            NSDictionary * profilerDict = [NSDictionary dictionaryWithContentsOfFile:path];
            NSDictionary * namesDict = [profilerDict objectForKey:@"CPU Names"];
            if (namesDict && namesDict.count > 0)
            {
                for (NSString * key in namesDict.allKeys)
                {
                    if ([key hasPrefix:modelKey])
                    {
                        if ([key rangeOfString:languageKey].length != 0)
                            return [namesDict objectForKey:key];
                    }
                }
                // 合并语言
                NSRange range = [languageKey rangeOfString:@"-"];
                if (range.length != 0)
                {
                    languageKey = [languageKey substringToIndex:range.location];
                }
                for (NSString * key in namesDict.allKeys)
                {
                    if ([key hasPrefix:modelKey])
                    {
                        if ([key rangeOfString:languageKey].length != 0)
                            return [namesDict objectForKey:key];
                    }
                }
                
                return [[namesDict allValues] objectAtIndex:0];
            }
        }
        NSString * code = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        if (code)
            languageKey = [NSString stringWithFormat:@"%@_%@", languageKey, code];
        // http 请求
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"http://support-sp.apple.com/sp/product?cc=%@&lang=%@",
                                            modelKey, languageKey]];
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url
                                                                cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                            timeoutInterval:5];
        NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        __block NSData *retData = nil;
        NSURLSessionDataTask *task = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (!error) {
                retData = data;
            }
        }];
        [task resume];
        //        NSData * data = [NSURLConnection sendSynchronousRequest:request
        //                                              returningResponse:nil
        //                                                          error:nil];
        if (!retData)
            return nil;
        NSString * str = [NSString stringWithUTF8String:retData.bytes];
        NSRange congfigCodeRange1 = [str rangeOfString:@"<configCode>"];
        NSRange congfigCodeRange2 = [str rangeOfString:@"</configCode>"];
        NSUInteger l1 = NSMaxRange(congfigCodeRange1);
        if (congfigCodeRange1.length > 0
            && congfigCodeRange2.length > 0
            && congfigCodeRange2.location > l1)
        {
            NSString * result = [str substringWithRange:NSMakeRange(l1, congfigCodeRange2.location - l1)];
            return result;
        }
    }
    return nil;
}

int indexOf(char *str1,char str2)
{
    size_t length = strlen(str1);
    for (int i = 0; i < length; i++)
    {
        if (str1[i] == str2)
            return i;
    }
    return -1;
}

NSDate * manufacureDate(NSString *serial)
{
    if (!serial)
        return nil;
    const char * serialChar = [serial UTF8String];
    size_t length = strlen(serialChar);
    if (10 < length && length  < 13)
    {
        int est_year = 0;
        int est_week = 0;
        if (length == 11)
        {
            char year = tolower(serialChar[2]);
            est_year = 2000 + indexOf("   3456789012", year);
            
            char week[3] = {0};
            strncpy(week,serialChar+3,2);
            est_week = atoi(week);
        }
        else
        {
            char * alpha_year = "cdfghjklmnpqrstvwxyz";
            char year = tolower(serialChar[3]);
            est_year = 2010 + (indexOf(alpha_year, year) / 2);
            int est_half = indexOf(alpha_year, year) % 2;
            
            char week= tolower(serialChar[4]);
            char * alpha_week = " 123456789cdfghjklmnpqrtvwxy";
            est_week = indexOf(alpha_week, week) + (est_half * 26);
        }
        NSDateComponents *comps = [[NSDateComponents alloc] init];
        [comps setYear:est_year];
        [comps setWeekOfYear:est_week];
        [comps setWeekday:0];
        NSCalendar * calendar = [NSCalendar currentCalendar];
        return [calendar dateFromComponents:comps];
    }
    return nil;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"machineName = %@, yearString = %@, thunderbolts = %ld, ports = %ld, cpuName = %@, cpuSpeed = %@, cpuCores = %@, L2Cache = %@, L3Cache = %@", self.machineName, self.yearString, self.thunderbolts, self.ports, self.cpuName, self.cpuSpeed, self.cpuCores, self.L2Cache, self.L3Cache];
}

@end

// MacBook Pro https://support.apple.com/zh-cn/HT201300
NSString * const kMacBookPro_15_3 = @"Mac15,3";
NSString * const kMacBookPro_15_6 = @"Mac15,6";
NSString * const kMacBookPro_15_8 = @"Mac15,8";
NSString * const kMacBookPro_15_10 = @"Mac15,10";
NSString * const kMacBookPro_15_7 = @"Mac15,7";
NSString * const kMacBookPro_15_9 = @"Mac15,9";
NSString * const kMacBookPro_15_11 = @"Mac15,11";
NSString * const kMacBookPro_14_5 = @"Mac14,5";
NSString * const kMacBookPro_14_9 = @"Mac14,9";
NSString * const kMacBookPro_14_6 = @"Mac14,6";
NSString * const kMacBookPro_14_10 = @"Mac14,10";
NSString * const kMacBookPro_early_18_3 = @"MacBookPro18,3";
NSString * const kMacBookPro_early_18_4 = @"MacBookPro18,4";
NSString * const kMacBookPro_early_18_1 = @"MacBookPro18,1";
NSString * const kMacBookPro_early_18_2 = @"MacBookPro18,2";

// MacBook Air https://support.apple.com/zh-cn/102869
NSString * const kMacBookAir_15_13 = @"Mac15,13";
NSString * const kMacBookAir_15_12 = @"Mac15,12";
NSString * const kMacBookAir_14_15 = @"Mac14,15";
NSString * const kMacBookAir_14_2 = @"Mac14,2";
NSString * const kMacBookAir_early_10_1 = @"MacBookAir10,1";

@implementation MachineModel (LHScreen)

+ (BOOL)isLiquidScreen {
    static BOOL isLiquid = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isLiquid = [self __isLiquidScreen];
    });
    return isLiquid;
}

#pragma mark - private

+ (BOOL)__isLiquidScreen {
    BOOL isLiquid = NO;
    MachineModel *model = [[MachineModel alloc] init];
    NSString *machineName =  model.machineName ? : @"Unknown Mac";
    NSArray *list = @[
        kMacBookPro_15_3,
        kMacBookPro_15_6,
        kMacBookPro_15_8,
        kMacBookPro_15_10,
        kMacBookPro_15_7,
        kMacBookPro_15_9,
        kMacBookPro_15_11,
        kMacBookPro_14_5,
        kMacBookPro_14_9,
        kMacBookPro_14_6,
        kMacBookPro_14_10,
        kMacBookPro_early_18_3,
        kMacBookPro_early_18_4,
        kMacBookPro_early_18_1,
        kMacBookPro_early_18_2,
        kMacBookAir_15_13,
        kMacBookAir_15_12,
        kMacBookAir_14_15,
        kMacBookAir_14_2,
        kMacBookAir_early_10_1
    ];
    if ([list containsObject:machineName]) {
        isLiquid = YES;
    } else if ([machineName containsString:@"iMac"]) {
        isLiquid = NO;
    } else if ([machineName containsString:@"Macmini"]) {
        isLiquid = NO;
    } else if ([machineName containsString:@"MacPro"]) {
        isLiquid = NO;
    } else if ([machineName containsString:@"MacBookAir"]) {
        isLiquid = NO;
    } else if ([machineName containsString:@"MacBookPro"]) {
        isLiquid = NO;
    } else if ([self __assertRegex:@"Mac(\\d{1,2}),(\\d{1,2})" matchStr:machineName]) {
        // 有电池则是笔记本，否则为iMac、Mac Mini、Mac Pro、Mac studio
        BatteryModel *batteryModel = [[BatteryModel alloc] init];
        isLiquid = [batteryModel isExistBattery];
    } else {
        isLiquid = NO;
    }
    return isLiquid;
}

// 正则比较
+ (BOOL)__assertRegex:(NSString*)regexString matchStr:(NSString *)str
{
    NSPredicate *regex = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexString];
    return [regex evaluateWithObject:str];
}

@end
