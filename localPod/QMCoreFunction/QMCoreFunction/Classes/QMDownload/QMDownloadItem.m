//
//  QMDownloadItem.m
//  QMDownload
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMDownloadItem.h"
#import "QMDownloadItemPrivate.h"
#import <objc/runtime.h>

NSString *QMDownloadItemStatusNotification = @"QMDownloadItemStatusNotification";

@implementation QMDownloadItem
@synthesize url,context,fileSize,hash_md5,hash_sha1;
@synthesize fileName,filePath,status,progress,speed,averageSpeed,totalSpendTime,latestSpendTime;
@synthesize downloadInfoPath;

- (void)postNotification
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(postNotification) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:QMDownloadItemStatusNotification
                                                        object:self
                                                      userInfo:nil];
}

- (NSString *)description
{
    NSMutableString *resultString = [NSMutableString string];
    unsigned int outCount = 0;
    const objc_property_t* propertyList = class_copyPropertyList(self.class, &outCount);
    for (unsigned int idx = 0; idx<outCount; idx++)
    {
        objc_property_t property = propertyList[idx];
        const char* propertyCStr = property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:propertyCStr];
        NSString *propertyValue = [self valueForKey:propertyName];
        
        if (propertyValue)
        {
            [resultString appendFormat:@"%@:%@\n",propertyName,propertyValue];
        }
    }
    return resultString;
}

@end
