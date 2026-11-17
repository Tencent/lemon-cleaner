//
//  FileMangerHelper.m
//  QQMacMgr
//
//  
//  Copyright © 2018 Hank. All rights reserved.
//

#import "FileMangerHelper.h"

@implementation FileMangerHelper
+(NSData *)returnDataWithDictionary:(NSMutableData*)mutableData
{
    NSMutableData * data = [[NSMutableData alloc] init];
    NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:mutableData forKey:@"talkData"];
    [archiver finishEncoding];
    
    return data;
}

+(NSMutableData *)returnDictionaryWithDataPath:(NSString *)path
{
    NSData * data = [[NSMutableData alloc] initWithContentsOfFile:path];
    NSKeyedUnarchiver * unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSMutableData * myDictionary = [unarchiver decodeObjectForKey:@"talkData"];
    [unarchiver finishDecoding];
    return myDictionary;
}

+ (void)saveResultData{
    //    NSString *alreadyCompareFileName = [self getDataFilePath:ALREADY_COMPARE_DATA];
    //
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //            NSData *data = [[self class ] returnDataWithDictionary:(NSMutableData*)self.resultData_needSaveData];
    //            BOOL res = [data writeToFile: alreadyCompareFileName atomically: NO];
    //            if (res) {
    //                NSLog(@"文件写入成功");
    //            } else {
    //                NSLog(@"文件写入失败");
    //            }
    //        });
}

+(Boolean)isContainPhotoLibraryWithPathArray:(NSArray*)rootPath{
    for (NSString *path in rootPath) {
        if ([path containsString:@".photoslibrary"]) {
            return YES;
        }
    }
    return NO;
}

+(NSArray<NSString *> *)removeNestedSubPathsWithPathArray:(NSArray<NSString *> *)paths{
    if (paths.count == 0) {
        return @[];
    }
    // 第一步：去掉完全相同的重复路径，保留首次出现顺序
    NSMutableOrderedSet<NSString *> *uniquePaths = [NSMutableOrderedSet orderedSet];
    for (NSString *path in paths) {
        if (path.length > 0) {
            [uniquePaths addObject:path];
        }
    }
    // 第二步：剔除被其它路径包含的子路径
    NSMutableArray<NSString *> *resultPaths = [NSMutableArray array];
    for (NSString *path in uniquePaths) {
        BOOL isChildOfOther = NO;
        for (NSString *comparePath in uniquePaths) {
            if ([comparePath isEqualToString:path]) {
                continue;
            }
            // comparePath 是 path 的祖先目录：补 "/" 边界，避免 /a/bc 被误判为 /a/b 的子路径
            NSString *prefix = [comparePath hasSuffix:@"/"] ? comparePath : [comparePath stringByAppendingString:@"/"];
            if (comparePath.length < path.length && [path hasPrefix:prefix]) {
                isChildOfOther = YES;
                break;
            }
        }
        if (!isChildOfOther) {
            [resultPaths addObject:path];
        }
    }
    return resultPaths;
}
@end
