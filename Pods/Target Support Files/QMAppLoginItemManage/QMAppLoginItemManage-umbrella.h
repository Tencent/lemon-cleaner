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

#import "QMAppLaunchItem.h"
#import "QMAppLoginItem.h"
#import "QMBaseLoginItem.h"
#import "QMSystemLoginItem.h"
#import "QMAppLoginItemManage.h"
#import "QMLocalApp.h"
#import "QMLocalAppHelper.h"
#import "QMLoginItemManager.h"

FOUNDATION_EXPORT double QMAppLoginItemManageVersionNumber;
FOUNDATION_EXPORT const unsigned char QMAppLoginItemManageVersionString[];

