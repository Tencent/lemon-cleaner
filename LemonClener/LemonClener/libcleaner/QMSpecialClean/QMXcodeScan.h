//
//  QMXcodeScan.h
//  LemonClener
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMActionItem.h"

@interface QMXcodeScan : NSObject

@property (weak) id<QMScanDelegate> delegate;

-(void)scanDerivedDataApp:(QMActionItem *)actionItem;

-(void)scanArchives:(QMActionItem *)actionItem;

@end
