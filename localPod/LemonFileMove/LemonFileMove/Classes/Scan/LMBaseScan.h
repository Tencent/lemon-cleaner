//
//  LMBaseScan.h
//  LemonFileMove
//

#import <Foundation/Foundation.h>
#import "LMFileMoveManger.h"
#import "LMResultItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMBaseScan : NSObject

// 获取相关目录
- (NSArray *)getPath:(NSString *)path
         shellString:(NSString *)shellString
             keyword:(NSString *)keyWord;

/// 查找子文件夹
/// - Parameters:
///   - path: 根目录
///   - destinationLevel: 遍历到设置的level结束
///   - isMatching: 判断是否为目标文件夹
- (NSArray *)enumerateSubdirectoriesAtPath:(NSString *)path
                          destinationLevel:(NSInteger)destinationLevel
                                isMatching:(BOOL (^)(NSString *fullPath, NSInteger currentLevel))isMatching;

//过滤90天/90天后
- (NSArray *)filterPathArray:(NSArray *)pathArray
                   parentDir:(nullable NSString *)parentDir
                continueExec:(BOOL(^)(NSString *path))continueExec
                      before:(BOOL)before;

- (void)callbackResultArray:(NSArray *)resultArray
                    appType:(LMAppCategoryItemType)appType
                       type:(LMFileMoveScanType)type
                     before:(BOOL)before
                 completion:(void(^)(LMResultItem *resultItem))completion;

@end

NS_ASSUME_NONNULL_END
