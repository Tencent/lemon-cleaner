//
//  CameraDeviceModel.m
//  Owl
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "CameraDeviceModel.h"
#import <CoreAudio/CoreAudio.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreMediaIO/CMIOHardware.h>
#import <AVFoundation/AVFoundation.h>
#import "OwlConstant.h"
#import "OwlManager.h"

@interface CameraDeviceModel() {
    
}
@property (nonatomic, assign) BOOL isCameraActive;
@property (nonatomic, copy) CMIOObjectPropertyListenerBlock deviceRuningBlock;
@property (nonatomic, assign) NSTimeInterval watchTimeInterval;
@property (nonatomic, assign) NSTimeInterval delayInterval;
@end

@implementation CameraDeviceModel

- (id)init{
    self = [super init];
    if (self) {
        _isCameraActive = NO;
        _watchTimeInterval = 0;
        _delayInterval = 2;
        //invoked when the camera is active
        __weak typeof(self) weakSelf = self;
        _deviceRuningBlock = ^(UInt32 inNumberAddresses, const CMIOObjectPropertyAddress addresses[])
        {
            //handle notification
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return ;
            }
            NSLog(@"listener camera block: %d,  %d", ([strongSelf isVedioDeviceActive]), strongSelf.isCameraActive);
            if (strongSelf.isCameraActive == [strongSelf isVedioDeviceActive]) {
                return;
            } else {
                strongSelf.isCameraActive = [strongSelf isVedioDeviceActive];
            }
            if (strongSelf.isCameraActive) {
                strongSelf.watchTimeInterval = [[NSDate date] timeIntervalSince1970];
                //[[OwlManager shareInstance] performSelector:@selector(startCameraWatchTimer) withObject:nil afterDelay:weakSelf.delayInterval];
                // Note: 移除延时
                [[OwlManager shareInstance] performSelector:@selector(startCameraWatchTimer)];
            } else {
                NSTimeInterval dv = [[NSDate date] timeIntervalSince1970] - strongSelf.watchTimeInterval;
                NSLog(@"dv:%f, %f, %f", dv, [[NSDate date] timeIntervalSince1970], strongSelf.watchTimeInterval);
                strongSelf.watchTimeInterval = 0;
                if (dv < weakSelf.delayInterval) {
                    [NSObject cancelPreviousPerformRequestsWithTarget:[OwlManager shareInstance] selector:@selector(startCameraWatchTimer) object:nil];
                    return;
                } else {
                    [[OwlManager shareInstance] stopCameraWatchTimer];
                }
            }
            if ([strongSelf isVedioDeviceActive]) {//strongSelf.isCameraActive) {
                
            } else {
                
            }
        };
    }
    return self;
}
- (void)dealloc{
    //unregister when exist
    [self stopListenCamera];
}

//register (add) property block listener
const static CMIOObjectPropertyAddress* propertyAddress(){
    const static CMIOObjectPropertyAddress opa = {
        .mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere,
        .mScope = kAudioObjectPropertyScopeGlobal,
        .mElement= kAudioObjectPropertyElementMaster
    };
    return &opa;
}
- (void)startListenCamera{
    if ([self isVedioDeviceActive]) {
        _isCameraActive = YES;
//        [[OwlXPCConnector shareInstance] sendMsg:@{FUNCTIONKEY: CameraBecomeActive,
//                                                   PARAMETERKEY: @{PeerCameraConnectionId: @(self.deviceConnectionID)}
//                                                   }];
        //[[OwlManager shareInstance] startCameraWatchTimer];
        self.watchTimeInterval = [[NSDate date] timeIntervalSince1970];
        [[OwlManager shareInstance] performSelector:@selector(startCameraWatchTimer) withObject:nil afterDelay:self.delayInterval];
    }
    //ps the address must using kAudio*, when use the kCMIODevice*, it not invoked, apple so pit
    OSStatus result = CMIOObjectAddPropertyListenerBlock(_deviceConnectionID, propertyAddress(), dispatch_get_main_queue(), _deviceRuningBlock);
    if (result != noErr ) {
        NSLog(@"startListenCamera happen some error: %d", result);
    }
    
    CMIOObjectPropertyAddress opa = {
        kCMIODevicePropertyDeviceIsRunningSomewhere,
        kCMIODevicePropertyScopeOutput,
        kCMIODevicePropertyDeviceMaster
    };
    CMIOObjectAddPropertyListenerBlock(_deviceConnectionID, &opa, dispatch_get_main_queue(), ^(UInt32 inNumberAddresses, const CMIOObjectPropertyAddress addresses[])
                                       {
                                           //handle notification
                                           NSLog(@"listener camera handle notification: %d", inNumberAddresses);
                                       });
}
//unregister (remove) property block listener
- (void)stopListenCamera{
    CMIOObjectRemovePropertyListenerBlock(_deviceConnectionID, propertyAddress(), dispatch_get_main_queue(), _deviceRuningBlock);
}

//get the specified camera is active
- (BOOL)isVedioDeviceActive {
    UInt32 value = 0;
    UInt32 valuePropertySize = sizeof(kCMIOObjectSystemObject);
    CMIOObjectPropertyAddress opa = {
        kCMIODevicePropertyDeviceIsRunningSomewhere,
        kCMIODevicePropertyScopeOutput,
        kCMIODevicePropertyDeviceMaster
    };
    //get the camera is using status
    OSStatus result = CMIOObjectGetPropertyData(self.deviceConnectionID, &opa, 0, NULL, sizeof(UInt32), &valuePropertySize, &value);
    if (result != noErr ) {
        NSLog(@"isVedioDeviceActive happen some error: %d", result);
        return NO;
    }
    NSLog(@"isVedioDeviceActive: %d", value);
    return value;
}

@end
