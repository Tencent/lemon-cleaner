//
//  QMCryptUtility.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

enum
{
    QMHashKindMd5,
    QMHashKindSha1,
    QMHashKindSha256,
    QMHashKindSha512,
};
typedef NSInteger QMHashKind;

enum
{
    QMCryptorKindAES128,
    QMCryptorKindDES,
};
typedef NSInteger QMCryptorKind;

enum {
    QMOperationKindEncrypt,
    QMOperationKindDecrypt,
};
typedef NSInteger QMOperationKind;

@interface QMCryptUtility : NSObject

+ (NSString *)hashFile:(NSString *)filePath with:(QMHashKind)hashKind;
+ (NSString *)hashData:(NSData *)data with:(QMHashKind)hashKind;
+ (NSString *)hashString:(NSString *)string with:(QMHashKind)hashKind;

+ (NSString *)hMacData:(NSData *)data withSecretKey:(NSString *)secretKey withHashKind:(QMHashKind)hashKind;
+ (NSString *)hMacString:(NSString *)string withSecretKey:(NSString *)secretKey withHashKind:(QMHashKind)hashKind;

+ (NSData *)cryptorData:(NSData *)data key:(NSData *)key iv:(NSData *)iv operation:(QMOperationKind)operation kind:(QMCryptorKind)cryKind;

@end
