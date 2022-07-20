//
//  CameraDeviceModel.h
//  Owl
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CameraDeviceModel : NSObject

//the deviceName contain device manufacturer and localizedName
@property (nonatomic, strong) NSString *deviceName;
//AVCaptureDevice connectionID
@property (nonatomic, assign) UInt32 deviceConnectionID;

//yes device is using, or no is not using
//@property (nonatomic, assign) BOOL deviceActive;
//only provide the caculate property(promise it is correct in real time as far as possible)
- (BOOL)isVedioDeviceActive;

//register (add) property block listener
- (void)startListenCamera;
//unregister (remove) property block listener
- (void)stopListenCamera;

@end
