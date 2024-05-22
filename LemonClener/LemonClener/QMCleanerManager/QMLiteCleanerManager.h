//
//  QMLiteCleanerManager.h
//  QMCleaner
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMCleanerDefine.h"

@protocol QMLiteCleanerDelegate <NSObject>

- (void)scanProgressInfo:(float)value scanPath:(NSString *)path;
- (void)scanDidEnd;

- (void)cleanProgressInfo:(float)value;
- (void)cleanDidEnd:(UInt64)size;

@end

@interface QMLiteCleanerManager : NSObject
{
    NSMutableArray * _resultItemArray;
}
@property (nonatomic, weak) id<QMLiteCleanerDelegate> delegate;
@property (nonatomic, assign) BOOL needRefresh;
@property (nonatomic, assign) BOOL isStopScan;

+ (QMLiteCleanerManager *)sharedManger;

- (void)startScan;    // 同步方法, 需在子线程调用.
- (void)stopScan;

- (void)startCleanWithActionSource:(QMCleanerActionSource)source;   // 同步方法, 需在子线程调用.

- (UInt64)resultSize;

@end
