//
//  McStatInfoHelp.h
//  MagicanPaster
//
//  Created by developer on 11-3-16.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//
//  this class for check base info

#import <Cocoa/Cocoa.h>


@interface McStatInfoHelp : NSObject {

}
// check battery is exist
+ (BOOL) checkBatteryExist;

+ (NSSize) getScreenSize;
@end
