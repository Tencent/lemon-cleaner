//
//  QMFullDiskAccessManager.h
//  QMCoreFunction
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, QMFullDiskAuthorationStatus) {
    QMFullDiskAuthorationStatusNotDetermined,
    QMFullDiskAuthorationStatusDenied,
    QMFullDiskAuthorationStatusAuthorized,
};

@interface QMFullDiskAccessManager : NSObject

+(QMFullDiskAuthorationStatus)getFullDiskAuthorationStatus;

+(QMFullDiskAuthorationStatus)getFullDiskAuthorationStatusWithoutLog; // 无日志版本

+(void)openFullDiskAuthPrefreence;

@end
