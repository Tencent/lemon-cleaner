//
//  QMLeftAppScan.h
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMXMLItemDefine.h"

@class QMActionItem;
@interface QMAppLeftScan : NSObject
{
    NSLock * addSoftLock;
    NSArray * m_localSoftArray;
}
@property (weak) id<QMScanDelegate> delegate;

- (void)scanAppLeftWithItem:(QMActionItem *)actionItem;

@end
