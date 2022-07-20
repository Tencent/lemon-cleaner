//
//  QMConditionLock.h
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMConditionLock : NSObject

+ (QMConditionLock *)sharedLock;

- (void)lockForKey:(id<NSCopying>)key;
- (void)unLockForKey:(id<NSCopying>)key;

@end
