//
//  McStatInfoHelp.m
//  MagicanPaster
//
//  Created by developer on 11-3-16.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import "McStatInfoHelp.h"
#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/ps/IOPSKeys.h>

@implementation McStatInfoHelp

// check battery is exist，use iokit
+ (BOOL) checkBatteryExist
{
    io_service_t smartBattery = IOServiceGetMatchingService(kIOMasterPortDefault, 
                                                            IOServiceMatching("AppleSmartBattery"));
    if (smartBattery == 0)
    {
        return NO;
    }
    IOObjectRelease(smartBattery);
    
	CFTypeRef   info;
    CFArrayRef  list;
    
    info = IOPSCopyPowerSourcesInfo();
    if(info == NULL)
    {
		return NO;
    }
    list = IOPSCopyPowerSourcesList(info);
    if(list == NULL) 
    {
        CFRelease(info);
        return NO;
    }
	CFIndex cfCount = CFArrayGetCount(list);
	CFRelease(list);
	CFRelease(info);
    if(cfCount > 0)
    {
        return YES;
    }
	else
    {
        return NO;
    }
}

+ (NSSize) getScreenSize
{
    NSRect screenRect;
    NSArray *screenArray = [NSScreen screens];
    //unsigned screenCount = [screenArray count];
    unsigned index = 0;
    
    // only get the first screen
    //for (index; index < screenCount; index++)
    {
        NSScreen *screen = [screenArray objectAtIndex: index];
        screenRect = [screen visibleFrame];
    }
    return NSMakeSize(screenRect.size.width, screenRect.size.height + screenRect.origin.y);
}

@end
