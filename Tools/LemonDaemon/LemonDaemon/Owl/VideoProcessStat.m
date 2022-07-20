//
//  VideoProcessStat.m
//  OwlHelper
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "VideoProcessStat.h"
#import <libproc.h>

@interface VideoProcessStat() {
    
}
@property (nonatomic, strong) NSTimer *listenTimer;
@property (nonatomic, assign) int vedioAsistantPid;
@property (nonatomic, strong) NSArray *whiteProcessArray;
@end

@implementation VideoProcessStat

- (id)initWithWhiteArray:(NSArray*)array {
    self = [super init];
    if (self) {
        _whiteProcessArray = [[NSArray alloc] initWithArray:array];
        
        _vedioAsistantPid = [self findProcessPidWithPath:VDCAssistantPath];
        //[self getVDCDictionaryWithPid:_vedioAsistantPid];
        
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(findWitchProcessUseCamera:) name:FindWitchProcessUseCamera object:nil];
        //[self startCollectProcessInfo];
    }
    return self;
}

- (void)dealloc {
    [self stopCollectProcessInfo];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startCollectProcessInfo{
    //when start the timer, grad the camera process info from the VDC once, and return the result to the main app
    if (_listenTimer) {
        return;
    }
    NSLog(@"startCollectProcessInfo");
    //begin timer
    _listenTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(gradVedioProcessInfo) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_listenTimer forMode:NSDefaultRunLoopMode];
    [self gradVedioProcessInfo];
}

- (void)stopCollectProcessInfo{
    NSLog(@"stopCollectProcessInfo");
    //when stop the timer, grad the camera process info from the VDC
    [self gradVedioProcessInfo];
    //stop timer
    [_listenTimer invalidate];
    _listenTimer = nil;
}

#pragma mark deal process
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

- (int)findProcessPidWithPath:(NSString*)processName{
    int pid = -1;
    int numberOfProcesses = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    pid_t pids[numberOfProcesses];
    bzero(pids, sizeof(pids));
    proc_listpids(PROC_ALL_PIDS, 0, pids, (int)sizeof(pids));
    for (int i = 0; i < numberOfProcesses; ++i) {
        if (pids[i] == 0) { continue; }
        char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
        bzero(pathBuffer, PROC_PIDPATHINFO_MAXSIZE);
        proc_pidpath(pids[i], pathBuffer, sizeof(pathBuffer));
        if (strlen(pathBuffer) == [processName length]) {
            if ([[NSString stringWithUTF8String:pathBuffer] isEqualToString:processName]) {
                NSLog(@"findProcessPid: %d", pids[i]);
                return pids[i];
            }
            NSLog(@"%s, path: %s", __FUNCTION__, pathBuffer);
        }
    }
    return pid;
}

#pragma mark deal vedio

-(NSString *)excuteShellAndReturnOut:(NSString *)shellString{
    NSLog(@"%s, cmd = %@", __FUNCTION__, shellString);
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
//    NSLog(@"pid = %d",pid);
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
    //    [task waitUntilExit];
    int ret = kill(pid, SIGKILL);
//    NSLog(@"%s, kill task ret: %d", __FUNCTION__ ,ret);
    [fileHandle closeFile];
    
    NSString *outputStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //NSLog(@"excuteShellAndReturnOut outputStr is = %@", outputStr);
    return outputStr;
}

- (NSMutableArray*)getVDCDictionaryWithPid:(int)pid{
    //BOOL permission = [ShellExcuteHelper getRootPermission];
    //NSLog(@"permission: %d", permission);
    NSString *result = [self excuteShellAndReturnOut:[NSString stringWithFormat:@"lsmp -p %d", pid]];
    
    // Camera
    static NSMutableDictionary* dicVedioMatched_old;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dicVedioMatched_old = [[NSMutableDictionary alloc] init];
        //            dicVedioMatched_old[@"xxx"] = [NSNumber numberWithLong:100]; // test
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
                for (NSString *whiteString in _whiteProcessArray) {
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
    NSMutableDictionary* dicDelta = [[NSMutableDictionary alloc] init];
    for (NSString *key in dicMatched) {
        NSNumber* value = dicMatched[key];
        NSNumber* value_old = dicVedioMatched_old[key];
        dicDelta[key] = [NSNumber numberWithLong:([value longValue] - [value_old longValue])];
        [dicVedioMatched_old removeObjectForKey:key];
//        NSLog(@"getVDCDictionaryWithPid:mathed Key %@: %@ - %@", key, value, value_old);
    }
    
    for (NSString *key in dicVedioMatched_old) {
        NSNumber* value = dicVedioMatched_old[key];
        dicDelta[key] = [NSNumber numberWithLong:(0-[value longValue])];
//        NSLog(@"getVDCDictionaryWithPid:miss Key %@: %@", key, value);
    }
    
    [dicVedioMatched_old removeAllObjects];
    [dicVedioMatched_old addEntriesFromDictionary:dicMatched];
    
    //NSLog(@"getVDCDictionaryWithPid:dicDelta=%@", dicDelta);
    
    
    // 数据返回
    NSMutableArray* arrayResult = [[NSMutableArray alloc] init];
    for (NSString *key in dicDelta)
    {
        NSArray* arraySplit = [key componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]];
        if (arraySplit.count < 3) {
            continue;
        }
        if ([arraySplit[2] length] < 2) {
            continue;
        }
        if ([dicDelta[key] intValue] == 0) {
            continue;
        }
        
        NSMutableDictionary* dicItem = [[NSMutableDictionary alloc] init];
        
        dicItem[OWL_PROC_ID] = arraySplit[1]; // 数组的0项是空，从第一个开始取
        dicItem[OWL_PROC_NAME] = [arraySplit[2] substringFromIndex:1]; // 去掉前面的空格
        dicItem[OWL_PROC_DELTA] = dicDelta[key];
        
        char exe_path[MAXPATHLEN] = {0};
        if (proc_pidpath([arraySplit[1] intValue], exe_path, sizeof(exe_path)) == 0)
        {
            dicItem[OWL_PROC_PATH] = @"";
        }
        else
        {
            dicItem[OWL_PROC_PATH] = [NSString stringWithUTF8String:exe_path];
        }
        
        [arrayResult addObject:dicItem];
    }
    
    //NSLog(@"getVDCDictionaryWithPid : %@", arrayResult);
    
    return arrayResult;
}
- (NSMutableArray*)gradVedioProcessInfo{
    //NSLog(@"gradVedioProcessInfo: %@", @"");
//    [[HelperXPCConnector shareInstance] sendMsg:@{FUNCTIONKEY: @"gradVedioProcessInfo", PARAMETERKEY: @{}}];
    if (![self processIsAlive:_vedioAsistantPid]) {
        _vedioAsistantPid = -1;
    }
    if (_vedioAsistantPid < 0) {
        _vedioAsistantPid = [self findProcessPidWithPath:VDCAssistantPath];
        if (_vedioAsistantPid < 0 || ![self processIsAlive:_vedioAsistantPid]) {
            _vedioAsistantPid = [self findProcessPidWithPath:AppleCameraAssistantPath];
            if (_vedioAsistantPid < 0 || ![self processIsAlive:_vedioAsistantPid]) {
                NSLog(@"gradVedioProcessInfo happen error: can't find the vedio asistant pid");
                return [NSMutableArray array];
            }
        }
    }
    NSMutableArray *array = [self getVDCDictionaryWithPid:self.vedioAsistantPid];
    return array;
    
    //NSLog(@"gradVedioProcessInfo self.oldMatchVideo : %@", self.oldMatchVideo);
//    NSMutableDictionary *res = [self findWitchProcessUseCamera:nil];
//    [[HelperXPCConnector shareInstance] sendMsgNoReply:res];
}

- (NSMutableDictionary*)findWitchProcessUseCamera:(NSDictionary*)message{
    NSLog(@"findWitchProcessUseCamera begin: %@", message);
    NSMutableDictionary *res = [[NSMutableDictionary alloc] initWithCapacity:2];
//    [res setObject:FindWitchProcessUseCameraReply forKey:FUNCTIONKEY];
//    NSMutableArray *array = [self getVDCDictionaryWithPid:_vedioAsistantPid];
//  
//    [res setObject:array forKey:PARAMETERKEY];
//    
//    NSLog(@"findWitchProcessUseCamera end: %@", message);
    return res;
}

- (int)getVedioAsistantPid{
//    NSLog(@"%s, getVedioAsistantPid start", __FUNCTION__);
    if (![self processIsAlive:_vedioAsistantPid]) {
        _vedioAsistantPid = -1;
    }
    if (_vedioAsistantPid < 0) {
        _vedioAsistantPid = [self findProcessPidWithPath:VDCAssistantPath];
        if (_vedioAsistantPid < 0 || ![self processIsAlive:_vedioAsistantPid]) {
            _vedioAsistantPid = [self findProcessPidWithPath:AppleCameraAssistantPath];
            if (_vedioAsistantPid < 0 || ![self processIsAlive:_vedioAsistantPid]) {
                _vedioAsistantPid = [self findProcessPidWithPath:AppleCameraAssistantPath2];
                if (_vedioAsistantPid < 0 || ![self processIsAlive:_vedioAsistantPid]) {
                    NSLog(@"gradVedioProcessInfo happen error: can't find the vedio asistant pid");
                    return -1;
                }
            }
        }
    }
    return _vedioAsistantPid;
}
@end
