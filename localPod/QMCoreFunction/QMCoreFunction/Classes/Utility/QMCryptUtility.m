//
//  QMCryptUtility.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMCryptUtility.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h>

@implementation QMCryptUtility

#pragma mark -
#pragma mark Hash

#define QMHashSizeForRead (4*1024)

+ (NSString *)hashFile:(NSString *)filePath with:(QMHashKind)hashKind
{
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:filePath];
    if (!inputStream)
    {
        return nil;
    }
    
    void *CTXPoint = NULL;
    switch (hashKind)
    {
        case QMHashKindMd5:
        {
            CTXPoint = (CC_MD5_CTX *)calloc(1, (sizeof(CC_SHA1_CTX)));
            CC_MD5_Init(CTXPoint);
            break;
        }
        case QMHashKindSha1:
        {
            CTXPoint = (CC_SHA1_CTX *)calloc(1, (sizeof(CC_SHA1_CTX)));
            CC_SHA1_Init(CTXPoint);
            break;
        }
        case QMHashKindSha256:
        {
            CTXPoint = (CC_SHA256_CTX *)calloc(1, (sizeof(CC_SHA256_CTX)));
            CC_SHA256_Init(CTXPoint);
            break;
        }
        case QMHashKindSha512:
        {
            CTXPoint = (CC_SHA512_CTX *)calloc(1, (sizeof(CC_SHA512_CTX)));
            CC_SHA512_Init(CTXPoint);
            break;
        }
        default:
        {
            return nil;
            break;
        }
    }
    
    [inputStream open];
    while (YES)
    {
        uint8_t buffer[QMHashSizeForRead];
        NSInteger readBytesCount = [inputStream read:buffer maxLength:sizeof(buffer)];
        if (readBytesCount < 0)
        {
            [inputStream close];
            free(CTXPoint);
            return nil;
        }
        else if (readBytesCount == 0)
        {
            break;
        }
        
        switch (hashKind)
        {
            case QMHashKindMd5:
            {
                CC_MD5_Update(CTXPoint,(const void *)buffer,(CC_LONG)readBytesCount);
                break;
            }
            case QMHashKindSha1:
            {
                CC_SHA1_Update(CTXPoint,(const void *)buffer,(CC_LONG)readBytesCount);
                break;
            }
            case QMHashKindSha256:
            {
                CC_SHA256_Update(CTXPoint,(const void *)buffer,(CC_LONG)readBytesCount);
                break;
            }
            case QMHashKindSha512:
            {
                CC_SHA512_Update(CTXPoint,(const void *)buffer,(CC_LONG)readBytesCount);
                break;
            }
        }
    }
    
    unsigned char *digest = NULL;
    NSUInteger digestLength = 0;
    switch (hashKind)
    {
        case QMHashKindMd5:
        {
            digestLength = CC_MD5_DIGEST_LENGTH;
            digest = (u_char *)calloc(1, digestLength);
            CC_MD5_Final(digest, CTXPoint);
            break;
        }
        case QMHashKindSha1:
        {
            digestLength = CC_SHA1_DIGEST_LENGTH;
            digest = (u_char *)calloc(1, digestLength);
            CC_SHA1_Final(digest, CTXPoint);
            break;
        }
        case QMHashKindSha256:
        {
            digestLength = CC_SHA256_DIGEST_LENGTH;
            digest = (u_char *)calloc(1, digestLength);
            CC_SHA256_Final(digest, CTXPoint);
            break;
        }
        case QMHashKindSha512:
        {
            digestLength = CC_SHA512_DIGEST_LENGTH;
            digest = (u_char *)calloc(1, digestLength);
            CC_SHA512_Final(digest, CTXPoint);
            break;
        }
    }
    // Compute the string result
    NSMutableString *hashString = [NSMutableString string];
    for (size_t i = 0; i < digestLength; ++i)
    {
        [hashString appendFormat:@"%02x",digest[i]];
    }
    
    [inputStream close];
    free(digest);
    free(CTXPoint);
    return hashString;
}

+ (NSString *)hashData:(NSData *)data with:(QMHashKind)hashKind
{
    if (!data)
    {
        return nil;
    }
    
    const char *cStr = [data bytes];
	
    unsigned char *digest = NULL;
    NSUInteger digestLength = 0;
    switch (hashKind)
    {
        case QMHashKindMd5:
        {
            digestLength = CC_MD5_DIGEST_LENGTH;
            digest = (u_char *)calloc(1, digestLength);
            CC_MD5(cStr, (uint32_t)data.length, digest);
            break;
        }
        case QMHashKindSha1:
        {
            digestLength = CC_SHA1_DIGEST_LENGTH;
            digest = (u_char *)calloc(1, digestLength);
            CC_SHA1(cStr, (uint32_t)data.length, digest);
            break;
        }
        case QMHashKindSha256:
        {
            digestLength = CC_SHA256_DIGEST_LENGTH;
            digest = (u_char *)calloc(1, digestLength);
            CC_SHA256(cStr, (uint32_t)data.length, digest);
            break;
        }
        case QMHashKindSha512:
        {
            digestLength = CC_SHA512_DIGEST_LENGTH;
            digest = (u_char *)calloc(1, digestLength);
            CC_SHA512(cStr, (uint32_t)data.length, digest);
            break;
        }
        default:
        {
            return nil;
            break;
        }
    }
    
    NSMutableString *hashString = [NSMutableString string];
    for (size_t i = 0; i < digestLength; ++i)
    {
        [hashString appendFormat:@"%02x",digest[i]];
    }
    free(digest);
    return hashString;
}

+ (NSString *)hashString:(NSString *)string with:(QMHashKind)hashKind
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (!data)
    {
        return nil;
    }
    return [self hashData:data with:hashKind];
}

#pragma mark -
#pragma mark HMAC

+ (NSString *)hMacData:(NSData *)data withSecretKey:(NSString *)secretKey withHashKind:(QMHashKind)hashKind
{
    if (!data || !secretKey)
    {
        return nil;
    }
    
    CCHmacAlgorithm algorithm;
    NSUInteger digestLength;
    switch (hashKind)
    {
        case QMHashKindMd5:
        {
            digestLength = CC_MD5_DIGEST_LENGTH;
            algorithm = kCCHmacAlgMD5;
            break;
        }
        case QMHashKindSha1:
        {
            digestLength = CC_SHA1_DIGEST_LENGTH;
            algorithm = kCCHmacAlgSHA1;
            break;
        }
        case QMHashKindSha256:
        {
            digestLength = CC_SHA256_DIGEST_LENGTH;
            algorithm = kCCHmacAlgSHA256;
            break;
        }
        case QMHashKindSha512:
        {
            digestLength = CC_SHA512_DIGEST_LENGTH;
            algorithm = kCCHmacAlgSHA512;
            break;
        }
        default:
        {
            return nil;
            break;
        }
    }
    
    const char *cKey =  [secretKey cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char cHMAC[digestLength];
    CCHmac(algorithm, cKey, strlen(cKey), data.bytes, data.length, cHMAC);
    
    NSMutableString* hash = [NSMutableString  string];
    for(int i = 0; i < sizeof(cHMAC); i++)
    {
        [hash appendFormat:@"%02x", cHMAC[i]];
    }
    return hash;
}

+ (NSString *)hMacString:(NSString *)string withSecretKey:(NSString *)secretKey withHashKind:(QMHashKind)hashKind
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (!data || !secretKey)
    {
        return nil;
    }
    return [self hMacData:data withSecretKey:secretKey withHashKind:hashKind];
}

#pragma mark -
#pragma mark Cryptor

+ (NSData *)cryptorData:(NSData *)data key:(NSData *)key iv:(NSData *)iv operation:(QMOperationKind)operation kind:(QMCryptorKind)cryKind
{
    CCOperation cryOperation;
    switch (operation)
    {
        case QMOperationKindEncrypt: cryOperation = kCCEncrypt; break;
        case QMOperationKindDecrypt: cryOperation = kCCDecrypt; break;
        default: return nil;
    }
    
    NSUInteger keyLength = 0;
    NSUInteger blockLength = 0;
    CCAlgorithm algorithm;
    switch (cryKind)
    {
        case QMCryptorKindAES128:
        {
            keyLength = kCCKeySizeAES128;
            blockLength = kCCBlockSizeAES128;
            algorithm = kCCAlgorithmAES128;
            break;
        }
        case QMCryptorKindDES:
        {
            keyLength = kCCKeySizeDES;
            blockLength = kCCBlockSizeDES;
            algorithm = kCCAlgorithmDES;
            break;
        }
        default:return nil;
    }
    
    //setup key
    unsigned char cKey[keyLength];
	bzero(cKey, sizeof(cKey));
    [key getBytes:cKey length:keyLength];
	
    //setup iv
    char cIv[blockLength];
    bzero(cIv, blockLength);
    if (iv)
    {
        [iv getBytes:cIv length:blockLength];
    }
    
    //setup output buffer
	size_t bufferSize = [data length] + blockLength;
	void *buffer = malloc(bufferSize);
    
    //encrypt|decrypt
	size_t encryptedSize = 0;
	CCCryptorStatus cryptStatus = CCCrypt(cryOperation,
                                          algorithm,
                                          kCCOptionPKCS7Padding,
                                          cKey,
                                          keyLength,
                                          cIv,
                                          [data bytes],
                                          [data length],
                                          buffer,
                                          bufferSize,
										  &encryptedSize);
    NSData* result = nil;
	if (cryptStatus == kCCSuccess)
    {
		result = [NSData dataWithBytesNoCopy:buffer length:encryptedSize];
	} else
    {
        free(buffer);
    }
	
	return result;
}

@end
