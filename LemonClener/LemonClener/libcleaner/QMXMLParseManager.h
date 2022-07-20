//
//  QMXMLParseManager.h
//  libcleaner
//

//  Copyright (c) 2014年 Magican Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMResultItem.h"

#define kQMCleanXMLItemParseEnd     @"QMCleanXMLItemParseEnd"

@interface QMXMLParseManager : NSObject
{
    NSMutableDictionary * m_filterDict;
    NSMutableDictionary * m_categoryDict;
    NSMutableDictionary * m_cautionItemDict;
    
    BOOL m_paseEnd;
}

+ (QMXMLParseManager *)sharedManager;

- (BOOL)startParaseXML:(BOOL)refresh;

- (void)setParseEndNO;

- (void)removeLastScanResult;
- (BOOL)checkWarnItemAtPath:(QMResultItem *)resultItem bundleID:(NSString **)bundle appName:(NSString **)name;

- (NSDictionary *)filterItemDict;
- (NSDictionary *)categoryItemDict;
- (NSDictionary *)cautionItemDict;

// 通过id获取title
- (NSString *)titleWithCategoryID:(NSString *)categoryID;

@end
