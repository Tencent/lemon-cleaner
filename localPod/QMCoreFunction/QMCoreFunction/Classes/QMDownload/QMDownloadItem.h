//
//  QMDownloadItem.h
//  QMDownload
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

enum
{
    QMDownloadStatusWait = 0,
    QMDownloadStatusDoing,
    QMDownloadStatusFaild,
    QMDownloadStatusFinish,
    QMDownloadStatusPaused,
    QMDownloadStatusCancel
};
typedef NSInteger QMDownloadStatus;

extern NSString *QMDownloadItemStatusNotification;

@interface QMDownloadItem : NSObject

//required
@property (nonatomic, strong) NSURL *url;

//optional
@property (nonatomic, strong) id context;
@property (nonatomic, assign) uint64_t fileSize;
@property (nonatomic, strong) NSString *hash_md5;
@property (nonatomic, strong) NSString *hash_sha1;

- (NSString *)fileName;
- (NSString *)filePath;
- (QMDownloadStatus)status;
- (double)progress;
- (double)speed;
- (double)averageSpeed;

- (NSTimeInterval)totalSpendTime;
- (NSTimeInterval)latestSpendTime;

@end
