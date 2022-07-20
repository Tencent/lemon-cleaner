//
//  QMXMLParse.m
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import "QMXMLParse.h"
#import "QMXMLItemDefine.h"
#import "QMActionItem.h"
#import "QMCoreFunction/QMSigFileHandler.h"
#import "InstallAppHelper.h"
#import "QMItemCreateHelper.h"
#import <QMCoreFunction/McCoreFunction.h>
#import <QMCoreFunction/LanguageHelper.h>

#define kSystemVersion   @"/System/Library/CoreServices/SystemVersion.plist"

@implementation QMXMLParse
@synthesize delegagte;

- (id)init
{
    if (self = [super init])
    {
        // 获取当前系统版本
        NSDictionary * dict = [NSDictionary dictionaryWithContentsOfFile:kSystemVersion];
        m_curSysVersion = [dict objectForKey:@"ProductVersion"];
        m_parseKeyArray = [[NSMutableArray alloc] init];
        m_installBundleIdDic = [InstallAppHelper getInstallBundleIds];
    }
    return self;
}

- (BOOL)parseXMLWithData:(NSString *)dataPath
{
    // 当前更新的xml版本
    NSString * updateVersion = nil;
    NSData * updateXmlData = nil;
    if (dataPath)
    {
        updateXmlData = [NSData dataWithContentsOfFile:dataPath];
        updateVersion = [self _parseXMLVersion:updateXmlData];
    }
    NSLog(@"lm cleaner use update verison = %@", updateVersion);
    // 本地的xml版本
    NSString * currentVersion = nil;
    NSData * currentXMLData = nil;
    
    if ([McCoreFunction isAppStoreVersion]) {
        if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese){
            currentXMLData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"garbage_appstore_zh" ofType:@"xml"]];
        }else{//其他语言都按照英语来
            currentXMLData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"garbage_appstore_en" ofType:@"xml"]];
        }
    }else{
        if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese){
            currentXMLData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"garbage1_zh" ofType:@"xml"]];
        }else{//其他语言都按照英语来
            currentXMLData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"garbage1_en" ofType:@"xml"]];
        }
    }
    
    currentVersion = [self _parseXMLVersion:currentXMLData];
    NSLog(@"lm cleaner use current verison = %@", currentVersion);
    
    if (!updateXmlData && !currentXMLData)
    return NO;
    
    if (!updateVersion && !currentVersion)
    return NO;
    
    NSData * xmlData = nil;
    if (currentVersion == nil ||
        (updateVersion && [updateVersion compare:currentVersion options:NSNumericSearch] == NSOrderedDescending)){
        NSLog(@"lm cleaner use update");
        xmlData = updateXmlData;
    }
    else{
        NSLog(@"lm cleaner use current");
        xmlData = currentXMLData;
    }
    
    
    m_onlyVersion = NO;
    QMSigFileHandler * sigFileHandler = [QMSigFileHandler initWithContent:xmlData];
    NSXMLParser * parser = nil;
    if (sigFileHandler)
        parser = [[NSXMLParser alloc] initWithData:sigFileHandler.data];
    else
        parser = [[NSXMLParser alloc] initWithData:xmlData];
    [parser setDelegate:self];
    [parser parse];
    if ([parser parserError])
    NSLog(@"Clean Parser XML Error : %@", [parser parserError]);
    return ([parser parserError] == nil);
}

- (NSString *)_parseXMLVersion:(NSData *)xmlData
{
    if (!xmlData)
    return nil;
    m_onlyVersion = YES;
    
    QMSigFileHandler * sigFileHandler = [QMSigFileHandler initWithContent:xmlData];
    NSXMLParser * parser = nil;
    if (sigFileHandler)
    parser = [[NSXMLParser alloc] initWithData:sigFileHandler.data];
    else
    parser = [[NSXMLParser alloc] initWithData:xmlData];
    [parser setDelegate:self];
    [parser parse];
    return self.version;
}

- (NSString *)parseXMLVersion:(NSString *)path
{
    // 当前更新的xml版本
    NSString * updateVersion = nil;
    NSData * updateXmlData = nil;
    if (path)
    {
        updateXmlData = [NSData dataWithContentsOfFile:path];
        updateVersion = [self _parseXMLVersion:updateXmlData];
    }
    
    // 本地的xml版本
    NSString * currentVersion = nil;
    NSData * currentXMLData = nil;
    
    currentXMLData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"garbage1_zh" ofType:@"xml"]];
    currentVersion = [self _parseXMLVersion:currentXMLData];
    
    if (!updateXmlData && !currentXMLData)
    return nil;
    
    if (!updateVersion && !currentVersion)
    return nil;
    
    // 返回版本最高的
    if (currentVersion == nil ||
        (updateVersion && [updateVersion compare:currentVersion options:NSNumericSearch] == NSOrderedDescending))
    self.version = updateVersion;
    else
    self.version = currentVersion;
    return self.version;
}

/*
 根据XML创建清理对象
 */
- (void)createCleanItem:(NSDictionary *)attributeDict
{
    if (!attributeDict)
    return;
    NSArray * allKeys = [attributeDict allKeys];
    if (![allKeys containsObject:kXMLKeyID])
    return;
    if (![allKeys containsObject:kXMLKeyColumn])
    return;
    
    m_curCautionItem = [[QMCautionItem alloc] init];
    m_curCautionItem.cautionID = [attributeDict objectForKey:kXMLKeyID];
    m_curCautionItem.column = [attributeDict objectForKey:kXMLKeyColumn];
    if ([allKeys containsObject:kXMLKeyValue])
    m_curCautionItem.value = [attributeDict objectForKey:kXMLKeyValue];
    if ([allKeys containsObject:kXMLKeyBundle])
    m_curCautionItem.bundleID = [attributeDict objectForKey:kXMLKeyBundle];
    if ([allKeys containsObject:kXMLKeyAppName])
    m_curCautionItem.appName = [attributeDict objectForKey:kXMLKeyAppName];
}

/*
 根据XML创建过滤对象
 */
- (void)createFilterItem:(NSDictionary *)attributeDict
{
    if (!attributeDict)
    return;
    NSArray * allKeys = [attributeDict allKeys];
    if (![allKeys containsObject:kXMLKeyID])
    return;
    if (![allKeys containsObject:kXMLKeyColumn])
    return;
    
    m_curFilterItem = [[QMFilterItem alloc] init];
    m_curFilterItem.filterID = [attributeDict objectForKey:kXMLKeyID];
    m_curFilterItem.column = [attributeDict objectForKey:kXMLKeyColumn];
    if ([allKeys containsObject:kXMLKeyRelation])
    m_curFilterItem.relation = [attributeDict objectForKey:kXMLKeyRelation];
    if ([allKeys containsObject:kXMLKeyValue])
    m_curFilterItem.value = [attributeDict objectForKey:kXMLKeyValue];
    if ([allKeys containsObject:kXMLKeyAction])
    m_curFilterItem.action = [attributeDict objectForKey:kXMLKeyAction];
}

/*
 根据XML获取子项清理对象
 */
- (void)createCategorySubItem:(NSDictionary *)attributeDict
{
    if (!attributeDict)
    return;
    NSArray * allKeys = [attributeDict allKeys];
    if (![allKeys containsObject:kXMLKeyID])
    return;
    m_curCategorySubItem = [[QMCategorySubItem alloc] init];
    m_curCategorySubItem.subCategoryID = [attributeDict objectForKey:kXMLKeyID];
    if ([allKeys containsObject:kXMLKeyRecommend]){
        m_curCategorySubItem.recommend = [[attributeDict objectForKey:kXMLKeyRecommend] boolValue];
        //先获取到是否需要提示谨慎处理 目前和recommend一个字段
        m_curCategorySubItem.isCautious = m_curCategorySubItem.recommend;
    }
    if ([allKeys containsObject:kXMLKeyShowAction])
    m_curCategorySubItem.showAction = [[attributeDict objectForKey:kXMLKeyShowAction] boolValue];
    if ([allKeys containsObject:kXMLKeyFastMode])
    m_curCategorySubItem.fastMode = [[attributeDict objectForKey:kXMLKeyFastMode] boolValue];
    if ([allKeys containsObject:kXMLKeyBundleId]) {
        m_curCategorySubItem.bundleId = [attributeDict objectForKey:kXMLKeyBundleId];
    }
    if ([allKeys containsObject:kXMLKeyAppStoreBundleId]) {
        m_curCategorySubItem.appStoreBundleId = [attributeDict objectForKey:kXMLKeyAppStoreBundleId];
    }
    if ([allKeys containsObject:kXMLKeyDefaultState]) {
        //NOTE:之前一级勾选默认是mix,需改为on
        m_curCategorySubItem.defaultState = 1;//[[attributeDict objectForKey:kXMLKeyDefaultState] integerValue];
    }
    
    //如果当前是其他应用垃圾 则插入 未适配的软件 自适配
    if ([m_curCategorySubItem.subCategoryID isEqualToString:@"22222"]) {
        [QMItemCreateHelper createAllSoftAdaptCategorySubItemWithInstallArr:m_installBundleIdDic curCategoryItem:m_curCategoryItem];
    }
    
    //判读bundleid不为空，并且没有安装 --- 将已经适配过的软件加入进来
    if ((m_curCategorySubItem.bundleId == nil) || ([m_installBundleIdDic objectForKey:m_curCategorySubItem.bundleId]) || [m_installBundleIdDic objectForKey:m_curCategorySubItem.appStoreBundleId]) {
        [m_curCategoryItem addSubCategoryItem:m_curCategorySubItem];
        //加入进来的软件进行移除 剩余的软件进行自适配
        if (m_curCategorySubItem.bundleId != nil) {
            [m_installBundleIdDic removeObjectForKey:m_curCategorySubItem.bundleId];
        }
        if (m_curCategorySubItem.appStoreBundleId != nil) {
            [m_installBundleIdDic removeObjectForKey:m_curCategorySubItem.appStoreBundleId];
        }
    }
}

/*
 根据XML创建清理种类对象
 */
- (void)createCategoryItem:(NSDictionary *)attributeDict
{
    NSArray * allKeys = [attributeDict allKeys];
    if (![allKeys containsObject:kXMLKeyID])
    return;
    m_curCategoryItem = [[QMCategoryItem alloc] init];
    m_curCategoryItem.categoryID = [attributeDict objectForKey:kXMLKeyID];
}

/*
 根据XML创建行为对象
 */
- (void)createActionItem:(NSDictionary *)attributeDict
{
    NSArray * allKeys = [attributeDict allKeys];
    if (![allKeys containsObject:kXMLKeyType])
    return;
    m_curActionItem = [[QMActionItem alloc] init];
    if ([allKeys containsObject:kXMLKeyID])
    m_curActionItem.actionID = [attributeDict objectForKey:kXMLKeyID];
    
    if ([allKeys containsObject:kXMLKeyOS])
    m_curActionItem.os = [attributeDict objectForKey:kXMLKeyOS];
    if (![m_curActionItem checkVersion:m_curSysVersion])
    return;
    
    if ([allKeys containsObject:kXMLKeySandboxType]) {
        NSString *type = [attributeDict objectForKey:kXMLKeySandboxType];
        if ([type isEqualToString:@"yes"]) {
            m_curActionItem.sandboxType = SandboxTypeYes;
        }else if ([type isEqualToString:@"not"]){
            m_curActionItem.sandboxType = SandboxTypeNot;
        }else if ([type isEqualToString:@"multi"]){
            m_curActionItem.sandboxType = SandboxTypeMulti;
        }
    }
    
    NSString * type = [attributeDict objectForKey:kXMLKeyType];
    if ([type isEqualToString:kXMLKeyFile])
        m_curActionItem.type = QMActionFileType;
    else if ([type isEqualToString:kXMLKeyDir])
        m_curActionItem.type = QMActionDirType;
    else if ([type isEqualToString:kXMLKeyLaunguage])
        m_curActionItem.type = QMActionLanguageType;
    else if ([type isEqualToString:kXMLKeyBrokenPlist])
        m_curActionItem.type = QMActionBrokenPlistType;
    else if ([type isEqualToString:kXMLKeyBrokenRegister])
        m_curActionItem.type = QMActionBrokenReigisterType;
    else if ([type isEqualToString:kXMLKeyDeveloper])
        m_curActionItem.type = QMActionDeveloperType;
    else if ([type isEqualToString:kXMLKeyAppLeft])
        m_curActionItem.type = QMActionAppLeftType;
    else if ([type isEqualToString:kXMLKeyBinary])
        m_curActionItem.type = QMActionBinarBinaryType;
    else if ([type isEqualToString:kXMLKeyOtherBinary])
        m_curActionItem.type = QMActionBinarOtherBinaryType;
    else if ([type isEqualToString:kXMLKeyInstallPackage])
        m_curActionItem.type = QMActionInstallPackage;
    else if ([type isEqualToString:kXMLKeyMail])
        m_curActionItem.type = QMActionMailType;
    else if ([type isEqualToString:kXMLKeySoft])
        m_curActionItem.type = QMActionSoftType;
    else if([type isEqualToString:kXMLKeyDerivedApp])
        m_curActionItem.type = QMActionDerivedAppType;
    else if([type isEqualToString:kXMLKeyArchives])
        m_curActionItem.type = QMActionArchivesType;
    else if ([type isEqualToString:kXMLKeyAppCache])
        m_curActionItem.type = QMActionSoftAppCacheType;
    else if ([type isEqualToString:kXMLKeyLeftCache])
        m_curActionItem.type = QMActionLeftCacheType;
    else if ([type isEqualToString:kXMLKeyLeftLog])
        m_curActionItem.type = QMActionLeftLogType;
    else if ([type isEqualToString:kXMLKeyWechatAvatar])
        m_curActionItem.type = QMActionWechatAvatar;
    else if ([type isEqualToString:kXMLKeyWechatImage])
        m_curActionItem.type = QMActionWechatImage;
    else if ([type isEqualToString:kXMLKeyWechatImage90])
        m_curActionItem.type = QMActionWechatImage90;
    else if ([type isEqualToString:kXMLKeyWechatFile])
        m_curActionItem.type = QMActionWechatFile;
    else if ([type isEqualToString:kXMLKeyWechatVideo])
        m_curActionItem.type = QMActionWechatVideo;
    else if ([type isEqualToString:kXMLKeyWechatAudio])
        m_curActionItem.type = QMActionWechatAudio;
    
    if ([allKeys containsObject:kXMLKeyCleanEmptyFolder])
    m_curActionItem.cleanemptyfolder = [[attributeDict objectForKey:kXMLKeyCleanEmptyFolder] boolValue];
    if ([allKeys containsObject:kXMLKeyCleanHiddenFile])
    m_curActionItem.cleanhiddenfile = [[attributeDict objectForKey:kXMLKeyCleanHiddenFile] boolValue];
    
    if ([allKeys containsObject:kXMLKeyCaution])
    m_curActionItem.cautionID = [attributeDict objectForKey:kXMLKeyCaution];
    
    if ([allKeys containsObject:kXMLKeyRecommend])
    m_curActionItem.recommend = [[attributeDict objectForKey:kXMLKeyRecommend] boolValue];
    
    if ([allKeys containsObject:kXMLKeyClean])
    {
        NSString * cleanStr = [attributeDict objectForKey:kXMLKeyClean];
        if ([cleanStr isEqualToString:kXMLKeyTruncate])
        m_curActionItem.cleanType = QMCleanTruncate;
        else if ([cleanStr isEqualToString:kXMLKeyMoveTrash])
        m_curActionItem.cleanType = QMCleanMoveTrash;
        else if ([cleanStr isEqualToString:kXMLKeyRemoveLanguage])
        m_curActionItem.cleanType = QMCleanRemoveLanguage;
        else if ([cleanStr isEqualToString:kXMLKeyCutBinary])
        m_curActionItem.cleanType = QMCleanCutBinary;
        else if ([cleanStr isEqualToString:kXMLKeyDeleteBinary])
        m_curActionItem.cleanType = QMCleanDeleteBinary;
        else if ([cleanStr isEqualToString:kXMLKeyDeletePackage])
        m_curActionItem.cleanType = QMCleanDeletePackage;
        else if ([cleanStr isEqualToString:KXMLKeySafariCookies])
        m_curActionItem.cleanType = QMCleanSafariCookies;
        else
        m_curActionItem.cleanType = QMCleanRemove;
    }
    
    if ([allKeys containsObject:kXMLKeyAppPath])
    m_curActionItem.appPath = [attributeDict objectForKey:kXMLKeyAppPath];
    if ([allKeys containsObject:kXMLKeyBundle])
    m_curActionItem.bundleID = [attributeDict objectForKey:kXMLKeyBundle];
    if ([allKeys containsObject:kXMLKeyAppVersion])
    m_curActionItem.appVersion = [attributeDict objectForKey:kXMLKeyAppVersion];
    if ([allKeys containsObject:kXMLKeyBuildVersion])
    m_curActionItem.buildVersion = [attributeDict objectForKey:kXMLKeyBuildVersion];
    
    if ([m_curActionItem checkAppVersion])
    [m_curCategorySubItem addActionItem:m_curActionItem];
    else
    {
        if (m_curActionItem.actionID)
        {
            if (m_notAddActionID != nil && [m_notAddActionID isEqualToString:m_curActionItem.actionID])
            [m_curCategorySubItem addActionItem:m_curActionItem];
            m_notAddActionID = m_curActionItem.actionID;
        }
    }
    m_curActionItem.bundleID = m_curCategorySubItem.bundleId;
    if (m_curCategorySubItem.appStoreBundleId != nil) {
        m_curActionItem.appstoreBundleID = m_curCategorySubItem.appStoreBundleId;
    }
}

/*
 创建Action，过滤对象
 */
- (void)fillActionAtomItem:(NSDictionary *)attributeDict
{
    if (!attributeDict)
    return;
    NSArray * allKeys = [attributeDict allKeys];
    
    QMActionAtomItem * atomItem = [[QMActionAtomItem alloc] init];
    if ([allKeys containsObject:kXMLKeyFilters])
    atomItem.resultFilters = [attributeDict objectForKey:kXMLKeyFilters];
    m_curActionItem.atomItem = atomItem;
}

/*
 创建Action，path对象
 */
- (void)fillActionPathItem:(NSDictionary *)attributeDict
{
    if (!attributeDict)
    return;
    NSArray * allKeys = [attributeDict allKeys];
    
    QMActionPathItem * pathItem = [[QMActionPathItem alloc] init];
    if ([allKeys containsObject:kXMLKeyLevel])
    pathItem.level = [[attributeDict objectForKey:kXMLKeyLevel] intValue];
    if ([allKeys containsObject:kXMLKeyFileName])
    pathItem.filename = [attributeDict objectForKey:kXMLKeyFileName];
    if ([allKeys containsObject:kXMLKeyType])
    pathItem.type = [attributeDict objectForKey:kXMLKeyType];
    if ([allKeys containsObject:kXMLKeyValue])
    pathItem.value = [attributeDict objectForKey:kXMLKeyValue];
    if ([allKeys containsObject:kXMLKeyValue1])
    pathItem.value1 = [attributeDict objectForKey:kXMLKeyValue1];
    if ([allKeys containsObject:kXMLKeyFilters])
    pathItem.scanFilters = [attributeDict objectForKey:kXMLKeyFilters];
    [m_curActionItem addActionPathItem:pathItem];
}

#pragma mark-
#pragma mark 解析XML委托

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    [delegagte xmlParseDidStart];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError;
{
    if (m_onlyVersion && [parseError code] == NSXMLParserDelegateAbortedParseError)
    return;
    [delegagte xmlParseErro:parseError];
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
    [delegagte xmlParseErro:validationError];
}
///元素开始解析时调用
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    //the parser found an XML tag and is giving you some information about it
    //what are you going to do?
    if (!elementName)
    return;
    
    [m_parseKeyArray addObject:elementName];
    
    NSUInteger curParserLevel = [m_parseKeyArray count];
    if (curParserLevel > 1)
    {
        // 解析filter
        if ([[m_parseKeyArray objectAtIndex:1] isEqualToString:kXMLKeyFilters]
            && [elementName isEqualToString:kXMLKeyFilter])
        [self createFilterItem:attributeDict];
        
        if ([[m_parseKeyArray objectAtIndex:1] isEqualToString:kXMLKeyCautions]
            && [elementName isEqualToString:kXMLKeyCaution])
        [self createCleanItem:attributeDict];
        
        
        // 解析category
        if ([[m_parseKeyArray objectAtIndex:1] isEqualToString:kXMLKeyCategory])
        {
            if (curParserLevel == 2)
            {
                [self createCategoryItem:attributeDict];
            }
            else if (curParserLevel == 3)
            {
                if ([elementName isEqualToString:kXMLKeyItem])
                {
                    m_notAddActionID = nil;
                    [self createCategorySubItem:attributeDict];
                }
            }
            else if (curParserLevel == 4)
            {
                if ([elementName isEqualToString:kXMLKeyAction])
                [self createActionItem:attributeDict];
            }
            else if (curParserLevel == 5)
            {
                if ([elementName isEqualToString:kXMLKeyAtom])
                [self fillActionAtomItem:attributeDict];
                else if ([elementName isEqualToString:kXMLKeyPath])
                [self fillActionPathItem:attributeDict];
            }
        }
    }
    else
    {
        
        if ([elementName isEqualToString:kXMLKeyGarbage])
        {
            self.version = [attributeDict objectForKey:@"version"];
            if (m_onlyVersion)
            {
                [parser abortParsing];
                [m_parseKeyArray removeAllObjects];
            }
        }
    }
}

///元素解析结束调用
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // 解析完整的对象至nil
    NSUInteger curParserLevel = [m_parseKeyArray count];
    if ([elementName isEqualToString:kXMLKeyFilter])
    {
        [delegagte xmlParseDidEndFilter:m_curFilterItem];
        m_curFilterItem = nil;
    }
    if ([elementName isEqualToString:kXMLKeyCaution])
    {
        [delegagte xmlParseDidEndCaution:m_curCautionItem];
        m_curCautionItem = nil;
    }
    if ([elementName isEqualToString:kXMLKeyCategory])
    {
        [delegagte xmlParseDidEndCategory:m_curCategoryItem];
        [m_curCategoryItem refreshStateValue];
        m_curCategoryItem = nil;
    }
    if (curParserLevel == 3 && [elementName isEqualToString:kXMLKeyItem])
    {
        m_curCategorySubItem = nil;
    }
    if (curParserLevel == 4 && [elementName isEqualToString:kXMLKeyAction])
    {
        m_curActionItem = nil;
    }
    // 移除解析完成的tag
    [m_parseKeyArray removeLastObject];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    // 解析tag内容
    NSUInteger curParserLevel = [m_parseKeyArray count];
    if (curParserLevel == 3)
    {
        if ([[m_parseKeyArray lastObject] isEqualToString:kXMLKeyTitle])
        {
            m_curCategoryItem.title = string;
        }
        else if ([[m_parseKeyArray lastObject] isEqualToString:kXMLKeyTips])
        {
            m_curCategoryItem.tips = string;
        }
    }
    else if (curParserLevel == 4)
    {
        if ([[m_parseKeyArray lastObject] isEqualToString:kXMLKeyTitle])
        {
            m_curCategorySubItem.title = string;
        }
        else if ([[m_parseKeyArray lastObject] isEqualToString:kXMLKeyTips])
        {
            if (m_curCategorySubItem.tips == nil) {
                m_curCategorySubItem.tips = string;
            }
        }
    }
    else if (curParserLevel == 5)
    {
        if ([[m_parseKeyArray lastObject] isEqualToString:kXMLKeyTitle])
        {
            m_curActionItem.title = string;
        }
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    //the parser finished. what are you going to do?
    [delegagte xmlParseDidEnd];
}

@end
