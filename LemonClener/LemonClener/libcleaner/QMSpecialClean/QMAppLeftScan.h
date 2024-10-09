//
//  QMLeftAppScan.h
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import "QMBaseScan.h"
#import "QMXMLItemDefine.h"

@class QMActionItem;
@interface QMAppLeftScan : QMBaseScan
{
    NSLock * addSoftLock;
    NSArray * m_localSoftArray;
}

- (void)scanAppLeftWithItem:(QMActionItem *)actionItem;

@end
