//
//  LMBaseScan.m
//  LemonFileMove
//
//

#import "LMBaseScan.h"
#import "NSString+Extension.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import "LMFileHelper.h"

@implementation LMBaseScan

//过滤90天/90天后
- (NSArray *)filterPathArray:(NSArray *)pathArray
                   parentDir:(NSString *)parentDir
                continueExec:(BOOL(^)(NSString *path))continueExec
                      before:(BOOL)before {
      NSMutableArray *resultArr = [NSMutableArray new];
      for (NSString *_path in pathArray) {
          @autoreleasepool {
              NSString *path = _path;
              if (parentDir) {
                  path = [parentDir stringByAppendingPathComponent:path];
              }
              
              if (continueExec && !continueExec(path)) {
                  continue;
              }
              BOOL isDirectory = NO;
              if ([LMFileHelper isEmptyDirectory:path filterHiddenItem:YES isDirectory:&isDirectory] || !isDirectory) {
                  continue;
              }
              
              NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
              NSTimeInterval createTime = [[attr objectForKey:NSFileCreationDate] timeIntervalSince1970];
              NSTimeInterval nowInterval = [[NSDate date] timeIntervalSince1970];
              NSTimeInterval extraIntervalCreate = nowInterval - createTime;
              if(before == YES) {
                  if ((extraIntervalCreate > 90 * 24 * 60 * 60)) {
                      [resultArr addObject:path];
                  }
              } else {
                  if ((extraIntervalCreate <= 90 * 24 * 60 * 60)) {
                      [resultArr addObject:path];
                  }
              }
              
          }
      }
    return resultArr.copy;
}

- (void)callbackResultArray:(NSArray *)resultArray
                    appType:(LMAppCategoryItemType)appType
                       type:(LMFileMoveScanType)type
                     before:(BOOL)before
                 completion:(void(^)(LMResultItem *resultItem))completion {
    for (int i = 0; i <[resultArray count]; i ++) {
        NSString *result = [resultArray objectAtIndex:i];
        LMResultItem * resultItem = [[LMResultItem alloc] init];
        resultItem.path = result;
        resultItem.appType = appType;
        resultItem.fileType = type;

        NSArray *titleArr = [result componentsSeparatedByString:@"/"];
        if (titleArr && titleArr.count > 0) {
            resultItem.title = titleArr.lastObject;
        }
        if (before) {
            resultItem.selecteState = NSControlStateValueOn;
        } else {
            resultItem.selecteState = NSControlStateValueOff;
        }
        // 添加结果
        if (resultItem.fileSize == 0) {
            resultItem = nil;
        } else if (completion) {
            completion(resultItem);
        }
    }
}

// 获取相关目录
- (NSArray *)getPath:(NSString *)path
         shellString:(NSString *)shellString
             keyword:(NSString *)keyWord {
    NSMutableArray *resultArray = [NSMutableArray new];
    path = [path stringByReplacingOccurrencesOfString:@"~" withString:[NSString getUserHomePath]];
    
    NSString *cmd = [NSString stringWithFormat:shellString, path];
    NSString *retPath = [QMShellExcuteHelper excuteCmd:cmd];
    if ([retPath isKindOfClass:[NSNull class]]) {
        return nil;
    }
    if ((retPath == nil) || ([retPath isEqualToString:@""])) {
        return nil;
    }
    NSArray *retArray = [retPath componentsSeparatedByString:@"\n"];
    for (NSString *resultPath in retArray) {
        if ([resultPath containsString:keyWord]) {
            [resultArray addObject:resultPath];
        }
    }
    return resultArray;
}

@end
