//
//  QMBaseScan.m
//  LemonClener
//
//  Copyright © 2023 Tencent. All rights reserved.
//

#import "QMBaseScan.h"
#import "QMXMLItemDefine.h"

@implementation QMBaseScan

- (void)scanActionCompleted:(QMActionItem *)actionItem {
    if ([self.delegate respondsToSelector:@selector(scanActionCompleted:)]) {
        [self.delegate scanActionCompleted:actionItem];
    }
}

@end

