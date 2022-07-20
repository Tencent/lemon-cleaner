//
//  CameraObserver.m
//  Owl
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "CameraObserver.h"
#import "CameraDeviceModel.h"
#import <CoreAudio/CoreAudio.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreMediaIO/CMIOHardware.h>
#import <AVFoundation/AVFoundation.h>

@interface CameraObserver() {
    
}
@property (nonatomic, strong) NSMutableArray *cameraDevices;
@property (nonatomic, copy) CMIOObjectPropertyListenerBlock deviceChangeBlock;
@end

@implementation CameraObserver

- (id)init{
    self = [super init];
    if (self) {
        _cameraDevices = [[NSMutableArray alloc] init];
        _cameraName = @"No Apple camera device";
        
        //enumerate all camera
        [self gradSystemCameraInfo];
        //is want update if the camera device is change like add new camera device?
        CMIOObjectPropertyAddress opa = {
            kCMIODevicePropertyDeviceHasChanged,
            kCMIODevicePropertyScopeOutput,
            kCMIODevicePropertyDeviceMaster};
        __weak typeof(self) weakSelf = self;
        _deviceChangeBlock = ^( UInt32 numberAddresses, const CMIOObjectPropertyAddress addresses[]) {
            //reget all camera device
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.cameraDevices removeAllObjects];
                [weakSelf gradSystemCameraInfo];
            });
        };
        CMIOObjectAddPropertyListenerBlock(kCMIOObjectSystemObject, &opa, dispatch_get_main_queue(), _deviceChangeBlock);
        
        //start all the camera observer
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [weakSelf startCameraObserver];
//        });
    }
    return self;
}
- (void)dealloc{
    //unregister when exist
    CMIOObjectPropertyAddress opa = {
        kCMIODevicePropertyDeviceHasChanged,
        kCMIODevicePropertyScopeOutput,
        kCMIODevicePropertyDeviceMaster};
    CMIOObjectRemovePropertyListenerBlock(kCMIOObjectSystemObject, &opa, dispatch_get_main_queue(), _deviceChangeBlock);
    
    //stop all the camera observer
    [self stopCameraObserver];
}

//grad camera info
- (void)gradSystemCameraInfo{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    CMIOObjectID connectionID = 0;
    for(AVCaptureDevice* camera in devices)
    {
        //display name
        CameraDeviceModel *model = [[CameraDeviceModel alloc] init];
        model.deviceName = [camera.manufacturer stringByAppendingString:camera.localizedName];
        //temp use the last one, (apple always has only one camera device?)
        self.cameraName = [camera.manufacturer stringByAppendingString:camera.localizedName];
        NSLog(@"camera: %@/%@", camera.manufacturer, camera.localizedName);
        
        //remove performSelector cause warning
        if (!camera) { break; }
        SEL selector = NSSelectorFromString(@"connectionID");
        IMP imp = [camera methodForSelector:selector];
        CMIOObjectID (*func)(id, SEL) = (void *)imp;
        connectionID = func(camera, selector);
        model.deviceConnectionID = connectionID;
        //connectionID = (CMIOObjectID)[camera performSelector:NSSelectorFromString(@"connectionID") withObject:nil];
        
        //只监控苹果的设备
        if ([camera.manufacturer containsString:@"Apple"]) {
            [_cameraDevices addObject:model];
            break;
        }
    }
}

- (BOOL)isVedioDeviceActive{
    for(CameraDeviceModel *model in _cameraDevices)
    {
        if ([model isVedioDeviceActive]) {
            return YES;
        }
    }
    return NO;
}
- (void)startCameraObserver{
    NSLog(@"%s, cameraDevices.count = %lu", __FUNCTION__, (unsigned long)_cameraDevices.count);
    for(CameraDeviceModel *model in _cameraDevices)
    {
        [model startListenCamera];
    }
}
- (void)stopCameraObserver{
    for(CameraDeviceModel *model in _cameraDevices)
    {
        [model stopListenCamera];
    }
}

@end
