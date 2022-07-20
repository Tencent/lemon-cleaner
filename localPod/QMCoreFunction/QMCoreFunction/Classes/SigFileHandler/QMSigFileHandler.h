//
//  QMSigFileHandler.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

// 该类用于读取加密后的特征库文件
// 能够自动解密并校验，可以返回版本
@interface QMSigFileHandler : NSObject
// 版本号
@property (assign) uint32_t version;
// 数据部分 - 解密后数据或者是加密数据
@property (retain) NSData *data;

// 根据文件内容初始化
+ (QMSigFileHandler *)initWithContent:(NSData *)data;

@end
