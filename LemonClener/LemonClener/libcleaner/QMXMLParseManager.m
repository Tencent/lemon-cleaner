//
//  QMXMLParseManager.m
//  libcleaner
//

//  Copyright (c) 2014年 Magican Software Ltd. All rights reserved.
//

#import "QMXMLParseManager.h"
#import "QMXMLParse.h"
#import "QMScanCategory.h"
#import "QMCleanUtils.h"
#import "QMDataConst.h"
#import <QMCoreFunction/McCoreFunction.h>
#import <QMCoreFunction/LanguageHelper.h>

NSString *kLMCleanKnowLedge = @"~/Library/Application Support/com.tencent.lemon/Knowledge/2";

@implementation QMXMLParseManager

- (id)init
{
    if (self = [super init])
    {
        m_filterDict = [[NSMutableDictionary alloc] init];
        m_cautionItemDict = [[NSMutableDictionary alloc] init];
        m_categoryDict = [[NSMutableDictionary alloc] init];
        
        if ([McCoreFunction isAppStoreVersion]) {
            if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
                kLMCleanKnowLedge = [@"~/Library/Application Support/com.tencent.LemonLite/KnowledgeCh/2" stringByExpandingTildeInPath];
            }else{
                kLMCleanKnowLedge = [@"~/Library/Application Support/com.tencent.LemonLite/KnowledgeEn/2" stringByExpandingTildeInPath];
            }
        } else {
            if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
                kLMCleanKnowLedge = [@"~/Library/Application Support/com.tencent.lemon/KnowledgeCh/2" stringByExpandingTildeInPath];
            }else{
                kLMCleanKnowLedge = [@"~/Library/Application Support/com.tencent.lemon/KnowledgeEn/2" stringByExpandingTildeInPath];
            }
        }
    }
    return self;
}

+ (QMXMLParseManager *)sharedManager
{
    static QMXMLParseManager * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[QMXMLParseManager alloc] init];
        [instance parseXMLVersion];
    });
    return instance;
}

- (void)setParseEndNO{
    m_paseEnd = NO;
}

- (BOOL)checkWarnItemAtPath:(QMResultItem *)resultItem bundleID:(NSString **)bundle appName:(NSString **)name
{
    if (!resultItem)
        return NO;
    if (resultItem.cautionID)
    {
        NSString * cautionID = resultItem.cautionID;
        NSArray * cautionArray = [cautionID componentsSeparatedByString:@"|"];
        for (NSString * strID in cautionArray)
        {
            QMCautionItem * cautionItem = [m_cautionItemDict objectForKey:strID];
            if ([cautionItem fliterCleanItem:[resultItem path] bundleID:bundle appName:name])
                return YES;
        }
    }
    return NO;
}
- (void)removeLastScanResult
{
    NSArray * array = [m_categoryDict allValues];
    for (QMCategoryItem * categoryItem in array)
    {
        [categoryItem removeAllResultItem];
        [categoryItem resetItemScanState];
    }
    // 移除清理缓存
    [QMCleanUtils cleanScanCacheResult];
}

- (NSDictionary *)filterItemDict
{
    return m_filterDict;
}
- (NSDictionary *)categoryItemDict
{
    return m_categoryDict;
}
- (NSDictionary *)cautionItemDict
{
    return m_cautionItemDict;
}

#pragma mark-
#pragma mark 解析xml

// 解析xml版本
- (void)parseXMLVersion
{
    QMXMLParse * xmlParse = [[QMXMLParse alloc] init];
    NSString * supportCleanXML = [kLMCleanKnowLedge stringByExpandingTildeInPath];
    NSString * path = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:supportCleanXML])
    {
        path = supportCleanXML;
    }
    else
    {
        if ([McCoreFunction isAppStoreVersion]) {
            path = [[NSBundle bundleForClass:[self class]] pathForResource:@"garbage_appstore" ofType:@"xml"];
        } else {
            path = [[NSBundle bundleForClass:[self class]] pathForResource:@"garbage1" ofType:@"xml"];
        }
    }
}

// 解析xml
- (BOOL)startParaseXML:(BOOL)refresh
{
    if (!refresh && m_paseEnd)
        return YES;
    
    NSString * supportCleanXML = [kLMCleanKnowLedge stringByExpandingTildeInPath];
    NSString * path = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:supportCleanXML])
    {
        NSLog(@"lm cleaner use support datapath %hhd", [[NSFileManager defaultManager] fileExistsAtPath:supportCleanXML]);
        path = supportCleanXML;
    }
    else
    {
        NSLog(@"lm cleaner use bundle datapath");
        if ([McCoreFunction isAppStoreVersion]) {
            path = [[NSBundle bundleForClass:[self class]] pathForResource:@"garbage_appstore" ofType:@"xml"];
        } else {
            path = [[NSBundle bundleForClass:[self class]] pathForResource:@"garbage1" ofType:@"xml"];
        }
    }
    // 解析xml
    QMXMLParse * xmlParse = [[QMXMLParse alloc] init];
    [xmlParse setDelegagte:(id<QMXMLParseDelegate>)self];
    BOOL retValue = [xmlParse parseXMLWithData:path];
    return retValue;
}

#pragma mark-
#pragma mark XML解析委托

- (void)xmlParseErro:(NSError *)erro
{
    //[delegate xmlParseErro:erro];
    // 移除当前解析失败文件
    NSString * path = [kLMCleanKnowLedge stringByExpandingTildeInPath];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)xmlParseDidStart
{
    m_paseEnd = NO;
    [m_filterDict removeAllObjects];
    [m_categoryDict removeAllObjects];
    [m_cautionItemDict removeAllObjects];
}

- (void)xmlParseDidEndCaution:(QMCautionItem *)item
{
    @try{
       [m_cautionItemDict setObject:item forKey:item.cautionID];
    }@catch (NSException *exception) {
        NSLog(@"xmlParseDidEndCaution exception = %@", exception);
    }
    
}
- (void)xmlParseDidEndFilter:(QMFilterItem *)item
{
    @try{
        [m_filterDict setObject:item forKey:item.filterID];
    }@catch (NSException *exception) {
        NSLog(@"xmlParseDidEndFilter exception = %@", exception);
    }
}
- (void)xmlParseDidEndCategory:(QMCategoryItem *)item
{
    @try{
        [m_categoryDict setObject:item forKey:item.categoryID];
    }@catch (NSException *exception) {
        NSLog(@"xmlParseDidEndCategory exception = %@", exception);
    }
    
}

- (void)xmlParseDidEnd
{
    m_paseEnd = YES;
    
    // 解析完毕
//    [[NSNotificationCenter defaultCenter] postNotificationName:kQMCleanXMLItemParseEnd
//                                                        object:m_categoryDict];
}


- (NSString *)titleWithCategoryID:(NSString *)categoryID
{
    QMCategoryItem * item = [m_categoryDict objectForKey:categoryID];
    return item.title;
}

@end
