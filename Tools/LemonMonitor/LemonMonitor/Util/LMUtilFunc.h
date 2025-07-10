//
//  LMUtilFunc.h
//  LemonMonitor
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LMReadDirection) {
    LMReadFromHead,
    LMReadFromTail
};

#ifdef __cplusplus
extern "C" {
#endif

NSString *monitorLogPath(void);
void redirctNSlog(void);
void trackExceptionLogAndCleanIfNeeded(void); // 追踪异常并且清理过大的日志

#ifdef __cplusplus
}
#endif


