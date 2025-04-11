//
//  Event.h
//  Application
//
//  Created by Patrick Wardle on 5/10/21.
//  Copyright © 2021 Objective-See. All rights reserved.
//

@import Cocoa;
@import Foundation;

#import <AVFoundation/AVCaptureDevice.h>

#import "Client.h"

@interface Event : NSObject

/* METHODS */

//init
-(id)init:(Client*)client device:(AVCaptureDevice*)device deviceType:(int)deviceType state:(NSControlStateValue)state;

/* PROPERTIES */

//client
@property(nonatomic, retain)Client* client;

//device
@property(nonatomic, retain)AVCaptureDevice* device;

//device
@property int deviceType;

//state
@property NSControlStateValue state;

//time stamp
@property(nonatomic, retain)NSDate* timestamp;

//was shown
@property BOOL wasShown;

@end
