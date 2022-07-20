//
//  QMMailScan.h
//  LemonClener
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMXMLItemDefine.h"
#import "QMActionItem.h"
#import "QMMailUtil.h"


@interface QMMailScan : NSObject<QMMailDelegate>

@property (weak) id<QMScanDelegate> delegate;

- (void)scanMailAttachments:(QMActionItem *)actionItem;

@end
