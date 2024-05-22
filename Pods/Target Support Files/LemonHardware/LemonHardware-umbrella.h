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

#import "LemonHardwareWindowController.h"
#import "DiskModel.h"
#import "BaseModel.h"
#import "MachineModel.h"

FOUNDATION_EXPORT double LemonHardwareVersionNumber;
FOUNDATION_EXPORT const unsigned char LemonHardwareVersionString[];

