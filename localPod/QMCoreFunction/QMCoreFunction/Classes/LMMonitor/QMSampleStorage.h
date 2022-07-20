//
//  QMSampleStorage.h
//  QQMacMgrMonitor
//
//  
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMSampleStorage : NSObject
/// array of McProcessInfoData
/// @see McProcessInfoData
@property (readonly, strong) NSArray *originProcessInfoArray;
@property (readonly, strong) NSArray *processInfoArray;
@property (nonatomic, assign) BOOL isProcessPortStat;

- (void)sample;
- (void)setProcessPortStat:(BOOL)isStat;
@end
