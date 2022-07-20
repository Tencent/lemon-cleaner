//
//  LMKextManager.m
//  LemonDaemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMKextManager.h"
#import <IOKit/kext/KextManager.h>
#import "CmcFileAction.h"

typedef struct _kextInfo {
    char path[1024];
    char bundleId[1024];
} kextInfo;

@implementation LMKextManager


//   dict 类似这种
//   bundleId1:  dict1{"OSBundlePath":path,  ....}
//   bundleId2:  dict2
void handle_kext_dict_iteration_get_path(const void *key, const void *value, void *context) {

    if (context == NULL) {
        return;
    }

    kextInfo *info = context;

    // OSBundlePath - CFString (this is merely a hint stored in the kernel; the kext is not guaranteed to be at this path)
    CFStringRef bundle_path_key = CFStringCreateWithCString(kCFAllocatorDefault, "OSBundlePath", kCFStringEncodingUTF8);
    const char *bundle_id_cstring = CFStringGetCStringPtr(key, kCFStringEncodingUTF8);
    const char *bundle_path_cstring = CFStringGetCStringPtr(CFDictionaryGetValue(value, bundle_path_key), kCFStringEncodingUTF8);
    if (bundle_path_cstring == NULL) {
        return;
    }
    int cmpResult = strcmp(bundle_path_cstring, info->path);
    if (cmpResult == 0) {
        strncpy(info->bundleId, bundle_id_cstring, sizeof(info->bundleId) - 1);
    }
}

void handle_kext_dict_iteration_get_BundleId(const void *key, const void *value, void *context) {

    if (context == NULL) {
        return;
    }

    kextInfo *info = context;

    // OSBundlePath - CFString (this is merely a hint stored in the kernel; the kext is not guaranteed to be at this path)
    CFStringRef bundle_path_key = CFStringCreateWithCString(kCFAllocatorDefault, "OSBundlePath", kCFStringEncodingUTF8);
    const char *bundle_id_cstring = CFStringGetCStringPtr(key, kCFStringEncodingUTF8);
    const char *bundle_path_cstring = CFStringGetCStringPtr(CFDictionaryGetValue(value, bundle_path_key), kCFStringEncodingUTF8);
    if (bundle_id_cstring == NULL) {
        return;
    }
    int cmpResult = strcmp(bundle_id_cstring, info->bundleId);
    if (cmpResult == 0 && bundle_path_cstring != NULL) {
        strncpy(info->path, bundle_path_cstring, sizeof(info->path) - 1);
    }
}

NSString *getKextBundleIdByPath(NSString *path) {

    if (!path || path.length < 1) {
        return nil;
    }

    const char *cPath = [path UTF8String];
    kextInfo *pInfo = malloc(sizeof(kextInfo));
    bzero(pInfo, sizeof(kextInfo));
    strncpy(pInfo->path, cPath, sizeof(pInfo->path) - 1);

    CFDictionaryRef loaded_kexts = KextManagerCopyLoadedKextInfo(NULL, NULL);
    CFDictionaryApplyFunction(loaded_kexts, handle_kext_dict_iteration_get_path, pInfo);

    NSString *bundleId = [[NSString alloc] initWithUTF8String:pInfo->bundleId];
    NSLog(@"%s get bundleId:%@ by path :%@", __FUNCTION__, bundleId, path);

    free(pInfo);
    return bundleId;
}

NSString *getKextPathByBundleId(NSString *bundleId) {
    if (!bundleId || bundleId.length < 1) {
        return nil;
    }

    const char *cBundleId = [bundleId UTF8String];
    kextInfo *pInfo = malloc(sizeof(kextInfo));
    bzero(pInfo, sizeof(kextInfo));
    strncpy(pInfo->bundleId, cBundleId, sizeof(pInfo->bundleId) - 1);

    CFDictionaryRef loaded_kexts = KextManagerCopyLoadedKextInfo(NULL, NULL);
    CFDictionaryApplyFunction(loaded_kexts, handle_kext_dict_iteration_get_BundleId, pInfo);

    NSString *path = [[NSString alloc] initWithUTF8String:pInfo->path];
    NSLog(@"%s get path:[%@] ,by bundleId :[%@]", __FUNCTION__, path, bundleId);
    free(pInfo);
    return path;
}

+ (BOOL)getKextRunningStatusByBundleId:(NSString *)bundleId {
    BOOL isRunning = NO;
    CFStringRef kext_ids[1];
    kext_ids[0] = (__bridge CFStringRef) bundleId;;
    CFArrayRef kext_id_query = CFArrayCreate(NULL, (const void **) kext_ids, 1,
            &kCFTypeArrayCallBacks);
    CFDictionaryRef kext_infos =
            KextManagerCopyLoadedKextInfo(kext_id_query, NULL);
    CFRelease(kext_id_query);
    CFDictionaryRef cf_driver_info = NULL;
    if (CFDictionaryGetValueIfPresent(kext_infos, (__bridge CFStringRef) bundleId,
            (const void **) &cf_driver_info)) {
        bool started = CFBooleanGetValue((CFBooleanRef) CFDictionaryGetValue(
                cf_driver_info, CFSTR("OSBundleStarted")));
        if (!started) {
            NSLog(@"kext is installed but no running");
        } else {
            NSLog(@"kext is installed and running");
            isRunning = YES;
        }
    } else {
        NSLog(@"kext is not installed");
    }
    CFRelease(kext_infos);

    return isRunning;
}

+ (BOOL)unloadKextWithBundleId:(NSString *)bundleId {
    CFStringRef km_identifier = CFStringCreateWithCString(kCFAllocatorDefault, [bundleId UTF8String],
            kCFStringEncodingUTF8);
    OSReturn status = KextManagerUnloadKextWithIdentifier(km_identifier);
    if (status == kOSReturnSuccess) {
        NSLog(@"unload %@ success", bundleId);
        return YES;
    } else {
        NSLog(@"unload %@ failed status = %d", bundleId, status);
        return NO;
    }
}

+ (NSInteger)uninstallKextWithPath:(mc_pipe_cmd *)pcmd {

    op_uninstall_kext *kext_param = (op_uninstall_kext *) (pcmd + 1);
    NSString *kextPath = [NSString stringWithUTF8String:kext_param->szKext];
    NSLog(@"uninstallKext kext path is %@", kextPath);


    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:kextPath];
    if (!isExist) {
        NSLog(@"stop uninstall kext because path %@ is unValid", kextPath);
        return -2;
    }

    NSString *bundleId = getKextBundleIdByPath(kextPath);
    BOOL unloadFlag = TRUE;
    if (!bundleId || bundleId.length < 1) {
        NSLog(@"no need unload because bundle id is %@", bundleId);
    } else {
        BOOL isRunning = [self getKextRunningStatusByBundleId:bundleId];
        if (isRunning) {
            unloadFlag = [self unloadKextWithBundleId:bundleId];
        }
    }

    if (!unloadFlag) {
        NSLog(@"%s stop remove kext, because unload failed", __FUNCTION__);
        return -1;
    }

    int rmResult = filesRemove((char *) [kextPath UTF8String], 1);
    NSLog(@"Removing kernel extension path :[%@], success %@", kextPath, rmResult >= 0 ? @"YES" : @"NO");
    return rmResult;

}


// kextstat -l -b bundleId #查看 bundleId 是否 Running
// kextunload  -b bundleId #卸载内核
// kextfind -b bundleId    #获取 bundleId 对应的 kext 的 path
+ (NSInteger)uninstallKextWithBundleId:(mc_pipe_cmd *)pcmd {
    op_uninstall_kext *kext_param = (op_uninstall_kext *) (pcmd + 1);
    NSString *bundleId = [NSString stringWithUTF8String:kext_param->szKext];
    NSLog(@"uninstallKext kext bundleId is %@", bundleId);

    if (!bundleId || bundleId.length < 1) {
        return -3;
    }
    
    NSString *path = getKextPathByBundleId(bundleId); //优先获取 path,防止unload 后无法正常获取 path

    BOOL isRunning = [self getKextRunningStatusByBundleId:bundleId];
    BOOL unloadFlag = TRUE;
    if (isRunning) {
        unloadFlag = [self unloadKextWithBundleId:bundleId];
    }

    if (!unloadFlag) {
        NSLog(@"%s stop remove kext, because unload failed", __FUNCTION__);
        return -1;
    }
    if (!path || path.length < 1) {
        NSLog(@"%s can't get path by bundleId:%@, stop remove", __FUNCTION__, bundleId);
        return -4;
    }

    int rmResult = filesRemove((char *) [path UTF8String], 1);
    NSLog(@"Removing kernel extension path :[%@], success %@", path, rmResult >= 0 ? @"YES" : @"NO");

    return rmResult;
}
@end
