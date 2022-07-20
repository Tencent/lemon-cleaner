//
//  QMDownloadTask.h
//  QMDownload
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMDownloadItem.h"

@class QMDownloadTask;
@protocol QMDownloadTaskDelegate <NSObject>
@required
- (void)downloadUpdate:(QMDownloadTask *)task;
@end

@interface QMDownloadTask : NSOperation
@property (nonatomic, readonly) QMDownloadItem *item;
@property (nonatomic, assign) id<QMDownloadTaskDelegate> delegate;
@property (nonatomic, copy) NSString *downloadDirectory;

- (id)initWithItem:(QMDownloadItem *)item;

@end
