//
//  QMXMLParse.h
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMCategoryItem.h"
#import "QMFilterItem.h"
#import "QMCautionItem.h"

@protocol QMXMLParseDelegate<NSObject>

- (void)xmlParseErro:(NSError *)erro;

- (void)xmlParseDidStart;

- (void)xmlParseDidEndFilter:(QMFilterItem *)item;
- (void)xmlParseDidEndCaution:(QMCautionItem *)item;
- (void)xmlParseDidEndCategory:(QMCategoryItem *)item;

- (void)xmlParseDidEnd;

@end


@interface QMXMLParse : NSObject<NSXMLParserDelegate>
{
    NSString * m_curSysVersion;
    
    NSMutableArray * m_parseKeyArray;
    //当前用户已安装app 列表 bundleid
    NSMutableDictionary *m_installBundleIdDic;
    
    QMFilterItem * m_curFilterItem;
    QMCautionItem * m_curCautionItem;
    QMCategoryItem * m_curCategoryItem;
    QMCategorySubItem * m_curCategorySubItem;
    QMActionItem * m_curActionItem;
    // 用于不满足任何action情况下的显示
    NSString * m_notAddActionID;
    
    BOOL m_onlyVersion;
}
@property (nonatomic, weak) id<QMXMLParseDelegate> delegagte;
@property (nonatomic, retain) NSString * version;

- (BOOL)parseXMLWithData:(NSString *)dataPath;
- (NSString *)parseXMLVersion:(NSString *)path;

@end
