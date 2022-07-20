//
//  CameraObserver.h
//  Owl
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CameraObserver : NSObject

@property (nonatomic, strong) NSString *cameraName;
- (BOOL)isVedioDeviceActive;
- (void)startCameraObserver;
- (void)stopCameraObserver;

@end
