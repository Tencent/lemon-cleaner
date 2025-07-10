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
- (BOOL)checkBrokenPlistInfo:(NSString *)path {
    // 获取文件的属性
    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    
    // 检查文件大小是否超过 2MB
    if ([[dict objectForKey:NSFileSize] unsignedLongLongValue] > 1024 * 1024 * 2) {
        return NO; // 文件太大，认为是有效的
    }
    
    // 读取文件数据
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:nil];
    // 如果 data 为 nil，返回 YES（认为是损坏的）
    if (!data) {
        NSLog(@"File does not exist or cannot be read.");
        return YES; // plist 文件无效
    }
    NSPropertyListFormat format;
    NSError *error = nil;
    
    // 尝试解析 plist 数据
    id plist = [NSPropertyListSerialization propertyListWithData:data
                                                         options:NSPropertyListImmutable
                                                          format:&format
                                                           error:&error];
    // 如果 plist 解析失败，返回 YES（认为是损坏的）
    if (!plist) {
        NSLog(@"Error parsing plist: %@", error.localizedDescription);
        return YES; // plist 文件损坏
    }
    
    return NO; // plist 文件有效
}

// 判断是否存在可执行文件
// 查询plist文件中对应的Program 或者 ProgramArguments的第一个元素对应的地址是否存在可执行文件
- (BOOL)checkBrokenRegister:(NSString *)path {
    // 1. 读取 plist 文件
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    if (!dict) {
        NSLog(@"not open plist（%@）", path);
        return YES;
    }
    
    // 2. 检查 Program 键
    NSString *executablePath = dict[@"Program"];
    // 排除Program被配置了空字符串的情况
    BOOL effectivePath = [executablePath isKindOfClass:NSString.class] && (executablePath.length > 0);
    if (!effectivePath) {
        // 3. 回退检查 ProgramArguments 的第一个元素
        NSArray *programArguments = dict[@"ProgramArguments"];
        if (programArguments.count == 0) {
            NSLog(@"Error: Program and ProgramArguments does not contain executable Path(%@)", path);
            return YES;
        }
        executablePath = programArguments[0];
    }
    
    if (![executablePath isKindOfClass:NSString.class]) {
        // 非字符串
        return YES;
    }
    
    // 4. 处理路径中的 ~ 符号
    executablePath = [executablePath stringByExpandingTildeInPath];
    
    // 5. 验证文件可执行性
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:executablePath];
    
    return !isExists;
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
