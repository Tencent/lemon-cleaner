//
//  OwlManageDaemon.m
//  LemonDaemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlManageDaemon.h"
#import "VideoProcessStat.h"
#import "AudioProcessStat.h"
#import <libproc.h>

@interface OwlManageDaemon() {
    VideoProcessStat *vedioStat;
    AudioProcessStat *audioStat;
}
@property (nonatomic, strong) NSMutableArray *runningVedioArray;
@property (nonatomic, strong) NSMutableArray *appleVedioArray;
@property (nonatomic, strong) NSMutableArray *changeAudioArray;
@property (nonatomic, strong) NSMutableArray *appleAudioArray;
@property (nonatomic, strong) NSMutableArray *whiteProcessArray;
@end

@implementation OwlManageDaemon

+ (OwlManageDaemon *)shareInstance{
    static OwlManageDaemon *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (id)init {
    self = [super init];
    NSLog(@"OwlManageDaemon init begin");
    if (self) {
        _whiteProcessArray = [[NSMutableArray alloc] init];
        [_whiteProcessArray addObject:@"launchd"];
        [_whiteProcessArray addObject:@"VDCAssistant"];
        [_whiteProcessArray addObject:@"CVMServer"];
        [_whiteProcessArray addObject:@"notifyd"];
        [_whiteProcessArray addObject:@"syslogd"];
        [_whiteProcessArray addObject:@"logd"];
        [_whiteProcessArray addObject:@"VDCAssistant"];
        [_whiteProcessArray addObject:@"CLOCK"];
        [_whiteProcessArray addObject:@"SEMAPHORE"];
        [_whiteProcessArray addObject:@"HOST"];
        [_whiteProcessArray addObject:@"VOUCHER"];
        [_whiteProcessArray addObject:@"IOKIT-OBJECT"];
        [_whiteProcessArray addObject:@"IOKIT-CONNECT"];
        [_whiteProcessArray addObject:@"cfprefsd"];
        [_whiteProcessArray addObject:@"MASTER-DEVICE"];
        [_whiteProcessArray addObject:@"WindowServer"];
        [_whiteProcessArray addObject:@"coreservicesd"];
        [_whiteProcessArray addObject:@"launchservicesd"];
        [_whiteProcessArray addObject:@"THREAD"];
        [_whiteProcessArray addObject:@"avconferenced"];
        [_whiteProcessArray addObject:@"systemstats"];
        [_whiteProcessArray addObject:@"UserEventAgent"];
        [_whiteProcessArray addObject:@"NAMED-MEMORY"];
        [_whiteProcessArray addObject:@"App Store"];
        [_whiteProcessArray addObject:@"diagnosticd"];
        [_whiteProcessArray addObject:@"mediaremoted"];
        [_whiteProcessArray addObject:@"signpost_notificationd"];
        [_whiteProcessArray addObject:@"SystemUIServer"];
        [_whiteProcessArray addObject:@"loginwindow"];
        [_whiteProcessArray addObject:@"AirPlayXPCHelper"];
        [_whiteProcessArray addObject:@"Terminal"];
        [_whiteProcessArray addObject:@"Xcode"];
        [_whiteProcessArray addObject:@"com.apple.WebKit.WebContent"];
        [_whiteProcessArray addObject:@"bluetoothd"];
        [_whiteProcessArray addObject:@"powerd"];
        [_whiteProcessArray addObject:@"distnoted"];
        [_whiteProcessArray addObject:@"AudioComponentRegistrar"];
        [_whiteProcessArray addObject:@"Lemon"];
        //[_whiteProcessArray addObject:@"Chrome"];
        [_whiteProcessArray addObject:@"com.tencent.OwlHelper"];
        [_whiteProcessArray addObject:@"VTDecoderXPCService"];
        [_whiteProcessArray addObject:@"OverSight"];
        
        [_whiteProcessArray addObject:@"systemsoundserverd"];
        [_whiteProcessArray addObject:@"callservicesd"];
        [_whiteProcessArray addObject:@"coreaudiod"];
        [_whiteProcessArray addObject:@"assistantd"];
        //[_whiteProcessArray addObject:@"com.apple."];
        
        _runningVedioArray = [[NSMutableArray alloc] init];
        _appleVedioArray = [[NSMutableArray alloc] init];
        vedioStat = [[VideoProcessStat alloc] initWithWhiteArray:_whiteProcessArray];
        audioStat = [[AudioProcessStat alloc] initWithWhiteArray:_whiteProcessArray];
        
        //[self getProcDictionaryWithPid:[vedioStat getVedioAsistantPid] isVedio:YES];
        //[self getProcDictionaryWithPid:[audioStat getAudioAsistantPid] isVedio:NO];
    }
    NSLog(@"OwlManageDaemon init finishi");
    return self;
}

- (void)dealloc{
    
}

- (void)changeDeviceWatchState:(owl_watch_device_param*)param{
    if (param->device_type == mc_arg_device_camera) {
        if (param->device_state == mc_arg_device_on) {
            //[vedioStat performSelectorOnMainThread:@selector(startCollectProcessInfo) withObject:nil waitUntilDone:NO];
            //[vedioStat startCollectProcessInfo];
        } else {
            //[vedioStat performSelectorOnMainThread:@selector(stopCollectProcessInfo) withObject:nil waitUntilDone:NO];
            //[vedioStat stopCollectProcessInfo];
        }
    }
}

-(NSString *)excuteShellAndReturnOut:(NSString *)shellString{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    
    NSArray *arguments = [NSArray arrayWithObjects:@"-c", shellString,nil];
    [task setArguments:arguments];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    NSFileHandle *fileHandle = [pipe fileHandleForReading];
    NSError *error = nil;
    if (@available(macOS 10.13, *)) {
        [task launchAndReturnError:&error];
    } else {
        // Fallback on earlier versions
        [task launch];
    }
    if (error) {
        NSLog(@"%s, task launch error = %@", __FUNCTION__, error);
    }
    int pid = [task processIdentifier];
    NSLog(@"pid = %d",pid);
//    NSData *data = [fileHandle readDataToEndOfFile];
    NSData *data = nil;
    if (@available(macOS 10.15, *)) {
        data = [fileHandle readDataUpToLength:1000000 error:&error];
    } else {
        // Fallback on earlier versions
        data = [fileHandle readDataOfLength:1000000];
    }
    if (error) {
        NSLog(@"%s, read data error = %@", __FUNCTION__, error);
    }
    
    // Note: Test
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        int ret = kill(pid, SIGKILL);
        NSLog(@"%s, kill task ret: %d", __FUNCTION__ ,ret);
    });
    [task waitUntilExit];
    
    [fileHandle closeFile];
    
    NSString *outputStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //NSLog(@"excuteShellAndReturnOut outputStr is = %@", outputStr);
    return outputStr;
}
- (BOOL)processIsAlive:(int)pid{
    //return YES;
    switch(kill(pid, 0)){
        case 0:
            return YES;
        case -1:
            if(errno == EPERM) //Operation not permitted, this must do in the xpc server
            {
                return NO;
            } else if(errno == ESRCH)
            {
                return NO;
            }
    }
    return NO;
}
- (NSMutableArray*)getProcDictionaryWithPid:(int)pid isVedio:(BOOL)isVedio{
    //BOOL permission = [ShellExcuteHelper getRootPermission];
    //NSLog(@"permission: %d", permission);
    NSString *result = [self excuteShellAndReturnOut:[NSString stringWithFormat:@"lsmp -p %d", pid]];
    NSLog(@"%s, result.length %lu", __FUNCTION__, result.length);
    // Camera
    static NSMutableDictionary* dicVedioMatched_old;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dicVedioMatched_old = [[NSMutableDictionary alloc] init];
    });
    // Audio
    static NSMutableDictionary* dicAudioMatched_old;
    static dispatch_once_t onceAudioToken;
    dispatch_once(&onceAudioToken, ^{
        dicAudioMatched_old = [[NSMutableDictionary alloc] init];
    });
    
    //NSLog(@"getVDCDictionaryWithPid:dicVedioMatched_old=%@", dicVedioMatched_old);
    // 收集符合条件的行数据
    //    NSString *str = [NSString stringWithContentsOfFile:@"/Users/admin/lsmp-204.txt" encoding:NSUTF8StringEncoding error:nil];
    NSArray* array = [result componentsSeparatedByString:@"\n"];
    NSMutableDictionary* dicMatched = [[NSMutableDictionary alloc] init];
    NSError* error;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"\\(\\d+\\)\\s.+$" options:0 error:&error];
    int matched = 0;
    for (int i=0; i<[array count]; i++) {
        NSString* item = array[i];
        NSRange range = [item rangeOfString:@".+\\(\\d+\\)\\s.+$" options:NSRegularExpressionSearch];
        if (range.location != NSNotFound) {
            matched++;
            NSTextCheckingResult* check = [regex firstMatchInString:item options:0 range:NSMakeRange(0, [item length])];
            if (check) {
                NSString* result = [item substringWithRange:check.range];
                BOOL isWhite = NO;
                for (NSString *whiteString in self.whiteProcessArray) {
                    if ([result containsString:whiteString]) {
                        isWhite = YES;
                        continue;
                    }
                }
                if (isWhite) {
                    continue;
                }
                NSNumber* value = dicMatched[result];
                if (value == nil)
                {
                    value = [NSNumber numberWithLong:1];
                }
                else
                {
                    long l = [value longValue];
                    value = [NSNumber numberWithLong:(l + 1)];
                }
                [dicMatched setValue:value forKey:result];
            }
            
        }
    }
    //NSLog(@"getVDCDictionaryWithPid:dicMatched=%@", dicMatched);
    
    // 计算变化的进程
    
    NSMutableDictionary* tempDicMatched_old = nil;
    if (isVedio) {
        tempDicMatched_old = [[NSMutableDictionary alloc] initWithDictionary:dicVedioMatched_old];
    } else {
        tempDicMatched_old = [[NSMutableDictionary alloc] initWithDictionary:dicAudioMatched_old];
    }
    NSMutableArray* arrayResult = [[NSMutableArray alloc] init];
    NSMutableArray* tempAppleArray = [[NSMutableArray alloc] init];
    NSFileManager *fm = [NSFileManager defaultManager];
    {
        NSMutableDictionary* dicDelta = [[NSMutableDictionary alloc] init];
        for (NSString *key in dicMatched) {
            NSNumber* value = dicMatched[key];
            NSNumber* value_old = tempDicMatched_old[key];
            dicDelta[key] = [NSNumber numberWithLong:([value longValue] - [value_old longValue])];
            [tempDicMatched_old removeObjectForKey:key];
        }
        
        for (NSString *key in tempDicMatched_old) {
            NSNumber* value = tempDicMatched_old[key];
            dicDelta[key] = [NSNumber numberWithLong:(0-[value longValue])];
        }
        
        [tempDicMatched_old removeAllObjects];
        [tempDicMatched_old addEntriesFromDictionary:dicMatched];
        //NSLog(@"getVDCDictionaryWithPid:dicDelta=%@", dicDelta);
        
        // 数据返回
        for (NSString *key in dicDelta)
        {
            // Case: (24806) QuickTime Player
            NSArray* arraySplit = [key componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]];
            // Case: ["", "24806", " QuickTime Player"]
            if (arraySplit.count < 3) {
                NSLog(@"arraySplit.count < 3");
                continue;
            }
            if ([arraySplit[2] length] < 2) {
                NSLog(@"arraySplit[2] length] < 2");
                continue;
            }
            
            // Case: "QuickTime Player"
            NSString *strName = [arraySplit[2] substringFromIndex:1];// 去掉前面的空格
            
            NSMutableDictionary* dicItem = [[NSMutableDictionary alloc] init];
            
            dicItem[OWL_PROC_ID] = arraySplit[1]; // 数组的0项是空，从第一个开始取
            dicItem[OWL_PROC_NAME] = strName;
            dicItem[OWL_PROC_DELTA] = dicDelta[key];
            
            char exe_path[MAXPATHLEN] = {0};
            if (proc_pidpath([arraySplit[1] intValue], exe_path, sizeof(exe_path)) == 0)
            {
                dicItem[OWL_PROC_PATH] = @"";
                // 如果进程路径为空，仍不能忽略，因为可能是结束app的情况
                //continue;
            }
            else
            {
                dicItem[OWL_PROC_PATH] = [NSString stringWithUTF8String:exe_path];
                // 如果进程path异常，则忽略
                if (![fm fileExistsAtPath:[NSString stringWithUTF8String:exe_path]]) {
                    NSLog(@"[fm fileExistsAtPath:[NSString stringWithUTF8String:exe_path]]");
                    continue;
                }
            }
            //
            if (!isVedio) {
                if ([dicDelta[key] intValue] == 0) {
//                    NSLog(@"[dicDelta[key] intValue] == 0");
                    continue;
                }
            }
            //pid 无效则忽略
            if (arraySplit[1] <= 0){//} || ![self processIsAlive:(int)arraySplit[1]]) {
                NSLog(@"pid 无效则忽略");
                continue;
            }
            // 如果进程名为空或者异常，则忽略
            if ((strName == nil) || [strName isEqualToString:@""] || [strName pathComponents].count > 1) {
                NSLog(@"如果进程名为空或者异常，则忽略");
                continue;
            }
            
            if ([strName isEqualToString:@"FaceTime"] ||
                [strName isEqualToString:@"Photo Booth"]) {
                //apple 这两个特殊处理，在sample采样的时候，FaceTime采样和其他的都不同，故不用经过采样流程
                [tempAppleArray addObject:dicItem];
                NSLog(@"FaceTime/Photo Booth");
                continue;
            }
            [arrayResult addObject:dicItem];
        }
        
    }
    if (isVedio) {
        [dicVedioMatched_old removeAllObjects];
        [dicVedioMatched_old addEntriesFromDictionary:tempDicMatched_old];
        [self.appleVedioArray removeAllObjects];
        [self.appleVedioArray addObjectsFromArray:tempAppleArray];
    } else {
        [dicAudioMatched_old removeAllObjects];
        [dicAudioMatched_old addEntriesFromDictionary:tempDicMatched_old];
        [self.appleAudioArray removeAllObjects];
        [self.appleAudioArray addObjectsFromArray:tempAppleArray];
    }
//    NSLog(@"%s, %lu", __FUNCTION__, (unsigned long)self.appleAudioArray.count);
    //NSLog(@"getVDCDictionaryWithPid : %@,  %@,  %@", dicVedioMatched_old, arrayResult, tempAppleArray);
    return arrayResult;
}

//- (NSMutableArray *)sampleVedio:(NSMutableArray*)vedioArray complete:(void (^)(NSMutableArray*))block{
- (NSMutableArray *)sampleVedio:(NSMutableArray*)vedioArray{
    //NSLog(@"sampleVedio: %@", vedioArray);
    //采样记录所有使用摄像头的进程
    NSMutableArray *tempVedio = [[NSMutableArray alloc] init];
    dispatch_queue_t dispatchQueue = dispatch_queue_create("lemondaemon.queue.owl", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t dispatchGroup = dispatch_group_create();
    //dispatch_semaphore_t semaphore = dispatch_semaphore_create(vedioArray.count);
    for (int i = 0; i < vedioArray.count; i++) {
        NSMutableDictionary *dicItem = [vedioArray objectAtIndex:i];
        pid_t pid = (pid_t)[dicItem[OWL_PROC_ID] intValue];
        dispatch_group_async(dispatchGroup, dispatchQueue, ^(){
            NSString *result = [self excuteShellAndReturnOut:[NSString stringWithFormat:@"sample %d 0.7 50", pid]];
            //NSLog(@"result: %@", result);
            if ([result containsString:@"CMIOGraph::DoWork"]) {
                dicItem[OWL_PROC_DELTA] = @(1);
                [tempVedio addObject:dicItem];
            }
        });
    }
    dispatch_group_wait(dispatchGroup, dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC));
    //NSLog(@"runningVedioArray: %@\n tempVedio: %@", self.runningVedioArray, tempVedio);
//    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^(){
//    });
    //新变化的（包含新增和停止）
    NSMutableArray *newChangeVedio = [[NSMutableArray alloc] init];
    //原有使用当前停止的
    NSMutableArray *closeVedio = [[NSMutableArray alloc] init];
    //上次采样和本次采样都在使用摄像头的
    NSMutableArray *runingVedio = [[NSMutableArray alloc] init];
//    [self.runningVedioArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//
//    }];
    NSMutableArray *runningVedioArrayTemp = [[NSMutableArray alloc] initWithArray:self.runningVedioArray];
    NSMutableArray *tempVedio1 = [[NSMutableArray alloc] initWithArray:tempVedio];
    for (NSMutableDictionary *dicItem in self.runningVedioArray) {
        BOOL isStop = NO;
        for (NSMutableDictionary *subItem in tempVedio) {
            //删除两者共有的（共有的也表示正在使用摄像头的，可放入），那么tempVedio剩余的则为新增的，runningVedioArray剩余的则为停止的（进程停止使用摄像头）
            if ([dicItem[OWL_PROC_NAME] isEqualToString:subItem[OWL_PROC_NAME]]) {
                [tempVedio1 removeObject:subItem];
                [runingVedio addObject:subItem];
                isStop = YES;
                break;
            }
        }
        if (isStop) {
            [runningVedioArrayTemp removeObject:dicItem];
        } else {
            dicItem[OWL_PROC_DELTA] = @(-1);
        }
    }
    [newChangeVedio addObjectsFromArray:tempVedio1];
    [closeVedio addObjectsFromArray:runningVedioArrayTemp];
    [self.runningVedioArray removeAllObjects];
    [self.runningVedioArray addObjectsFromArray:tempVedio1];
    [self.runningVedioArray addObjectsFromArray:runingVedio];
    [newChangeVedio addObjectsFromArray:closeVedio];
    [newChangeVedio addObjectsFromArray:self.appleVedioArray];
    //NSLog(@"newVedio: %@\n closeVedio: %@\n appleVedioArray: %@\n changeVedio: %@", newChangeVedio, closeVedio, self.appleVedioArray, self.runningVedioArray);
    return newChangeVedio;
}
- (NSMutableArray *)sampleAudio:(NSMutableArray*)audioArray{
    NSLog(@"sampleAudio: %@", audioArray);
    NSMutableArray *clientArray = [[NSMutableArray alloc] init];
    NSMutableArray *newChangeAudio = [[NSMutableArray alloc] init];
    CFMutableDictionaryRef vfdref = IOServiceMatching("IOPMrootDomain");
    io_service_t ioser = IOServiceGetMatchingService(kIOMasterPortDefault, vfdref);
    io_iterator_t iter = 0;
    kern_return_t ret = IORegistryEntryGetChildIterator(ioser, "IOService", &iter);
    if (ret == KERN_SUCCESS) {
        io_object_t obj = IOIteratorNext(iter);
        while (obj) {
            CFTypeRef data = IORegistryEntryCreateCFProperty(obj, CFSTR("IOUserClientCreator"), kCFAllocatorDefault, 0);
            IOObjectRelease(obj);
            if (data != 0) {
                NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@", "];
                NSString *strData = (__bridge NSString*)data;
                //NSLog(@"strData: %@", strData);
                NSArray<NSString*> *array = [strData componentsSeparatedByCharactersInSet:set];
                NSInteger count = [array count];
                if (count == 4) {
                    NSString *strValue = [array objectAtIndexedSubscript:1];
                    int pid = [strValue intValue];
                    [clientArray addObject:[NSNumber numberWithInt:pid]];
                }
            }
            obj = IOIteratorNext(iter);
        }
    }
    for (NSMutableDictionary *dicItem in audioArray) {
        BOOL isInClient = NO;
        for (NSNumber *number in clientArray) {
            if ([dicItem[OWL_PROC_ID] intValue] == [number intValue]) {
                isInClient = YES;
                NSLog(@"sampleAudio find oooo in client: %@", dicItem);
                [newChangeAudio addObject:dicItem];
                break;
            }
        }
        if (!isInClient) {
            //[audioArray removeObject:dicItem];
            NSLog(@"sampleAudio find xxxxx not in client: %@", dicItem);
        }
    }
    
    //NSLog(@"newChangeAudio: %@", newChangeAudio);
    return newChangeAudio;
}
- (int)getDeviceWitchProcess:(owl_watch_device_param*)param pInfo:(lemon_com_process_info **)pInfo_t{
    NSMutableArray *vedioArray = [NSMutableArray array];
    NSMutableArray *audioArray = [NSMutableArray array];
    
    if (param->device_type == mc_arg_device_camera) {
        vedioArray = [self getProcDictionaryWithPid:[vedioStat getVedioAsistantPid] isVedio:YES];
        vedioArray = [self sampleVedio:vedioArray];
    } else if (param->device_type == mc_arg_device_audio) {
        audioArray = [self getProcDictionaryWithPid:[audioStat getAudioAsistantPid] isVedio:NO];
        //audioArray = [audioStat gradAudioProcessInfo];
        //audioArray = [self sampleAudio:audioArray];
    } else if (param->device_type == mc_arg_device_camera_audio) {
        vedioArray = [self getProcDictionaryWithPid:[vedioStat getVedioAsistantPid] isVedio:YES];
        vedioArray = [self sampleVedio:vedioArray];
        audioArray = [self getProcDictionaryWithPid:[audioStat getAudioAsistantPid] isVedio:NO];
        //audioArray = [self sampleAudio:audioArray];
    }
    //NSMutableArray *vedioArray = [vedioStat gradVedioProcessInfo];
    //NSMutableArray *audioArray = [audioStat gradAudioProcessInfo];
    int count = (int)(vedioArray.count + audioArray.count);
    lemon_com_process_info *proc = malloc(sizeof(lemon_com_process_info) * count);
    //memset(proc, 0, sizeof(lemon_com_process_info) * vedioStat.oldMatchVideo.count);
    int index = 0;
    for (int i = 0; i < vedioArray.count; i++) {
        memset(&proc[index], 0, sizeof(lemon_com_process_info));
        NSDictionary *dicItem = [vedioArray objectAtIndex:i];
        proc[index].pid = (pid_t)[dicItem[OWL_PROC_ID] intValue];
        proc[index].time_count = (int)[dicItem[OWL_PROC_DELTA] intValue];
        proc[index].device_type = 0;
        memcpy(proc[index].name, [dicItem[OWL_PROC_NAME] UTF8String], strlen([dicItem[OWL_PROC_NAME] UTF8String]));
        memcpy(proc[index].path, [dicItem[OWL_PROC_PATH] UTF8String], strlen([dicItem[OWL_PROC_PATH] UTF8String]));
        //NSLog(@"getDeviceWitchProcess: %d, %d", [dicItem[@"PROC_ID"] intValue], [dicItem[@"PROC_DELTA"] intValue]);
        index++;
    }
    for (int i = 0; i < audioArray.count; i++) {
        memset(&proc[index], 0, sizeof(lemon_com_process_info));
        NSDictionary *dicItem = [audioArray objectAtIndex:i];
        proc[index].pid = (pid_t)[dicItem[OWL_PROC_ID] intValue];
        proc[index].time_count = (int)[dicItem[OWL_PROC_DELTA] intValue];
        proc[index].device_type = 1;
        memcpy(proc[index].name, [dicItem[OWL_PROC_NAME] UTF8String], strlen([dicItem[OWL_PROC_NAME] UTF8String]));
        memcpy(proc[index].path, [dicItem[OWL_PROC_PATH] UTF8String], strlen([dicItem[OWL_PROC_PATH] UTF8String]));
        //NSLog(@"getDeviceWitchProcess: %d, %d", [dicItem[@"PROC_ID"] intValue], [dicItem[@"PROC_DELTA"] intValue]);
        index++;
    }
    int fun_ret = count;
    *pInfo_t = proc;
    return fun_ret;
}

@end
