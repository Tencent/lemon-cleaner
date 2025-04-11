//
//  Client.h
//  Application
//
//  Created by Patrick Wardle on 4/30/21.
//  Copyright © 2021 Objective-See. All rights reserved.
//

@import Foundation;

@interface Client : NSObject

/* PROPERTIES */

//pid
@property(nonatomic, retain)NSNumber* pid;

//path
@property(nonatomic, retain)NSString* path;

//name
@property(nonatomic, retain)NSString* name;

@end

