//
//  AudioDeviceModel.m
//  Owl
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "AudioDeviceModel.h"
#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioToolbox.h>
#import "OwlManager.h"

@interface AudioDeviceModel() {
    
}
@property (nonatomic, assign) BOOL isAudioActive;
@property (nonatomic, copy) AudioObjectPropertyListenerBlock deviceRuningBlock;
@property (nonatomic, assign) NSTimeInterval watchTimeInterval;
@property (nonatomic, assign) NSTimeInterval delayInterval;
@end

@implementation AudioDeviceModel

- (id)init{
    self = [super init];
    if (self) {
        _isAudioActive = NO;
        _watchTimeInterval = 0;
        _delayInterval = 2.5;
        //invoked when the audio is active
        __weak typeof(self) weakSelf = self;
        _deviceRuningBlock = ^(UInt32 inNumberAddresses,
                               const AudioObjectPropertyAddress*   inAddresses)
        {
            //handle notification
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.isAudioActive == [strongSelf isAudioDeviceActive]) {
                return;
            } else {
                strongSelf.isAudioActive = [strongSelf isAudioDeviceActive];
            }
            NSLog(@"listener audio block: %d", ([strongSelf isAudioDeviceActive]));
            
            if (strongSelf.isAudioActive) {
                strongSelf.watchTimeInterval = [[NSDate date] timeIntervalSince1970];
//                [[OwlManager shareInstance] performSelector:@selector(startAudioWatchTimer) withObject:nil afterDelay:weakSelf.delayInterval];
                // Note: 移除延时
                [[OwlManager shareInstance] performSelector:@selector(startAudioWatchTimer)];
            } else {
                NSTimeInterval dv = [[NSDate date] timeIntervalSince1970] - strongSelf.watchTimeInterval;
                NSLog(@"dv:%f, %f, %f", dv, [[NSDate date] timeIntervalSince1970], strongSelf.watchTimeInterval);
                strongSelf.watchTimeInterval = 0;
                if (dv < weakSelf.delayInterval) {
                    [NSObject cancelPreviousPerformRequestsWithTarget:[OwlManager shareInstance] selector:@selector(startAudioWatchTimer) object:nil];
                    return;
                } else {
                    [[OwlManager shareInstance] stopAudioWatchTimer];
                }
            }
            
//            if ([strongSelf isAudioDeviceActive]) {
//                [[OwlManager shareInstance] startAudioWatchTimer];
//            } else {
//                [[OwlManager shareInstance] stopAudioWatchTimer];
//            }
        };
    }
    return self;
}
- (void)dealloc{
    //unregister when exist
    [self stopListenAudio];
}
//register (add) property block listener
const static AudioObjectPropertyAddress* audioPropertyAddress(){
    const static AudioObjectPropertyAddress opa = {
        .mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere,
        .mScope = kAudioObjectPropertyScopeGlobal,
        .mElement= kAudioObjectPropertyElementMaster
    };
    return &opa;
}
- (void)startListenAudio{
    if ([self isAudioDeviceActive]) {
        _isAudioActive = YES;
        self.watchTimeInterval = [[NSDate date] timeIntervalSince1970];
        [[OwlManager shareInstance] performSelector:@selector(startAudioWatchTimer) withObject:nil afterDelay:self.delayInterval];
//        [[OwlManager shareInstance] startAudioWatchTimer];
    }
    //ps the address must using kAudio*, when use the kCMIODevice*, it not invoked, apple so pit
    OSStatus result = AudioObjectAddPropertyListenerBlock(_deviceConnectionID, audioPropertyAddress(), dispatch_get_main_queue(), _deviceRuningBlock);
    if (result != noErr ) {
        NSLog(@"startListenCamera happen some error: %d", result);
    }
}
//unregister (remove) property block listener
- (void)stopListenAudio{
    AudioObjectRemovePropertyListenerBlock(_deviceConnectionID, audioPropertyAddress(), dispatch_get_main_queue(), (__bridge AudioObjectPropertyListenerBlock _Nonnull)((__bridge void * _Nullable)(_deviceRuningBlock)));
}

//get the specified audio is active
- (BOOL)isAudioDeviceActive {
    //can't using the kAudioDevicePropertyDeviceIsRunning
//    AudioObjectPropertyAddress opa = {
//        .mSelector = kAudioDevicePropertyDeviceIsRunning,
//        .mScope = kAudioObjectPropertyScopeOutput,
//        .mElement= kAudioObjectPropertyElementMaster
//    };
    AudioObjectPropertyAddress opa = {
        kAudioDevicePropertyDeviceIsRunningSomewhere,
        kAudioDevicePropertyScopeInput,
        kAudioObjectPropertyElementMaster
    };
    UInt32 running;
    UInt32 defaultSize = sizeof(UInt32);
    //get the audio is using status
    OSStatus result = AudioObjectGetPropertyData(self.deviceConnectionID, &opa, 0, NULL, &defaultSize, &running);
    //result = AudioHardwareServiceGetPropertyData(self.deviceConnectionID, &opa, 0, NULL, &defaultSize, &running);
    //result = AudioDeviceGetProperty(self.deviceConnectionID, 0, 0, kAudioDevicePropertyDeviceIsRunning, &defaultSize, &running);
    //result = AudioUnitGetProperty(self.deviceConnectionID, kAudioDevicePropertyDeviceIsRunning, kAudioUnitScope_Input, 0, &running, &defaultSize);
    if (result != noErr ) {
        NSLog(@"isAudioDeviceActive happen some error: %d", result);
        return NO;
    }
    NSLog(@"isAudioDeviceActive: %d", running);
    return running;
}

@end
