//
//  QMMailScan.h
//  LemonClener
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QMActionItem;

@protocol QMMailDelegate <NSObject>

- (void)mailScanProcess:(double)process path:(NSString *) path pathResult:(NSArray *)paths actionItem:(QMActionItem *)actionItem;

@end


@interface QMMailUtil : NSObject

// 路径 ~/Library/Containers/com.apple.mail/Data/Library/Mail Downloads/
+(NSArray *) getMailDownloadFilePathArray:(NSString *) mailDownloadPath;

// 路径 "~/Library/Mail"
+(NSArray *) getMailAttachMentPathArray:(NSString *)mailPath actionItem:(QMActionItem *)actionItem withDelegate:(id<QMMailDelegate>) mailDelegate;

@end
