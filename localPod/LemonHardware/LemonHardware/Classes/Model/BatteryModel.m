//
//  BatteryModel.m
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "BatteryModel.h"

#define BATT_PLIST @"batt.plist"
#define kAppleSmartBattery          "AppleSmartBattery"
#define kBatterySerialKey           "BatterySerialNumber"
#define kBatterySearalKey_macOS11   "Serial"
#define kBatteryExternalChargeKey   "ExternalChargeCapable"

io_service_t g_smartBattery = 0;

@implementation BatteryModel

//电池是否存在
-(BOOL)isExistBattery{
    char serial_buf[200] = {0};
    if (CmcGetBatterySerial(serial_buf, sizeof(serial_buf)) == -1){
        return NO;
    }else{
        return YES;
    }
}

#ifndef APPSTORE_VERSION
-(instancetype)init{
    self = [super init];
    if(self){
        // get AppleSmartBattery service object
        g_smartBattery = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                     IOServiceMatching(kAppleSmartBattery));
    }
    
    return self;
}

-(void)dealloc{
    if (g_smartBattery == 0)
        return;
    
    IOObjectRelease(g_smartBattery);
}

-(BOOL)getHardWareInfo{
    if([self isExistBattery]){
        self.haveBattery = YES;
        [self writeInfoToFile];
        [self readFromFile];
        [self getPercentageFromShell];
//        [self getIsConnectAC];
        self.isInit = YES;
    }else{
        self.haveBattery = NO;
    }
    
    return YES;
}

-(void)getIsConnectAC{
    int value;
    @try
    {
        if ((value = CmcGetBatteryChargeCapable()) == -1)
            self.batExternalCharge = NO;
    }
    @catch (NSException * e)
    {
        self.batExternalCharge = NO;
        return;
    }
    
    // convert
    
    if (value == 1)
        self.batExternalCharge = YES;
    else
        self.batExternalCharge = NO;
}

-(void)writeInfoToFile{
    NSString *pathName = [self getHardWareInfoPathByName:BATT_PLIST];
    pathName = [pathName stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
    NSString *shellString = [NSString stringWithFormat:@"system_profiler SPPowerDataType -xml > %@", pathName];
    @try{
        [QMShellExcuteHelper excuteCmd:shellString];
    }
    @catch(NSException *exception){
        NSLog(@"exception = %@", exception);
    }
}

-(BOOL)readFromFile{
    NSString *fileName = [self getHardWareInfoPathByName:BATT_PLIST];
    NSArray *battArr = [[NSArray alloc] initWithContentsOfFile:fileName];
    if ([battArr count] == 0) {
        return NO;
    }
    NSDictionary *battDic = [battArr objectAtIndex:0];
    if (battDic == nil) {
        return NO;
    }
    NSArray *_items = [battDic objectForKey:@"_items"];
    if([_items count] == 0){
        return NO;
    }
    //item0
    NSDictionary *item0Dic = [_items objectAtIndex:0];
    if(item0Dic == nil){
        return NO;
    }
    NSDictionary *sppower_battery_charge_info = [item0Dic objectForKey:@"sppower_battery_charge_info"];
    if(sppower_battery_charge_info == nil){
        return NO;
    }
    self.maxCapacity = [sppower_battery_charge_info objectForKey:@"sppower_battery_max_capacity"];
    self.currentCapacity = [sppower_battery_charge_info objectForKey:@"sppower_battery_current_capacity"];
    if ([[sppower_battery_charge_info objectForKey:@"sppower_battery_is_charging"] isEqualToString:@"TRUE"]) {
        self.ischarge = YES;
    }else{
        self.ischarge = NO;
    }
    self.isFullyCharged = [sppower_battery_charge_info objectForKey:@"sppower_battery_fully_charged"];
    NSDictionary *sppower_battery_health_info = [item0Dic objectForKey:@"sppower_battery_health_info"];
    if(sppower_battery_health_info == nil){
        return NO;
    }
    self.loopCount = [sppower_battery_health_info objectForKey:@"sppower_battery_cycle_count"];
    self.status = [sppower_battery_health_info objectForKey:@"sppower_battery_health"];
    self.healthMaxCapacity = sppower_battery_health_info[@"sppower_battery_health_maximum_capacity"];
    NSLog(@"healthMaxCapacity = %@",self.healthMaxCapacity);
    //item1
    for (NSDictionary *tempDic in _items) {
        if ([[tempDic allKeys] containsObject:@"AC Power"]) {
            NSDictionary *acPowerDic = tempDic[@"AC Power"];
            NSString *useAcPower = acPowerDic[@"Current Power Source"];
            if ([useAcPower isEqualToString:@"TRUE"]) {
                self.batExternalCharge = YES;
            }else{
                self.batExternalCharge = NO;
            }
        }
    }
    
//    NSLog(@"batt = %@", self);
    
    return YES;
}

-(BOOL)getPercentageFromShell{
    NSString *shellString = @"pmset -g batt";
    NSString *retString = [QMShellExcuteHelper excuteCmd:shellString];
//    NSLog(@"retString = %@", retString);
    if ((retString == nil) || ([retString isEqualToString:@""])) {
        return NO;
    }
    if ([retString containsString:@"discharging"]) {
        self.ischarge = NO;
    }else if([retString containsString:@"charged"]){
        self.ischarge = NO;
    }else if ([retString containsString:@"charging"]){
        self.ischarge = YES;
    }
    //使用正则表达式来过滤百分比
    NSString *pattern = @"\\d+%;";
    NSRegularExpression *regular = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *results = [regular matchesInString: retString options:0 range:NSMakeRange(0, retString.length)];
    if([results count] == 0){
        self.percentage = @"-1";//无电池
        return NO;
    }
    NSTextCheckingResult *result = [results objectAtIndex:0];
    NSString *percentage = [retString substringWithRange:result.range];
    self.percentage = [percentage stringByReplacingOccurrencesOfString:@";" withString:@""];
//    NSLog(@"results = %@", [retString substringWithRange:result.range]);
//    NSLog(@"batt = %@", self);
    return YES;
}

#endif

// get battery serial, UTF8 encoding
// serial_buf       output buffer
// buf_size         size in bytes
int CmcGetBatterySerial(char *serial_buf, int buf_size)
{
    CFStringRef serial;
    
    if (g_smartBattery == 0)
    {
        return -1;
    }
    
    // get serial value
    serial = IORegistryEntryCreateCFProperty(g_smartBattery,
                                             CFSTR(kBatterySerialKey),
                                             kCFAllocatorDefault,
                                             kNilOptions);
    if (serial == NULL) {
        serial = IORegistryEntryCreateCFProperty(g_smartBattery,
                                                 CFSTR(kBatterySearalKey_macOS11),
                                                 kCFAllocatorDefault,
                                                 kNilOptions);
    }
    //获取所有属性
//    CFMutableDictionaryRef battery;
//    IORegistryEntryCreateCFProperties(g_smartBattery, &battery, NULL, 0);
//    NSDictionary *dict = (__bridge NSDictionary *)(battery);

    if (serial == NULL)
    {
        return -1;
    }
    
    // output serial to buffer
    if (!CFStringGetCString(serial, serial_buf, buf_size, kCFStringEncodingUTF8))
    {
        CFRelease(serial);
        return -1;
    }
    
    CFRelease(serial);
    return 0;
}

#ifndef APPSTORE_VERSION

// get battery externel charge
// return 0 for false, 1 for true, -1 for error
int CmcGetBatteryChargeCapable()
{
    CFBooleanRef number;
    int retvalue;
    
    if (g_smartBattery == 0)
    {
        return -1;
    }
    
    number = IORegistryEntryCreateCFProperty(g_smartBattery,
                                             CFSTR(kBatteryExternalChargeKey),
                                             kCFAllocatorDefault,
                                             kNilOptions);
    if (number == NULL)
    {
        return -1;
    }
    
    if (CFBooleanGetValue(number))
        retvalue = 1;
    else
        retvalue = 0;
    
    CFRelease(number);
    return retvalue;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"maxCapacity = %@, currentCapacity = %@, loopCount = %@, status = %@, percentage = %@, ischarge = %hhd, isFullyCharged = %@", self.maxCapacity, self.currentCapacity, self.loopCount, self.status, self.percentage, self.ischarge, self.isFullyCharged];
}

#endif

@end
