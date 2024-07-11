#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "McBatteryInfo.h"
#import "McCpuInfo.h"
#import "McDiskInfo.h"
#import "McGpuInfo.h"
#import "McLogUtil.h"
#import "McMemoryInfo.h"
#import "McNetInfo.h"
#import "McSystemInfo.h"

FOUNDATION_EXPORT double LemonStatVersionNumber;
FOUNDATION_EXPORT const unsigned char LemonStatVersionString[];

