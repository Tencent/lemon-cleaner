//
//  Event.m
//  Application
//
//  Created by Patrick Wardle on 5/10/21.
//  Copyright © 2021 Objective-See. All rights reserved.
//

#import "Event.h"

@implementation Event

//init
-(id)init:(Client*)client device:(int)device state:(NSControlStateValue)state
{
    //super
    self = [super init];
    if(nil != self)
    {
        //save client
        self.client = client;
        
        //set device
        self.device = device;
        
        //set state
        self.state = state;
        
        //set timestamp
        self.timestamp = [NSDate date];
    }
    
    return self;
}



@end
