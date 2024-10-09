//
//  QMSoftScan.h
//  LemonClener
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "QMBaseScan.h"
#import "QMActionItem.h"

@interface QMSoftScan : QMBaseScan

//扫描sketch的缓存大小
-(void)scanSketchFileCache:(QMActionItem *)actionItem;

//扫描自适配软件缓存
-(void)scanAdaptSoftCache:(QMActionItem *)actionItem;

//扫描剩余的缓存的大小
-(void)scanLeftAppCache:(QMActionItem *)actionItem;

//扫描剩余的日志大小
-(void)scanLeftAppLog:(QMActionItem *)actionItem;


@end
