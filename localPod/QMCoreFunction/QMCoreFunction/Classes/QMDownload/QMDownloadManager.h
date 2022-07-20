//
//  QMDownloadManager.h
//  QMDownload
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QMCoreFunction/QMDownloadItem.h>

extern NSString *QMDownloadListChangedNotification;

@interface QMDownloadManager : NSObject
@property (nonatomic, strong) NSString *downloadDirectory;
@property (nonatomic, assign) NSInteger concurrentCount;

+ (id)sharedManager;

- (NSArray *)downloadItems;
- (QMDownloadItem *)itemWithContext:(id)context;

- (void)startDownload:(QMDownloadItem *)item;
- (void)puseDownload:(QMDownloadItem *)item;
- (void)stopDownload:(QMDownloadItem *)item;

@end
