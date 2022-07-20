//
//  McUninstallSoftManager.m
//  McSoftwareScanner
//
//  
//  Copyright (c) 2018年 Tencent. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "McUninstallSoftManager.h"
#import <QMCoreFunction/McLocalSoftManager.h>
#import <QMCoreFunction/QMConditionLock.h>
#import <QMCoreFunction/QMSafeMutableArray.h>
#import <QMCoreFunction/QMSafeMutableDictionary.h>
#import <QMCoreFunction/QMSafeMutableArray.h>

#import "QMSoftwareConfigConst.h"
#import "NSString+Extension.h"

@interface McUninstallSoftManager ()
{
    QMSafeMutableArray *uninstallsofts;
    QMSafeMutableArray *removingSoftArray;
    QMSafeMutableArray *removedBundleIDArray;
    
    McLocalSoftManager *softMgr;
    NSOperationQueue *createQueue;
    QMConditionLock *bundleIDLock;
    
//    NSArray *_groupConfig;
//    QMSafeMutableDictionary *_groups;
}
@end

@implementation McUninstallSoftManager
@synthesize sortFlag;
@synthesize ascending;
@synthesize filterString;

NSString*  McUninstallSoftManagerChangedNotification = @"McUninstallSoftManagerChangedNotification";

+ (McUninstallSoftManager *)sharedManager
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        ascending = NO;
        
        //读取软件配置
//        [self createConfig];
//        _groups = [[QMSafeMutableDictionary alloc] init];
        
        createQueue = [[NSOperationQueue alloc] init];
        [createQueue setMaxConcurrentOperationCount:3];
        bundleIDLock = [[QMConditionLock alloc] init];
        
        uninstallsofts = [[QMSafeMutableArray alloc] init];         //所有需要卸载的程序
        removingSoftArray = [[QMSafeMutableArray alloc] init];      //记录正在卸载的程序
        removedBundleIDArray = [[QMSafeMutableArray alloc] init];   //记录已经卸载的程序
        
        //根据已有的软件对象创建卸载对象
        softMgr = [McLocalSoftManager sharedManager];
        NSArray *localArray = [softMgr softsWithFlag:kMcLocalFlagAll];
        [self createUninstallWithLocals:localArray];
        
        //注册本地软件列表的通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(softManagerDidChanged:)
                                                     name:McLocalSoftManagerChangedNotification
                                                   object:nil];
    }
    return self;
}

//- (void)createConfig
//{
//#ifdef DEBUG
//    {
//        //生成加密的配置
//        NSString *directory = [(__bridge NSString*)CFSTR(__FILE__) stringByDeletingLastPathComponent];
//        NSString *configPath = [directory stringByAppendingPathComponent:@"software.json"];
//        NSString *encryptPath = [directory stringByAppendingPathComponent:@"software.qce"];
//
//        NSData *configData = [[NSData alloc] initWithContentsOfFile:configPath];
//        NSData *encryptData = [QMSigFileHandler encryptData:configData];
//        [encryptData writeToFile:encryptPath atomically:YES];
//    }
//#endif
//
//    {
//        NSString *encryptPath = [[NSBundle bundleForClass:self.class] pathForResource:@"software" ofType:@"qce"];
//        NSData *encryptData = [[NSData alloc] initWithContentsOfFile:encryptPath];
//        if (!encryptData)
//            return;
//
//        NSData *configData = [QMSigFileHandler decryptData:encryptData];
//        if (!configData)
//            return;
//
//        NSDictionary *configInfo = [NSJSONSerialization JSONObjectWithData:configData options:0 error:NULL];
//        if (!configInfo || ![configInfo isKindOfClass:[NSDictionary class]])
//            return;
//
//        _groupConfig = [configInfo objectForKey:@"groups"];
//    }
//}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (McLocalSort)sortFlag
{
    return sortFlag;
}

- (void)sortby:(McLocalSort)type isAscending:(BOOL)isAscending {
    sortFlag = type;
    ascending = isAscending;
    [self postChangedNotification];
}

- (void)setSortFlag:(McLocalSort)value
{
    if (sortFlag == value)
        return;
    
    sortFlag = value;
}

- (BOOL)ascending
{
    return ascending;
}

- (void)setAscending:(BOOL)value
{
    if (ascending == value)
        return;
    
    ascending = value;
}

- (NSString *)filterString
{
    return filterString;
}

- (void)setFilterString:(NSString *)value
{
    filterString = value;
    [self postChangedNotification];
}

//获取检索的软件列表(返回之前对结果进行排序和过滤)
- (NSArray *)softsWithType:(McLocalType)type
{
    NSMutableArray *listArray = [[NSMutableArray alloc] init];
    if (uninstallsofts.count > 0)
        [listArray addObjectsFromArray:uninstallsofts];
    if (removingSoftArray.count > 0)
        [listArray addObjectsFromArray:removingSoftArray];
//    if (_groups.count > 0)
//    {
//        [listArray addObjectsFromArray:[_groups allValues]];
//    }
    
    //类型
    if (type != kMcLocalFlagAll)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %d",type];
        [listArray filterUsingPredicate:predicate];
    }
    
    //过滤
    if ([filterString length] > 0)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(showName contains[cd] %@) OR (localSoft.appName contains[cd] %@)",
                                  filterString,filterString];
        [listArray filterUsingPredicate:predicate];
    }
    
    //排序(只针对APP)
    [listArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        McUninstallSoft *item1 = (McUninstallSoft *)obj1;
        McUninstallSoft *item2 = (McUninstallSoft *)obj2;
        
        NSComparisonResult result = [item1.showName localizedCompare:item2.showName];;
//        return result;
//        //针对非APP的类型，只需要按名字排序即可
        if (type != kMcLocalFlagApplication)
            return result;
        
        if (self->sortFlag == McLocalSortSize)
        {
            if (item1.size>item2.size)
                result = NSOrderedDescending;
            if (item1.size<item2.size)
                result = NSOrderedAscending;
        }
        else if (self->sortFlag == McLocalSortModifyDate)
        {
            if (item1.modifyDate && item2.modifyDate)
                result = 0-[item1.modifyDate compare:item2.modifyDate];
            else if(item1.modifyDate)
                result = 0-NSOrderedDescending;
            else if(item2.modifyDate)
                result = 0-NSOrderedAscending;
        }
        else if (self->sortFlag == McLocalSortCreateDate)
        {
            if (item1.createDate && item2.createDate)
                result = [item1.createDate compare:item2.createDate];
            else if(item1.createDate)
                result = NSOrderedDescending;
            else if(item2.createDate)
                result = NSOrderedAscending;
        }
        
        return self->ascending ?  (0-result):result;
    }];
    
    return listArray;
}

//查询软件当时是否正在检索过程中
- (BOOL)loading
{
    return ([createQueue operationCount]>0 || [softMgr loadingWithFlag:kMcLocalFlagApplication]);
}

//刷新软件,查询结果通过Notification返回
- (BOOL)refresh
{
    if ([self loading])
    {
        return NO;
    }
    
    //设置状态并清空现有列表
//    [_groups removeAllObjects];
    [uninstallsofts removeAllObjects];
    [removedBundleIDArray removeAllObjects];
    
    //刷新并通知主线程
    [softMgr refreshWithFlag:kMcLocalFlagAll];
    
    //通知界面已经开始刷新
    [self postChangedNotification];
    return YES;
}

/*
- (void)createBrowserExtension
{
    NSBlockOperation *safariOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        NSString *filePath = [@"~/Library/Safari/Extensions" stringByExpandingTildeInPath];
        NSString *infoPath = [filePath stringByAppendingPathComponent:@"Extensions.plist"];
        NSDictionary *extensionsInfo = [[NSDictionary alloc] initWithContentsOfFile:infoPath];
        NSArray *extensions = [extensionsInfo objectForKey:@"Installed Extensions"];
        for (NSDictionary *oneExtension in extensions)
        {
            NSString *fileName = [oneExtension objectForKey:@"Archive File Name"];
            NSString *extensionPath = [filePath stringByAppendingPathComponent:fileName];
            
            //McUninstallSoft *uninstallSoft = [McUninstallSoft uninstallSoftWithPath:<#(NSString *)#>];
        }
    }];
}
 */

//根据软件创建卸载对象
- (void)createUninstallWithLocals:(NSArray *)array
{
    //用于控制通知的发送频率
    static NSTimeInterval interval = 0;
    
    //将App类型与非App类型顺序混合,这样界面可以同时显示
    NSMutableArray *softwareArray = [NSMutableArray arrayWithCapacity:array.count];
    NSArray *appArray = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == %d",kMcLocalFlagApplication]];
    NSArray *pluginArray = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type != %d",kMcLocalFlagApplication]];
    for (NSInteger idx=0; idx<MAX(appArray.count, pluginArray.count); idx++)
    {
        if (idx < appArray.count)
            [softwareArray addObject:appArray[idx]];
        if (idx < pluginArray.count)
            [softwareArray addObject:pluginArray[idx]];
    }
    
    for (McLocalSoft *localSoft in softwareArray)
    {
        //不处理输入法
        if (localSoft.type == kMcLocalFlagInputMethod)
            continue;
        
        //创建一个任务
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            
//            //处理Group情况
//            for (NSDictionary *groupInfo in self->_groupConfig)
//            {
//                //判定是否为Group元素
//                BOOL isGroup = NO;
//                NSDictionary *groupCondition = groupInfo[kQMSoftwareGroupCondition];
//
//                do {
//                    NSArray *bundleIDs = groupCondition[kQMSoftwareGroupConIDs];
//                    for (NSString *bundleID in bundleIDs)
//                    {
//                        if ([localSoft.bundleID isEqualToString:bundleID] ||
//                            [localSoft.bundleID hasPrefix:bundleID])
//                        {
//                            isGroup = YES;
//                            break;
//                        }
//                    }
//
//                    NSString *bundlePath = [localSoft.bundlePath stringByAbbreviatingWithTildeInPath];
//                    NSArray *filePaths = groupCondition[kQMSoftwareGroupConPaths];
//                    for (NSString *filePath in filePaths)
//                    {
//                        if ([filePath isEqualToString:bundlePath] ||
//                            [filePath isParentPath:bundlePath])
//                        {
//                            isGroup = YES;
//                            break;
//                        }
//                    }
//                } while (0);
//
//                //对Group对象特殊处理
//                if (isGroup)
//                {
//                    //对同一个组操作，互斥
//                    id identifer = groupInfo[kQMSoftwareGroupIdentifer];
//                    [self->bundleIDLock lockForKey:identifer];
//
//                    McUninstallSoftGroup *groupItem = [self->_groups objectForKey:identifer];
//                    if (!groupItem)
//                    {
//                        groupItem = [[McUninstallSoftGroup alloc] init];
//                        groupItem.groupInfo = groupInfo;
//                        [groupItem appendItem:groupCondition[kQMSoftwareGroupConPaths]];
//                        [groupItem appendItem:[McUninstallSoft uninstallSoftWithSoft:localSoft]];
//                        [self->_groups setObject:groupItem forKey:identifer];
//                    }else
//                    {
//                        [groupItem appendItem:[McUninstallSoft uninstallSoftWithSoft:localSoft]];
//                    }
//
//                    [self->bundleIDLock unLockForKey:identifer];
//                    return;
//                }
//            }
            
            //处理普通的软件对象，对相同bundleID操作，互斥
            [self->bundleIDLock lockForKey:localSoft.bundleID];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"localSoft.bundleID == %@",localSoft.bundleID];
            NSArray *filterArray = [self->uninstallsofts filteredArrayUsingPredicate:predicate];
            
            if ([filterArray count] == 0)
            {
                //当没有bundleID相同时,直接创建新对象并加入到列表中
                McUninstallSoft *uninstallSoft = [McUninstallSoft uninstallSoftWithSoft:localSoft];
                if (uninstallSoft) [self->uninstallsofts addObject:uninstallSoft];
            }
            else
            {
                //存在bundleID相同时且路径或版本不相同,则合并,合并后将localSoft设置为版本更高的
                McUninstallSoft *currentSoft = [filterArray objectAtIndex:0];
                [currentSoft appendItem:localSoft];
            }
            
            [self->bundleIDLock unLockForKey:localSoft.bundleID];
        }];
        
        //任务结束后在主线程发通知(控制发送频率)
        [operation setCompletionBlock:^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSTimeInterval curInterval = [NSDate timeIntervalSinceReferenceDate];
                if (curInterval-interval > 1.0 || self->createQueue.operationCount == 0)
                {
                    interval = curInterval;
                    [self postChangedNotification];
                }
            });
        }];
        
        //将任务添加到队列
        [self->createQueue addOperation:operation];
    }
}

//卸载软件
- (void)uninstall:(McUninstallSoft*)soft
{
    if (!soft)
        return;
    
    size_t totalSize = 0;
    
    NSInteger selectedGruopCount = 0;
    NSInteger selectedFileItemCount = 0;
    for (McUninstallItemTypeGroup *group in soft.items) {
        if (group.selectedState != NSOffState) {
            selectedGruopCount++;
        }
        selectedFileItemCount += group.selectedCount;
    }
    if (selectedGruopCount == 0){
        return;
    }
        
//    for (McSoftwareFileItem *item in items)
//        totalSize += item.fileSize;
    
    [removingSoftArray addObject:soft];
    [uninstallsofts removeObject:soft];
    
    McUninstallSoft *softwarePr = soft;
    [soft delSelectedItems:NULL :^(BOOL removeAll) {
        if (removeAll)
        {
            //通知本地软件列表更新
            [[McLocalSoftManager sharedManager] removeSoftWithBundleID:softwarePr.bundleID];
        } else {
            [self->uninstallsofts addObject:softwarePr];
        }
        [self->removingSoftArray removeObject:softwarePr];
//        [self->_groups removeObjectForKey:softwarePr.bundleID];
        [self->removedBundleIDArray addObject:softwarePr.bundleID];
    }];
}

//软件列表改变
- (void)postChangedNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:McUninstallSoftManagerChangedNotification
                                                        object:self
                                                      userInfo:nil];
}

#pragma mark -
#pragma mark 本地软件列表更新的通知

- (void)softManagerDidChanged:(NSNotification *)notify
{
    NSDictionary *userInfo = [notify userInfo];
    NSInteger type = [[userInfo objectForKey:McLocalSoftManagerFlagKey] integerValue];

    
    NSArray *resultArray = [userInfo objectForKey:McLocalSoftManagerUpdateListKey];
    NSMutableArray *localSofts = [[NSMutableArray alloc] init];
    
    if (type == kMcLocalFlagAll || type == kMcLocalFlagInputMethod)
        return;
    
    for (McLocalSoft *software in resultArray)
    {
        //已经删除记录中包含,不处理
        if ([removedBundleIDArray containsObject:software.bundleID])
        {
            continue;
        }
        
        //正在删除的文件中包含,不处理
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"localSoft.bundleID == %@",software.bundleID];
        if ([removingSoftArray filteredArrayUsingPredicate:predicate].count > 0)
        {
            continue;
        }
        
        [localSofts addObject:software];
    }
    
    //创建卸载对象
    [self createUninstallWithLocals:localSofts];
}

@end

