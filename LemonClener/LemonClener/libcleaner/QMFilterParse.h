//
//  QMFilterParseManager.h
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMXMLItemDefine.h"

@class QMActionItem;
@interface QMFilterParse : NSObject
{    
    NSMutableArray * m_filterItemArray;
    
    NSDictionary * m_filerDict;
    
    QMActionItem * m_actionItem;
}
@property (assign) id<QMScanDelegate> delegate;

- (id)initFilterDict:(NSDictionary *)filerDict;

- (NSArray *)enumeratorAtFilePath:(QMActionItem *)item;

- (BOOL)filterPathWithFilters:(NSString *)path;

@end
