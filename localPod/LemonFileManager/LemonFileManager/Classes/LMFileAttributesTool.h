//
//  LMFileAttributesTool.h
//  LemonFileManager
//

//

#import <Foundation/Foundation.h>
#import "LMFileAttributesBaseItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^FinderResultBlock)(NSURL * pathURL);

@interface LMFileAttributesTool : NSObject

// item 用于处理不同来源的关联值
+ (uint64)caluactionSize:(NSString *)path associatedItem:(nullable __kindof LMFileAttributesBaseItem *)associatedItem diskMode:(BOOL)diskMode;

+ (uint64)caluactionSize:(NSString *)path diskMode:(BOOL)diskMode;

+ (BOOL)isHiddenItemForPath:(NSString *)path;

+ (BOOL)assertRegex:(NSString*)regexString matchStr:(NSString *)str;

@end

NS_ASSUME_NONNULL_END
