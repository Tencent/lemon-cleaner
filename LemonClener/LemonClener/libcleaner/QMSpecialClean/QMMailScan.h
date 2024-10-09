//
//  QMMailScan.h
//  LemonClener
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "QMBaseScan.h"
#import "QMXMLItemDefine.h"
#import "QMActionItem.h"
#import "QMMailUtil.h"


@interface QMMailScan : QMBaseScan <QMMailDelegate>

- (void)scanMailAttachments:(QMActionItem *)actionItem;

@end
