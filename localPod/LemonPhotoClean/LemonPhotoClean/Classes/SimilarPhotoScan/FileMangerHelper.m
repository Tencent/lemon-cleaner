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
@end
