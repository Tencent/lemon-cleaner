//
//  QMDuplicateHelp.m
//  FileCleanDemo
//
//  
//  Copyright (c) 2014年 yuanwen. All rights reserved.
//

#import "QMDuplicateHelp.h"
#import <CommonCrypto/CommonDigest.h>

/*
 Function FileMD5HashCreateWithPath to compute MD5 hash
 written by Joel Lopes Da Silva.
 
 It’s really simple to adapt this function to other algorithms.
 Say you want to adapt it to get the SHA1 hash instead.
 Here’s what you need to do:
 
 replace CC_MD5_CTX with CC_SHA1_CTX;
 replace CC_MD5_Init with CC_SHA1_Init;
 replace CC_MD5_Update with CC_SHA1_Update;
 replace CC_MD5_Final with CC_SHA1_Final;
 replace CC_MD5_DIGEST_LENGTH with CC_SHA1_DIGEST_LENGTH;
 */

CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath, size_t chunkSize, int max_time)
{
    
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    
    // Get the file URL
    CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                     filePath,
                                                     kCFURLPOSIXPathStyle,
                                                     (Boolean)false);
    if (!fileURL)
        goto done;
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,(CFURLRef)fileURL);
    if (!readStream)
        goto done;
    
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed)
        goto done;
    
    // Initialize the hash object
//    CC_MD5_CTX hashObject;
//    CC_MD5_Init(&hashObject);
    
    // Make sure chunkSize is valid
    if (chunkSize == 0)
        chunkSize = kDefaultChunkSize;
    
    // Feed the data to the hash object
    int times = 0;
    bool hasMoreData = true;
    while (hasMoreData)
    {
        uint8_t buffer[chunkSize];
        CFIndex readBytesCount = CFReadStreamRead(readStream, (UInt8 *)buffer,(CFIndex)sizeof(buffer));
        
        if (readBytesCount == -1)
            break;
        if (readBytesCount == 0)
        {
            hasMoreData = false;
            continue;
        }
        //CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
        
        if (max_time != 0 && times++ > max_time)
        {
            hasMoreData = false;
            break;
        }
    }
    
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    
    // Compute the hash digest
//    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    //CC_MD5_Final(digest, &hashObject);
    
    // Abort if the read operation failed
    if (!didSucceed)
        goto done;
    
    // Compute the string result
//    char hash[2 * sizeof(digest) + 1];
//    for (size_t i = 0; i < sizeof(digest); ++i)
//    {
//        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
//    }
//    result = CFStringCreateWithCString(kCFAllocatorDefault,(const char *)hash,kCFStringEncodingUTF8);
    
done:
    if (readStream)
    {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL)
    {
        CFRelease(fileURL);
    }
    return result;
}

NSString *FileMD5HashWithPath(NSString *filePath, int dataSize)
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSData *fileData = [fileMgr contentsAtPath:filePath];
    if (fileData == nil)
        return nil;
    
    // calc hash
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    if (dataSize > 0)
    {
        CC_MD5([fileData bytes], dataSize, result);
    }
    else
    {
        CC_MD5([fileData bytes], (CC_LONG)[fileData length], result);
    }
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}


CFStringRef FileMD5HashWithData(NSData *fileData, int dataSize)
{
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    if (dataSize > 0)
    {
        CC_MD5([fileData bytes], dataSize, digest);
    }
    else
    {
        CC_MD5([fileData bytes], (CC_LONG)[fileData length], digest);
    }
    
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i)
    {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    CFStringRef result = NULL;
    result = CFStringCreateWithCString(kCFAllocatorDefault,(const char *)hash,kCFStringEncodingUTF8);

    return result;
}

