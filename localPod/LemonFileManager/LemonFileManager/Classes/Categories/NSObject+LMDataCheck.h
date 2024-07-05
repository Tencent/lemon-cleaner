//
//  NSObject+LMDataCheck.h
//  LemonFileManager
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (LMDataCheck)

/// 递归检查数据是否包含null
/// 仅递归检查字典和数组
- (BOOL)traverseDataStructureAndCheckForNullValues;

@end

NS_ASSUME_NONNULL_END
