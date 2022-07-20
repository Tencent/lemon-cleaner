//
//  McSystemInfo.h
//  TestFunction
//
//  Created by developer on 11-1-11.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface McSystemInfo : NSObject 
{
    NSDate *bootTime;
    NSString *serialNum;
    NSString *modelName;
    NSString *osVersion;
    // get from internet
    NSString *prodDescr;
    NSString *purchCountry;
    NSString *covEndData;
}

// update boot time
- (NSDate *) UpdateBootTime;

// update machine serial number
- (NSString *) UpdateSerialNumber;

// update machine model
- (NSString *) UpdateModelName;

// update os version
- (NSString *) UpdateOsVersion;

// retrieve product information from internet
// this will block for a while
- (BOOL) RetrieveProductInformation;

// properties
@property (copy) NSDate *bootTime;
@property (copy) NSString *serialNum;
@property (copy) NSString *modelName;
@property (copy) NSString *osVersion;
// get from internet
@property (copy) NSString *prodDescr;
@property (copy) NSString *purchCountry;
@property (copy) NSString *covEndData;

@end
