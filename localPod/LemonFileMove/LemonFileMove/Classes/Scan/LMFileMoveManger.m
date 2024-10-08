//
//  LMFileMoveManger.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveManger.h"
#import "LMResultItem.h"
#import "NSString+Extension.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import "LMAppCategoryItem.h"
#import "LMWeChatScan.h"
#import "LMWorkWeChatScan.h"
#import "LMQQScan.h"
#import "LMFileHelper.h"
#import "LMFileCategoryItem.h"
#import "LMFileMoveFeatureDefines.h"

#define KB_LEVEL 1000000.0
#define MB_LEVEL 1000000000.0


@interface LMFileMoveManger ()<LMWeChatScanDelegate, LMWorkWeChatScanDelegate, LMQQScanDelegate >

@property (nonatomic, assign) BOOL isMoving;

@property (nonatomic, strong) NSMutableArray *appArr;
@property (nonatomic, assign) long long selectedFileSize;

@property (nonatomic, assign) LMFileMoveTargetPathType targetPathType;
@property (nonatomic, strong) NSString *targetPath;

@property (nonatomic, assign) long long movedFileSize; // 已移动完成的文件大小，等于成功+失败（不包括源文件被删除导致的失败，因为已经无法读取到源文件大小）
@property (nonatomic, assign) long long moveFailedFileSize; // 移动失败的文件大小（不包括源文件被删除导致的失败）
@property (nonatomic, assign) BOOL isMoveFailed;

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) NSMutableArray *scanningList;

@end

@implementation LMFileMoveManger

+ (instancetype)shareInstance {
    static LMFileMoveManger *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[[self class] alloc] init];
    });
    return shareInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.queue = dispatch_queue_create("com.tencent.lemonFileMoveManager", 0);
        [self resetData];
    }
    return self;
}

- (void)resetData {
    _scanningList = [NSMutableArray array];
    _appArr = [NSMutableArray array];
    _movedFileSize = 0;
    [self setupAppArr];

    self.delegate = nil;
    self.selectedFileSize = 0;
    self.movedFileSize = 0;
    self.moveFailedFileSize = 0;
    self.targetPath = nil;
    self.targetPathType = LMFileMoveTargetPathTypeUnknown;
    self.isMoveFailed = NO;
    self.isMoving = NO;
}

- (void)setupAppArr {
    LMAppCategoryItem *wechat = [[LMAppCategoryItem alloc] initWithType:LMAppCategoryItemType_WeChat];
    LMAppCategoryItem *weCom = [[LMAppCategoryItem alloc] initWithType:LMAppCategoryItemType_WeCom];
    LMAppCategoryItem *qq = [[LMAppCategoryItem alloc] initWithType:LMAppCategoryItemType_QQ];
    [_appArr addObject:wechat];
    [_appArr addObject:weCom];
    [_appArr addObject:qq];
}

- (void)stopScan {
    dispatch_async(self.queue, ^{
        for (__kindof LMBaseScan *scan in self.scanningList) {
            scan.cancel = YES;
        }
        [self resetData];
    });
}

- (void)startScan {
    dispatch_async(self.queue, ^{
        [self __startScan];
    });
}

- (void)__startScan {
    
    NSTimeInterval startScanTime = [[NSDate date] timeIntervalSince1970];
    // 微信
    LMWeChatScan *weChatScan = [[LMWeChatScan alloc] init];
    weChatScan.delegate = self;
    [weChatScan startScanWeChat];
    // 企业微信
    LMWorkWeChatScan *workWeChatScan = [[LMWorkWeChatScan alloc] init];
    workWeChatScan.delegate = self;
    [workWeChatScan startScanWorkWeChat];
    // qq
    LMQQScan *qqScan = [[LMQQScan alloc] init];
    qqScan.delegate = self;
    [qqScan startScanQQ];
    
    [_scanningList addObject:weChatScan];
    [_scanningList addObject:workWeChatScan];
    [_scanningList addObject:qqScan];

    // 计算大小
    for (LMAppCategoryItem *item in self.appArr) {
        for (int num = 0; num < 6; num ++) {
            LMFileCategoryItem *filecategory = item.subItems[num];
            item.fileSize = item.fileSize + filecategory.fileSize;
            NSArray *sortArr = [filecategory.subItems sortedArrayUsingComparator:^NSComparisonResult(LMResultItem *obj1, LMResultItem *obj2) {
                return (obj1.fileSize < obj2.fileSize);
            }];
            filecategory.subItems = [NSMutableArray arrayWithArray:sortArr];
        }
    }
    // 排序
    NSArray *sortArr = [self.appArr sortedArrayUsingComparator:^NSComparisonResult(LMAppCategoryItem *obj1, LMAppCategoryItem *obj2) {
        return (obj1.fileSize < obj2.fileSize);
    }];
    self.appArr = [NSMutableArray arrayWithArray:sortArr];
    //
    [self caculateSize];
    if ([self.delegate respondsToSelector:@selector(fileMoveMangerScanFinished)]) {
        [self.delegate fileMoveMangerScanFinished];
    }
}

- (long long)caculateSize {
    self.selectedFileSize = 0;
    // 计算select大小
    for (LMAppCategoryItem *item in self.appArr) {
        for (int num = 0; num < 6; num ++) {
            LMFileCategoryItem *filecategory = item.subItems[num];
            [filecategory.subItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                LMResultItem *item = obj;
                if (item.selecteState == NSControlStateValueOn) {
                    self.selectedFileSize = self.selectedFileSize + item.fileSize;
                }

            }];
        }
    }
    return self.selectedFileSize;
}

- (NSString *)sizeNumChangeToStr:(long long)num {
    float resultSize = 0.0;
    NSString *fileSizeStr;
    if (num < 0) {
        fileSizeStr = @"0KB";
    } if (num < KB_LEVEL){
        resultSize = num/1000.0;
        fileSizeStr = [NSString stringWithFormat:@"%0.1fKB",resultSize];
    }else if(num < MB_LEVEL){
        resultSize = num/KB_LEVEL;
        fileSizeStr = [NSString stringWithFormat:@"%0.1fMB",resultSize];
    }else{
        resultSize = num/MB_LEVEL;
        fileSizeStr = [NSString stringWithFormat:@"%0.1fGB",resultSize];
    }
    return fileSizeStr;
}

#pragma mark - LMWeChatScanDelegate
- (void)weChatScanWithType:(LMFileMoveScanType)type resultItem:(LMResultItem *)item {
    
    LMAppCategoryItem *currenAppItem = self.appArr[0];
    [self getFileItemToCategoryWithItem:item Itemtype:type appCategory:currenAppItem];
    if ([self.delegate respondsToSelector:@selector(fileMoveMangerScan:size:)]) {
        [self.delegate fileMoveMangerScan:item.path size:item.fileSize];
    }
}

#pragma mark - LMWorkWeChatScanDelegate
- (void)workWeChatScanWithType:(LMFileMoveScanType)type resultItem:(LMResultItem *)item {
//    NSLog(@"--%d:%@==%lld",type, item.path, item.fileSize);
    LMAppCategoryItem *currenAppItem = self.appArr[1];
    [self getFileItemToCategoryWithItem:item Itemtype:type appCategory:currenAppItem];
    if ([self.delegate respondsToSelector:@selector(fileMoveMangerScan:size:)]) {
        [self.delegate fileMoveMangerScan:item.path size:item.fileSize];
    }
}


#pragma mark - LMQQScanDelegate
- (void)QQScanWithType:(LMFileMoveScanType)type resultItem:(LMResultItem *)item {
//    NSLog(@"--%d:%@==%lld",type, item.originPath, item.fileSize);
    LMAppCategoryItem *currenAppItem = self.appArr[2];
    [self getFileItemToCategoryWithItem:item Itemtype:type appCategory:currenAppItem];
    if ([self.delegate respondsToSelector:@selector(fileMoveMangerScan:size:)]) {
        [self.delegate fileMoveMangerScan:item.originPath size:item.fileSize];
    }
}

- (void)getFileItemToCategoryWithItem:(LMResultItem *)item
                             Itemtype:(LMFileMoveScanType)type
                          appCategory:(LMAppCategoryItem *)currenAppItem {
    LMFileCategoryItem *filecategory;
    if(type == LMFileMoveScanType_File && item.selecteState == YES) {
        filecategory = currenAppItem.subItems[LMFileCategoryItemType_File90Before];
    } else if(type == LMFileMoveScanType_File && item.selecteState == NO) {
        filecategory = currenAppItem.subItems[LMFileCategoryItemType_File90];
    } else if(type == LMFileMoveScanType_Image && item.selecteState == YES) {
        filecategory = currenAppItem.subItems[LMFileCategoryItemType_Image90Before];
    } else if(type == LMFileMoveScanType_Image && item.selecteState == NO) {
        filecategory = currenAppItem.subItems[LMFileCategoryItemType_Image90];
    } else if(type == LMFileMoveScanType_Video && item.selecteState == YES) {
        filecategory = currenAppItem.subItems[LMFileCategoryItemType_Video90Before];
    } else if(type == LMFileMoveScanType_Video && item.selecteState == NO) {
        filecategory = currenAppItem.subItems[LMFileCategoryItemType_Video90];
    }
    [filecategory.subItems addObject:item];
    filecategory.fileSize = filecategory.fileSize + item.fileSize;
}

#pragma mark - Moving File

- (void)didSelectedTargetPath:(NSString *)path pathType:(LMFileMoveTargetPathType)pathType {
    self.targetPath = path;
    self.targetPathType = pathType;
}

- (void)startMoveFile {
    dispatch_async(self.queue, ^{
        NSTimeInterval startMoveTime = [[NSDate date] timeIntervalSince1970];
        
        self.isMoving = YES;
        // self.targetPath == .../柠檬清理_文件搬家/
        self.targetPath = [self.targetPath stringByAppendingPathComponent:[self dateString]]; // .../柠檬清理_文件搬家/2022-1-1
        self.targetPath = [LMFileHelper legalFilePath:self.targetPath]; // .../柠檬清理_文件搬家/2022-1-1(1)
        for (LMAppCategoryItem *appCategoryItem in self.appArr) {
            // 开始移动某个app
            if ([self.delegate respondsToSelector:@selector(lmFileMoveManager:startMovingAppCategoryType:)]) {
                [self.delegate lmFileMoveManager:self startMovingAppCategoryType:appCategoryItem.type];
            }

            NSString *toAppPath = [self.targetPath stringByAppendingPathComponent:[self pathComponentWithAppCategoryItem:appCategoryItem]]; // .../柠檬清理_文件搬家/2022-1-1(1)/微信
            for (LMFileCategoryItem *fileCategoryItem in appCategoryItem.subItems) {
                NSString *toFilePath = [toAppPath stringByAppendingPathComponent:[self pathComponentWithFileCategoryItem:fileCategoryItem]]; // .../柠檬清理_文件搬家/2022-1-1(1)/微信/图片
                for (LMResultItem *resultItem in fileCategoryItem.subItems) {
                    if (!self.isMoving) {
                        return;
                    }
                    if (resultItem.selecteState == NSControlStateValueOn) {
                        @autoreleasepool {
                            NSString *fromFilePath = [resultItem availableFilePath];
                            [self moveAllFilesFromFilePath:fromFilePath
                                                toFilePath:toFilePath
                                           appCategoryItem:appCategoryItem
                                          fileCategoryItem:fileCategoryItem
                                                resultItem:resultItem];
                        }
                    }
                }
            }
            // 移动完其中一个app
            if ([self.delegate respondsToSelector:@selector(lmFileMoveManager:didFinishMovingAppCategoryType:appMoveFailedFileSize:)]) {
                [self.delegate lmFileMoveManager:self didFinishMovingAppCategoryType:appCategoryItem.type appMoveFailedFileSize:appCategoryItem.moveFailedFileSize];
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(lmFileMoveManager:didFinishMovingSuccessfully:)]) {
            [self.delegate lmFileMoveManager:self didFinishMovingSuccessfully:!self.isMoveFailed];
        }
    });
}

- (void)stopMoveFile {
    self.isMoving = NO;
}

- (void)moveAllFilesFromFilePath:(NSString *)fromFilePath
                      toFilePath:(NSString *)toFilePath
                 appCategoryItem:(LMAppCategoryItem *)appCategoryItem
                fileCategoryItem:(LMFileCategoryItem *)fileCategoryItem
                      resultItem:(LMResultItem *)resultItem {
    if (fromFilePath.length <= 0) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self enumAllFilesInFilePath:fromFilePath
                           level:[self enumPathLevelWithAppCategoryItem:appCategoryItem]
                           block:^(NSString *fromPath, NSString *fileName, long long fileSize) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf.isMoving) {
            return;
        }

        NSString *toPath = [toFilePath stringByAppendingPathComponent:fileName];
        NSError *error = nil;
        if ([strongSelf.delegate respondsToSelector:@selector(lmFileMoveManager:movingFileName:filePath:fileSize:appCategoryType:)]) {
            [strongSelf.delegate lmFileMoveManager:strongSelf
                                    movingFileName:fileName
                                          filePath:fromPath
                                          fileSize:fileSize
                                   appCategoryType:resultItem.appType];
        }
        [[LMFileHelper defaultHelper] moveItemAtPath:fromPath toPath:toPath error:&error moveProgressHandler:^(long long movedFileSize) {
            if ([strongSelf.delegate respondsToSelector:@selector(lmFileMoveManager:updateMovedFileSize:totalFileSize:)]) {
                [strongSelf.delegate lmFileMoveManager:strongSelf
                                   updateMovedFileSize:strongSelf.movedFileSize + movedFileSize
                                         totalFileSize:strongSelf.selectedFileSize];
            }
        }];
        if (error) {
            strongSelf.moveFailedFileSize += fileSize;
            appCategoryItem.moveFailedFileSize += fileSize;
            fileCategoryItem.moveFailedFileSize += fileSize;
            resultItem.moveFailedFileSize += fileSize;
            
            strongSelf.isMoveFailed = YES;
            appCategoryItem.isMoveFailed = YES;
            fileCategoryItem.isMoveFailed = YES;
            resultItem.isMoveFailed = YES;
        }
        strongSelf.movedFileSize += fileSize;
        if ([strongSelf.delegate respondsToSelector:@selector(lmFileMoveManager:updateMovedFileSize:totalFileSize:)]) {
            [strongSelf.delegate lmFileMoveManager:strongSelf
                               updateMovedFileSize:strongSelf.movedFileSize
                                     totalFileSize:strongSelf.selectedFileSize];
        }
    }];
}

#pragma mark - Helper

- (NSString *)pathComponentWithAppCategoryItem:(LMAppCategoryItem *)item {
    switch (item.type) {
        case LMAppCategoryItemType_WeChat:
            return @"微信";
        case LMAppCategoryItemType_WeCom:
            return @"企业微信";
        case LMAppCategoryItemType_QQ :
            return @"QQ";
    }
}

- (NSString *)pathComponentWithFileCategoryItem:(LMFileCategoryItem *)item {
    switch (item.type) {
        case LMFileCategoryItemType_Image90Before:
        case LMFileCategoryItemType_Image90:
            return @"图片";
        case LMFileCategoryItemType_File90Before:
        case LMFileCategoryItemType_File90:
            return @"文件";
        case LMFileCategoryItemType_Video90Before:
        case LMFileCategoryItemType_Video90:
            return @"视频";
    }
}

- (NSInteger)enumPathLevelWithAppCategoryItem:(LMAppCategoryItem *)item {
    switch (item.type) {
        case LMAppCategoryItemType_WeChat:
            return 1;   // Image/xx.jpg
        case LMAppCategoryItemType_WeCom:
            return 2;   // 2022-02/somebody/xx.jpg
        case LMAppCategoryItemType_QQ :
            return 0;   // xx.jpg
    }
}

- (NSString *)dateString {
    NSTimeInterval sec = [[NSDate date] timeIntervalSinceNow];
    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter stringFromDate:currentDate];
}

/// 遍历目录下的文件。如果是文件夹，继续遍历level个层级深度
/// @param filePath 目录路径
/// @param level 文件夹层级，最大2
/// @param block 回调
- (void)enumAllFilesInFilePath:(NSString *)filePath
                         level:(NSInteger)level
                         block:(void(^)(NSString *fromPath, NSString *fileName, long long fileSize))block {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (!isDirectory) {
        // 单独的文件
        block(filePath, [filePath lastPathComponent], [LMFileHelper sizeForFilePath:filePath isDirectory:isDirectory]);
        return;
    }
    
    // 文件夹
    if (level == 0) { // 不需再往深层遍历了
        block(filePath, [filePath lastPathComponent], [LMFileHelper sizeForFilePath:filePath isDirectory:isDirectory]);
        return;
    }
    
    NSArray *paths = [fileManager contentsOfDirectoryAtPath:filePath error:nil];
    for (NSString *path in paths) {
        if (!self.isMoving) {
            return;
        }
        NSString *resultPath = [filePath stringByAppendingPathComponent:path];
        [fileManager fileExistsAtPath:resultPath isDirectory:&isDirectory];
        if (!isDirectory) {
            // 文件
            block(resultPath, [resultPath lastPathComponent], [LMFileHelper sizeForFilePath:resultPath isDirectory:isDirectory]);
        } else {
            // 文件夹
            if (level == 1) { // 不需再往深层遍历了
                block(resultPath, [resultPath lastPathComponent], [LMFileHelper sizeForFilePath:resultPath isDirectory:isDirectory]);
            } else { // level == 2
                // 再遍历一层
                NSArray *subPaths = [fileManager contentsOfDirectoryAtPath:resultPath error:nil];
                for (NSString *subPath in subPaths) {
                    NSString *resultSubPath = [resultPath stringByAppendingPathComponent:subPath];
                    [fileManager fileExistsAtPath:resultSubPath isDirectory:&isDirectory];
                    block(resultSubPath, [resultSubPath lastPathComponent], [LMFileHelper sizeForFilePath:resultSubPath isDirectory:isDirectory]);
                }
            }
        }
    }
}

@end
