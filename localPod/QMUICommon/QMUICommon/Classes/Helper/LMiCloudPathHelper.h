//
//  LMiCloudPathHelper.h
//  LemonDuplicateFile
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMiCloudPathHelper : NSObject


// Finder 中 iClound 的目录是 "~/Library/Mobile Documents/com~apple~CloudDocs" 但是其在 Finder 中展示的内容不仅是其子目录,还
// 包括其同级目录. 所以用户选择 "~/Library/Mobile Documents/com~apple~CloudDocs"时,替换为"~/Library/Mobile Documents" 目录.
//
+ (BOOL)isICloudSubPath:(NSString *)path;
+ (BOOL)isICloudContanierPath:(NSString *)path;
+ (BOOL)isICloudPath:(NSString *)path;
+ (NSString *)getICloudContainerPath;
+ (NSString *)getICloudPath;
+ (NSString *)getICloudPathdisplayName;



@end


