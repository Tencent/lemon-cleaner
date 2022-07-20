//
//  QMWechatScan.h
//  LemonClener
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMActionItem.h"

@interface QMWechatScan : NSObject

@property (weak) id<QMScanDelegate> delegate;

//扫描头像图片
-(void)scanWechatAvatar:(QMActionItem *)actionItem;

//扫描聊天图片
-(void)scanWechatImage:(QMActionItem *)actionItem;

//扫描聊天图片 90天前
-(void)scanWechatImage90DayAgo:(QMActionItem *)actionItem;

//扫描接收的文件
-(void)scanWechatFile:(QMActionItem *)actionItem;

//扫描接收到的视频
-(void)scanWechatVideo:(QMActionItem *)actionItem;

//扫描接收到的音频
-(void)scanWechatAudio:(QMActionItem *)actionItem;

@end
