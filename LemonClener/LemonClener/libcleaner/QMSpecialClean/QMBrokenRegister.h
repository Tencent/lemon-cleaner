//
//  QMBrokenRegister.h
//  TestXMLParase
//

//  Copyright (c) 2013年 zero. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMActionItem.h"
#import "QMXMLItemDefine.h"

@interface QMBrokenRegister : NSObject

@property (weak) id<QMScanDelegate> delegate;

- (void)scanBrokenRegister:(QMActionItem *)actionItem;

@end
