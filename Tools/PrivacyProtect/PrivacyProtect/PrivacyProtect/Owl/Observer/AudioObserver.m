//
//  AudioObserver.m
//  Owl
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "AudioObserver.h"
#import "AudioDeviceModel.h"
#import <CoreAudio/CoreAudio.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioObserver() {
    
}
@property (nonatomic, strong) NSMutableArray *audioDevices;
@property (nonatomic, copy) AudioObjectPropertyListenerBlock deviceChangeBlock;
@end

@implementation AudioObserver

- (id)init{
    self = [super init];
    if (self) {
        _audioDevices = [[NSMutableArray alloc] init];
        _audioName = @"No Apple audio device";
        
        
        //enumerate all camera
        [self gradSystemCameraInfo];
        //is want update if the camera device is change like add new camera device?
        __weak typeof(self) weakSelf = self;
        _deviceChangeBlock = ^(UInt32 inNumberAddresses,
                               const AudioObjectPropertyAddress*   inAddresses)
        {
            //reget all camera device
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.audioDevices removeAllObjects];
                [weakSelf gradSystemCameraInfo];
            });
        };
        AudioObjectPropertyAddress opa = {
            kAudioDevicePropertyDeviceHasChanged,
            kAudioDevicePropertyScopeOutput,
            kAudioObjectPropertyElementMaster};
        AudioObjectRemovePropertyListenerBlock(kAudioObjectSystemObject, &opa, dispatch_get_main_queue(), _deviceChangeBlock);
        
        //start all the camera observer
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [weakSelf startAudioObserver];
//        });
    }
    return self;
}
- (void)dealloc{
    //unregister when exist
    AudioObjectPropertyAddress opa = {
        kAudioDevicePropertyDeviceHasChanged,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMaster};
    AudioObjectRemovePropertyListenerBlock(kAudioObjectSystemObject, &opa, dispatch_get_main_queue(), _deviceChangeBlock);
    
    //stop all the camera observer
    [self stopAudioObserver];
}

//grad camera info
- (void)gradSystemCameraInfo{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    AudioObjectID connectionID = 0;
    for(AVCaptureDevice* camera in devices)
    {
        //display name
        AudioDeviceModel *model = [[AudioDeviceModel alloc] init];
        model.deviceName = [camera.manufacturer stringByAppendingString:camera.localizedName];
        self.audioName = [camera.manufacturer stringByAppendingString:camera.localizedName];
        NSLog(@"audio: %@/%@", camera.manufacturer, camera.localizedName);
        
        //remove performSelector cause warning
        if (!camera) { break; }
        SEL selector = NSSelectorFromString(@"connectionID");
        IMP imp = [camera methodForSelector:selector];
        AudioObjectID (*func)(id, SEL) = (void *)imp;
        connectionID = func(camera, selector);
        model.deviceConnectionID = connectionID;
        //只监控苹果的设备
        if ([camera.manufacturer containsString:@"Apple"]) {
            [_audioDevices addObject:model];
            break;
        }
    }
}

- (BOOL)isAudioDeviceActive{
    for(AudioDeviceModel *model in _audioDevices)
    {
        if ([model isAudioDeviceActive]) {
            return YES;
        }
    }
    return NO;
}
- (void)startAudioObserver{
    NSLog(@"%s, audioDevices.count = %lu", __FUNCTION__, (unsigned long)_audioDevices.count);
    for(AudioDeviceModel *model in _audioDevices)
    {
        [model startListenAudio];
    }
}
- (void)stopAudioObserver{
    for(AudioDeviceModel *model in _audioDevices)
    {
        [model stopListenAudio];
    }
}

@end
