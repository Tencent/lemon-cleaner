//
//  NSBundle+Extension.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle(NoCache)

- (id)infoValueForKey:(NSString *)key;
- (NSString *)shortVersionString;

@end
