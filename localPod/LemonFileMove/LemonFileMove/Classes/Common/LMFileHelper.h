//
//  LMFileHelper.h
//  LemonFileMove
//
//  
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^LMFileHelperMoveProgressHandler)(long long movedFileSize);

@interface LMFileHelper : NSObject

+ (instancetype)defaultHelper;

/// 文件(夹)是否存在
/// @param path 路径
+ (BOOL)fileExistsAtPath:(NSString *)path;

/// 返回一个不冲突的命名，如xx(1).xx
/// @param originFilePath 原始路径
+ (NSString *)legalFilePath:(NSString *)originFilePath;

/// 目录下的所有文件个数（文件夹遍历到子节点）
/// 使用脚本计算，.DS_Store等隐藏文件也会被算进去
/// @param path 文件全路径
+ (NSInteger)fileCountAtPath:(NSString *)path;

/// 是否为空文件夹
/// @param path 目录
/// @param filterHiddenItem 是否过滤隐藏文件
/// @param isDirectory 甚至可能不是个文件夹
+ (BOOL)isEmptyDirectory:(NSString *)path filterHiddenItem:(BOOL)filterHiddenItem isDirectory:(nullable BOOL *)isDirectory;

/// 返回文件(夹)大小
/// @param filePath 文件(夹)完整路径
+ (long long)sizeForFilePath:(NSString *)filePath;

/// 返回文件(夹)大小
/// @param filePath 文件(夹)完整路径
/// @param isDirectory 已知是文件/文件夹
+ (long long)sizeForFilePath:(NSString *)filePath isDirectory:(BOOL)isDirectory;


/// 移动文件(夹)。注：为方便开发同学重复测试，DEBUG下实际为copy而非move操作
/// @param path 原始路径
/// @param toPath 目标路径
/// @param error 移动过程发生的错误
/// @param moveProgressHandler 移动过程中，每0.2秒回调一次进度
- (BOOL)moveItemAtPath:(NSString *)path
                toPath:(NSString *)toPath
                 error:(NSError **)error
    moveProgressHandler:(LMFileHelperMoveProgressHandler)moveProgressHandler;

@end

NS_ASSUME_NONNULL_END
