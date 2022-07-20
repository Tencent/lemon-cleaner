//
//  Client.m
//  Application
//
//  Created by Patrick Wardle on 4/30/21.
//  Copyright © 2021 Objective-See. All rights reserved.
//

#import "Client.h"

@implementation Client

//override description method
-(NSString*)description
{
    //description
    return [NSString stringWithFormat:@"CLIENT: pid: %@, path: %@, clientID: %@", self.pid, self.path, self.clientID];
}

@end
