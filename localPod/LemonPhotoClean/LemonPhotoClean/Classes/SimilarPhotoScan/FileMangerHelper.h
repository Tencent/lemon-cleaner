//
//  FileMangerHelper.h
//  QQMacMgr
//
//  
//  Copyright © 2018 Hank. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileMangerHelper : NSObject

+(NSData *)returnDataWithDictionary:(NSMutableData*)mutableData;
+(NSMutableData *)returnDictionaryWithDataPath:(NSString *)path;
/**
 判断路径中是否包含系统图库

 @param rootPath 选择的路径
 @return YES：是
 */
+(Boolean)isContainPhotoLibraryWithPathArray:(NSArray*)rootPath;

/**
 剔除嵌套的子路径与完全相同的重复路径。

 当用户同时添加父目录与其子目录（如 ~/Pictures 与 ~/Pictures/sub）时，若不去重，
 收集图片阶段会对同一批图片重复收集，导致进度分母虚高、扫描无法结束（卡住）。
 本方法保留最外层路径、丢弃被其它路径包含的子路径，官网版与 AppStore 版逻辑一致。

 @param paths 用户选择的路径数组
 @return 去重后的路径数组（保留首次出现顺序）
 */
+(NSArray<NSString *> *)removeNestedSubPathsWithPathArray:(NSArray<NSString *> *)paths;
@end
