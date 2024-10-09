//
//  LMFileMoveManger.h
//  LemonFileMove
//
//  
//

#import <Foundation/Foundation.h>
#import "LMAppCategoryItem.h"

@class LMFileMoveManger;

typedef NS_ENUM(NSInteger, LMFileMoveScanType) {
    LMFileMoveScanType_Image = 0,
    LMFileMoveScanType_File,
    LMFileMoveScanType_Video,
};

typedef NS_ENUM(NSUInteger, LMFileMoveTargetPathType) {
    LMFileMoveTargetPathTypeUnknown     = 0,
    LMFileMoveTargetPathTypeLocalPath   = 1, // 本地路径
    LMFileMoveTargetPathTypeDisk        = 2, // 外设磁盘
};

@protocol LMFileMoveMangerDelegate <NSObject>

@optional

#pragma mark - 扫描过程回调

- (void)fileMoveMangerScan:(NSString *)path size:(long long)size;

/// 扫描结束
- (void)fileMoveMangerScanFinished;

#pragma mark - 迁移过程回调

/// 开始移动某个App
/// @param manager manager
/// @param type 微信/QQ/企业微信
- (void)lmFileMoveManager:(LMFileMoveManger *)manager startMovingAppCategoryType:(LMAppCategoryItemType)type;
/// 某个App移动完成
/// @param manager manager
/// @param type 微信/QQ/企业微信
- (void)lmFileMoveManager:(LMFileMoveManger *)manager didFinishMovingAppCategoryType:(LMAppCategoryItemType)type appMoveFailedFileSize:(long long)appMoveFailedFileSize;

/// 进度更新
/// @param manager manager
/// @param movedFileSize 已移动完成的总文件大小
/// @param totalFileSize 总共需移动的总文件大小
- (void)lmFileMoveManager:(LMFileMoveManger *)manager
      updateMovedFileSize:(long long)movedFileSize
            totalFileSize:(long long)totalFileSize;

/// 正在移动某个文件
/// @param manager manager
/// @param fileName 文件名
/// @param filePath 文件完整路径
/// @param fileSize 文件大小
/// @param type 微信/QQ/企业微信
- (void)lmFileMoveManager:(LMFileMoveManger *)manager
           movingFileName:(NSString *)fileName
                 filePath:(NSString *)filePath
                 fileSize:(long long)fileSize
          appCategoryType:(LMAppCategoryItemType)type;

/// 全部移动完成时回调
/// @param manager manager
/// @param isSucceed 是否全部移动成功
- (void)lmFileMoveManager:(LMFileMoveManger *)manager didFinishMovingSuccessfully:(BOOL)isSucceed;

@end

@interface LMFileMoveManger : NSObject

@property (nonatomic, weak) id<LMFileMoveMangerDelegate> delegate;

@property (nonatomic, strong, readonly) NSMutableArray <LMAppCategoryItem *> *appArr;

@property (nonatomic, assign, readonly) long long selectedFileSize;

// 导出到目标路径/类型
@property (nonatomic, assign, readonly) LMFileMoveTargetPathType targetPathType;
@property (nonatomic, strong, readonly) NSString *targetPath;

+ (instancetype)shareInstance;

- (void)startScan;
- (void)stopScan;

- (NSString *)sizeNumChangeToStr:(long long)num;

- (long long)caculateSize;

#pragma mark - Moving File

@property (nonatomic, assign, readonly) long long movedFileSize; // 已移动完成的文件大小，等于成功+失败（不包括源文件被删除导致的失败，因为已经无法读取到源文件大小）
@property (nonatomic, assign, readonly) long long moveFailedFileSize; // 移动失败的文件大小（不包括源文件被删除导致的失败）

- (void)didSelectedTargetPath:(NSString *)path pathType:(LMFileMoveTargetPathType)pathType;
- (void)startMoveFile;
- (void)stopMoveFile;

@end
