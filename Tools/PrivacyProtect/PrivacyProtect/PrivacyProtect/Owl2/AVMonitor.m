//
//  AVMonitor.m
//  Application
//
//  Created by Patrick Wardle on 4/30/21.
//  Copyright © 2021 Objective-See. All rights reserved.
//

@import OSLog;
@import AVFoundation;

#import "AVMonitor.h"
#import "utilities.h"

//log handle
extern os_log_t logHandle;

@interface AVMonitor ()
@property(nonatomic, assign) BOOL isM1;
@end

@implementation AVMonitor

@synthesize videoClients;
@synthesize audioClients;
@synthesize lastMicEvent;

//init
// create XPC connection & set remote obj interface
-(id)init
{
    self = [super init];
    if (nil != self)
    {
        self.videoLogMonitor = [[LogMonitor alloc] init];
        self.audioLogMonitor = [[LogMonitor alloc] init];
        
        self.videoClients = [QMSafeMutableArray array];
        self.audioClients = [QMSafeMutableArray array];
        
        self.isM1 = AppleSilicon();
        // any active cameras
        // only call on intel, since broken on M1 :/
        if (YES != self.isM1)
        {
            self.cameraState = [self isACameraOn];
        }
    }
    
    return self;
}

//monitor AV
// also generate alerts as needed
-(void)start
{
    //dbg msg
    os_log_debug(logHandle, "starting AV monitoring");
    // video
    (YES == self.isM1) ? [self monitorVideoM1] : [self monitorVideoIntel];
    // audio
    [self startAudioMonitor];
}

// 通过appleh13camerad监控 video events
- (void)monitorVideoM1
{
    os_log_debug(logHandle, "CPU architecuture: M1, will leverage 'appleh13camerad'");
    
    [self.videoLogMonitor start:[NSPredicate predicateWithFormat:@"process == 'appleh13camerad'"] level:Log_Level_Default callback:^(OSLogEvent* logEvent) {
    
        //new client
        // add to list
        if ((YES == [logEvent.composedMessage hasPrefix:@"TCC access already allowed for pid"]) ||
            (YES == [logEvent.composedMessage hasPrefix:@"TCC preflight access returned allowed for pid"])) {
            
            os_log_debug(logHandle, "new client msg: %{public}@", logEvent.composedMessage);
            
            NSNumber* pid = nil;
            pid = @([logEvent.composedMessage componentsSeparatedByString:@" "].lastObject.intValue);
            if (nil != pid) {
                Client* client = [[Client alloc] init];
                client.pid = pid;
                client.path = getProcessPath(pid.intValue);
                client.name = getProcessName(client.path);
                Event *event = [[Event alloc] init:client device:Device_Camera state:self.cameraState];
                os_log_debug(logHandle, "new client: %{public}@", client);
                
                //camera already on?
                // show notifcation for new client
                if (NSControlStateValueOn == self.cameraState) {
                    if (YES == [self generateNotification:event]) {
//                        [self executeUserAction:event];
                    }
                } else {
                    //will handle when "on" camera msg is delivered
                    [self.videoClients addObject:client];
                }
            }
        } else if (YES == [logEvent.composedMessage isEqualToString:@"StartStream : StartStream: Powering ON camera"]) {
            //camera on
            os_log_debug(logHandle, "camera on msg: %{public}@", logEvent.composedMessage);
            
            self.cameraState = NSControlStateValueOn;
            
            Client *client = nil;
            client = self.videoClients.lastObject;
            
            // Note: `avconferenced`负责FaceTime右边视图区域，这里增加判断如果最前的应用是FaceTime的话，替换成FaceTime！
            if (client && !client.clientID && [client.path isEqualToString:AV_CONFERENCED]
                && [NSWorkspace.sharedWorkspace.frontmostApplication.executableURL.path isEqualToString:FACE_TIME]) {
                
                NSRunningApplication *frontmostApplication = NSWorkspace.sharedWorkspace.frontmostApplication;
                Client* _client = [[Client alloc] init];
                _client.pid = @(frontmostApplication.processIdentifier);
                _client.path = getProcessPath(client.pid.intValue);
                _client.name = getProcessName(FACE_TIME);
                _client.clientID = @([logEvent.composedMessage componentsSeparatedByString:@" "].lastObject.intValue);
                
                client = _client;
                os_log_debug(logHandle, "did found, the facetime client: %{public}@", client);
            }
            
            //init event
            Event *event = [[Event alloc] init:client device:Device_Camera state:self.cameraState];
            if(YES == [self generateNotification:event])
            {
//                [self executeUserAction:event];
            }
        } else if (YES == [logEvent.composedMessage hasPrefix:@"Removing client: pid"]) {
            //dead client
            // remove from list
            os_log_debug(logHandle, "removed client msg: %{public}@", logEvent.composedMessage);
            
            NSNumber* pid = 0;
            pid = @([logEvent.composedMessage componentsSeparatedByString:@" "].lastObject.intValue);
            if (nil != pid) {
                @synchronized (self) {
                //find and remove client
                for (NSInteger i = self.videoClients.count - 1; i >= 0; i--) {
                    if (pid != ((Client*)self.videoClients[i]).pid) {
                        continue;
                    }
                    os_log_debug(logHandle, "removed client at index %ld", (long)i);
                    [self.videoClients removeObjectAtIndex:i];
                }
                }
            }
        } else if (YES == [logEvent.composedMessage hasPrefix:@"StopStream : Powering OFF camera"]) {
            //camera off
            // show inactive notification
            os_log_debug(logHandle, "camera off msg: %{public}@", logEvent.composedMessage);
            
            self.cameraState = NSControlStateValueOff;
            Event *event = [[Event alloc] init:nil device:Device_Camera state:self.cameraState];
            
            if (YES == [self generateNotification:event]) {
//                [self executeUserAction:event];
            }
            @synchronized (self) {
                os_log_debug(logHandle, "removed all (video) clients");
                [self.videoClients removeAllObjects];
            }
        }
    }];

    return;
}


// 通过VDCAssistant监控video events
- (void)monitorVideoIntel
{
    os_log_debug(logHandle, "CPU architecuture: Intel ...will leverage 'VDCAssistant'");
    
    __block unsigned long long msgCount = 0;
    [self.videoLogMonitor start:[NSPredicate predicateWithFormat:@"process == 'VDCAssistant'"] level:Log_Level_Default callback:^(OSLogEvent *logEvent) {
        msgCount++;
        // 新client，加入列表
        if (YES == [logEvent.composedMessage hasPrefix:@"Client Connect for PID"]) {
            
            os_log_debug(logHandle, "new client msg: %{public}@", logEvent.composedMessage);
            
            NSNumber *pid = nil;
            pid = @([logEvent.composedMessage componentsSeparatedByString:@" "].lastObject.intValue);
            if (nil != pid) {
                Client *client = [[Client alloc] init];
                client.msgCount = msgCount;
                client.pid = pid;
                client.path = getProcessPath(pid.intValue);
                client.name = getProcessName(client.path);
                [self.videoClients addObject:client];
                os_log_debug(logHandle, "new client: %{public}@", client);
            }
        } else if (YES == [logEvent.composedMessage containsString:@"GetDevicesState for client"]) {
            //client w/ id msg
            // 刷新 (last) client, with client id
            os_log_debug(logHandle, "new client id msg : %{public}@", logEvent.composedMessage);
            
            NSNumber *clientID = nil;
            clientID = @([logEvent.composedMessage componentsSeparatedByString:@" "].lastObject.intValue);
            if (0 != clientID) {
                //get last client
                // check that it the one in the *last* msg
                Client *client = nil;
                client = self.videoClients.lastObject;
                if (client.msgCount == msgCount-1) {
                    client.clientID = clientID;
                    os_log_debug(logHandle, "refresh client: %{public}@", client);
                }
            }
        } else if (YES == [logEvent.composedMessage containsString:@"StartStream for client"]) {
            //camera on (for client)
            // show notification
            //client
            os_log_debug(logHandle, "camera on msg: %{public}@", logEvent.composedMessage);
            
            self.cameraState = NSControlStateValueOn;
            Client *client = nil;
            NSNumber *clientID = nil;
            clientID = @([logEvent.composedMessage componentsSeparatedByString:@" "].lastObject.intValue);
            if (0 != clientID) {
                //find client w/ matching id
                for (Client *candidateClient in self.videoClients) {
                    if (candidateClient.clientID == clientID) {
                        client = candidateClient;
                        os_log_debug(logHandle, "found client: %{public}@", client);
                        break;
                    }
                }
                
                //nil, but last client is FaceTime?
                // use that, as FaceTime is "special"
                if (nil == client) {
                    //facetime check?
                    if ((YES == [((Client*)self.videoClients.lastObject).path isEqualToString:FACE_TIME]) &&
                        (YES == [NSWorkspace.sharedWorkspace.frontmostApplication.executableURL.path isEqualToString:FACE_TIME])) {
                        client = self.videoClients.lastObject;
                        client.clientID = clientID;
                        os_log_debug(logHandle, "not found, but facetime client: %{public}@", client);
                    } else {
                        // 没监控到启动信息，clientid关联不上pid
                        os_log_debug(logHandle, "not found, and not facetime client: %{public}@", client);
                    }
                }
            }
            
            // Note: `avconferenced`负责FaceTime右边视图区域，这里增加判断如果最前的应用是FaceTime的话，替换成FaceTime！
            if (client && [client.path isEqualToString:AV_CONFERENCED]
                && [NSWorkspace.sharedWorkspace.frontmostApplication.executableURL.path isEqualToString:FACE_TIME]) {
                
                NSRunningApplication *frontmostApplication = NSWorkspace.sharedWorkspace.frontmostApplication;
                Client* _client = [[Client alloc] init];
                _client.pid = @(frontmostApplication.processIdentifier);
                _client.path = getProcessPath(client.pid.intValue);
                _client.name = getProcessName(FACE_TIME);
                _client.clientID = @([logEvent.composedMessage componentsSeparatedByString:@" "].lastObject.intValue);
                
                client = _client;
                os_log_debug(logHandle, "did found, the facetime client: %{public}@", client);
            }
            
            Event *event = [[Event alloc] init:client device:Device_Camera state:self.cameraState];
            if (YES == [self generateNotification:event]) {
                //execute action
//                [self executeUserAction:event];
            }
        } else if ((YES == [logEvent.composedMessage hasPrefix:@"ClientDied "]) &&
                 (YES == [logEvent.composedMessage hasSuffix:@"]"])) {
            //dead client
            // remove from list
            // e.x. "ClientDied 11 [PID: 22]"
            os_log_debug(logHandle, "dead client msg: %{public}@", logEvent.composedMessage);
            
            //init message
            // trim off last ']'
            NSString *message = nil;
            message = [logEvent.composedMessage substringToIndex:logEvent.composedMessage.length - 1];

            NSNumber *pid = 0;
            pid = @([message componentsSeparatedByString:@" "].lastObject.intValue);
            if (nil != pid) {
                @synchronized (self) {
                
                for (NSInteger i = self.videoClients.count - 1; i >= 0; i--) {
                    //no match?
                    if (pid != ((Client*)self.videoClients[i]).pid)
                    {
                        continue;
                    }
                    os_log_debug(logHandle, "removed client at index %ld client: %{public}@", (long)i, self.videoClients[i]);
                    [self.videoClients removeObjectAtIndex:i];
                }
                    
                } //sync
            }
        } else if(YES == [logEvent.composedMessage containsString:@"StopStream for client"]) {
//            else if(YES == [event.composedMessage containsString:@"Post event kCameraStreamStop"])
            //camera off
            os_log_debug(logHandle, "camera off msg: %{public}@", logEvent.composedMessage);
            
            Client *client = nil;
            NSNumber *clientid = @([logEvent.composedMessage componentsSeparatedByString:@" "].lastObject.intValue);
            for (NSInteger i = self.videoClients.count - 1; i >= 0; i--) {
                if (clientid != ((Client*)self.videoClients[i]).clientID) {
                    continue;
                }
                client = self.videoClients[i];
                //dbg msg
                os_log_debug(logHandle, "stop client at index %ld, client: %{public}@", (long)i, self.videoClients[i]);
            }
            if (nil != client) {
                Event *event = [[Event alloc] init:client device:Device_Camera state:NSControlStateValueOff];
                if (YES == [self generateNotification:event]) {
                    //execute action
//                        [self executeUserAction:event];
                }
            } else {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    //all camera's off?
                    if (YES != [self isACameraOn]) {
                        self.cameraState = NSControlStateValueOff;
                        Event *event = [[Event alloc] init:nil device:Device_Camera state:self.cameraState];
                        
                        if (YES == [self generateNotification:event]) {
                            //execute action
    //                        [self executeUserAction:event];
                        }
                    }
                });
            }
            
        }
    }];
    
    return;
}

//start monitor audio
- (void)startAudioMonitor
{
    os_log_debug(logHandle, "starting audio monitor");
   
    __block unsigned long long msgCount = 0;
    
    // Note: 统一在外部的Manager监听音频插口
//    AudioObjectID builtInMic = 0;
//    builtInMic = [self findBuiltInMic];
//    if (0 != builtInMic) {
//        [self watchAudio:builtInMic];
//    } else {
//        os_log_error(logHandle, "ERROR: failed to find built-in mic");
//    }
    
    NSRegularExpression *regex = nil;
    //macOS 10.16 (11)
    if (@available(macOS 10.16, *)) {
        regex = [NSRegularExpression regularExpressionWithPattern:@"pid:(\\d*)," options:0 error:nil];
    } else {
        //macOS 10.15
        regex = [NSRegularExpression regularExpressionWithPattern:@"0x([a-fA-F0-9]){20,}" options:0 error:nil];
    }
    
    //start audio-related log monitoring
    // looking for tccd access msgs from coreaudio
    [self.audioLogMonitor start:[NSPredicate predicateWithFormat:@"process == 'coreaudiod' && subsystem == 'com.apple.TCC' && category == 'access'"] level:Log_Level_Info callback:^(OSLogEvent *logEvent) {
        
        msgCount++;
        
        //macOS 10.16 (11)
        if(@available(macOS 10.16, *)) {
            //tcc request
            if (YES == [logEvent.composedMessage containsString:@"function=TCCAccessRequest, service=kTCCServiceMicrophone"]) {
                os_log_debug(logHandle, "new tcc access msg: %{public}@", logEvent.composedMessage);
                NSTextCheckingResult *match = nil;
                match = [regex firstMatchInString:logEvent.composedMessage options:0 range:NSMakeRange(0, logEvent.composedMessage.length)];
                if ((nil == match) ||
                    (NSNotFound == match.range.location) ||
                    (match.numberOfRanges < 2)) {
                    //ignore
                    return;
                }
                
                NSNumber *pid = nil;
                pid = @([[logEvent.composedMessage substringWithRange:[match rangeAtIndex:1]] intValue]);
                if (nil == pid) {
                    return;
                }
                
                Client *client = nil;
                client = [[Client alloc] init];
                client.msgCount = msgCount;
                client.pid = pid;
                client.path = getProcessPath(pid.intValue);
                client.name = getProcessName(client.path);
                [self.audioClients addObject:client];
                
                os_log_debug(logHandle, "new client: %{public}@", client);
                return;
            }
        } else {
            //macOS 10.15
            //tcc request
            if ((YES == [logEvent.composedMessage containsString:@"TCCAccessRequest"]) &&
                (YES == [logEvent.composedMessage containsString:@"kTCCServiceMicrophone"])) {
                os_log_debug(logHandle, "new tcc access msg: %{public}@", logEvent.composedMessage);
                
                //match/extract pid
                NSTextCheckingResult *match = nil;
                match = [regex firstMatchInString:logEvent.composedMessage options:0 range:NSMakeRange(0, logEvent.composedMessage.length)];
                
                if ((nil == match) ||
                    (NSNotFound == match.range.location)) {
                    //ignore
                    return;
                }
                
                NSString *token = nil;
                token = [logEvent.composedMessage substringWithRange:[match rangeAtIndex:0]];
                if (token.length < 46) {
                    return;
                }
                
                //extract pid
                NSString *substring = nil;
                substring = [token substringWithRange:NSMakeRange(42, 4)];
                unsigned int pid = 0;
                sscanf(substring.UTF8String, "%x", &pid);
                if (0 == pid) {
                    return;
                }
    
                Client *client = nil;
                client = [[Client alloc] init];
                client.msgCount = msgCount;
                client.pid = @(htons(pid));
                client.path = getProcessPath(client.pid.intValue);
                client.name = getProcessName(client.path);
                [self.audioClients addObject:client];
                
                os_log_debug(logHandle, "new (audio) client: %{public}@", client);
                return;
            }
        }
        //tcc auth response
        // check that a) auth ok b) msg is right after new request
        //            c) mic is still on d) process is still alive
        // then trigger notification
        if ((YES == [logEvent.composedMessage containsString:@"RECV: synchronous reply"]) ||
            (YES == [logEvent.composedMessage containsString:@"Received synchronous reply"])) {
            __block Client *client = nil;

            os_log_debug(logHandle, "new client tccd response : %{public}@", logEvent.composedMessage);
            
            BOOL isAuthorized = NO;
            //look for:
            // "result" => <bool: xxx>: true
            for (NSString *response in [logEvent.composedMessage componentsSeparatedByString:@"\n"]) {
                //no match?
                if( (YES != [response hasSuffix:@"true"]) ||
                    (YES != [response containsString:@"\"result\""])) {
                    continue;
                }
                isAuthorized = YES;
                break;
            }
            //未授权
            if (YES != isAuthorized) {
                return;
            }
            //授权，获取last client
            // check that it the one in the *last* msg
            client = self.audioClients.lastObject;
            if (client.msgCount != msgCount-1) {
                //ignore
                return;
            }
            //is mic (really) on?
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.microphoneState = [self isMicOn];
                
                if (YES != self.microphoneState) {
                    os_log_debug(logHandle, "mic is not on...");
                    //return;
                }
                
                //make sure process is still alive
                if (YES != isProcessAlive(client.pid.intValue)) {
                    os_log_debug(logHandle, "%@ is no longer alive, so ignoring", client.name);
                    return;
                }
            
                //more than one client?
                // only use candiate client if:
                // a) it's the foreground and b) the last event was from a different client
                if (1 != self.audioClients.count) {
                    os_log_debug(logHandle, "more than one audio client (total: %lu)", (unsigned long)self.audioClients.count);
                    
                    //not foreground?
                    if (YES != [NSWorkspace.sharedWorkspace.frontmostApplication.executableURL.path isEqualToString:client.path]) {
                        //client = nil;
                    } else if ((self.lastMicEvent.client.pid == client.pid) &&
                             (YES == [self.lastMicEvent.client.path isEqualToString:client.path])) {
                        //last event was same client?
                        client = nil;
                    }
                }
            
                // Note: `corespeechd`负责Siri录音，当前path为corespeechd时，替换成Siri！
                if (client && !client.clientID && [client.path isEqualToString:CORE_SPEECHD]
                    /*&& [NSWorkspace.sharedWorkspace.frontmostApplication.executableURL.path isEqualToString:SIRI_APP]*/) {
                    
                    Client* _client = [[Client alloc] init];
                    _client.pid = @(findProcess(SIRI_SYS));
                    _client.path = getProcessPath(client.pid.intValue);
                    _client.name = getProcessName(SIRI_APP);
                    _client.msgCount = client.msgCount;
                    _client.clientID = @([logEvent.composedMessage componentsSeparatedByString:@" "].lastObject.intValue);
                    
                    client = _client;
                    
                    os_log_debug(logHandle, "did found, the fake client: %{public}@", client);
                }
            
                Event *event = nil;
                event = [[Event alloc] init:client device:Device_Microphone state:self.microphoneState];
                    
                //show notification
                [self generateNotification:event];
                    
//                //execute action
//                [self executeUserAction:event];
                
//            });
        }
    }];
}

// 有摄像头打开
- (BOOL)isACameraOn
{
    BOOL cameraOn = NO;
    unsigned int connectionID = 0;
    
    os_log_debug(logHandle, "checking if any camera is active");
    
    for (AVCaptureDevice *currentCamera in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
    {
        os_log_debug(logHandle, "device: %{public}@/%{public}@", currentCamera.manufacturer, currentCamera.localizedName);
        
        connectionID = [self getAVObjectID:currentCamera];
        
        // is (any) camera on?
        if (NSControlStateValueOn == [self getCameraStatus:connectionID])
        {
            os_log_debug(logHandle, "device: %{public}@/%{public}@, is on!", currentCamera.manufacturer, currentCamera.localizedName);
            
            cameraOn = YES;
            break;
        }
    }
    return cameraOn;
}

//get built-in mic
- (AudioObjectID)findBuiltInMic
{
    AudioObjectID builtInMic = 0;

    //look for mic that belongs to apple
    for (AVCaptureDevice* currentMic in [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio])
    {
        os_log_debug(logHandle, "device: %{public}@/%{public}@", currentMic.manufacturer, currentMic.localizedName);
        
        //check if apple
        // also check input source
        if( (YES == [currentMic.manufacturer isEqualToString:@"Apple Inc."]) &&
            (YES == [[[currentMic activeInputSource] inputSourceID] isEqualToString:@"imic"]) )
        {
            builtInMic = [self getAVObjectID:currentMic];
            break;
        }
    }
    
    if (0 == builtInMic)
    {
        builtInMic = [self getAVObjectID:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio]];
        os_log_debug(logHandle, "Apple mic not found, defaulting to default (id: %d)", builtInMic);
    }
    
    return builtInMic;
}

//获取av object's ID
- (UInt32)getAVObjectID:(AVCaptureDevice *)audioObject
{
    AudioObjectID objectID = 0;
    
    SEL methodSelector = nil;
    methodSelector = NSSelectorFromString(@"connectionID");
    
    if (YES != [audioObject respondsToSelector:methodSelector])
    {
        return 0;
    }
    
    //ignore leak warning
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
    objectID = (unsigned int)[audioObject performSelector:methodSelector withObject:nil];
    
    //restore
    #pragma clang diagnostic pop
    
    return objectID;
}

//is built-in mic on?
- (BOOL)isMicOn
{
    BOOL isMicOn = NO;

    AudioObjectID builtInMic = 0;
    
    os_log_debug(logHandle, "checking if built-in mic is active");
    
    builtInMic = [self findBuiltInMic];
    if ((0 != builtInMic) &&
        (NSControlStateValueOn == [self getMicState:builtInMic]))
    {
        os_log_debug(logHandle, "built-in mic is on");
        isMicOn = YES;
    }
    return isMicOn;
}
    
//注册audio notifcations，只关注mic deactivation events
// ...only care about mic deactivation request
- (BOOL)watchAudio:(AudioObjectID)builtInMic
{
    OSStatus status = -1;
    AudioObjectPropertyAddress propertyStruct = {0};
    
    propertyStruct.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere;
    propertyStruct.mScope = kAudioObjectPropertyScopeGlobal;
    propertyStruct.mElement = kAudioObjectPropertyElementMaster;
    
    __unsafe_unretained typeof(self)weakSelf = self;
    
    self.listenerBlock = ^(UInt32 inNumberAddresses, const AudioObjectPropertyAddress *inAddresses)
    {
        NSInteger state = -1;
        state = [self getMicState:builtInMic];
        
        os_log_debug(logHandle, "built in mic changed state to %ld", (long)state);
        
        Event *event = nil;
        event = [[Event alloc] init:nil device:Device_Microphone state:state];
        
        //mic off?
        if (NSControlStateValueOff == state)
        {
            os_log_debug(logHandle, "built in mic turned to off");
            NSLog(@"!!!! built in mic turned to off");
            
            if (YES == [weakSelf generateNotification:event])
            {
                //execute action
//                [weakSelf executeUserAction:event];
            }
            @synchronized (weakSelf) {
                [weakSelf.audioClients removeAllObjects];
                os_log_debug(logHandle, "removed all (audio) clients");
            }
        }
    };
    
    //add property listener for audio changes
    status = AudioObjectAddPropertyListenerBlock(builtInMic, &propertyStruct, dispatch_get_main_queue(), self.listenerBlock);
    if (noErr != status)
    {
        os_log_error(logHandle, "ERROR: AudioObjectAddPropertyListenerBlock() failed with %d", status);
        
        return NO;
    }
    
    return YES;
}

//stop audio monitor
- (void)stopAudioMonitor
{
    OSStatus status = -1;
    AudioObjectID builtInMic = 0;
    AudioObjectPropertyAddress propertyStruct = {0};
    
    os_log_debug(logHandle, "stopping audio (device) monitor");
    
    propertyStruct.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere;
    propertyStruct.mScope = kAudioObjectPropertyScopeGlobal;
    propertyStruct.mElement = kAudioObjectPropertyElementMaster;
    
    builtInMic = [self findBuiltInMic];
    if (0 != builtInMic)
    {
        //remove
        status = AudioObjectRemovePropertyListenerBlock(builtInMic, &propertyStruct, dispatch_get_main_queue(), self.listenerBlock);
        if (noErr != status)
        {
            os_log_error(logHandle, "ERROR: 'AudioObjectRemovePropertyListenerBlock' failed with %d", status);
        }
    }
}

// 获取mic状态
- (UInt32)getMicState:(AudioObjectID)deviceID
{
    OSStatus status = -1;
    
    UInt32 isRunning = 0;
    UInt32 propertySize = sizeof(isRunning);
    
    AudioObjectPropertyAddress propertyAddress = {
        kAudioDevicePropertyDeviceIsRunningSomewhere,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    
    status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, NULL, &propertySize, &isRunning);
    if (noErr != status)
    {
        os_log_error(logHandle, "ERROR: getting status of audio device failed with %d", status);
        isRunning = -1;
    }
    return isRunning;
}

//check if a specified video is active
// note: on M1 this always says 'on' (smh apple)
- (UInt32)getCameraStatus:(CMIODeviceID)deviceID
{
    OSStatus status = -1;
    UInt32 isRunning = 0;
    UInt32 propertySize = 0;
    CMIOObjectPropertyAddress propertyStruct = {0};
    
    propertySize = sizeof(isRunning);
    propertyStruct.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere;
    propertyStruct.mScope = kCMIOObjectPropertyScopeGlobal;
    propertyStruct.mElement = 0;
    
    status = CMIOObjectGetPropertyData(deviceID, &propertyStruct, 0, NULL, sizeof(kAudioDevicePropertyDeviceIsRunningSomewhere), &propertySize, &isRunning);
    if (noErr != status)
    {
        os_log_error(logHandle, "ERROR: failed to get camera status (error: %#x)", status);
        isRunning = -1;
    }
    os_log_debug(logHandle, "isRunning: %d", isRunning);
    
    return isRunning;
}

//build and display notification
- (BOOL)generateNotification:(Event *)event
{
    //(new) mic event?
    // need extra logic, since macOS sometimes toggles / delivers 2x event, etc...
    if (Device_Microphone == event.device)
    {
        //from same client?
        // ignore if last event *just* occurred
        if ((self.lastMicEvent.client.pid == event.client.pid) &&
            ([[NSDate date] timeIntervalSinceDate:self.lastMicEvent.timestamp] < 1.0f))
        {
            NSLog(@"!!!! mic ignoring mic event, as it happened <0.5s");
            os_log_debug(logHandle, "ignoring mic event, as it happened <0.5s ");
            return NO;
        }
        
        //or, was a 2x off?
        if ((nil != self.lastMicEvent) &&
            (NSControlStateValueOff == event.state) &&
            (NSControlStateValueOff == self.lastMicEvent.state))
        {
            NSLog(@"ignoring mic event, as it was a 2x off");
            os_log_debug(logHandle, "ignoring mic event, as it was a 2x off");
            //return NO;
        }
        if (nil == event.client /*&& NSControlStateValueOff == event.state*/) {
            if (1 == self.audioClients.count) {
                event.client = self.lastMicEvent.client;
            }
        }
        self.lastMicEvent = event;
    }
    if (self.completeBlock) {
        self.completeBlock(event.device, event.state, event.client);
    }
    return YES;
}


////execute user action
//-(BOOL)executeUserAction:(AVDevice)device state:(NSControlStateValue)state client:(Client*)client
//{
//    //flag
//    BOOL wasExecuted = NO;
//
//    //path to action
//    NSString* action = nil;
//
//    //args
//    NSMutableArray* args = nil;
//
//    //execute user-specified action?
//    if(YES != [NSUserDefaults.standardUserDefaults boolForKey:PREF_EXECUTE_ACTION])
//    {
//        //dbg msg
//        os_log_debug(logHandle, "'execute action' is disabled");
//
//        //bail
//        goto bail;
//    }
//
//    //dbg msg
//    os_log_debug(logHandle, "executing user action");
//
//    //grab action
//    action = [NSUserDefaults.standardUserDefaults objectForKey:PREF_EXECUTE_PATH];
//    if(YES != [NSFileManager.defaultManager fileExistsAtPath:action])
//    {
//        //err msg
//        os_log_error(logHandle, "ERROR: %{public}@ is not a valid action", action);
//
//        //bail
//        goto bail;
//    }
//
//    //pass args?
//    if(YES == [NSUserDefaults.standardUserDefaults boolForKey:PREF_EXECUTE_ACTION_ARGS])
//    {
//        //alloc
//        args = [NSMutableArray array];
//
//        //add device
//        [args addObject:@"-device"];
//        (Device_Camera == device) ? [args addObject:@"camera"] : [args addObject:@"microphone"];
//
//        //add event
//        [args addObject:@"-event"];
//        (NSControlStateValueOn == state) ? [args addObject:@"on"] : [args addObject:@"off"];
//
//        //add process
//        if(nil != client)
//        {
//            //add
//            [args addObject:@"-process"];
//            [args addObject:client.pid.stringValue];
//        }
//    }
//
//    //exec user specified action
//    execTask(action, args, NO, NO);
//
//bail:
//
//    return wasExecuted;
//}

//stop monitor
- (void)stop
{
    [self.videoLogMonitor stop];
    [self.audioLogMonitor stop];
    [self stopAudioMonitor];
}

@end
