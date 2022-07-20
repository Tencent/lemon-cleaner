/*
 *  CmcSystem.m
 *  TestFunction
 *
 *  Created by developer on 11-1-12.
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */
//do_not_delete_this_line_for_app_store_report
#include <string.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <errno.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <IOKit/IOKitLib.h>
#include <CoreServices/CoreServices.h>
#include <netinet/in.h>
#include <SystemConfiguration/SCNetworkReachability.h>
#include "CmcSystem.h"

#define kIOPlatformExpertDevice     "IOPlatformExpertDevice"
#define kIOPlatformModelKey         "model"

// app store version
bool gLMReportIsAppStoreVersion = false;

void setLMReportAppStoreVersion(bool isAppstore){
    gLMReportIsAppStoreVersion = isAppstore;
}
bool isLMReportAppStoreVersion(void){
    return gLMReportIsAppStoreVersion;
}

// get passed time in nanoseconds
uint64_t CmcGetAbsoluteNanosec()
{
    static mach_timebase_info_data_t sTimebaseInfo = {0};
    if (sTimebaseInfo.denom == 0)
        mach_timebase_info(&sTimebaseInfo);
    if (sTimebaseInfo.denom == 0) {
        return mach_absolute_time() * sTimebaseInfo.numer;
    }
    uint64_t nanoSecond = mach_absolute_time() * sTimebaseInfo.numer / sTimebaseInfo.denom;
    return nanoSecond;
}

// get system boot time via sysctl
// return seconds, -1 indicates error
long CmcGetBootTime()
{
    // get boot time
    struct timeval boot_time;
    size_t buf_size = sizeof(boot_time);
    int boot_time_names[] = {CTL_KERN, KERN_BOOTTIME};
    
    if (sysctl(boot_time_names, 2, &boot_time, &buf_size, NULL, 0) == -1)
    {
        //McLog(MCLOG_ERR, @"[%s] get boot time fail: %d", __FUNCTION__, errno);
        return -1;
    }
    
    return boot_time.tv_sec;
}

// get machine serial, UTF8 encoding
// serial_buf       output buffer
// buf_size         size in bytes
int CmcGetMachineSerial(char *serial_buf, int buf_size)
{
    io_service_t platform;
    CFStringRef serial;
    
    serial_buf[0] = '\0';
    
    // get IOPlatformExpertDevice service object
    platform = IOServiceGetMatchingService(kIOMasterPortDefault, 
                                           IOServiceMatching(kIOPlatformExpertDevice));
    if (platform == 0)
    {
        //McLog(MCLOG_ERR, @"[%s] get platform expert device sevice fail", __FUNCTION__);
        return -1;
    }
    
    // get serial value
    serial = IORegistryEntryCreateCFProperty(platform, 
                                             CFSTR(kIOPlatformSerialNumberKey), 
                                             kCFAllocatorDefault, 
                                             kNilOptions);
    if (serial == NULL)
    {
        //McLog(MCLOG_ERR, @"[%s] get serial value fail", __FUNCTION__);
        
        IOObjectRelease(platform);
        return -1;
    }
    IOObjectRelease(platform);
    
    // output serial to buffer
    if (!CFStringGetCString(serial, serial_buf, buf_size, kCFStringEncodingUTF8))
    {
        //McLog(MCLOG_ERR, @"[%s] convert serial string fail", __FUNCTION__);
        
        CFRelease(serial);
        return -1;
    }
    
    CFRelease(serial);
    return 0;
}

// get machine model, UTF8 encoding
// model_buf        output buffer
// buf_size         size in bytes
int CmcGetMachineModel(char *model_buf, int buf_size)
{
    io_service_t platform;
    CFDataRef model;
    CFIndex modelSize;
    
    model_buf[0] = '\0';
    
    // get IOPlatformExpertDevice service object
    platform = IOServiceGetMatchingService(kIOMasterPortDefault, 
                                           IOServiceMatching(kIOPlatformExpertDevice));
    if (platform == 0)
    {
        //McLog(MCLOG_ERR, @"[%s] get platform expert device sevice fail", __FUNCTION__);
        return -1;
    }
    
    // get model value
    model = IORegistryEntryCreateCFProperty(platform, 
                                            CFSTR(kIOPlatformModelKey), 
                                            kCFAllocatorDefault, 
                                            kNilOptions);
    if (model == NULL)
    {
        //McLog(MCLOG_ERR, @"[%s] get model value fail", __FUNCTION__);
        
        IOObjectRelease(platform);
        return -1;
    }
    IOObjectRelease (platform);
    
    // check output buffer size
    modelSize = CFDataGetLength(model);
    if (modelSize > buf_size - 1)
    {
        //McLog(MCLOG_ERR, @"[%s] ouput buffer too small", __FUNCTION__);
        
        CFRelease(model);
        return -1;
    }
    // output model name to buffer
    memcpy(model_buf, CFDataGetBytePtr(model), CFDataGetLength(model));
    model_buf[CFDataGetLength(model) - 1] = '\0';
    
    CFRelease(model);
    return 0;
}

// get os version
int CmcGetOSVersion(int *pMajor, int *pMinor, int *pBugfix)
{
    Gestalt(gestaltSystemVersionMajor, pMajor);
    Gestalt(gestaltSystemVersionMinor, pMinor);
    Gestalt(gestaltSystemVersionBugFix, pBugfix);
    
    return 0;
}

// get default os language
int CmcGetDefalutLanguage(char *lang_buf, int buf_size)
{
    // read from preferences
    lang_buf[0] = '\0';
    CFArrayRef languages = CFPreferencesCopyValue(CFSTR("AppleLanguages"),
                                                  kCFPreferencesAnyApplication,
                                                  kCFPreferencesCurrentUser,
                                                  kCFPreferencesAnyHost);
    if (languages == NULL)
        return -1;
    
    // get the first member and make sure it's cfstring data
    const void *defaultLang = CFArrayGetValueAtIndex(languages, 0);
    if (defaultLang == NULL || CFGetTypeID(defaultLang) != CFStringGetTypeID())
    {
        CFRelease(languages);
        return -1;
    }
    
    if (!CFStringGetCString((CFStringRef)defaultLang, lang_buf, buf_size, kCFStringEncodingUTF8))
    {
        CFRelease(languages);
        return -1;
    }
    
    CFRelease(languages);
    return 0;
}

/*
 外部注册一个回调来返回bundle,
 因为在Agent进程中是无法获取到bundle位置的,
 而Report模块是通用的,所以通过外部回调来返回达到通用目的
 */
static void*(*fun_bundleCallback)(void) = NULL;

int CmcRegisterBundleCallBack( void*(*callback)() )
{
    fun_bundleCallback = callback;
    return 0;
}

CFBundleRef _CmcCopyMainBundle()
{
    if (fun_bundleCallback)
    {
        return (CFBundleRef)fun_bundleCallback();
    }
    
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    if (!mainBundle)
        return NULL;
    
    //获得bundle的绝对路径
    CFURLRef bundleURL = CFBundleCopyBundleURL(mainBundle);
    CFStringRef bundlePath = CFURLCopyFileSystemPath(bundleURL, kCFURLPOSIXPathStyle);
    CFRelease(bundleURL);
    
    //查找第一个.app出现的路径
    CFRange range = CFStringFind(bundlePath, CFSTR(".app"), kCFCompareCaseInsensitive);
    if (range.length == 0)
    {
        CFRelease(bundlePath);
        return NULL;
    }
    
    //如果与当前的bundle路径相同,则直接返回mainBundle
    CFRange subRange = CFRangeMake(0, range.location+range.length);
    CFStringRef subPath = CFStringCreateWithSubstring(kCFAllocatorDefault, bundlePath, subRange);
    if (CFStringCompare(bundlePath, subPath, 0) == kCFCompareEqualTo)
    {
        CFRelease(subPath);
        CFRelease(bundlePath);
        
        return (CFBundleRef)CFRetain(mainBundle);
    }
    
    //根据子路径创建URL
    CFRelease(bundlePath);
    bundleURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, subPath, kCFURLPOSIXPathStyle, true);
    if (!bundleURL)
    {
        CFRelease(subPath);
        return NULL;
    }
    
    //根据子URL创建Bundle
    CFRelease(subPath);
    mainBundle = CFBundleCreate(kCFAllocatorDefault, bundleURL);
    CFRelease(bundleURL);
    
    return mainBundle;
}

// get current application version
int CmcGetCurrentAppVersion(char *version, int version_size, char *buildver, int buildver_size)
{
    CFBundleRef mainBundle = _CmcCopyMainBundle();
    if (!mainBundle)
    {
        return 0;
    }
    
    CFTypeRef shortVersion = CFBundleGetValueForInfoDictionaryKey(mainBundle, CFSTR("CFBundleShortVersionString"));
    CFTypeRef buildVersion = CFBundleGetValueForInfoDictionaryKey(mainBundle, CFSTR("CFBundleVersion"));
    
    if (shortVersion != NULL && CFGetTypeID(shortVersion) == CFStringGetTypeID())
    {
        CFStringGetCString((CFStringRef)shortVersion, version, version_size - 10, kCFStringEncodingUTF8);
        // 为了跟PC端的版本保持一致
        // 2.1.34 -> 2.1.34.0
        // Lemon 版本将最后一位版本号改为1
        if (isLMReportAppStoreVersion()) {
            strcat(version, ".2");
        } else {
            strcat(version, ".1");
        }
    }
    
    if (buildVersion != NULL && CFGetTypeID(buildVersion) == CFStringGetTypeID())
    {
        CFStringGetCString((CFStringRef)buildVersion, buildver, buildver_size, kCFStringEncodingUTF8);
    }
    CFRelease(mainBundle);
    return 0;
}

// convert version
uint64_t CmcConvertAppVersion(char *version)
{
    uint64_t Ver1 = atoi(version);
    char *nextVer = strchr(version, '.');
    if (nextVer == NULL)
        return (Ver1<<48);
    
    nextVer++;
    uint64_t Ver2 = atoi(nextVer);
    nextVer = strchr(nextVer, '.');
    if (nextVer == NULL)
        return ((Ver1<<48) + (Ver2<<32));
    
    nextVer++;
    uint64_t Ver3 = atoi(nextVer);
    nextVer = strchr(nextVer, '.');
    if (nextVer == NULL)
        return ((Ver1<<48) + (Ver2<<32) + (Ver3<<16));
    
    nextVer++;
    uint64_t Ver4 = atoi(nextVer);
    
    return ((Ver1<<48) + (Ver2<<32) + (Ver3<<16) + Ver4);
}

// if internet is available
bool CmcInternetAvailable()
{
    static bool available = true;
    static CFTimeInterval lastchecktime = 0;
    CFTimeInterval curtime = CFAbsoluteTimeGetCurrent();
    
    // 网络通畅的情况下也是每隔 1 分钟检查一下
    if (!available || curtime - lastchecktime > 60)
    {
        available = true;
        lastchecktime = curtime;
        
        struct sockaddr zeroAddress;
        bzero(&zeroAddress, sizeof(zeroAddress));
        zeroAddress.sa_len = sizeof(zeroAddress);
        zeroAddress.sa_family = AF_INET;
        
        //SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, "www.qq.com");
        SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(NULL, (const struct sockaddr*)&zeroAddress);
        if (reachabilityRef != NULL)
        {
            SCNetworkReachabilityFlags flags = 0;
            
            if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
            {
                bool isReachable = ((flags & kSCNetworkFlagsReachable) != 0);
                bool connectionRequired = ((flags & kSCNetworkFlagsConnectionRequired) != 0);
                if (!isReachable || connectionRequired)
                    available = false;
            }
            
            CFRelease(reachabilityRef);
        }
    }
    
    return available;
}

int CmcGetSupplyID(unsigned int *sup_id)
{
    CFBundleRef mainBundle = _CmcCopyMainBundle();
    if (!mainBundle)
    {
        return 0;
    }
    
    CFTypeRef supportID = CFBundleGetValueForInfoDictionaryKey(mainBundle, CFSTR("SupplyID"));
    if (supportID != NULL && CFGetTypeID(supportID) == CFStringGetTypeID())
    {
        *sup_id = CFStringGetIntValue(supportID);
    }
    CFRelease(mainBundle);
    
    return 0;
}
