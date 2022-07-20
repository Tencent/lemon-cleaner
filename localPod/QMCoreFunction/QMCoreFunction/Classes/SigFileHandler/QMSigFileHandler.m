//
//  QMSigFileHandler.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "QMSigFileHandler.h"

@implementation QMSigFileHandler
@synthesize version;
@synthesize data;

// 根据文件内容初始化
+ (QMSigFileHandler *)initWithContent:(NSData *)outputData
{
    NSData *origData;
    NSData *realData;
    uint32_t nVersion = 0;
        
    // MD5+[版本号+数据]
    // 比对hash结果
    const unsigned char *pHashValue = (unsigned char *)[outputData bytes];
    origData = [outputData subdataWithRange:NSMakeRange(16, [outputData length] - 16)];
    
    unsigned char hashValue[16] = {0};
    CC_MD5([origData bytes], (int)[origData length], hashValue);
    if (memcmp(hashValue, pHashValue, sizeof(hashValue)) != 0)
    {
        // hash校验错误
        return nil;
    }
    
    // 获取版本
    nVersion = *(uint32_t *)[origData bytes];
    // 纯数据部分
    realData = [origData subdataWithRange:NSMakeRange(sizeof(uint32_t), [origData length] - sizeof(uint32_t))];
    
    QMSigFileHandler *object = [[QMSigFileHandler alloc] init];
    object.version = nVersion;
    object.data = realData;
    return object;
}

@end
