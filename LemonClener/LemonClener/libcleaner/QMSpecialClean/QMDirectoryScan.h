//
//  QMDirectoryScan.h
//  QMCleanDemo
//

//

#import "QMBaseScan.h"
#import "QMXMLItemDefine.h"

@class QMActionItem;
@interface QMDirectoryScan : QMBaseScan
{
}

- (void)scanActionWithItem:(QMActionItem *)actionItem;

@end
