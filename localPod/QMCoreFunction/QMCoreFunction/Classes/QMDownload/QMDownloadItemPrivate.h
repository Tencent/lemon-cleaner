//
//  QMDownloadItemPrivate.h
//  QMDownload
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMDownloadItem.h"

@interface QMDownloadItem ()

@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) QMDownloadStatus status;
@property (nonatomic, assign) double progress;
@property (nonatomic, assign) double speed;
@property (nonatomic, assign) double averageSpeed;
@property (nonatomic, assign) NSTimeInterval totalSpendTime;
@property (nonatomic, assign) NSTimeInterval latestSpendTime;

@property (nonatomic, strong) NSString *downloadInfoPath;

- (void)postNotification;

@end
