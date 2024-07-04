//
//  LMFileAttributesBaseItem.h
//  LemonFileManager
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMFileAttributesBaseItem : NSObject

@end

@interface LMFileAttributesCleanItem : LMFileAttributesBaseItem

/// 停止遍历计算文件夹大小
@property (nonatomic, copy) BOOL (^isStopped)(NSString *path);

@end

NS_ASSUME_NONNULL_END
