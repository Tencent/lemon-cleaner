//
//  McKextMgr.m
//  McFireWallCtl
//

//  Copyright (c) 2011 Magican Software Ltd. All rights reserved.
//

#import "McKextMgr.h"
#import <IOKit/kext/KextManager.h>
#import "OSKextError.h"

int stopKextPath(const char *kextPath)
{
    NSString *unloadCmd = [NSString stringWithFormat:@"kextunload %s",kextPath];
    return system([unloadCmd UTF8String]);
}

int stopKext(const char *kextBundle)
{
    //#include <IOKit/kext/OSKextPrivate.h>
    //OSKextUnloadKextWithIdentifier

    NSString *unloadCmd = [NSString stringWithFormat:@"kextunload -b %s",kextBundle];
    return system([unloadCmd UTF8String]);
    
/* only for 10.7
    OSReturn ret = kOSKextReturnStartStopError;
    NSString *bundleId = [NSString stringWithUTF8String:kextBundle];
    
    //NSLog(@"kOSKextReturnInternalError: %x", kOSKextReturnInternalError);
    
    while (ret != kOSReturnSuccess)
    {
        NSLog(@"ready to unload kext");
        ret = KextManagerUnloadKextWithIdentifier((CFStringRef)bundleId);
        if (ret == kOSReturnSuccess)
        {
            NSLog(@"[OK] kext unload OK");
            return 0;
        }
        
        if (ret != kOSKextReturnStartStopError) 
        {
            NSLog(@"[ERR] kext unload fail");
            return -1;
        }
        
        usleep(1000 * 2000);
    }
    
    return 0;
*/
}

int startKext(const char *origKextPath)
{    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    // first to copy kext to tmp
    NSString *kextPath = [NSString stringWithUTF8String:origKextPath];
    NSString *destPath = [@"/tmp" stringByAppendingPathComponent:[kextPath lastPathComponent]];
    
    [fileMgr removeItemAtPath:destPath error:NULL];
    if (![fileMgr copyItemAtPath:kextPath toPath:destPath error:NULL])
    {
        NSLog(@"[ERR] copy kext to temp folder fail");
        return -1;
    }
    
    // change file to root/wheel
    NSArray *fileParts = [fileMgr subpathsAtPath:destPath];
    for (NSString *filePart in fileParts)
    {
        NSString *filePath = [destPath stringByAppendingPathComponent:filePart];
        //NSLog(@"chown file: %@", filePath);
        chown([filePath fileSystemRepresentation], 0, 0);
    }
    chown([destPath fileSystemRepresentation], 0, 0);
    
    CFURLRef kextURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                     (CFStringRef)destPath,
                                                     kCFURLPOSIXPathStyle,
                                                     NO);
    if (kextURL == NULL)
    {
        NSLog(@"[ERR] convert to CFURL fail");
        return -1;
    }
    
    OSReturn ret = KextManagerLoadKextWithURL(kextURL, NULL);
    // another version is running
    if (ret == kOSKextReturnLoadedVersionDiffers)
    {
        // should stop first
        stopKextPath([destPath fileSystemRepresentation]);
        ret = KextManagerLoadKextWithURL(kextURL, NULL);
    }
    
    CFRelease(kextURL);
    if (ret == kOSReturnSuccess)
    {
        return 0;
    }
    
    NSLog(@"[ERR] load kext fail: %d", ret);
    return -1;
}
