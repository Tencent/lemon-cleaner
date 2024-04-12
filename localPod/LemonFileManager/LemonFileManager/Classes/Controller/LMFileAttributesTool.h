//
//  LMFileAttributesTool.h
//  LemonFileManager
//

//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMFileAttributesTool : NSObject

+ (unsigned long long)lmFastFolderSizeAtFSRef:(NSString*)path diskMode:(BOOL)diskMode;

@end

NS_ASSUME_NONNULL_END
