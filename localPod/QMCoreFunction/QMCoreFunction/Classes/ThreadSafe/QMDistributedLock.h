//
//  QMDistributedLock.h
//  Test
//
//  
//  Copyright (c) 2014年 http://www.tanhao.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMDistributedLock : NSObject

+ (QMDistributedLock *)lockWithPath:(NSString *)path;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPath:(NSString *)path;

- (BOOL)tryLock;
- (void)unlock;
- (void)breakLock;
@property (readonly, copy) NSDate *lockDate;

@end
