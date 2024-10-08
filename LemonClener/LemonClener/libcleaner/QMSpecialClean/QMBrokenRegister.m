//
//  QMBrokenRegister.m
//  TestXMLParase
//

//  Copyright (c) 2013年 tencent. All rights reserved.
//

#import "QMBrokenRegister.h"
//#include <stdio.h>
//#include <stdlib.h>
//#include <string.h>
//#include <sys/stat.h>
#import "QMFilterParse.h"
#import "QMResultItem.h"

@implementation QMBrokenRegister
@synthesize delegate;

// 检查plist是否合法
- (BOOL)checkBrokenPlistInfo:(NSString *)path
{
    //                struct stat *filestats = (struct stat *) malloc(sizeof(struct stat));
    //
    //                char *plist_entire = NULL;
    //                const char * filePath = [curObj UTF8String];
    //                FILE *iplist = NULL;
    //                iplist = fopen(filePath, "rb");
    //                stat(filePath, filestats);
    //                plist_entire = (char *) malloc(sizeof(char) * (filestats->st_size + 1));
    //                fread(plist_entire, sizeof(char), filestats->st_size, iplist);
    //                fclose(iplist);
    //                if (memcmp(plist_entire, "bplist00", 8)!= 0)
    //                {
    //
    //                }
    //                free(filestats);
    //                free(plist_entire);
    NSDictionary * dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                          error:nil];
    if ([[dict objectForKey:NSFileSize] unsignedLongLongValue] > 1024 * 1024 * 2)
        return NO;
    NSData *data = [NSData dataWithContentsOfFile:path
                                          options:0
                                            error:nil];
    if (data)
    {
        NSPropertyListFormat format;
        id plist = [NSPropertyListSerialization propertyListWithData:data
                                                             options:NSPropertyListImmutable
                                                              format:&format
                                                               error:nil];
        // insert code here...
        if (!plist)
        {
            return YES;
        }
    }
//    NSDictionary * dict = [NSDictionary dictionaryWithContentsOfFile:path];
//    NSArray * array = [NSArray arrayWithContentsOfFile:path];
//    if (!dict && !array)
//        return YES;
    return NO;
}

- (BOOL)checkProgramExist:(NSString *)program
{
    if ([program hasPrefix:@"/"])
    {
        return [[NSFileManager defaultManager] fileExistsAtPath:program];
    }
    return NO;
}

// 根据Plist中ProgramArguments/Program字段判断程序是否存在
- (BOOL)checkBrokenRegister:(NSString *)path
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    if (dict)
    {
        BOOL isBroken = YES;
        NSArray * array = [dict objectForKey:@"ProgramArguments"];
        if (array)
        {
            for (NSString * str in array)
            {
                if ([self checkProgramExist:str])
                {
                    isBroken = NO;
                    break;
                }
            }
        }
        else
        {
            NSString * program = [dict objectForKey:@"Program"];
            if (program && [self checkProgramExist:program])
                isBroken = NO;
        }
        return isBroken;
    }
    return YES;
}

// 通过LaunchSever获取当前未用的启动项
- (NSArray *)scanBrokenLoginInfo
{
    NSMutableArray * retArray = [NSMutableArray array];
    NSFileManager * fm = [NSFileManager defaultManager];
    
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems)
    {
		UInt32 seedValue;
		//Retrieve the list of Login Items and cast them to
		// a NSArray so that it will be easier to iterate.
		NSArray  *loginItemsArray = (__bridge_transfer NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
		
		for(int i = 0; i< [loginItemsArray count]; i++)
        {
			LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)[loginItemsArray
                                                                        objectAtIndex:i];
            if (!itemRef)
                continue;
            
            CFStringRef displayName = LSSharedFileListItemCopyDisplayName(itemRef);
            if (!displayName)
                continue;
            CFURLRef url;
			//Resolve the item with URL
			if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr && url)
            {
				NSString * urlPath = [(__bridge NSURL*)url path];
                if (![fm fileExistsAtPath:urlPath])
                    [retArray addObject:(__bridge NSString *)displayName];
                CFRelease(url);
			}
            else
            {
                [retArray addObject:(__bridge NSString *)displayName];
            }
            CFRelease(displayName);
		}
        CFRelease(loginItems);
	}
    return retArray;
}

- (void)scanBrokenRegister:(QMActionItem *)actionItem
{
    [self __scanBrokenRegister:actionItem];
    [self scanActionCompleted];
}

- (void)__scanBrokenRegister:(QMActionItem *)actionItem
{
    QMFilterParse * filterParse = [[QMFilterParse alloc] initFilterDict:[delegate xmlFilterDict]];
    NSArray * pathArray = [filterParse enumeratorAtFilePath:actionItem];
    for (int i = 0; i < [pathArray count]; i++)
    {
        NSString * result = [pathArray objectAtIndex:i];
        
        QMResultItem * resultItem = nil;
        if (actionItem.type == QMActionBrokenPlistType)
        {
            // 结果过滤
            if ([self checkBrokenPlistInfo:result]
                && [filterParse filterPathWithFilters:result])
                resultItem = [[QMResultItem alloc] initWithPath:result];
        }
        else if (actionItem.type == QMActionBrokenReigisterType)
        {
            // 结果过滤
            if ([self checkBrokenRegister:result]
                && [filterParse filterPathWithFilters:result])
                resultItem = [[QMResultItem alloc] initWithPath:result];
        }
        // 添加结果
        resultItem.cleanType = actionItem.cleanType;
        if (resultItem) [resultItem addResultWithPath:result];
        if ([delegate scanProgressInfo:(i + 1.0) / [pathArray count] scanPath:result resultItem:resultItem])
        {
            return;
        }
    }
    // 添加登陆项
    if (actionItem.type == QMActionBrokenReigisterType)
    {
        NSArray * loginArray = [self scanBrokenLoginInfo];
        for (NSString * brokenLogin in loginArray)
        {
            
            QMResultItem * resultItem = nil;
            if ([filterParse filterPathWithFilters:brokenLogin])
                resultItem = [[QMResultItem alloc] init];
            // 添加结果
            if (resultItem)
            {
                resultItem.title = brokenLogin;
                resultItem.path = brokenLogin;
                resultItem.showPath = brokenLogin;
                [resultItem addResultWithPath:brokenLogin];
                resultItem.cleanType = QMCleanRemoveLogin;
            }
            if ([delegate scanProgressInfo:(1.0) / [pathArray count] scanPath:brokenLogin resultItem:resultItem])
                break;
                
        }
    }
}

@end
