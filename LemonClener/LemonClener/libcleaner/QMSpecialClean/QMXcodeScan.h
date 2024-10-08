//
//  QMXcodeScan.h
//  LemonClener
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "QMBaseScan.h"
#import "QMActionItem.h"

@interface QMXcodeScan : QMBaseScan

-(void)scanDerivedDataApp:(QMActionItem *)actionItem;

-(void)scanArchives:(QMActionItem *)actionItem;

@end
