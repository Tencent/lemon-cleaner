//
//  Event.h
//  Application
//
//  Created by Patrick Wardle on 5/10/21.
//  Copyright © 2021 Objective-See. All rights reserved.
//

@import Cocoa;
@import Foundation;

#import "Client.h"

@interface Event : NSObject

/* METHODS */

//init
-(id)init:(Client*)client device:(int)device state:(NSControlStateValue)state;

/* PROPERTIES */

//client
@property(nonatomic, retain)Client* client;

//time stamp
@property(nonatomic, retain)NSDate* timestamp;

//device
@property int device;

//state
@property NSControlStateValue state;

@end
