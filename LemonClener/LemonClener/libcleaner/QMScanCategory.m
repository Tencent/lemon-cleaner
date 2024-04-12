//
//  QMScanCategory.m
//  QMCleanDemo
//
//

#import "QMScanCategory.h"
#import "QMAppUnlessFile.h"
#import "QMBrokenRegister.h"
#import "QMFilterParse.h"
#import "QMDirectoryScan.h"
#import "QMAppLeftScan.h"
#import "QMCleanUtils.h"
#import "QMMailScan.h"
#import "QMSoftScan.h"
#import "QMXcodeScan.h"
#import "QMCacheEnumerator.h"
#import "QMWechatScan.h"

@interface QMScanCategory()<QMScanDelegate>

@end

@implementation QMScanCategory
@synthesize m_filerDict;
@synthesize delegate;
@synthesize isStopScan;

- (id)init
{
    if (self = [super init])
    {
        m_appUnlessFile = [[QMAppUnlessFile alloc] init];
        m_brokenRegister = [[QMBrokenRegister alloc] init];
        m_directoryScan = [[QMDirectoryScan alloc] init];
        m_appLeftScan = [[QMAppLeftScan alloc] init];
        m_mailScan = [[QMMailScan alloc] init];
        m_softScan = [[QMSoftScan alloc] init];
        m_xcodeScan = [[QMXcodeScan alloc] init];
        m_wechatScan = [[QMWechatScan alloc] init];
        m_appUnlessFile.delegate = self;
        m_brokenRegister.delegate = self;
        m_directoryScan.delegate = self;
        m_appLeftScan.delegate = self;
        m_mailScan.delegate = self;
        m_softScan.delegate = self;
        m_xcodeScan.delegate = self;
        m_wechatScan.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    m_appUnlessFile.delegate = nil;
    m_brokenRegister.delegate = nil;
    m_directoryScan.delegate = nil;
    m_mailScan.delegate = nil;
    m_softScan.delegate = nil;
    m_xcodeScan.delegate = nil;
}

- (void)scanActiontem:(QMActionItem *)actionItem
{
//    if ([actionItem state] != NSOnState)
//        return;
    m_curScanActionItem = actionItem;
    m_curScanActionItem.progressValue = 0;
    QMActionType actionType = actionItem.type;
    
    [self scanProgressInfo:0 scanPath:nil resultItem:nil];
    
    switch (actionType)
    {
        case QMActionFileType:
        case QMActionDirType:
            [m_directoryScan scanActionWithItem:actionItem];
            break;
        case QMActionLeftCacheType:
            [m_softScan scanLeftAppCache:actionItem];
            break;
        case QMActionLeftLogType:
            [m_softScan scanLeftAppLog:actionItem];
            break;
        case QMActionLanguageType:
            [m_appUnlessFile scanAppUnlessLanguage:actionItem];
            break;
        case QMActionBinarBinaryType:
            [m_appUnlessFile scanAppUnlessBinary:actionItem];
            break;
        case QMActionBinarOtherBinaryType:
            [m_appUnlessFile scanAppGeneralBinary:actionItem];
            break;
        case QMActionInstallPackage:
            [m_appUnlessFile scanAppInstallPackage:actionItem];
            break;
        case QMActionDeveloperType:
            [m_appUnlessFile scanDeveloperJunck:actionItem];
            break;
        case QMActionBrokenReigisterType:
        case QMActionBrokenPlistType:
            [m_brokenRegister scanBrokenRegister:actionItem];
            break;
        case QMActionAppLeftType:
            [m_appLeftScan scanAppLeftWithItem:actionItem];
            break;
        case QMActionMailType:
            [m_mailScan scanMailAttachments:actionItem];
            break;
        case QMActionSoftType:
            [m_softScan scanSketchFileCache:actionItem];
            break;
        case QMActionSoftAppCacheType:
            [m_softScan scanAdaptSoftCache:actionItem];
            break;
        case QMActionDerivedAppType:
            [m_xcodeScan scanDerivedDataApp:actionItem];
            break;
        case QMActionArchivesType:
            [m_xcodeScan scanArchives:actionItem];
            break;
        case QMActionWechatAvatar:
            [m_wechatScan scanWechatAvatar:actionItem];
            break;
        case QMActionWechatImage:
            [m_wechatScan scanWechatImage:actionItem];
            break;
        case QMActionWechatImage90:
            [m_wechatScan scanWechatImage90DayAgo:actionItem];
            break;
        case QMActionWechatFile:
            [m_wechatScan scanWechatFile:actionItem];
            break;
        case QMActionWechatVideo:
            [m_wechatScan scanWechatVideo:actionItem];
            break;
        case QMActionWechatAudio:
            [m_wechatScan scanWechatAudio:actionItem];
            break;
        default:
            break;
    }
    m_curScanActionItem.progressValue = 1;
}

- (void)scanCategoryWithItem:(QMCategoryItem *)categoryItem
{
    if (!categoryItem)
        return;
    
    categoryItem.progressValue = 0;
    NSUInteger totalCount = 0;
    //计算所有需要扫描的action，每个action下面有一个或者多个扫描路径
    NSArray *m_categorySubItemArray_copy = [categoryItem.m_categorySubItemArray copy];
    for (QMCategorySubItem *subItem in m_categorySubItemArray_copy) {
        NSUInteger subCount = [subItem.m_actionItemArray count];
        totalCount += subCount;
    }
    
    // 计算扫描进度
    m_scanCount = 0;
    if (totalCount != 0) {
        m_scanFlags =  1.0 / totalCount;
    } else {
        m_scanFlags = 0;
    }
    m_curScanCategoryItem = categoryItem;
    
    for (QMCategorySubItem * subItem in m_categorySubItemArray_copy) {
        @autoreleasepool {
            if (isStopScan) {
                break;
            }
            
            m_curScanSubCategoryItem = subItem;
            
            // 开始扫描
            if (delegate)   [delegate startScanCategory:subItem.subCategoryID];
            if([subItem.title isEqualToString:@"IntelliJIdea"]){
                NSLog(@"");
            }
            NSUInteger subCount = [subItem.m_actionItemArray count];
            for (int j = 0; j < subCount; j++)
            {
                m_curScanIndex = j;
                [self scanActiontem:[subItem.m_actionItemArray objectAtIndex:j]];
                m_scanCount++;
                if (isStopScan)
                    break;
            }
            m_curScanSubCategoryItem.progressValue = 1;
            // 扫描结束
            if (delegate)   [delegate scanCategoryDidEnd:subItem.subCategoryID];
        }
    }
    categoryItem.progressValue = 1;
}

- (void)startScanAllCategoryArray:(NSArray *)itemArray
{
    self.isStopScan = NO;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self performAllCategoryScanWithArray:itemArray];
    });
}

- (void)performAllCategoryScanWithArray:(NSArray *)itemArray {
    int i = 0;
    for (QMCategoryItem * item in itemArray)
    {
        // 开始扫描
        if (self->delegate)   [self->delegate startScanCategory:item.categoryID];
        if ([item.categoryID isEqualToString:@"2"]) {
            QMCacheEnumerator *cacheEnumerator = [QMCacheEnumerator shareInstance];
            [cacheEnumerator initialData];
        }
        // 扫描item
        [self scanCategoryWithItem:item];
        // 扫描结束
        if (self->delegate)   [self->delegate scanCategoryDidEnd:item.categoryID];
        if (self->isStopScan) break;
        i++;
    }
}

- (void)scanQuickCategoryWithItem:(QMCategoryItem *)categoryItem
{
    if (!categoryItem)
        return;
    
    categoryItem.progressValue = 0;
    NSUInteger count = [categoryItem.m_categorySubItemArray count];
    NSUInteger totalCount = 0;
    for (int i = 0; i < count; i++)
    {
        // 未勾选不进行扫描
        QMCategorySubItem * subItem = [categoryItem.m_categorySubItemArray objectAtIndex:i];
        if (subItem.state == NSOffState  || !subItem.fastMode){
            NSLog(@"subitem title = %@ fastmode = no", [subItem title]);
            continue;
        }
//        NSLog(@"subitem title = %@ fastmode = yes", [subItem title]);
        NSUInteger subCount = [subItem.m_actionItemArray count];
        totalCount += subCount;
    }
    // 计算扫描进度
    m_scanCount = 0;
    if (totalCount != 0) {
        m_scanFlags =  1.0 / totalCount;
    } else {
        m_scanFlags = 0;
    }
    m_curScanCategoryItem = categoryItem;
    
    for (int i = 0; i < count && !isStopScan; i++)
    {
        @autoreleasepool
        {
            QMCategorySubItem * subItem = [categoryItem.m_categorySubItemArray objectAtIndex:i];
            
            // 未勾选不进行扫描
            if (subItem.state == NSOffState || !subItem.fastMode)
                continue;
            
            m_curScanSubCategoryItem = subItem;
            
            // 开始扫描
            if (delegate)   [delegate startScanCategory:subItem.subCategoryID];
            
            NSUInteger subCount = [subItem.m_actionItemArray count];
            for (int j = 0; j < subCount; j++)
            {
                m_curScanIndex = j;
                QMActionItem * actionItem = [subItem.m_actionItemArray objectAtIndex:j];
                if (!actionItem.cautionID && [actionItem state] == NSOnState)
                    [self scanActiontem:actionItem];
                m_scanCount++;
                if (isStopScan)
                    break;
            }
            m_curScanSubCategoryItem.progressValue = 1;
            // 扫描结束
            if (delegate)   [delegate scanCategoryDidEnd:subItem.subCategoryID];
        }
    }
    categoryItem.progressValue = 1;
}
- (void)startQuickScanCategoryArray:(NSArray *)itemArray;
{
    QMCacheEnumerator *cacheEnumerator = [QMCacheEnumerator shareInstance];
    [cacheEnumerator initialData];
    NSMutableArray * scanCategoryArray = [NSMutableArray array];
    for (QMCategoryItem * item in itemArray)
    {
        NSUInteger count = [item.m_categorySubItemArray count];
        for (int i = 0; i < count; i++)
        {
            // 未勾选不进行扫描
            QMCategorySubItem * subItem = [item.m_categorySubItemArray objectAtIndex:i];
            if (subItem.state == NSOffState  || !subItem.fastMode)
                continue;
            [scanCategoryArray addObject:item];
            break;
        }
    }
    if ([delegate respondsToSelector:@selector(scanCategoryArray:)])
        [delegate scanCategoryArray:scanCategoryArray];
    for (QMCategoryItem * item in scanCategoryArray)
    {
        // 开始扫描
        if (delegate)   [delegate startScanCategory:item.categoryID];
        // 扫描item
        if (item.state != NSOffState)
            [self scanQuickCategoryWithItem:item];
        // 扫描结束
        if (delegate)   [delegate scanCategoryDidEnd:item.categoryID];
        if (isStopScan) break;
    }
}

#pragma mark-
#pragma mark scan delegate

- (NSDictionary *)xmlFilterDict
{
    return m_filerDict;
}

- (BOOL)needStopScan
{
    return isStopScan;
}

- (BOOL)scanProgressInfo:(float)value scanPath:(NSString *)path resultItem:(QMResultItem *)item
{
    float progressValue = (value + m_scanCount) * m_scanFlags;
    if (item) {
        item.cautionID = m_curScanActionItem.cautionID;
        if ([[m_curScanCategoryItem m_categorySubItemArray] count] == 0) {
            [m_curScanCategoryItem addResultItem:item];
        } else {
            if (![m_curScanSubCategoryItem showAction]) {
                [self->m_curScanSubCategoryItem addResultItem:item];
                if ([self->m_curScanSubCategoryItem.subCategoryID isEqualToString:@"204021"]) {
                    [self->m_curScanSubCategoryItem sortResultItem];
                }
                if ([[self->m_curScanSubCategoryItem subCategoryID] isEqualToString:@"1003"]) {
                    [self->m_curScanSubCategoryItem refreshResultSize];
                }
            } else {
                item.showHierarchyType = 4;
                [self->m_curScanActionItem addResultItem:item];
            }
        }
    }
    m_curScanActionItem.progressValue = value;
    m_curScanSubCategoryItem.progressValue = (m_curScanIndex + value) / [[m_curScanSubCategoryItem m_actionItemArray] count];
    m_curScanCategoryItem.progressValue = progressValue;
    if (delegate)
        [delegate scanProgressInfo:progressValue scanPath:path resultItem:item];
    return isStopScan;
}

- (NSString *)currentScanCategoryKey
{
    return m_curScanCategoryItem.categoryID;
}


@end
