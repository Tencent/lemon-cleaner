//
//  LMASRecentProjectsXMLParse.h
//  LemonUninstaller
//
//  
//  Copyright (c) 2021年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

// androidstudio的用户工程目录解析
@interface LMASRecentProjectsXMLParse : NSObject<NSXMLParserDelegate>

/**
 * 解析xml获得用户工程目录集合
 * @param xmlFilePath
 * @return
 */
- (NSArray<NSString *> *)parseXMLWithPath:(NSString *)xmlFilePath;

@end
