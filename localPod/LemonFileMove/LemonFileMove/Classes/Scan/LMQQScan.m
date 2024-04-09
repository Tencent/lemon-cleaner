//
//  LMQQScan.m
//  LemonFileMove
//
//  
//

#import "LMQQScan.h"
#import "NSString+Extension.h"


#define QQScanPath       @"~/Library/Containers/com.tencent.qq/Data/Library/Caches"
#define QQScanNewPath    @"~/Library/Containers/com.tencent.qq/Data/Library/Application Support/QQ"

@implementation LMQQScan

- (void)startScanQQ {
    [self start];
    [self scanQQ:LMFileMoveScanType_Image before:YES];
    [self scanQQ:LMFileMoveScanType_Image before:NO];
    [self scanQQ:LMFileMoveScanType_File before:YES];
    [self scanQQ:LMFileMoveScanType_File before:NO];
    [self scanQQ:LMFileMoveScanType_Video before:YES];
    [self scanQQ:LMFileMoveScanType_Video before:NO];
    
    [self scanNewQQ:LMFileMoveScanType_Image before:YES];
    [self scanNewQQ:LMFileMoveScanType_Image before:NO];
    [self scanNewQQ:LMFileMoveScanType_File before:YES];
    [self scanNewQQ:LMFileMoveScanType_File before:NO];
    [self scanNewQQ:LMFileMoveScanType_Video before:YES];
    [self scanNewQQ:LMFileMoveScanType_Video before:NO];
}

- (void)scanQQ:(LMFileMoveScanType)type before:(BOOL)before {
    NSArray *pathArray;
    NSString *originPath = [QQScanPath stringByReplacingOccurrencesOfString:@"~" withString:[NSString getUserHomePath]];
    if (type == LMFileMoveScanType_Image) {
        pathArray = @[[originPath stringByAppendingPathComponent:@"Images"]];
    } else if (type == LMFileMoveScanType_File) {
        pathArray = @[[originPath stringByAppendingPathComponent:@"Files"]];
    } else if (type == LMFileMoveScanType_Video) {
        pathArray = @[[originPath stringByAppendingPathComponent:@"Videos"]];
    }
    
    //过滤90天/90天后
    NSMutableArray *resultArr = [NSMutableArray new];
    for (NSString *path in pathArray) {
        if (![path containsString:@"/Caches/Images"] && ![path containsString:@"/Caches/Videos"] && ![path containsString:@"/Caches/Files"]) {
            continue;
        }
        
        NSArray *subArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        NSArray *subResultArr = [self filterPathArray:subArr parentDir:path continueExec:^BOOL(NSString * path) {
            return YES;
        } before:before];
        [resultArr addObjectsFromArray:subResultArr];
    }
    
    __weak typeof(self) weakSelf = self;
    [self callbackResultArray:resultArr.copy appType:LMAppCategoryItemType_QQ type:type before:before completion:^(LMResultItem *resultItem) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(QQScanWithType:resultItem:)] && !self.cancel) {
            [strongSelf.delegate QQScanWithType:type resultItem:resultItem];
        }
    }];
}

- (void)scanNewQQ:(LMFileMoveScanType)type before:(BOOL)before {
    NSString *originPath = [QQScanNewPath stringByReplacingOccurrencesOfString:@"~" withString:[NSString getUserHomePath]];
    
    /// 1.用户文件夹
    /// 目标子文件夹的深度为1
    NSArray *userDirectories = [self enumerateSubdirectoriesAtPath:originPath destinationLevel:1 isMatching:^BOOL(NSString *fullpath, NSInteger currentLevel) {
        NSString *lastFileName = [fullpath pathComponents].lastObject;
        switch (currentLevel) {
            case 1:
                return [lastFileName hasPrefix:@"nt_qq_"];
            default:
                return NO;
        }
    }];
    
    NSArray *targetDirectories;
    if (type == LMFileMoveScanType_Image) {
        targetDirectories = [self findPicDirectoriesAtUserDirectories:userDirectories];
    } else if (type == LMFileMoveScanType_File) {
        targetDirectories = [self findFileDirectoriesAtUserDirectories:userDirectories];
    } else if (type == LMFileMoveScanType_Video) {
        targetDirectories = [self findVideoDirectoriesAtUserDirectories:userDirectories];
    }
    
    NSArray *resultArr = [self filterPathArray:targetDirectories
                                     parentDir:nil
                                  continueExec:^BOOL(NSString * path) { return YES; }
                                        before:before];
    
    __weak typeof(self) weakSelf = self;
    [self callbackResultArray:resultArr appType:LMAppCategoryItemType_QQ type:type before:before completion:^(LMResultItem *resultItem) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(QQScanWithType:resultItem:)] && !self.cancel) {
            [strongSelf.delegate QQScanWithType:type resultItem:resultItem];
        }
    }];
}

- (NSArray *)findPicDirectoriesAtUserDirectories:(NSArray *)userDirectories {
    
    NSMutableArray *picDirectories = [NSMutableArray array];
    
    for (NSString *path in userDirectories) {
        NSString *picPath = [path stringByAppendingPathComponent:@"nt_data/Pic"];
        NSArray *subPicContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:picPath error:nil];
        if (subPicContents.count > 0) {
            NSArray *imagesUnderPicPath = [picPath stringsByAppendingPaths:subPicContents];
            [picDirectories addObjectsFromArray:imagesUnderPicPath];
        }
    }
    
    return picDirectories.copy;
}

- (NSArray *)findFileDirectoriesAtUserDirectories:(NSArray *)userDirectories {
    NSMutableArray *fileDirectories = [NSMutableArray array];
    for (NSString *path in userDirectories) {
        NSString *filePath = [path stringByAppendingPathComponent:@"nt_data/File"];
        [fileDirectories addObject:filePath];
    }
    return fileDirectories.copy;
}

- (NSArray *)findVideoDirectoriesAtUserDirectories:(NSArray *)userDirectories {
    NSMutableArray *videoDirectories = [NSMutableArray array];
    for (NSString *path in userDirectories) {
        NSString *videoPath = [path stringByAppendingPathComponent:@"nt_data/Video"];
        NSArray *subVideoContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:videoPath error:nil];
        if (subVideoContents.count > 0) {
            NSArray *videoUnderPicPath = [videoPath stringsByAppendingPaths:subVideoContents];
            [videoDirectories addObjectsFromArray:videoUnderPicPath];
        }
    }
    return videoDirectories.copy;
}

@end
