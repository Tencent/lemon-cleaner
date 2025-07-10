//
//  MdlsToolsHelper.h
//  LemonClener
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MdlsToolsHelper : NSObject

+(NSInteger)getAppSizeByPath:(NSString *)path andFileType:(NSString *)type;

// maxSize 单位为MB
+ (void)redirectLogToFileAtPath:(NSString *)path forDays:(NSInteger)persistDays maxSize:(unsigned long long)maxSize;

@end
