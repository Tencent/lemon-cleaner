//
//  QMShellExcuteHelper.h
//  QMCoreFunction
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMShellExcuteHelper : NSObject

+(NSString *)excuteCmd:(NSString *)cmd;

+(nullable NSString *) executeScript:(nonnull NSString*)scriptPath arguments:(nullable NSArray<NSString *>*)scriptArguments;

@end
