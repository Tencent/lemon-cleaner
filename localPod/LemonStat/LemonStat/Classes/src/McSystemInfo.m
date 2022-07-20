//
//  McSystemInfo.m
//  TestFunction
//
//  Created by developer on 11-1-11.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import "McSystem.h"
#import "McLogUtil.h"
#import "McSystemInfo.h"

@implementation McSystemInfo

// properties
@synthesize bootTime;
@synthesize serialNum;
@synthesize modelName;
@synthesize osVersion;
@synthesize prodDescr;
@synthesize purchCountry;
@synthesize covEndData;

- (id) init
{
    if (self = [super init])
    {
        bootTime = nil;
        serialNum = nil;
        modelName = nil;
        prodDescr = nil;
        purchCountry = nil;
        covEndData = nil;
        osVersion = nil;
        
        // update values
        [self UpdateBootTime];
        [self UpdateSerialNumber];
        [self UpdateModelName];
        [self UpdateOsVersion];
    }
    
    return self;
}


- (NSString *) description
{
    NSString *descStr = [NSString stringWithFormat:@"McSystemInfo class"];
    return descStr;
}

// update boot time
- (NSDate *) UpdateBootTime
{
    long seconds = McGetBootTime();
    if (seconds == -1)
        return nil;
    
    // convert
    
    bootTime = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
    return bootTime;
}

// update machine serial number
- (NSString *) UpdateSerialNumber
{
    char serial_buf[200] = {0};
    @try 
    {
        if (McGetMachineSerial(serial_buf, sizeof(serial_buf)) == -1)
            return nil;
    }
    @catch (NSException * e)
    {
        McLog(MCLOG_ERR, @"[%s] exception: %@: %@", __FUNCTION__, [e name], [e reason]);
        return nil;
    }
    
    // convert to nsstring
    
    serialNum = [[NSString alloc] initWithUTF8String:serial_buf];
    return serialNum;
}

// update machine model name
- (NSString *) UpdateModelName
{
    char model_buf[200] = {0};
    @try 
    {
        if (McGetMachineModel(model_buf, sizeof(model_buf)) == -1)
            return nil;
    }
    @catch (NSException * e)
    {
        McLog(MCLOG_ERR, @"[%s] exception: %@: %@", __FUNCTION__, [e name], [e reason]);
        return nil;
    }
    
    // convert to nsstring
    
    modelName = [[NSString alloc] initWithUTF8String:model_buf];
    return modelName;
}

// update os version
- (NSString *) UpdateOsVersion
{
    SInt32 majorVer = 0;
    Gestalt(gestaltSystemVersionMajor, &majorVer);
    SInt32 minorVer = 0;
    Gestalt(gestaltSystemVersionMinor, &minorVer);
    SInt32 bugVer = 0;
    Gestalt(gestaltSystemVersionBugFix, &bugVer);
    
    // combine to nsstring
    
    osVersion = [[NSString alloc] initWithFormat:@"%d.%d.%d", majorVer, minorVer, bugVer];
    return osVersion;
}

- (NSString *)findProductDesc:(NSString *)jsString {
    // search "PROD_DESCR":"iPhone 3GS"
    NSRange range = [jsString rangeOfString:@"\"PROD_DESCR\""];
    if (range.length != 0)
    {
       NSString *tempStr = [jsString substringFromIndex:(range.location + range.length + 2)];
        range = [tempStr rangeOfString:@"\""];
        if (range.location != 0 && range.length != 0)
        {
            // find
            return [[NSString alloc] initWithString:
                         [tempStr substringToIndex:range.location]];
        }
    }
    
    return NULL;
}

- (NSString *)findPurchCountry:(NSString *)jsString {
    // search "PURCH_COUNTRY":"HK"
    NSRange range = [jsString rangeOfString:@"\"PURCH_COUNTRY\""];
    if (range.length != 0)
    {
        NSString *tempStr = [jsString substringFromIndex:(range.location + range.length + 2)];
        range = [tempStr rangeOfString:@"\""];
        if (range.location != 0 && range.length != 0)
        {
            // find
            return [[NSString alloc] initWithString:
                         [tempStr substringToIndex:range.location]];
        }
    }
    return NULL;
}

- (NSString *)findEndDate:(NSString *)jsString {
    // search "COV_END_DATE":"2011-01-31"
    NSRange range = [jsString rangeOfString:@"\"COV_END_DATE\""];
    if (range.length == 0)
    {
        range = [jsString rangeOfString:@"\"ESTIMATED_END_DT\""];
    }
    if (range.length != 0)
    {
        NSString *tempStr = [jsString substringFromIndex:(range.location + range.length + 2)];
        range = [tempStr rangeOfString:@"\""];
        if (range.location != 0 && range.length != 0)
        {
            // find
            return [[NSString alloc] initWithString:
                            [tempStr substringToIndex:range.location]];
        }
    }
    return NULL;
}

// retrieve product information from internet
// this will block for a while
- (BOOL) RetrieveProductInformation
{
    if (serialNum == nil)
        return NO;
    
    // only need to get for one time
    if (prodDescr != nil && purchCountry != nil && covEndData != nil)
        return YES;
    
    // get https data
    NSString *urlAddr = [NSString stringWithFormat:@"https://selfsolve.apple.com/warrantyChecker.do?sn=%@&cb=crossDomainAjax.successResponse",
                         serialNum];
    
    // for test
    //NSLog(@"URL: [%@]", urlAddr);
    
    // create http request
    // time out set to 20s
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:urlAddr] 
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy 
                                          timeoutInterval:20.0];
    NSMutableData *urlData = (NSMutableData *)[NSURLConnection sendSynchronousRequest:theRequest 
                                                                    returningResponse:nil 
                                                                                error:nil];
    if (urlData == nil)
    {
        McLog(MCLOG_ERR, @"[%s] read url data fail", __FUNCTION__);
        return NO;
    }
    // add null
    [urlData appendBytes:"\0" length:1];
    
    // for test
    //[urlData writeToFile:@"/tmp/11.log" atomically:NO];
    
    NSString *jsString = [[NSString alloc] initWithUTF8String:[urlData bytes]];
    NSRange range;
    NSString *tempStr;
    
    // search "PROD_DESCR":"iPhone 3GS"
    prodDescr = [self findProductDesc:jsString];
    
    // search "PURCH_COUNTRY":"HK"
    purchCountry = [self findPurchCountry:jsString];
    
    // search "COV_END_DATE":"2011-01-31"
    covEndData = [self findEndDate:jsString];
    // if the product is not registed, we can only get estimated data
    if (covEndData == nil)
    {
        // search "ESTIMATED_END_DT":"2011-01-31"
        range = [jsString rangeOfString:@"\"ESTIMATED_END_DT\""];
        if (range.length != 0)
        {
            tempStr = [jsString substringFromIndex:(range.location + range.length + 2)];
            range = [tempStr rangeOfString:@"\""];
            if (range.location != 0 && range.length != 0)
            {
                // find
                
                covEndData = [[NSString alloc] initWithString:
                              [tempStr substringToIndex:range.location]];
            }
        }
    }
    
    if (prodDescr == nil || purchCountry == nil || covEndData == nil)
        return NO;
    
    return YES;
}

@end
