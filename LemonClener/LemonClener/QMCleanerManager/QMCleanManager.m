//
//  QMCleanManager.m
//  QMCleaner
//

//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMCleanManager.h"
#import "QMResultItem.h"
#import <QMCoreFunction/McCoreFunction.h>
#import "QMCleanerUtils.h"
#import "QMCleanUtils.h"
#import "QMDataConst.h"
#import <QMCoreFunction/QMDataCenter.h>
#import "QMScanCategory.h"
#import "LMCleanerDataCenter.h"
#import "QMCacheEnumerator.h"
#import <QMUICommon/SharedPrefrenceManager.h>

#define IS_NOT_FIRST_SCAN_INTELIGENT      @"is_not_first_scan_inteligent"
#define IS_NOT_FIRST_SCAN_ADNROID_STUIDO  @"is_not_first_scan_android_studio"
#define IS_NOT_FIRST_SCAN_PHP_STUIDO      @"is_not_first_scan_php_studio"

@interface QMCleanManager()
{
    NSDictionary *m_categoryDictOrigin;
    // 扫描
    QMScanCategory * _scanCategory;
    // 删除
    QMRemoveManager * _removeManager;
   
    NSInteger _errLoopCount;
}

@property (nonatomic, strong) NSArray *fileMoveArr;
@property (nonatomic, assign) long long fileMoveTotalNum;

@end

@implementation QMCleanManager
- (id)init
{
    if (self = [super init])
    {
        _scanCategory = [[QMScanCategory alloc] init];
        [_scanCategory setDelegate:(id<QMScanCategoryDelegate>)self];
        _removeManager = [QMRemoveManager getInstance];
        [_removeManager setDelegate:(id<QMRemoveManagerDelegate>)self];
        
        
        m_subCategoryDict = [[NSMutableDictionary alloc] init];
        m_scanCategoryArray = [[NSMutableArray alloc] init];
        m_scanResultDict = [[NSMutableDictionary alloc] init];
        m_curScanCategoryArray = [[NSMutableArray alloc] init];
        [self parseCleanXMLItem];
        self.fileMoveArr = @[@"200013",@"200014",@"200015",@"200017"
                             ,@"200024",@"200025",@"200026"
                             ,@"200034",@"200035",@"200036",@"200037"];
        self.fileMoveTotalNum = 0;
    }
    return self;
}

+ (QMCleanManager *)sharedManger
{
    static QMCleanManager * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[QMCleanManager alloc] init];
    });
    return instance;
}

//获取所有的扫描分类 --- m_categoryDict
- (void)parseCleanXMLItem
{
    if (m_categoryDictOrigin != nil) {
        m_categoryDict = [[NSDictionary alloc] initWithDictionary:m_categoryDictOrigin copyItems:YES];
        NSMutableArray *array = [NSMutableArray arrayWithArray:m_categoryDict.allValues];
        [array sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            QMCategoryItem * item1 = obj1;
            QMCategoryItem * item2 = obj2;
            return [item1.categoryID compare:item2.categoryID options:NSNumericSearch];
        }];
        
        // 解析完毕
        [[NSNotificationCenter defaultCenter] postNotificationName:kQMCleanXMLItemParseEnd
                                                            object:array];
        return;
    }
    QMXMLParseManager * parseManager = [QMXMLParseManager sharedManager];
    BOOL retValue = [parseManager startParaseXML:YES];
    // xml解析失败
    if (!retValue)
    {
        if (_errLoopCount < 3)
        {
            _errLoopCount++;
            double delayInSeconds = 2.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self parseCleanXMLItem];
            });
        }
        // 解析失败
        [[NSNotificationCenter defaultCenter] postNotificationName:kQMCleanXMLItemParseEnd
                                                            object:nil];
    }
    else
    {
        _errLoopCount = 0;
        m_categoryDictOrigin = [parseManager categoryItemDict];
        m_categoryDict = [[NSDictionary alloc] initWithDictionary:m_categoryDictOrigin copyItems:YES];
        NSMutableArray *array = [NSMutableArray arrayWithArray:m_categoryDict.allValues];
        [array sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            QMCategoryItem * item1 = obj1;
            QMCategoryItem * item2 = obj2;
            return [item1.categoryID compare:item2.categoryID options:NSNumericSearch];
        }];
        
        // 解析完毕
        [[NSNotificationCenter defaultCenter] postNotificationName:kQMCleanXMLItemParseEnd
                                                            object:array];
    }
}

//设置大清理界面的delegate-------后面会更改成 QMCleanManagerDelegate --》数据中心 ----》 小界面 | 大界面 订阅形式
-(void)setBigViewCleanDelegate:(id<QMCleanManagerDelegate>)bigDelegate{
    m_bigDelegate = bigDelegate;
}

// 自定义扫描
- (void)customStartScan:(id<QMCleanManagerDelegate>)delegate array:(NSArray *)array
{
    // 获取category
    QMXMLParseManager * xmlParseManager = [QMXMLParseManager sharedManager];
//    m_categoryDict = [[xmlParseManager categoryItemDict] mutableCopy];
//    m_categoryDict = [[NSDictionary alloc] initWithDictionary:m_categoryDictOrigin copyItems:YES];
    // 移除上次扫描 --- 扫描的resultItem都是放在subCategoryItem的成员变量里
//    [xmlParseManager removeLastScanResult];
    for (NSString * key in m_categoryDict.allKeys)
    {
        QMCategoryItem * categoryItem = [m_categoryDict objectForKey:key];
        //写数据库
        [[LMCleanerDataCenter shareInstance] addRecordIfNotExist:categoryItem];
        //清理环境
        [categoryItem setState:NSMixedState];
        [[LMCleanerDataCenter shareInstance] removeAllItemInSubCateArr];
        [categoryItem setShowHighlight:NO];
        [categoryItem setIsScanning:NO];
        [categoryItem setShowHignlightClean:NO];
        for (QMCategorySubItem * categorySubItem in categoryItem.m_categorySubItemArray)
        {
            NSString *bundleId = [categorySubItem bundleId];
            BOOL isNotFirstScanIntellij = [SharedPrefrenceManager getBool:IS_NOT_FIRST_SCAN_INTELIGENT];
            BOOL isNotFirstScanAndStu = [SharedPrefrenceManager getBool:IS_NOT_FIRST_SCAN_ADNROID_STUIDO];
            BOOL isNotFirstScanPhpStu = [SharedPrefrenceManager getBool:IS_NOT_FIRST_SCAN_PHP_STUIDO];
            if ([bundleId isEqualToString:@"com.jetbrains.intellij"] && !isNotFirstScanIntellij) {
                [[LMCleanerDataCenter shareInstance] changeSubcate:[categorySubItem subCategoryID] selectStatus:CleanSubcateSelectStatusDeselect];
                [SharedPrefrenceManager putBool:YES withKey:IS_NOT_FIRST_SCAN_INTELIGENT];
            }else if([bundleId isEqualToString:@"com.google.android.studio"] && !isNotFirstScanAndStu){
                [[LMCleanerDataCenter shareInstance] changeSubcate:[categorySubItem subCategoryID] selectStatus:CleanSubcateSelectStatusDeselect];
                [SharedPrefrenceManager putBool:YES withKey:IS_NOT_FIRST_SCAN_ADNROID_STUIDO];
            }else if([bundleId isEqualToString:@"com.jetbrains.PhpStorm"] && !isNotFirstScanPhpStu){
                [[LMCleanerDataCenter shareInstance] changeSubcate:[categorySubItem subCategoryID] selectStatus:CleanSubcateSelectStatusDeselect];
                [SharedPrefrenceManager putBool:YES withKey:IS_NOT_FIRST_SCAN_PHP_STUIDO];
            }
            
            //读取数据库
            CleanSubcateSelectStatus status = [[LMCleanerDataCenter shareInstance] getSubcateSelectStatus:categorySubItem.subCategoryID];
            if (status == CleanSubcateSelectStatusSelect) {
                [categorySubItem setRecommend:YES];
            }else if (status == CleanSubcateSelectStatusDeselect){
                [categorySubItem setRecommend:NO];
            }
            //Note:巨大坑warn,由于需要重置二级目录状态，但是有些二级目录不在清理页面中提醒，所以根本无法在清理页面修改它的状态
            if ([categorySubItem showAction]) {
                //Note:重置二级目录操作状态
                if (categorySubItem.m_actionItemArray.count > 0) {
                    NSInteger statusSelect = categorySubItem.m_actionItemArray.count;
                    for (QMActionItem * actionItem in categorySubItem.m_actionItemArray) {
                        CleanSubcateSelectStatus astatus = [[LMCleanerDataCenter shareInstance] getSubcateSelectStatus:actionItem.actionID];
                        if (astatus == CleanSubcateSelectStatusSelect) {
                            [actionItem setRecommend:YES];
                        }else if (astatus == CleanSubcateSelectStatusDeselect) {
                            [actionItem setRecommend:NO];
                        }
                        if (actionItem.actionID != nil) {
                            if (astatus == CleanSubcateSelectStatusDeselect) {
                                statusSelect--;
                            }
                        } else {
                            statusSelect--;
                        }
                        
                    }
                    BOOL needupdateState = YES;
                    for (QMActionItem * actionItem in categorySubItem.m_actionItemArray) {
                        if (actionItem.actionID == nil) {
                            needupdateState = NO;
                        }
                    }
                    if (needupdateState != NO) {
                        if (statusSelect >  0 && statusSelect != categorySubItem.m_actionItemArray.count) {
                            [categorySubItem setState:NSMixedState];
                        } else if (statusSelect >  0 && statusSelect == categorySubItem.m_actionItemArray.count) {
                            [categorySubItem setState:NSOnState];
                        }
                    }
                    
                }
            }
            
            
            [categorySubItem setIsScaned:NO];
            [m_subCategoryDict setObject:categorySubItem forKey:categorySubItem.subCategoryID];
        }
    }
    
    if (!delegate || [m_categoryDict count] == 0)
        return;
    [m_curScanCategoryArray removeAllObjects];
    [_removeManager removeWarnItem];
    
    NSArray * scanCategoryArray = array;
    if (!scanCategoryArray) scanCategoryArray = m_categoryDict.allValues;
    
    m_StopScan = NO;
    m_delegate = delegate;
    NSDictionary *filterDicts = [xmlParseManager filterItemDict];
    for (QMFilterItem *filterItem in filterDicts.allValues) {
        filterItem.andFilterItem = nil;
        filterItem.orFilterItem = nil;
    }
    [_scanCategory setM_filerDict:[xmlParseManager filterItemDict]];
    [_scanCategory startScanAllCategoryArray:scanCategoryArray];
    [m_curScanCategoryArray addObjectsFromArray:scanCategoryArray];
}

// 取消扫描
- (void)stopScan
{
    m_StopScan = YES;
    [_scanCategory setIsStopScan:YES];
}

// 扫描委托，非主线程回调
- (void)startScanCategory:(NSString *)categoryID
{
    __weak QMCleanManager *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        QMCleanManager *strongSelf = weakSelf;
        
        QMCategoryItem * categoryItem = [strongSelf->m_categoryDict objectForKey:categoryID];
        if (categoryItem)
        {
            strongSelf->m_curCategoryItem = categoryItem;
            [strongSelf->m_scanCategoryArray addObject:categoryID];
            [strongSelf->m_delegate scanCategoryStart:categoryItem];
            [strongSelf->m_bigDelegate scanCategoryStart:categoryItem];
        }
        QMCategorySubItem * subCategoryItem = [strongSelf->m_subCategoryDict objectForKey:categoryID];
        if (subCategoryItem){
            [strongSelf->m_scanCategoryArray addObject:categoryID];
            [strongSelf->m_delegate scanSubCategoryDidStart:subCategoryItem];
            [strongSelf->m_bigDelegate scanSubCategoryDidStart:subCategoryItem];
        }
        
    });
}

// 进度显示
- (void)scanProgressInfo:(float)value scanPath:(NSString *)path resultItem:(QMResultItem *)item
{
    __weak QMCleanManager *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        QMCleanManager *strongSelf = weakSelf;
        
        QMCategorySubItem * categorySubItem = [strongSelf->m_subCategoryDict objectForKey:[strongSelf->m_scanCategoryArray lastObject]];
        [strongSelf->m_delegate scanProgressInfo:value
                            scanPath:path
                                  category:strongSelf->m_curCategoryItem
                     subCategoryItem:categorySubItem];
        [strongSelf->m_bigDelegate scanProgressInfo:value
                            scanPath:path
                                     category:strongSelf->m_curCategoryItem
                     subCategoryItem:categorySubItem];
    });
}

// 扫描结束
- (void)scanCategoryDidEnd:(NSString *)categoryID
{
    __weak QMCleanManager *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        QMCleanManager *strongSelf = weakSelf;
        
        [strongSelf->m_scanCategoryArray removeLastObject];
        
        if (![strongSelf->m_categoryDict objectForKey:categoryID]){
            QMCategorySubItem *subItem = [strongSelf->m_subCategoryDict objectForKey:categoryID];
            [strongSelf->m_delegate scanSubCategoryDidEnd:subItem];
            [strongSelf->m_bigDelegate scanSubCategoryDidEnd:subItem];
            
            if (subItem.m_actionItemArray != nil && subItem.m_actionItemArray.count != 0) {
                for (QMActionItem *object in subItem.m_actionItemArray) {
                    if ([self.fileMoveArr containsObject:object.actionID]) {
                        NSUInteger selectedSize = [object resultFileSize];
                        NSLog(@"big = %@", [NSString stringFromDiskSize:selectedSize]);
                        self.fileMoveTotalNum = self.fileMoveTotalNum + selectedSize;
                    }
                }
            }
        }
        else
        {
            NSLog(@"qmclean manager scanCategoryDidEnd = %@", [strongSelf->m_curCategoryItem title]);
            NSLog(@"qmclean manager scanCategoryDidEnd size = %ld", [strongSelf->m_curScanCategoryArray count]);
            [strongSelf->m_curScanCategoryArray removeObject:strongSelf->m_curCategoryItem];
            [strongSelf->m_delegate scanCategoryDidEnd:strongSelf->m_curCategoryItem];
            [strongSelf->m_bigDelegate scanCategoryDidEnd:strongSelf->m_curCategoryItem];
            [strongSelf->m_curCategoryItem sortResultItem];
            if ([strongSelf->m_curScanCategoryArray count] == 0 || strongSelf->m_StopScan){
                NSLog(@"通知程序 扫描结束");
                [strongSelf->m_delegate scanCategoryAllDidEnd:self.fileMoveTotalNum];
                [strongSelf->m_bigDelegate scanCategoryAllDidEnd:self.fileMoveTotalNum];
                self.fileMoveTotalNum = 0;
            }
        }
    });
}

- (BOOL)isStopScan{
    return m_StopScan;
}

//如果文件夹文件数量特别巨大 每计算一千个文件回调一次主界面路径 其他全部不做回调
- (void)caculateSizeScanPath:(NSString *)path{
    QMCategorySubItem * categorySubItem = [m_subCategoryDict objectForKey:[m_scanCategoryArray lastObject]];
    [m_delegate scanProgressInfo:0
                        scanPath:path
                        category:m_curCategoryItem
                 subCategoryItem:categorySubItem];
    [m_bigDelegate scanProgressInfo:0
                           scanPath:path
                           category:m_curCategoryItem
                    subCategoryItem:categorySubItem];
}

#pragma mark-
#pragma mark clean

//- (BOOL)startCleaner
//{
//    NSMutableDictionary * removeItemDict = [NSMutableDictionary dictionary];
//
//    for (QMCategoryItem * categoryItem in m_categoryDict.allValues)
//    {
//        if (categoryItem.state == NSOffState)
//            continue;
//
//        NSUInteger removeSize = 0;
//        NSArray * array = [categoryItem removeSelectedResultItem:&removeSize];
//        if ([array count] > 0)
//            [removeItemDict setObject:array forKey:categoryItem.categoryID];
//    }
//
//    return [_removeManager startCleaner:removeItemDict];
//}

- (BOOL)startCleaner
{
    NSMutableDictionary * removeItemDict = [NSMutableDictionary dictionary];
    for (QMCategoryItem * categoryItem in m_categoryDict.allValues)
    {
        if (categoryItem.state == NSOffState)
            continue;
        
        NSMutableDictionary *removeSubItemDict = [NSMutableDictionary dictionary];
        for (QMCategorySubItem *subItem in categoryItem.m_categorySubItemArray) {
            NSUInteger removeSize = 0;
            NSArray *array = [subItem getSelectedResultItem:&removeSize];
//            if ([array count] > 0)
                [removeSubItemDict setObject:array forKey:subItem.subCategoryID];
        }
        
        [removeItemDict setObject:removeSubItemDict forKey:categoryItem.categoryID];
    }
    
    return [_removeManager startCleaner:removeItemDict];
}

- (void)cleanCategoryStart:(NSString *)categoryId{
    [m_delegate cleanCategoryStart:[m_categoryDict objectForKey:categoryId]];
    [m_bigDelegate cleanCategoryStart:[m_categoryDict objectForKey:categoryId]];
}

- (void)cleanCategoryEnd:(NSString *)categoryId{
    [m_delegate cleanCategoryEnd:[m_categoryDict objectForKey:categoryId]];
    [m_bigDelegate cleanCategoryEnd:[m_categoryDict objectForKey:categoryId]];
}

- (void)cleanProgressInfo:(float)value categoryKey:(NSString *)key path:(NSString *)path totalSize:(NSUInteger)totalSize
{
//    NSLog(@"xxx cleanProgressInfo %f, totalSize:%ld", value, totalSize);
    [m_delegate cleanProgressInfo:value item:[m_categoryDict objectForKey:key] path:path totalSize:totalSize];
    [m_bigDelegate cleanProgressInfo:value item:[m_categoryDict objectForKey:key] path:path totalSize:totalSize];
}

- (void)cleanFileNums:(NSUInteger) cleanFileNums{
//    NSLog(@"clean file nums size = %ld", cleanFileNums);
    [m_delegate cleanFileNums:cleanFileNums];
}

- (void)cleanResultDidEnd:(NSUInteger)totalSize leftSize:(NSUInteger)leftSize
{
    [m_delegate cleanResultDidEnd:totalSize leftSize:leftSize];
    [m_bigDelegate cleanResultDidEnd:totalSize leftSize:leftSize];
}

- (void)cleanSubCategoryStart:(NSString *)subCategoryID {
//    NSLog(@"clean subCategoryStart %@", subCategoryID);
    [m_delegate cleanSubCategoryStart:[m_subCategoryDict objectForKey:subCategoryID]];
    [m_bigDelegate cleanSubCategoryStart:[m_subCategoryDict objectForKey:subCategoryID]];
}

- (void)cleanSubCategoryEnd:(NSString *)subCategoryID{
//    NSLog(@"clean subCategoryEnd %@", subCategoryID);
    [m_delegate cleanSubCategoryEnd:[m_subCategoryDict objectForKey:subCategoryID]];
    [m_bigDelegate cleanSubCategoryEnd:[m_subCategoryDict objectForKey:subCategoryID]];
}

#pragma mark-
#pragma mark warning

- (NSArray *)warnResultItemArray
{
    return [_removeManager warnResultItemArray];
}
- (BOOL)canRemoveWarnItem
{
    return [_removeManager canRemoveWarnItem];
}
- (BOOL)cleanWarnResultItem:(id<QMCleanWarnItemDelegate>)delegate item:(QMWarnReultItem *)warnItem
{
    [_removeManager setWarnItemDelegate:(id<QMCleanWarnItemDelegate>)delegate];
    return [_removeManager cleanWarnResultItem:warnItem];
}
- (BOOL)checkWarnItemAtPath:(QMResultItem *)resultItem bundleID:(NSString **)bundle appName:(NSString **)name
{
    QMXMLParseManager * xmlParseManager = [QMXMLParseManager sharedManager];
    return [xmlParseManager checkWarnItemAtPath:resultItem bundleID:bundle appName:name];
}

@end
