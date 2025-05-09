//
//  AVMonitor.m
//  Application
//
//  Created by Patrick Wardle on 4/30/21.
//  Copyright © 2021 Objective-See. All rights reserved.
//

@import OSLog;
@import AVFoundation;

#import "consts.h"
#import "Client.h"
#import "AVMonitor.h"
#import "utilities.h"
#include <sys/sysctl.h>

#define kLemonUseAVMonitorNotification 0

extern os_log_t logHandle;

typedef NS_ENUM(NSUInteger, LMControlCenterLogStatusType) {
    LMControlCenterLogStatusTypeUnknown,
    LMControlCenterLogStatusTypeSystemAudio,
    LMControlCenterLogStatusTypeMicrophone,
    LMControlCenterLogStatusTypeCamera,
    LMControlCenterLogStatusTypeScreen,
};

@interface LMControlCenterLogStatus : NSObject

@property (nonatomic) LMControlCenterLogStatusType type;
@property (nonatomic) NSString *displayName;
@property (nonatomic) NSString *name; //process name

@end

@implementation LMControlCenterLogStatus

- (NSString *)description
{
    return [self debugDescription];
}

- (NSString *)debugDescription
{
    return [self.name stringByAppendingFormat:@" %lu", (unsigned long)self.type];
}

@end



@interface AVMonitor ()

@property (nonatomic, copy) NSArray *lastPrivacyResult;
@property (nonatomic, copy) NSDate *lastPrivacyResultDate;

@property (nonatomic, copy) NSArray<LMControlCenterLogStatus *> *lastSystemAudioResult; //上次系统音频隐私状态
@property (nonatomic, copy) NSArray<LMControlCenterLogStatus *> *lastCameraResult; //上次摄像头隐私状态
@property (nonatomic, copy) NSArray<LMControlCenterLogStatus *> *lastMicResult; //上次麦克风隐私状态
@property (nonatomic) AVCaptureDevice *activeCamera;
@property (nonatomic) AVCaptureDevice *activeMic;

@end

@implementation AVMonitor

//init
-(id)init
{
#if kLemonUseAVMonitorNotification
    //action: ok
    UNNotificationAction *ok = nil;
    
    //action: allow
    UNNotificationAction *allow = nil;
    
    //action: allow
    UNNotificationAction *allowAlways = nil;
    
    //action: block
    UNNotificationAction *block = nil;
    
    //close category
    UNNotificationCategory* closeCategory = nil;
    
    //action category
    UNNotificationCategory* actionCategory = nil;
#endif
    
    //super
    self = [super init];
    if(nil != self)
    {
        //init log monitor
        self.logMonitor = [[LogMonitor alloc] init];
        self.audio13logMonitor = [[LogMonitor alloc] init];
        self.controlCenterLogMonitor = [[LogMonitor alloc] init];
        
        //init audio attributions
        self.audioAttributions = [NSMutableArray array];
        
        //init camera attributions
        self.cameraAttributions = [NSMutableArray array];
        
        //init audio listeners
        self.audioListeners = [NSMutableDictionary dictionary];
        
        //init video listeners
        self.cameraListeners = [NSMutableDictionary dictionary];
        
        //init event queue
        self.eventQueue = dispatch_queue_create([[NSString stringWithFormat:@"%s.eventQueue", BUNDLE_ID] UTF8String], DISPATCH_QUEUE_CONCURRENT);
        
#if kLemonUseAVMonitorNotification
        //set up delegate
        UNUserNotificationCenter.currentNotificationCenter.delegate = self;
        
        //init ok action
        ok = [UNNotificationAction actionWithIdentifier:@"Ok" title:@"Ok" options:UNNotificationActionOptionNone];
        
        //init close category
        closeCategory = [UNNotificationCategory categoryWithIdentifier:CATEGORY_CLOSE actions:@[ok] intentIdentifiers:@[] options:0];
        
        //init allow action
        allow = [UNNotificationAction actionWithIdentifier:@"Allow" title:NSLocalizedString(@"Allow (once)", @"Allow (once)") options:UNNotificationActionOptionNone];
        
        //init allow action
        allowAlways = [UNNotificationAction actionWithIdentifier:@"AllowAlways" title:NSLocalizedString(@"Allow (always)", @"Allow (always)") options:UNNotificationActionOptionNone];
        
        //init block action
        block = [UNNotificationAction actionWithIdentifier:@"Block" title:NSLocalizedString(@"Block",@"Block") options:UNNotificationActionOptionNone];
        
        //init category
        actionCategory = [UNNotificationCategory categoryWithIdentifier:CATEGORY_ACTION actions:@[allow, allowAlways, block] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
        
        //set categories
        [UNUserNotificationCenter.currentNotificationCenter setNotificationCategories:[NSSet setWithObjects:closeCategory, actionCategory, nil]];
#endif
        
        //per device events
        self.deviceEvents = [NSMutableDictionary dictionary];
        
        //find built-in mic
        self.builtInMic = [self findBuiltInMic];
        
        //dbg msg
        NSLog(@"built-in mic: %@ (device ID: %d)", self.builtInMic.localizedName, [self getAVObjectID:self.builtInMic]);
        
        //find built-in camera
        self.builtInCamera = [self findBuiltInCamera];
        
        //dbg msg
        NSLog(@"built-in camera: %@ (device ID: %d)", self.builtInCamera.localizedName, [self getAVObjectID:self.builtInCamera]);
    }
    
    return self;
}

//monitor AV
// also generate alerts as needed
-(void)start
{
    //dbg msg
    NSLog(@"starting AV monitoring");

    //start log monitor
    [self startLogMonitor];
    [self startControlCenterLogMonitor];
    
    //dbg msg
    NSLog(@"registering for device connection/disconnection notifications");
    
    //handle new device connections
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleConnectedDeviceNotification:) name:AVCaptureDeviceWasConnectedNotification object:nil];

    //handle device disconnections
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleDisconnectedDeviceNotification:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];
    
    
    return;
}

- (void)watchAllAudioDevice
{
    //watch all input audio (mic) devices
    for(AVCaptureDevice* audioDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio])
    {
        //start (device) monitor
        [self watchAudioDevice:audioDevice];
    }
}
- (void)watchAllVideoDevice
{
    //watch all input video (cam) devices
    for(AVCaptureDevice* videoDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
    {
        //start (device) monitor
        [self watchVideoDevice:videoDevice];
    }
}
- (void)unwatchAllAudioDevice
{
    //watch all input audio (mic) devices
    for(AVCaptureDevice* audioDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio])
    {
        //start (device) monitor
        [self unwatchAudioDevice:audioDevice];
    }
}
- (void)unwatchAllVideoDevice
{
    //watch all input video (cam) devices
    for(AVCaptureDevice* videoDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
    {
        //start (device) monitor
        [self unwatchVideoDevice:videoDevice];
    }
}

//new device is connected
// get its type, then watch it for events
-(void)handleConnectedDeviceNotification:(NSNotification *)notification
{
    //device
    AVCaptureDevice* device = NULL;
    device = notification.object;
    //dbg msg
    NSLog(@"new device connected: %@", device.localizedName);
    
    //audio devive
    if(YES == [device hasMediaType:AVMediaTypeAudio])
    {
        //watch
        [self watchAudioDevice:device];
    }
    //video device
    else if(YES == [device hasMediaType:AVMediaTypeVideo])
    {
        //watch
        [self watchVideoDevice:device];
    }
    return;
}

//device is disconnected
-(void)handleDisconnectedDeviceNotification:(NSNotification *)notification
{
    //device
    AVCaptureDevice* device = NULL;
    
    //type
    device = notification.object;
    
    //dbg msg
    NSLog(@"device disconnected: %@", device.localizedName);
    
    //audio devive
    if(YES == [device hasMediaType:AVMediaTypeAudio])
    {
        //unwatch
        [self unwatchAudioDevice:device];
    }
    
    //video device
    else if(YES == [device hasMediaType:AVMediaTypeVideo])
    {
        //unwatch
        [self unwatchVideoDevice:device];
    }
    
    return;
}

//log monitor
-(void)startLogMonitor
{
    //dbg msg
    NSLog(@"starting log monitor for AV events");
    
    if (@available(macOS 13.0, *)) {
        // 13 以上使用控制中心日志
    }
    else if (@available(macOS 12.0, *)) {
        //previous versions of macOS
        // use predicate: "subsystem=='com.apple.SystemStatus'"
        [self monitor12VideoIntel];
        [self monitor12Audio];
    }
    else {  //11 系统使用老方法
        [self monitorSystemStatus];
    }
    return;
}

- (void)startControlCenterLogMonitor
{
    if (@available(macOS 13.0, *)) {
        if (@available(macOS 14.0, *)) {
        } else {
            // 13 系统日志不是持续性的，先设置状态
            self.lastSystemAudioResult = @[];
            self.lastMicResult = @[];
            self.lastCameraResult = @[];
        }
        [self.controlCenterLogMonitor start:[NSPredicate predicateWithFormat:@"subsystem=='com.apple.controlcenter'"] level:Log_Level_Default callback:^(OSLogEvent * _Nonnull event) {
            NSArray *result = nil;
            if (@available(macOS 14.0, *)) {
                if ([event.composedMessage containsString:@"SystemStatus update: "]) {
                    result = [self _parseAttributionsFromLog:event.composedMessage];
                }
            } else if (@available(macOS 13.0, *)) {
                if ([event.composedMessage containsString:@"Active activity attributions changed to"]) {
                    result = [self _parseMacOS12AttributionsFromLog:event.composedMessage];
                }
            }
            if (result) {
                self.lastPrivacyResult = result;
                if (self.lastPrivacyResultDate && -[self.lastPrivacyResultDate timeIntervalSinceNow] < 1) { //后续消息延迟1秒消费
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (-[self.lastPrivacyResultDate timeIntervalSinceNow] > 1) {
                            self.lastPrivacyResultDate = [NSDate date];
                            [self _consumeResult:self.lastPrivacyResult];
                        }
                    });
                } else {
                    self.lastPrivacyResultDate = [NSDate date];
                    [self _consumeResult:self.lastPrivacyResult];
                }
            }
        }];
    }
}

- (void)_consumeResult:(NSArray *)result
{
    NSLog(@"_consumeResult %@", result);
    [self _processPrivacyStatusChange:result type:LMControlCenterLogStatusTypeCamera];
    [self _processPrivacyStatusChange:result type:LMControlCenterLogStatusTypeSystemAudio];
    [self _processPrivacyStatusChange:result type:LMControlCenterLogStatusTypeMicrophone];
}

- (NSArray *)_filterResultArray:(NSArray *)result type:(LMControlCenterLogStatusType)type;
{
    NSMutableArray *currentResult = [NSMutableArray new];
    for (LMControlCenterLogStatus *status in result) {
        if (status.type == type) {
            [currentResult addObject:status];
        }
    }
    return currentResult;
}

- (void)_processPrivacyStatusChange:(NSArray *)result type:(LMControlCenterLogStatusType)type;
{
    NSArray *lastResult = nil;
    NSArray *currentResult = [self _filterResultArray:result type:type];
    if (type == LMControlCenterLogStatusTypeSystemAudio) {
        if (!self.lastSystemAudioResult) {
            self.lastSystemAudioResult = currentResult;
            return;
        }
        lastResult = self.lastSystemAudioResult;
        self.lastSystemAudioResult = currentResult;
    } else if (type == LMControlCenterLogStatusTypeCamera) {
        if (!self.lastCameraResult) {
            self.lastCameraResult = currentResult;
            return;
        }
        lastResult = self.lastCameraResult;
        self.lastCameraResult = currentResult;
    } else if (type == LMControlCenterLogStatusTypeMicrophone) {
        if (!self.lastMicResult) {
            self.lastMicResult = currentResult;
            return;
        }
        lastResult = self.lastMicResult;
        self.lastMicResult = currentResult;
    } else {
        return;
    }
    
    if (currentResult.count <= 0 && lastResult.count <= 0) {
        return; //无变化
    }
    
    NSMutableArray *addArray = [NSMutableArray new];
    NSMutableArray *delArray = [NSMutableArray new];
    for (LMControlCenterLogStatus *lasStatus in lastResult) {
        BOOL didDel = YES;
        for (LMControlCenterLogStatus *currentStatus in currentResult) {
            if ([lasStatus.name isEqualToString:currentStatus.name]) {
                didDel = NO;
                break;
            }
        }
        if (didDel) {
            [delArray addObject:lasStatus];
            [self _processPrivacyEvent:lasStatus state:NSControlStateValueOff type:type];
        }
    }
    for (LMControlCenterLogStatus *currentStatus in currentResult) {
        BOOL didAdd = YES;
        for (LMControlCenterLogStatus *lasStatus in lastResult) {
            if ([lasStatus.name isEqualToString:currentStatus.name]) {
                didAdd = NO;
                break;
            }
        }
        if (didAdd) {
            [addArray addObject:currentStatus];
            NSLog(@"_processPrivacyStatusChange new event %@", currentStatus);
            [self _processPrivacyEvent:currentStatus state:NSControlStateValueOn type:type];
        }
    }
}

- (void)_processPrivacyEvent:(LMControlCenterLogStatus *)status state:(NSControlStateValue)state type:(LMControlCenterLogStatusType)type;
{
    Client *client = [[Client alloc] init];
    client.processBundleID = status.name;
    
    if (state == NSControlStateValueOff) { //用户kill或者app停止调用，都根据配对信息获取，避免pid等信息失效
        client.pid = nil;
    } else {
        client.pid = @(GUIApplicationPidForBundleIdentifier(status.name));
        NSString *processPath = getProcessPath(client.pid.intValue);
        client.path = valueForStringItem(processPath);
        client.name = valueForStringItem(getProcessName(client.path));
    }
    
    Event *event = nil;
    if (type == LMControlCenterLogStatusTypeSystemAudio) {
        event = [[Event alloc] init:client device:nil deviceType:Device_SystemAudio state:state];
    } else if (type == LMControlCenterLogStatusTypeCamera) {
        event = [[Event alloc] init:client device:self.activeCamera deviceType:Device_Camera state:state];
    } else if (type == LMControlCenterLogStatusTypeMicrophone) {
        event = [[Event alloc] init:client device:self.activeMic deviceType:Device_Microphone state:state];
    } else {
        return;
    }

    if (self.eventCallback) {
        self.eventCallback(event);
    }
}

- (NSArray *)_parseAttributionsFromLog:(NSString *)log {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[([a-zA-Z0-9_]+)\\]\\s*(.*?)\\s*\\(([^)]+)\\)" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
    
    if (error) {
        NSLog(@"regex error: %@", error);
        return @[];
    }
    
    NSArray *matches = [regex matchesInString:log options:0 range:NSMakeRange(0, log.length)];
    NSMutableArray *result = [NSMutableArray array];
    
    for (NSTextCheckingResult *match in matches) {
        if (match.numberOfRanges < 4) continue;
        
        LMControlCenterLogStatus *status = [LMControlCenterLogStatus new];
        NSString *type = [log substringWithRange:[match rangeAtIndex:1]];
        
        if ([type isEqualToString:@"mic"]) {
            status.type = LMControlCenterLogStatusTypeMicrophone;
        } else if ([type isEqualToString:@"aud"]) {
            status.type = LMControlCenterLogStatusTypeSystemAudio;
        } else if ([type isEqualToString:@"scr"]) {
            status.type = LMControlCenterLogStatusTypeScreen;
        } else if ([type isEqualToString:@"cam"]) {
            status.type = LMControlCenterLogStatusTypeCamera;
        } else {
            status.type = LMControlCenterLogStatusTypeUnknown;
        }
        
        status.displayName = [[log substringWithRange:[match rangeAtIndex:2]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        status.name = [log substringWithRange:[match rangeAtIndex:3]];
        
        if (status.type == LMControlCenterLogStatusTypeSystemAudio ||
            status.type == LMControlCenterLogStatusTypeCamera ||
            status.type == LMControlCenterLogStatusTypeMicrophone) {
            [result addObject:status];
        }
    }
    return [result copy];
}

- (NSArray *)_parseMacOS12AttributionsFromLog:(NSString *)log {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\"([^:]+):([^\"]+)\"" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
    
    if (error) {
        NSLog(@"regex error: %@", error);
        return @[];
    }
    
    NSArray *matches = [regex matchesInString:log options:0 range:NSMakeRange(0, log.length)];
    NSMutableArray *result = [NSMutableArray array];
    
    for (NSTextCheckingResult *match in matches) {
        if (match.numberOfRanges < 3) continue;
        
        LMControlCenterLogStatus *status = [LMControlCenterLogStatus new];
        NSString *type = [log substringWithRange:[match rangeAtIndex:1]];
        
        if ([type isEqualToString:@"mic"]) {
            status.type = LMControlCenterLogStatusTypeMicrophone;
        } else if ([type isEqualToString:@"aud"]) {
            status.type = LMControlCenterLogStatusTypeSystemAudio;
        } else if ([type isEqualToString:@"scr"]) {
            status.type = LMControlCenterLogStatusTypeScreen;
        } else if ([type isEqualToString:@"cam"]) {
            status.type = LMControlCenterLogStatusTypeCamera;
        } else {
            status.type = LMControlCenterLogStatusTypeUnknown;
        }
        
        status.name = [log substringWithRange:[match rangeAtIndex:2]];
        
        if (status.type == LMControlCenterLogStatusTypeSystemAudio ||
            status.type == LMControlCenterLogStatusTypeCamera ||
            status.type == LMControlCenterLogStatusTypeMicrophone) {
            [result addObject:status];
        }
    }
    return [result copy];
}

// 监听 intel 芯片 macOS 12/13 系统摄像头调用
- (void)monitor12VideoIntel
{
    NSLog(@"CPU architecuture: Intel ...will leverage 'VDCAssistant'");
    
    __block unsigned long long msgCount = 0;
    [self.logMonitor start:[NSPredicate predicateWithFormat:@"process == 'VDCAssistant'"] level:Log_Level_Default callback:^(OSLogEvent *logEvent) {
        msgCount++;
        // 新client，加入列表
        if (YES == [logEvent.composedMessage hasPrefix:@"Client Connect for PID"]) {
            
            NSLog(@"new client msg: %@", logEvent.composedMessage);
            
            NSInteger pid = [logEvent.composedMessage componentsSeparatedByString:@" "].lastObject.intValue;
            if (pid > 0) {
                self.lastCameraClient = pid;
                NSLog(@"new client: %@", @(pid));
            }
        }
    }];
}

- (void)monitor12Audio
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"pid:(\\d*)," options:0 error:nil];
    [self.audio13logMonitor start:[NSPredicate predicateWithFormat:@"process == 'coreaudiod' && subsystem == 'com.apple.TCC' && category == 'access'"] level:Log_Level_Info callback:^(OSLogEvent *logEvent) {
        //tcc request
        if (YES == [logEvent.composedMessage containsString:@"function=TCCAccessRequest, service=kTCCServiceMicrophone"]) {
            NSLog(@"new tcc access msg: %@", logEvent.composedMessage);
            NSTextCheckingResult *match = nil;
            match = [regex firstMatchInString:logEvent.composedMessage options:0 range:NSMakeRange(0, logEvent.composedMessage.length)];
            if ((nil == match) ||
                (NSNotFound == match.range.location) ||
                (match.numberOfRanges < 2)) {
                //ignore
                return;
            }
            
            NSInteger pid = [[logEvent.composedMessage substringWithRange:[match rangeAtIndex:1]] intValue];
            if (pid <= 0) {
                return;
            }
            self.lastMicClient = pid;
            NSLog(@"new client: %@", @(pid));
        }
    }];
}

- (BOOL)isRunOnAppleSilicon {
    BOOL result = NO;
    if (@available(macOS 11, *)) {
        char buf[100];
        size_t buflen = 100;
        sysctlbyname("machdep.cpu.brand_string", &buf, &buflen, NULL, 0);
        NSString *cupArch = [[NSString alloc] initWithCString:(char*)buf encoding:NSASCIIStringEncoding];
        if ([cupArch containsString:@"Apple"]) {
            result = YES;
        } else {
            result = NO;
        }
    }
    return result;
}

- (void)monitorSystemStatus
{
    //dbg msg
    NSLog(@"< macOS 13.3+: Using 'com.apple.SystemStatus'");
    
    //start logging
    [self.logMonitor start:[NSPredicate predicateWithFormat:@"subsystem=='com.apple.SystemStatus'"] level:Log_Level_Default callback:^(OSLogEvent* logEvent) {
        
        //sync to process
        @synchronized (self) {
            
            //flags
            BOOL audioAttributionsList = NO;
            BOOL cameraAttributionsList = NO;
            
            //new audio attributions
            NSMutableArray* newAudioAttributions = nil;
            
            //new camera attributions
            NSMutableArray* newCameraAttributions = nil;
            
            //only interested on "Server data changed..." msgs
            if(YES != [logEvent.composedMessage containsString:@"Server data changed for media domain"])
            {
                return;
            }
            
            //split on newlines
            // ...and then parse out audio/camera attributions
            for(NSString* __strong line in [logEvent.composedMessage componentsSeparatedByString:@"\n"])
            {
                //pid
                NSNumber* pid = 0;
                
                //trim
                line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
                //'audioAttributions' list?
                if( (YES == [line hasPrefix:@"audioAttributions = "]) ||
                   (YES == [line hasPrefix:@"audioRecordingAttributions = "]) )
                {
                    //dbg msg
                    NSLog(@"found 'audio attributions'");
                    
                    //set flag
                    audioAttributionsList = YES;
                    
                    //init
                    newAudioAttributions = [NSMutableArray array];
                    
                    //unset (other) list
                    cameraAttributionsList = NO;
                    
                    //next
                    continue;
                }
                
                //'cameraAttributions' list?
                if( (YES == [line hasPrefix:@"cameraAttributions = "]) ||
                   (YES == [line hasPrefix:@"cameraCaptureAttributions = "]) )
                {
                    //dbg msg
                    NSLog(@"found 'camera attributions'");
                    
                    //set flag
                    cameraAttributionsList = YES;
                    
                    //init
                    newCameraAttributions = [NSMutableArray array];
                    
                    //unset (other) list
                    audioAttributionsList = NO;
                    
                    //next
                    continue;
                }
                
                //audit token of item?
                if(YES == [line containsString:@"<BSAuditToken:"])
                {
                    //dbg msg
                    NSLog(@"line has audit token...");
                    
                    //pid extraction regex
                    NSRegularExpression* regex = nil;
                    
                    //match
                    NSTextCheckingResult* match = nil;
                    
                    //init regex
                    regex = [NSRegularExpression regularExpressionWithPattern:@"(?<=PID: )[0-9]*" options:0 error:nil];
                    
                    //match/extract pid
                    match = [regex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
                    if( (nil == match) ||
                       (NSNotFound == match.range.location))
                    {
                        //dbg msg
                        NSLog(@"no match on regex");
                        
                        //ignore
                        continue;
                    }
                    
                    //extract pid
                    pid = @([[line substringWithRange:[match rangeAtIndex:0]] intValue]);
                    
                    //dbg msg
                    NSLog(@"pid: %@", pid);
                    
                    //in audio list?
                    if(YES == audioAttributionsList)
                    {
                        //dbg msg
                        NSLog(@"...for audio");
                        
                        //add
                        [newAudioAttributions addObject:[NSNumber numberWithInt:[pid intValue]]];
                    }
                    //in camera list?
                    else if(YES == cameraAttributionsList)
                    {
                        //dbg msg
                        NSLog(@"...for camera");
                        
                        //add
                        [newCameraAttributions addObject:[NSNumber numberWithInt:[pid intValue]]];
                    }
                    
                    //next
                    continue;
                }
            }
            
            //macOS 12: off events trigger the removal of the list
            // so then we'll just pass in an empty list in that case
            if(12 == NSProcessInfo.processInfo.operatingSystemVersion.majorVersion)
            {
                //nil?
                if(nil == newAudioAttributions)
                {
                    //init blank
                    newAudioAttributions = [NSMutableArray array];
                }
                
                //nil?
                if(nil == newCameraAttributions)
                {
                    //init blank
                    newCameraAttributions = [NSMutableArray array];
                }
            }
            
            //process attibutions
            [self processAttributions:newAudioAttributions newCameraAttributions:newCameraAttributions];
            
        }//sync
        
    }];
}

//process attributions
// will generate (any needed) events to trigger alerts to user
-(void)processAttributions:(NSMutableArray*)newAudioAttributions newCameraAttributions:(NSMutableArray*)newCameraAttributions
{
    //audio differences
    NSOrderedCollectionDifference* audioDifferences = nil;
    
    //camera differences
    NSOrderedCollectionDifference* cameraDifferences = nil;
    
    //client
    __block Client* client = nil;
    
    //event
    __block Event* event = nil;
    
    //dbg msg
    NSLog(@"method '%s' invoked", __PRETTY_FUNCTION__);
    
    //diff audio differences
    if( (nil != newAudioAttributions) &&
        (nil != self.audioAttributions) )
    {
        //diff
        audioDifferences = [newAudioAttributions differenceFromArray:self.audioAttributions];
    }
    
    //diff camera differences
    if( (nil != newCameraAttributions) &&
        (nil != self.cameraAttributions) )
    {
        //diff
        cameraDifferences = [newCameraAttributions differenceFromArray:self.cameraAttributions];
    }
    
    /* audio event logic */
    
    //new audio event?
    // handle (lookup mic, send event)
    if(YES == audioDifferences.hasChanges)
    {
        //dbg msg
        NSLog(@"new audio event");
        
        //active mic
        AVCaptureDevice* activeMic = nil;
        
        //audio off?
        // sent event
        if(0 == audioDifferences.insertions.count)
        {
            //dbg msg
            NSLog(@"audio event: off");
            
            //init event
            // process (client) and device are nil
            event = [[Event alloc] init:nil device:nil deviceType:Device_Microphone state:NSControlStateValueOff];
            
            //handle event
            [self handleEvent:event];
        }
        
        //audio on?
        // send event
        else
        {
            //dbg msg
            NSLog(@"audio event: on");
            
            //send event for each process (attribution)
            for(NSOrderedCollectionChange* audioAttribution in audioDifferences.insertions)
            {
                //init client from attribution
                client = [[Client alloc] init];
                client.pid = audioAttribution.object;
                client.path = valueForStringItem(getProcessPath(client.pid.intValue));
                client.name = valueForStringItem(getProcessName(client.path));
                
                //look for active mic
                for(AVCaptureDevice* microphone in [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio])
                {
                    //off? skip
                    if(NSControlStateValueOn != [self getMicState:microphone])
                    {
                        //skip
                        continue;
                    }
                    
                    //dbg msg
                    NSLog(@"audio device: %@/%@ is on", microphone.manufacturer, microphone.localizedName);
                    
                    //save
                    activeMic = microphone;
                    
                    //init event
                    // with client and (active) mic
                    event = [[Event alloc] init:client device:activeMic deviceType:Device_Microphone state:NSControlStateValueOn];
                    
                    //handle event
                    [self handleEvent:event];
                }
                
                //no mic found? (e.g. headphones as input)
                // show (limited) alert
                if(nil == activeMic)
                {
                    //init event
                    // devivce is nil
                    event = [[Event alloc] init:client device:nil deviceType:Device_Microphone state:NSControlStateValueOn];
                    
                    //handle event
                    [self handleEvent:event];
                }
            }
        }
    
    } //audio event
    
    /* camera event logic */

    //new camera event?
    // handle (lookup camera, send event)
    if(YES == cameraDifferences.hasChanges)
    {
        //dbg msg
        NSLog(@"new camera event");
        
        //active camera
        AVCaptureDevice* activeCamera = nil;
            
        //camera off?
        // send event
        if(0 == cameraDifferences.insertions.count)
        {
            //dbg msg
            NSLog(@"camera event: off");
            
            //init event
            // process (client) and device are nil
            event = [[Event alloc] init:nil device:nil deviceType:Device_Camera state:NSControlStateValueOff];
            
            //handle event
            [self handleEvent:event];
        }
        
        //camera on?
        // send event
        else
        {
            //dbg msg
            NSLog(@"camera event: on");
            
            //send event for each process (attribution)
            for(NSOrderedCollectionChange* cameraAttribution in cameraDifferences.insertions)
            {
                //init client from attribution
                client = [[Client alloc] init];
                client.pid = cameraAttribution.object;
                client.path = valueForStringItem(getProcessPath(client.pid.intValue));
                client.name = valueForStringItem(getProcessName(client.path));
                
                //look for active camera
                for(AVCaptureDevice* camera in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
                {
                    //off? skip
                    if(NSControlStateValueOn != [self getCameraState:camera])
                    {
                        //skip
                        continue;
                    }
                    
                    //virtual
                    // TODO: is there a better way to determine this?
                    if(YES == [camera.localizedName containsString:@"Virtual"])
                    {
                        //skip
                        continue;
                    }
                    
                    //dbg msg
                    NSLog(@"camera device: %@/%@ is on", camera.manufacturer, camera.localizedName);
                    
                    //save
                    activeCamera = camera;
                    
                    //init event
                    // with client and (active) camera
                    event = [[Event alloc] init:client device:activeCamera deviceType:Device_Camera state:NSControlStateValueOn];
                    
                    //handle event
                    [self handleEvent:event];
                }
                
                //no camera found?
                // show (limited) alert
                if(nil == activeCamera)
                {
                    //init event
                    // devivce is nil
                    event = [[Event alloc] init:client device:nil deviceType:Device_Camera state:NSControlStateValueOn];
                    
                    //handle event
                    [self handleEvent:event];
                }
            }
        }
        
    } //camera event
     
    //update audio attributions
    self.audioAttributions = [newAudioAttributions copy];
        
    //update camera attributions
    self.cameraAttributions = [newCameraAttributions copy];
    
    return;
}

//TODO: refactor alerts
// delay showing them!

//register for audio changes
-(BOOL)watchAudioDevice:(AVCaptureDevice*)device
{
    //ret var
    BOOL bRegistered = NO;
    
    //status var
    OSStatus status = -1;
    
    //device ID
    AudioObjectID deviceID = 0;
    
    //property struct
    AudioObjectPropertyAddress propertyStruct = {0};
    
    //init property struct's selector
    propertyStruct.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere;
    
    //init property struct's scope
    propertyStruct.mScope = kAudioObjectPropertyScopeGlobal;
    
    //init property struct's element
    propertyStruct.mElement = kAudioObjectPropertyElementMain;
    
    //block
    // invoked when audio changes
    AudioObjectPropertyListenerBlock listenerBlock = ^(UInt32 inNumberAddresses, const AudioObjectPropertyAddress *inAddresses)
    {
        //state
        NSInteger state = -1;

        //get state
        state = [self getMicState:device];
        
        //dbg msg
        NSLog(@"Mic: %@ changed state to %ld", device.localizedName, (long)state);
        
        //save last mic off
        if(NSControlStateValueOff == state)
        {
            //save
            self.lastMicOff = device;
        }
    
        //macOS 13.3+
        // use this as trigger
        // older version send event via log monitor
        if (@available(macOS 12.0, *)) {
            
            //dbg msg
            NSLog(@"new audio event");
            
            //audio off?
            if(NSControlStateValueOff == state)
            {
                //dbg msg
                NSLog(@"audio event: off");
                self.lastMicClient = 0;
                
                if (@available(macOS 13.0, *)) { //13以上直接使用控制中心日志
                } else {
                    //still wait
                    // cuz the on event is waiting...
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        
                        //init event
                        // process (client) and device are nil
                        Event *event = [[Event alloc] init:nil device:device deviceType:Device_Microphone state:NSControlStateValueOff];
                        
                        //handle event
                        [self handleEvent:event];
                        
                    });
                }
            }
            
            //audio on?
            else if(NSControlStateValueOn == state)
            {
                //dbg msg
                NSLog(@"audio event: on");
                self.activeMic = device;
                
                
                if (@available(macOS 13.0, *)) { //13以上直接使用控制中心日志
                } else {
                    
                    //delay
                    // need time for logging to grab responsible process
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        
                        Client* client = nil;
                        if(0 != self.lastMicClient)
                        {
                            //init client from attribution
                            client = [[Client alloc] init];
                            client.pid = [NSNumber numberWithInteger:self.lastMicClient];
                            client.path = valueForStringItem(getProcessPath(client.pid.intValue));
                            client.name = valueForStringItem(getProcessName(client.path));
                        }
                        Event *event = [[Event alloc] init:client device:device deviceType:Device_Microphone state:NSControlStateValueOn];
                        [self handleEvent:event];
                    });
                }
            }
        } //macOS 13.3+
    };
    
    //get device ID
    deviceID = [self getAVObjectID:device];
    if(0 == deviceID)
    {
        //err msg
        os_log_error(logHandle, "ERROR: 'failed to find %@'s object id", device.localizedName);
        
        //bail
        goto bail;
    }
    
    //add property listener for audio changes
    status = AudioObjectAddPropertyListenerBlock(deviceID, &propertyStruct, self.eventQueue, listenerBlock);
    if(noErr != status)
    {
        //err msg
        os_log_error(logHandle, "ERROR: AudioObjectAddPropertyListenerBlock() failed with %d", status);
        
        //bail
        goto bail;
    }
    
    //save
    self.audioListeners[device.uniqueID] = listenerBlock;
    
    //dbg msg
    NSLog(@"monitoring %@ (uuid: %@ / %x) for audio changes", device.localizedName, device.uniqueID, deviceID);

    //happy
    bRegistered = YES;
    
bail:
    
    return bRegistered;
}

//register for video changes
-(BOOL)watchVideoDevice:(AVCaptureDevice*)device
{
    //ret var
    BOOL bRegistered = NO;
    
    //status var
    OSStatus status = -1;
    
    //device id
    CMIOObjectID deviceID = 0;
    
    //property struct
    CMIOObjectPropertyAddress propertyStruct = {0};
    
    //init property struct's selector
    propertyStruct.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere;
    
    //init property struct's scope
    propertyStruct.mScope = kAudioObjectPropertyScopeGlobal;
    
    //init property struct's element
    propertyStruct.mElement = kAudioObjectPropertyElementMain;
    
    //block
    // invoked when video changes
    CMIOObjectPropertyListenerBlock listenerBlock = ^(UInt32 inNumberAddresses, const CMIOObjectPropertyAddress addresses[])
    {
        //state
        NSInteger state = -1;
    
        //get state
        state = [self getCameraState:device];
        
        //dbg msg
        NSLog(@"Camera: %@ changed state to %ld", device.localizedName, (long)state);
        
        //save last camera off
        if(NSControlStateValueOff == state)
        {
            //save
            self.lastCameraOff = device;
        }
        
        //camera on?
        // macOS 13.3+, use this as trigger
        // older version send event via log monitor
        // 从12系统开始观察设备状态
        if (@available(macOS 12.0, *)) {
            //dbg msg
            NSLog(@"new camera event");
            
            //camera: on
            if(NSControlStateValueOn == state)
            {
                NSLog(@"camera event: on");
                self.activeCamera = device;
                
                //delay
                // need time for logging to grab responsible process
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                    if (@available(macOS 13.0, *)) { //13以上直接使用控制中心日志
                    } else {
                        Client* client = nil;
                        if(0 != self.lastCameraClient)
                        {
                            //init client from attribution
                            client = [[Client alloc] init];
                            client.pid = [NSNumber numberWithInteger:self.lastCameraClient];
                            client.path = valueForStringItem(getProcessPath(client.pid.intValue));
                            client.name = valueForStringItem(getProcessName(client.path));
                        }
                        Event *event = [[Event alloc] init:client device:device deviceType:Device_Camera state:NSControlStateValueOn];
                        [self handleEvent:event];
                    }

                });
            }
            
            //camera: off
            else if(NSControlStateValueOff == state)
            {
                //dbg msg
                NSLog(@"camera event: off");
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    if (@available(macOS 13.0, *)) { //13以上直接使用控制中心日志
                    } else {
                        Event *event = [[Event alloc] init:nil device:device deviceType:Device_Camera state:NSControlStateValueOff];
                        [self handleEvent:event];
                    }
                });
            }
        } //macOS 13.3
    };
    
    //get device ID
    deviceID = [self getAVObjectID:device];
    if(0 == deviceID)
    {
        //err msg
        os_log_error(logHandle, "ERROR: 'failed to find %@'s object id", device.localizedName);
        
        //bail
        goto bail;
    }
    
    //register (add) property block listener
    status = CMIOObjectAddPropertyListenerBlock(deviceID, &propertyStruct, self.eventQueue, listenerBlock);
    if(noErr != status)
    {
        //err msg
        os_log_error(logHandle, "ERROR: CMIOObjectAddPropertyListenerBlock() failed with %d", status);
        
        //bail
        goto bail;
    }
    
    //save
    self.cameraListeners[device.uniqueID] = listenerBlock;
    
    //dbg msg
    NSLog(@"monitoring %@ (uuid: %@ / %x) for video changes", device.localizedName, device.uniqueID, deviceID);
    
    //happy
    bRegistered = YES;
    
bail:
    
    return bRegistered;
}

//enumerate active devices
-(NSMutableArray*)enumerateActiveDevices
{
    //active device
    NSMutableArray* activeDevices = nil;
    
    //init
    activeDevices = [NSMutableArray array];
    
    //look for active cameras
    for(AVCaptureDevice* camera in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
    {
        //skip virtual devices (e.g. OBS virtual camera)
        // TODO: is there a better way to determine this?
        if(YES == [camera.localizedName containsString:@"Virtual"])
        {
            //skip
            continue;
        }
        
        //save those that are one
        if(NSControlStateValueOn == [self getCameraState:camera])
        {
            //save
            [activeDevices addObject:camera];
        }
    }
    
    //look for active mic
    for(AVCaptureDevice* microphone in [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio])
    {
        //save those that are one
        if(NSControlStateValueOn == [self getMicState:microphone])
        {
            //save
            [activeDevices addObject:microphone];
        }
    }
    
    return activeDevices;
}

//get built-in mic
// looks for Apple device that's 'BuiltInMicrophoneDevice'
-(AVCaptureDevice*)findBuiltInMic
{
    //mic
    AVCaptureDevice* builtInMic = 0;
    
    //built in mic appears as "BuiltInMicrophoneDevice"
    for(AVCaptureDevice* currentMic in [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio])
    {
        //dbg msg
        NSLog(@"device: %@/%@/%@", currentMic.manufacturer, currentMic.localizedName, currentMic.uniqueID);
        
        //is device apple + built in mic?
        if(YES == [currentMic.manufacturer isEqualToString:@"Apple Inc."])
        {
            //is built in mic?
            if( (YES == [currentMic.uniqueID isEqualToString:@"BuiltInMicrophoneDevice"]) ||
                (YES == [currentMic.localizedName isEqualToString:@"Built-in Microphone"]) )
            {
                //found
                builtInMic = currentMic;
                break;
            }
        }
    }
    
    //not found?
    // grab default
    if(0 == builtInMic)
    {
        //get mic / id
        builtInMic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        
        //dbg msg
        NSLog(@"Apple Mic not found, defaulting to default device: %@/%@", builtInMic.manufacturer, builtInMic.localizedName);
    }
    
    return builtInMic;
}

//get built-in camera
-(AVCaptureDevice*)findBuiltInCamera
{
    //camera
    AVCaptureDevice* builtInCamera = 0;
    
    //built in mic appears as "BuiltInMicrophoneDevice"
    for(AVCaptureDevice* currentCamera in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
    {
        //dbg msg
        NSLog(@"device: %@/%@/%@", currentCamera.manufacturer, currentCamera.localizedName, currentCamera.uniqueID);
        
        //is device apple + built in camera?
        if(YES == [currentCamera.manufacturer isEqualToString:@"Apple Inc."])
        {
            //is built in camera?
            if( (YES == [currentCamera.uniqueID isEqualToString:@"FaceTime HD Camera"]) ||
                (YES == [currentCamera.localizedName isEqualToString:@"FaceTime-HD-camera"]) ||
                (YES == [currentCamera.localizedName isEqualToString:@"FaceTime HD Camera"]) )
            {
                //found
                builtInCamera = currentCamera;
                break;
            }
        }
    }
    
    //not found?
    // grab default
    if(0 == builtInCamera)
    {
        //get mic / id
        builtInCamera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        //dbg msg
        NSLog(@"Apple Camera not found, defaulting to default device: %@/%@)", builtInCamera.manufacturer, builtInCamera.localizedName);
    }
    
    return builtInCamera;
}

//get av object's ID
-(UInt32)getAVObjectID:(AVCaptureDevice*)device
{
    //object id
    UInt32 objectID = 0;
    
    //selector for getting device id
    SEL methodSelector = nil;

    //init selector
    methodSelector = NSSelectorFromString(@"connectionID");
    
    //sanity check
    if(YES != [device respondsToSelector:methodSelector])
    {
        //bail
        goto bail;
    }
    
    //ignore warning
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wpointer-to-int-cast"
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"

    //grab connection ID
    objectID = (UInt32)[device performSelector:methodSelector withObject:nil];
    
    //restore
    #pragma clang diagnostic pop
    
bail:
    
    return objectID;
}

//determine if audio device is active
-(UInt32)getMicState:(AVCaptureDevice*)device
{
    //status var
    OSStatus status = -1;
    
    //device ID
    AudioObjectID deviceID = 0;
    
    //running flag
    UInt32 isRunning = 0;
    
    //size of query flag
    UInt32 propertySize = 0;
    
    //get device ID
    deviceID = [self getAVObjectID:device];
    if(0 == deviceID)
    {
        //err msg
        os_log_error(logHandle, "ERROR: 'failed to find %@'s object id", device.localizedName);
        
        //set error
        isRunning = -1;
        
        //bail
        goto bail;
    }
    
    //init size
    propertySize = sizeof(isRunning);
    
    //query to get 'kAudioDevicePropertyDeviceIsRunningSomewhere' status
    status = AudioDeviceGetProperty(deviceID, 0, false, kAudioDevicePropertyDeviceIsRunningSomewhere, &propertySize, &isRunning);
    if(noErr != status)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to get run state for %@ (error: %#x)", device.localizedName, status);
        
        //set error
        isRunning = -1;
        
        //bail
        goto bail;
    }
    
bail:
    
    return isRunning;
}

//check if a specified video is active
// note: on M1 this sometimes always says 'on' (smh apple)
-(UInt32)getCameraState:(AVCaptureDevice*)device
{
    //status var
    OSStatus status = -1;
    
    //device ID
    CMIODeviceID deviceID = 0;
    
    //running flag
    UInt32 isRunning = 0;
    
    //size of query flag
    UInt32 propertySize = 0;
    
    //property address struct
    CMIOObjectPropertyAddress propertyStruct = {0};
    
    //get device ID
    deviceID = [self getAVObjectID:device];
    if(0 == deviceID)
    {
        //err msg
        os_log_error(logHandle, "ERROR: 'failed to find %@'s object id", device.localizedName);
        
        //set error
        isRunning = -1;
        
        //bail
        goto bail;
    }
    
    //init size
    propertySize = sizeof(isRunning);
    
    //init property struct's selector
    propertyStruct.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere;
    
    //init property struct's scope
    propertyStruct.mScope = kCMIOObjectPropertyScopeGlobal;
    
    //init property struct's element
    propertyStruct.mElement = kAudioObjectPropertyElementMain;
    
    //query to get 'kAudioDevicePropertyDeviceIsRunningSomewhere' status
    status = CMIOObjectGetPropertyData(deviceID, &propertyStruct, 0, NULL, sizeof(kAudioDevicePropertyDeviceIsRunningSomewhere), &propertySize, &isRunning);
    if(noErr != status)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to get run state for %@ (error: %#x)", device.localizedName, status);
        
        //set error
        isRunning = -1;
        
        //bail
        goto bail;
    }

bail:
    
    return isRunning;
}

//should an event be shown?
-(NSUInteger)shouldShowNotification:(Event*)event
{
    //result
    NSUInteger result = NOTIFICATION_ERROR;

    //device ID
    NSNumber* deviceID = 0;
    
    //device's last event
    Event* deviceLastEvent = nil;
    
    //get device ID
    deviceID = [NSNumber numberWithInt:[self getAVObjectID:event.device]];
    if(0 == deviceID)
    {
        //err msg
        os_log_error(logHandle, "ERROR: 'failed to find %@'s object id", event.device.localizedName);
        
        //bail
        goto bail;
    }
    
    //extract its last event
    deviceLastEvent = self.deviceEvents[deviceID];
    
    //disabled?
    // really shouldn't ever get here, but can't hurt to check
    if(YES == [NSUserDefaults.standardUserDefaults boolForKey:PREF_IS_DISABLED])
    {
        //set result
        result = NOTIFICATION_SPURIOUS;
        
        //dbg msg
        NSLog(@"disable is set, so ignoring event");
            
        //bail
        goto bail;
    }
    
    //inactive alerting off?
    // ignore if event is an inactive/off
    if( (NSControlStateValueOff == event.state) &&
        (YES == [NSUserDefaults.standardUserDefaults boolForKey:PREF_DISABLE_INACTIVE]))
    {
        //set result
        result = NOTIFICATION_SKIPPED;
        
        //dbg msg
        NSLog(@"disable inactive alerts set, so ignoring inactive/off event");
            
        //bail
        goto bail;
    }
    
    //no external devices mode?
    if(YES == [NSUserDefaults.standardUserDefaults boolForKey:PREF_NO_EXTERNAL_DEVICES_MODE])
    {
        //on?
        // we have the device directly
        if(NSControlStateValueOn == event.state)
        {
            //external device?
            // don't show notification
            if( (YES != [self.builtInMic.uniqueID isEqualToString:event.device.uniqueID]) &&
                (YES != [self.builtInCamera.uniqueID isEqualToString:event.device.uniqueID]) )
            {
                //set result
                result = NOTIFICATION_SKIPPED;
                
                //dbg msg
                NSLog(@"ingore external devices is set, so ignoring external device 'on' event");
                
                //bail
                goto bail;
            }
        }
        
        //off
        // check last device that turned off
        else
        {
            //mic
            // check last mic off device
            if( (Device_Microphone == event.deviceType) &&
                (nil != self.lastMicOff) &&
                (YES != [self.builtInMic.uniqueID isEqualToString:self.lastMicOff.uniqueID]) )
            {
                //set result
                result = NOTIFICATION_SKIPPED;
                
                //dbg msg
                NSLog(@"ingore external devices is set, so ignoring external mic 'off' event");
                
                //bail
                goto bail;
            }
            
            //camera
            // check last camera off device
            if( (Device_Camera == event.deviceType) &&
                (nil != self.lastCameraOff) &&
                (YES != [self.builtInCamera.uniqueID isEqualToString:self.lastCameraOff.uniqueID]) )
            {
                //set result
                result = NOTIFICATION_SKIPPED;
                
                //dbg msg
                NSLog(@"ingore external devices is set, so ignoring external camera 'off' event");
                
                //bail
                goto bail;
            }
        }
        
    } //PREF_NO_EXTERNAL_DEVICES_MODE
    
    //macOS sometimes toggles delivers 2x events for same device
    if(deviceLastEvent.deviceType == event.deviceType)
    {
        //ignore if last event was < 1.0s ago
        if([event.timestamp timeIntervalSinceDate:deviceLastEvent.timestamp] < 1.0f)
        {
            //ignore if last event was same state
            if( (deviceLastEvent.state == event.state) &&
                ([event.timestamp timeIntervalSinceDate:deviceLastEvent.timestamp] < 1.0f) )
            {
                //set result
                result = NOTIFICATION_SPURIOUS;
                
                //dbg msg
                NSLog(@"ignoring event as it was same state as last (%ld), and happened <1.0s ago", (long)event.state);
                
                //bail
                goto bail;
            }
        }
        
    } //same device

    //client provided?
    // check if its allowed
    if(nil != event.client)
    {
        //match is simply: device and path
        for(NSDictionary* allowedItem in [NSUserDefaults.standardUserDefaults objectForKey:PREFS_ALLOWED_ITEMS])
        {
            //match?
            if( ([allowedItem[EVENT_DEVICE] intValue] == event.deviceType) &&
                (YES == [allowedItem[EVENT_PROCESS_PATH] isEqualToString:event.client.path]) )
            {
                //set result
                result = NOTIFICATION_SKIPPED;
                
                //dbg msg
                NSLog(@"%@ is allowed to access %d, so no notification will not be shown", event.client.path, event.deviceType);
                
                //done
                goto bail;
            }
        }
    }
    
    //set result
    result = NOTIFICATION_DELIVER;
    
bail:
    
    //(always) update last event
    self.deviceEvents[deviceID] = event;
    
    return result;
}

//handle an event
// show alert / exec user action
-(void)handleEvent:(Event*)event
{
    if (self.eventCallback) {
        self.eventCallback(event);
        return;
    }
#if kLemonUseAVMonitorNotification
    //result
    NSInteger result = NOTIFICATION_ERROR;
    
    //dbg msg
    NSLog(@"handling event: %@", event);
    
    //should show?
    @synchronized (self) {
        
       //show?
       result = [self shouldShowNotification:event];
    }
    
    //dbg msg
    NSLog(@"'shouldShowNotification:' method returned %ld", (long)result);
    
    //deliver/show user?
    if(NOTIFICATION_DELIVER == result)
    {
        //deliver
        [self showNotification:event];
    }
    //should (also) exec user action?
    if( (NOTIFICATION_ERROR != result) &&
        (NOTIFICATION_SPURIOUS != result) &&
        (0 != [[NSUserDefaults.standardUserDefaults objectForKey:PREF_EXECUTE_PATH] length]) )
    {
        //exec
        [self executeUserAction:event];
    }

    return;
#endif
}

#if kLemonUseAVMonitorNotification
//build and display notification
-(void)showNotification:(Event*)event
{
    //notification content
    UNMutableNotificationContent* content = nil;
    
    //notificaito0n request
    UNNotificationRequest* request = nil;
    
    //alloc content
    content = [[UNMutableNotificationContent alloc] init];
    
    //title
    NSMutableString* title = nil;
    
    //set (default) category
    content.categoryIdentifier = CATEGORY_CLOSE;
    
    //alloc title
    title = [NSMutableString string];

    //set device type
    (Device_Camera == event.deviceType) ? [title appendString:@"📸"] : [title appendFormat:@"🎙️"];
    
    //set status
    (NSControlStateValueOn == event.state) ? [title appendString:NSLocalizedString(@" Became Active!",@" Became Active!")] : [title appendString:NSLocalizedString(@" Became Inactive.", @" Became Inactive.")];
    
    //set title
    content.title = title;
    
    //sub-title
    // device name
    if(nil != event.device)
    {
        //set
        content.subtitle = [NSString stringWithFormat:@"%@", event.device.localizedName];
    }
    
    //have client?
    // use as body
    if(nil != event.client)
    {
        //set body
        content.body = [NSString stringWithFormat:NSLocalizedString(@"Process: %@ (%@)", @"Process: %@ (%@)"), event.client.name, (0 != event.client.pid.intValue) ? event.client.pid : NSLocalizedString(@"pid: unknown", @"pid: unknown")];
        
        //set category
        content.categoryIdentifier = CATEGORY_ACTION;
        
        //set user info
        content.userInfo = @{EVENT_DEVICE:@(event.deviceType), EVENT_PROCESS_ID:event.client.pid, EVENT_PROCESS_PATH:event.client.path};
    }
    else if(nil != event.device)
    {
        //set body
        content.body = [NSString stringWithFormat:NSLocalizedString(@"Device: %@", @"Device: %@"), event.device.localizedName];
    }
    
    //init request
    request = [UNNotificationRequest requestWithIdentifier:NSUUID.UUID.UUIDString content:content trigger:NULL];
    
    //log: on
    if(NSControlStateValueOn == event.state)
    {
        //log
        os_log(logHandle, "[Alert] On Event: %@ / Device: %@ / %@", content.title, content.subtitle, content.body);
    }
    //log: off
    else
    {
        //log
        os_log(logHandle, "[Alert] Off Event: %@ / Device: %@", content.title, content.subtitle);
    }
    
    //send notification
    [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error)
    {
        //error?
        if(nil != error)
        {
            //err msg
            os_log_error(logHandle, "ERROR failed to deliver notification (error: %@)", error);
        }
    }];

bail:

    return;
}

//execute user action
// via the shell to handle binaries and scripts
-(BOOL)executeUserAction:(Event*)event
{
    //flag
    BOOL wasExecuted = NO;
    
    //path to action
    NSString* action = nil;
    
    //args
    NSMutableString* args = nil;
    
    //dbg msg
    NSLog(@"executing user action");
    
    //alloc
    args = [NSMutableString string];
    
    //grab action
    action = [NSUserDefaults.standardUserDefaults objectForKey:PREF_EXECUTE_PATH];
    if(YES != [NSFileManager.defaultManager fileExistsAtPath:action])
    {
        //err msg
        os_log_error(logHandle, "ERROR: action %@, does not exist", action);
        
        //bail
        goto bail;
    }
    
    //pass args?
    if(YES == [NSUserDefaults.standardUserDefaults boolForKey:PREF_EXECUTE_ACTION_ARGS])
    {
        //add device
        [args appendString:@"-device "];
        (Device_Camera == event.deviceType) ? [args appendString:@"camera"] : [args appendString:@"microphone"];
        
        //add event
        [args appendString:@" -event "];
        (NSControlStateValueOn == event.state) ? [args appendString:@"on"] : [args appendString:@"off"];
        
        //add process
        if(nil != event.client)
        {
            //add
            [args appendString:@" -process "];
            [args appendString:event.client.pid.stringValue];
        }
        
        //add active device count
        [args appendString:@" -activeCount "];
        [args appendFormat:@"%lu", [self enumerateActiveDevices].count];
    }
    
    //exec user specified action
    execTask(SHELL, @[@"-c", [NSString stringWithFormat:@"\"%@\" %@", action, args]], NO, NO);
    
bail:
    
    return wasExecuted;
}
#endif

//stop monitor
-(void)stop
{
    //dbg msg
    NSLog(@"stopping log monitor");

    //stop log monitoring
    [self.logMonitor stop];
    [self.audio13logMonitor stop];
    [self.controlCenterLogMonitor stop];
    
    //dbg msg
    NSLog(@"stopping audio monitor(s)");
    
    //unwatch all input audio (mic) devices
    for(AVCaptureDevice* audioDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio])
    {
        //unwatch
        [self unwatchAudioDevice:audioDevice];
    }
       
    //dbg msg
    NSLog(@"stopping video monitor(s)");
    
    //unwatch all input video (cam) devices
    for(AVCaptureDevice* videoDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
    {
        //unwatch
        [self unwatchVideoDevice:videoDevice];
    }
    
    //dbg msg
    NSLog(@"unregistering notifications");
    
    //remove connection notification
    [NSNotificationCenter.defaultCenter removeObserver:self name:AVCaptureDeviceWasConnectedNotification object:nil];
    
    //remove disconnection notification
    [NSNotificationCenter.defaultCenter removeObserver:self name:AVCaptureDeviceWasDisconnectedNotification object:nil];
    
    //dbg msg
    NSLog(@"all stopped...");
    
    return;
}

//stop audio monitor
-(void)unwatchAudioDevice:(AVCaptureDevice*)device
{
    //status
    OSStatus status = -1;
    
    //device ID
    AudioObjectID deviceID = 0;

    //property struct
    AudioObjectPropertyAddress propertyStruct = {0};
    
    //bail if device was disconnected
    if(NO == device.isConnected)
    {
        //bail
        goto bail;
    }
    
    //get device ID
    deviceID = [self getAVObjectID:device];
    if(0 == deviceID)
    {
        //err msg
        os_log_error(logHandle, "ERROR: 'failed to find %@'s object id", device.localizedName);
        
        //bail
        goto bail;
    }

    //init property struct's selector
    propertyStruct.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere;
    
    //init property struct's scope
    propertyStruct.mScope = kAudioObjectPropertyScopeGlobal;
    
    //init property struct's element
    propertyStruct.mElement = kAudioObjectPropertyElementMain;
    
    //remove
    status = AudioObjectRemovePropertyListenerBlock(deviceID, &propertyStruct, self.eventQueue, self.audioListeners[device.uniqueID]);
    if(noErr != status)
    {
        //err msg
        os_log_error(logHandle, "ERROR: 'AudioObjectRemovePropertyListenerBlock' failed with %d", status);
        
        //bail
        goto bail;
    }
    
    //dbg msg
    NSLog(@"stopped monitoring %@ (uuid: %@ / %x) for audio changes", device.localizedName, device.uniqueID, deviceID);
    
    //unset listener block
    self.audioListeners[device.uniqueID] = nil;
    
bail:
    
    return;
}

//stop video monitor
-(void)unwatchVideoDevice:(AVCaptureDevice*)device
{
    //status
    OSStatus status = -1;
    
    //device id
    CMIOObjectID deviceID = 0;
    
    //property struct
    CMIOObjectPropertyAddress propertyStruct = {0};
    
    //bail if device was disconnected
    if(NO == device.isConnected)
    {
        //bail
        goto bail;
    }
    
    //get device ID
    deviceID = [self getAVObjectID:device];
    if(0 == deviceID)
    {
        //err msg
        os_log_error(logHandle, "ERROR: 'failed to find %@'s object id", device.localizedName);
        
        //bail
        goto bail;
    }
    
    //init property struct's selector
    propertyStruct.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere;
    
    //init property struct's scope
    propertyStruct.mScope = kAudioObjectPropertyScopeGlobal;
    
    //init property struct's element
    propertyStruct.mElement = kAudioObjectPropertyElementMain;
    
    //remove
    status = CMIOObjectRemovePropertyListenerBlock(deviceID, &propertyStruct, self.eventQueue, self.cameraListeners[device.uniqueID]);
    if(noErr != status)
    {
        //err msg
        os_log_error(logHandle, "ERROR: 'AudioObjectRemovePropertyListenerBlock' failed with %d", status);
        
        //bail
        goto bail;
    }
    
    //dbg msg
    NSLog(@"stopped monitoring %@ (uuid: %@ / %x) for video changes", device.localizedName, device.uniqueID, deviceID);
    
bail:
    
    //always unset listener block
    self.cameraListeners[device.uniqueID] = nil;
    
    return;
    
}

# pragma mark UNNotificationCenter Delegate Methods
#if kLemonUseAVMonitorNotification
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    
    completionHandler(UNNotificationPresentationOptionAlert);
    
    return;
}

//handle user response to notification
-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    
    //allowed items
    NSMutableArray* allowedItems = nil;
    
    //device
    NSNumber* device = nil;
    
    //process path
    NSString* processPath = nil;
    
    //process name
    NSString* processName = nil;
    
    //process id
    NSNumber* processID = nil;
    
    //error
    int error = 0;
    
    //dbg msg
    //os_log_debug(logHandle, "user response to notification: %@", response);
    
    //extract device
    device = response.notification.request.content.userInfo[EVENT_DEVICE];
    
    //extact process path
    processPath = response.notification.request.content.userInfo[EVENT_PROCESS_PATH];
    
    //extract process id
    processID = response.notification.request.content.userInfo[EVENT_PROCESS_ID];
    
    //get process name
    processName = valueForStringItem(getProcessName(processPath));
    
    //default action
    // set/save for logic in 'applicationShouldHandleReopen' ...which gets called :|
    if(YES == [response.actionIdentifier isEqualToString:@"com.apple.UNNotificationDefaultActionIdentifier"])
    {
        //dbg msg
        NSLog(@"user click triggered 'com.apple.UNNotificationDefaultActionIdentifier'");
        
        //save
        self.lastNotificationDefaultAction = [NSDate date];
        
        //done
        goto bail;
    }

    //close?
    // nothing to do
    if(YES == [response.notification.request.content.categoryIdentifier isEqualToString:CATEGORY_CLOSE])
    {
        //dbg msg
        NSLog(@"user clicked 'Ok'");
        
        //done
        goto bail;
    }
        
    //allow?
    // really nothing to do
    else if(YES == [response.actionIdentifier isEqualToString:@"Allow"])
    {
        //dbg msg
        NSLog(@"user clicked 'Allow'");
        
        //done
        goto bail;
    }
    
    //always allow?
    // added to 'allowed' items
    if(YES == [response.actionIdentifier isEqualToString:@"AllowAlways"])
    {
        //dbg msg
        NSLog(@"user clicked 'Allow Always'");
        
        //load allowed items
        allowedItems = [[NSUserDefaults.standardUserDefaults objectForKey:PREFS_ALLOWED_ITEMS] mutableCopy];
        if(nil == allowedItems)
        {
            //alloc
            allowedItems = [NSMutableArray array];
        }
        
        //add item
        [allowedItems addObject:@{EVENT_PROCESS_PATH:processPath, EVENT_DEVICE:device}];
        
        //save & sync
        [NSUserDefaults.standardUserDefaults setObject:allowedItems forKey:PREFS_ALLOWED_ITEMS];
        [NSUserDefaults.standardUserDefaults synchronize];
        
        //dbg msg
        NSLog(@"added %@ to list of allowed items", processPath);
        
        //broadcast
        [[NSNotificationCenter defaultCenter] postNotificationName:RULES_CHANGED object:nil userInfo:nil];
        
        //done
        goto bail;
    }
    
    //block?
    // kill process
    if(YES == [response.actionIdentifier isEqualToString:@"Block"])
    {
        //dbg msg
        NSLog(@"user clicked 'Block'");
        
        //kill
        error = kill(processID.intValue, SIGKILL);
        if(0 != error)
        {
            //err msg
            os_log_error(logHandle, "ERROR: failed to kill %@ (%@)", processName, processID);
    
            //show an alert
            showAlert([NSString stringWithFormat:NSLocalizedString(@"ERROR: failed to terminate %@ (%@)", @"ERROR: failed to terminate %@ (%@)"), processName, processID], [NSString stringWithFormat:NSLocalizedString(@"system error code: %d", @"system error code: %d"), error], @"OK");
            
            //bail
            goto bail;
        }
        
        //dbg msg
        NSLog(@"killed %@ (%@)", processName, processID);
    }
   
bail:
    
    //gotta call
    completionHandler();
    
    return;
}
#endif

@end


