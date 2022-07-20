//
//  QMDirectoryScan.h
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMXMLItemDefine.h"

@class QMActionItem;
@interface QMDirectoryScan : NSObject
{
}
@property (weak) id<QMScanDelegate> delegate;

- (void)scanActionWithItem:(QMActionItem *)actionItem;

@end
