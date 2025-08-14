//
//  QMWechatScan.m
//  LemonClener
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "QMWechatScan.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import "QMResultItem.h"
#import <sys/stat.h>
#import "QMCleanUtils.h"
#import <QMCoreFunction/LMReferenceDefines.h>

static NSString * const kCommonPartsOfPath = @"/Message/MessageTemp";
/// 微信4头像路径 包含 的字符串
static NSString * const kWeChat4PartsOfHeadImage = @"/temp/head_image";
/// 微信4聊天中的图片路径 包含 的字符串
static NSString * const kWeChat4PartsOfImages = @"/msg/attach";
/// 微信4接收的文件路径 包含 的字符串
static NSString * const kWeChat4PartsOfFiles = @"/msg/file";
/// 微信4接收的视频文件路径 包含 的字符串
static NSString * const kWeChat4PartsOfVideos = @"/msg/video";

@implementation QMWechatScan

#pragma mark - Public

//扫描头像图片
- (void)scanWechatAvatar:(QMActionItem *)actionItem {
    [self __scanWechatAvatar:actionItem];
    [self scanActionCompleted];
}

- (void)__scanWechatAvatar:(QMActionItem *)actionItem {
    // 微信4直接在结果中展示微信4的文件夹
    
    // 第一步：找出文件夹
    NSArray *folders = [self findFoldersWithAction:actionItem keyword:@"Avatar" v4Keyword:@"head_image"];
    
    NSMutableArray * v4Folders = [NSMutableArray array];
    NSMutableArray * v3Folders = [NSMutableArray array];
    for (NSString * dir in folders) {
        if ([QMCleanUtils isWeChat4FromPath:dir] && [dir hasSuffix:kWeChat4PartsOfHeadImage]) {
            [v4Folders addObject:dir];
        } else {
            [v3Folders addObject:dir];
        }
    }
    
    // 微信4
    if (v4Folders.count > 0) {
        [self callbackResultArray:v4Folders cleanType:actionItem.cleanType];
    }
    
    // 微信3
    // 分部处理结果
    // 该命令递归找出所有路径下的图片文件需要20s
    // NSString *shellString = @"mdfind -onlyin \"%@\" 'kMDItemContentTypeTree == \"public.image\"'";
    
    //该命令找出所有路径下第一层文件需要0.45s
    //NSString *shellString = @"find \"%@\" -maxdepth 1 -type f -not -name \".*\"";
    
    // 与mdfind 命令类似，前提是用户不修改后缀名。耗时0.35
    NSString *shellString = @"find \"%@\" -type f \\( -iname \\*.jpg -o -iname \\*.jpeg -o -iname \\*.png -o -iname \\*.gif \\)";
    @weakify(self);
    [self scanFileWithFolders:v3Folders shell:shellString continueExec:^BOOL(NSString *path){
        return YES;
    } eachCompletion:^(NSArray *resultArray) {
        @strongify(self);
        [self callbackResultArray:resultArray cleanType:actionItem.cleanType];
    }];
}

//扫描聊天图片 90天内
- (void)scanWechatImage:(QMActionItem *)actionItem {
    [self __scanWechatImage:actionItem];
    [self scanActionCompleted];
}

- (void)__scanWechatImage:(QMActionItem *)actionItem {
    // 微信4直接在结果中展示微信4的文件夹

    // 第一步：找出文件夹
    NSArray *folders = [self findFoldersWithAction:actionItem keyword:@"Image" v4Keyword:@"attach"];
    
    NSMutableArray * v4Folders = [NSMutableArray array];
    NSMutableArray * v3Folders = [NSMutableArray array];
    for (NSString * dir in folders) {
        if ([QMCleanUtils isWeChat4FromPath:dir] && [dir hasSuffix:kWeChat4PartsOfImages]) {
            [v4Folders addObject:dir];
        } else {
            [v3Folders addObject:dir];
        }
    }
    
    // 微信4
    if (v4Folders.count > 0) {
        [self callbackResultArray:v4Folders cleanType:actionItem.cleanType];
    }
    
    // 微信3
    // 原始代码是找出目录下所有文件。
    // 此处为了优化后续处理结果的代码，因此只按需查找图片文件
    // 为处理结果中的获取可以打开文件应用图标的耗时优化做准备
    NSString *shellString = @"find \"%@\" -type f \\( -iname \\*.jpg -o -iname \\*.jpeg -o -iname \\*.png -o -iname \\*.gif \\)";
    @weakify(self);
    [self scanFileWithFolders:v3Folders shell:shellString continueExec:^BOOL(NSString *path){
        return [path containsString:kCommonPartsOfPath];
    } eachCompletion:^(NSArray *resultArray) {
        @strongify(self);
        [self callbackResultArray:resultArray cleanType:actionItem.cleanType];
    }];
}

//扫描聊天图片 90天前
- (void)scanWechatImage90DayAgo:(QMActionItem *)actionItem {
    [self __scanWechatImage90DayAgo:actionItem];
    [self scanActionCompleted];
}

- (void)__scanWechatImage90DayAgo:(QMActionItem *)actionItem {
    NSArray *folders = [self findFoldersWithAction:actionItem keyword:@"Image" v4Keyword:@""];
    // 原始代码是找出目录下所有文件。
    // 此处为了优化后续处理结果的代码，因此只按需查找图片文件
    // 为处理结果中的获取可以打开文件应用图标的耗时优化做准备
    NSString *shellString = @"find \"%@\" -type f \\( -iname \\*.jpg -o -iname \\*.jpeg -o -iname \\*.png -o -iname \\*.gif \\) -mtime +90";
    @weakify(self);
    [self scanFileWithFolders:folders shell:shellString continueExec:^BOOL(NSString *path){
        return [path containsString:kCommonPartsOfPath];
    } eachCompletion:^(NSArray *resultArray) {
        @strongify(self);
        [self callbackResultArray:resultArray cleanType:actionItem.cleanType];
    }];
}

//扫描接收的文件
- (void)scanWechatFile:(QMActionItem *)actionItem {
    [self __scanWechatFile:actionItem];
    [self scanActionCompleted];
}

- (void)__scanWechatFile:(QMActionItem *)actionItem {
    NSArray *folders = [self findFoldersWithAction:actionItem keyword:@"File" v4Keyword:@"file"];
    
    NSMutableArray * v4Folders = [NSMutableArray array];
    NSMutableArray * v3Folders = [NSMutableArray array];
    for (NSString * dir in folders) {
        if ([QMCleanUtils isWeChat4FromPath:dir] && [dir hasSuffix:kWeChat4PartsOfFiles]) {
            [v4Folders addObject:dir];
        } else {
            [v3Folders addObject:dir];
        }
    }
    // 微信4
    if (v4Folders.count > 0) {
        [self callbackResultArray:v4Folders cleanType:actionItem.cleanType];
    }
    
    // 微信3
    @weakify(self);
    [self scanFileWithFolders:v3Folders shell:nil continueExec:^BOOL(NSString *path){
        return [path containsString:kCommonPartsOfPath];
    } eachCompletion:^(NSArray *resultArray) {
        @strongify(self);
        [self callbackResultArray:resultArray cleanType:actionItem.cleanType];
    }];
}

//扫描接收到的视频
- (void)scanWechatVideo:(QMActionItem *)actionItem {
    [self __scanWechatVideo:actionItem];
    [self scanActionCompleted];
}

- (void)__scanWechatVideo:(QMActionItem *)actionItem {
    NSArray *folders = [self findFoldersWithAction:actionItem keyword:@"Video" v4Keyword:@"video"];
    
    NSMutableArray * v4Folders = [NSMutableArray array];
    NSMutableArray * v3Folders = [NSMutableArray array];
    for (NSString * dir in folders) {
        if ([QMCleanUtils isWeChat4FromPath:dir] && [dir hasSuffix:kWeChat4PartsOfVideos]) {
            [v4Folders addObject:dir];
        } else {
            [v3Folders addObject:dir];
        }
    }
    // 微信4
    if (v4Folders.count > 0) {
        [self callbackResultArray:v4Folders cleanType:actionItem.cleanType];
    }
    
    // 微信3
    @weakify(self);
    [self scanFileWithFolders:folders shell:nil continueExec:^BOOL(NSString *path){
        return [path containsString:kCommonPartsOfPath];
    } eachCompletion:^(NSArray *resultArray) {
        @strongify(self);
        [self callbackResultArray:resultArray cleanType:actionItem.cleanType];
    }];
}

//扫描接收到的音频
- (void)scanWechatAudio:(QMActionItem *)actionItem {
    [self __scanWechatAudio:actionItem];
    [self scanActionCompleted];
}

- (void)__scanWechatAudio:(QMActionItem *)actionItem {
    NSArray *folders = [self findFoldersWithAction:actionItem keyword:@"Audio" v4Keyword:@""];
    @weakify(self);
    [self scanFileWithFolders:folders shell:nil continueExec:^BOOL(NSString *path){
        return [path containsString:kCommonPartsOfPath];
    } eachCompletion:^(NSArray *resultArray) {
        @strongify(self);
        [self callbackResultArray:resultArray cleanType:actionItem.cleanType];
    }];
}

#pragma mark - Common

/// 第一步：找出文件夹
/// @keyword 微信3专用
/// @v4Keywork 微信4专用
- (NSArray *)findFoldersWithAction:(QMActionItem *)actionItem keyword:(NSString *)keyword v4Keyword:(NSString *)v4Keyword {
    NSMutableArray *resultArray = [NSMutableArray new];
    NSMutableArray *pathArray = [NSMutableArray new];
    
    NSArray *pathItemArr = actionItem.pathItemArray;
    for (QMActionPathItem *pathItem in pathItemArr) {
        // 数量相对较少，此处均只有一个元素，可不用@autoreleasepool
        NSString *path = [pathItem value];
        path = [path stringByReplacingOccurrencesOfString:@"~" withString:[NSString getUserHomePath]];
        [pathArray addObject:path];
    }
    // 在指定路径下找到指定命名的文件夹
    NSString *shellString = @"mdfind -onlyin \"%@\" 'kMDItemContentType == \"public.folder\" && kMDItemDisplayName == \"%@\"'";
    NSString *shellStringEmptyName = @"mdfind -onlyin \"%@\" 'kMDItemContentType == \"public.folder\"'";
    // 统一使用find命令
    // 该命令找不到文件夹，暂时未使用
    // NSString *shellString = @"find \"%@\" -type d -name \"%@\"";
    
    for (NSString *path in pathArray) {
        NSString * currentKeyWord = keyword;
        if ([QMCleanUtils isWeChat4FromPath:path]) {
            currentKeyWord = v4Keyword;
        }
        
        // 数量相对较少，此处均只有一个元素，可不用@autoreleasepool
        NSString *cmd = nil;
        if (currentKeyWord.length > 0) {
            cmd = [NSString stringWithFormat:shellString, path, currentKeyWord];
        } else {
            cmd = [NSString stringWithFormat:shellStringEmptyName, path];
        }
        
        NSString *retPath = [QMShellExcuteHelper excuteCmd:cmd];
        if ([retPath isKindOfClass:[NSNull class]]) {
            continue;
        }
        if ((retPath == nil) || ([retPath isEqualToString:@""])) {
            continue;
        }
        NSArray *retArray = [retPath componentsSeparatedByString:@"\n"];
        [resultArray addObjectsFromArray:retArray];
        [resultArray removeObject:@""];
    }
    
    return resultArray;
}

// 递归找出folders下的所有图片文件并返回
- (void)scanFileWithFolders:(NSArray *)folders shell:(NSString *)shellString continueExec:(BOOL(^)(NSString *path))continueExec eachCompletion:(void(^)(NSArray *))completion {
    for(NSInteger i = 0; i < folders.count; i++) {
        @autoreleasepool {
            NSString *path = folders[i];
            if ([self.delegate scanProgressInfo:(i + 1.0) / [folders count] scanPath:path resultItem:nil]) {
                break;
            }
            
            if (continueExec && !continueExec(path)) {
                continue;
            }
            // 第二步：递归找出path下的文件
            if (shellString.length == 0) {
                // 直接返回当前路径
                if (completion) {
                    completion(@[path]);
                }
                continue;
            }
            
            NSArray *retArray = [self findFilesWithShell:shellString folder:path];
            if (retArray.count == 0) {
                continue;
            }
            if (completion) {
                completion(retArray);
            }
        }
    }
}

// 找出文件夹下的对应文件
- (NSArray *)findFilesWithShell:(NSString *)shellString folder:(NSString *)path {
    NSString *cmd = [NSString stringWithFormat:shellString, path];
    NSString *retPath = [QMShellExcuteHelper excuteCmd:cmd];
    if ([retPath isKindOfClass:[NSNull class]]) {
        return @[];
    }
    if ((retPath == nil) || ([retPath isEqualToString:@""])) {
        return @[];
    }
    NSArray *retArray = [retPath componentsSeparatedByString:@"\n"];
    NSMutableArray *resultArray = retArray.mutableCopy;
    [resultArray removeObject:@""];
    
    if (resultArray.count == 0) {
        return @[];
    }
    return resultArray.copy;
}

- (void)callbackResultArray:(NSArray *)resultArray cleanType:(QMCleanType)cleanType {
    // 逐个获取icon，耗时增加了2个数量级。
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:resultArray.firstObject];    
    for (int i = 0; i < [resultArray count]; i++)
    {
        @autoreleasepool {
            NSString *result = [resultArray objectAtIndex:i];
            
            QMResultItem *resultItem = [[QMResultItem alloc] initWithPath:result icon:icon];
            resultItem.cleanType = cleanType;
            
            // 添加结果
            if (resultItem) [resultItem addResultWithPath:result];
            if ([resultItem resultFileSize] == 0) {
                resultItem = nil;
            }
            if ([self.delegate scanProgressInfo:(i + 1.0) / [resultArray count] scanPath:result resultItem:resultItem])
                break;
        }
    }
}

@end
