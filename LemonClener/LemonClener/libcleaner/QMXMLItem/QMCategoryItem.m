//
//  QMCategoryItem.m
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import "QMCategoryItem.h"

@implementation QMCategorySubItem
@synthesize subCategoryID;
@synthesize recommend;
@synthesize showAction;
@synthesize fastMode;
@synthesize title;
@synthesize tips;
@synthesize m_actionItemArray;

- (id)init
{
    if (self = [super init])
    {
        showAction = NO;
        recommend = YES;
        fastMode = YES;
        m_resultItemArray = [[NSMutableArray alloc] init];
        self.m_stateValue = NSOnState;
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone{
    QMCategorySubItem *copy = [super copyWithZone:zone];
    if (copy) {
        copy.subCategoryID = [self.subCategoryID mutableCopy];
        copy.bundleId = [self.bundleId mutableCopy];
        copy.appStoreBundleId = [self.appStoreBundleId mutableCopy];
        copy.recommend = self.recommend;
        copy.defaultState = self.defaultState;
        copy.isCautious = self.isCautious;
        copy.showAction = self.showAction;
        copy.fastMode = self.fastMode;
        copy.title = [self.title mutableCopy];
        copy.tips = [self.tips mutableCopy];
        copy->m_actionItemArray = [[NSMutableArray alloc] initWithArray:m_actionItemArray copyItems:YES];
        copy->m_resultItemArray = [[NSMutableArray alloc] init];
        copy.isScanning = self.isScanning;
        copy.isScaned = self.isScaned;
        copy.isCleanning = self.isCleanning;
    }
    
    return copy;
}

-(id)mutableCopyWithZone:(NSZone *)zone{
    QMCategorySubItem *copy = [super mutableCopyWithZone:zone];
    if (copy) {
        copy.subCategoryID = [self.subCategoryID mutableCopy];
        copy.bundleId = [self.bundleId mutableCopy];
        copy.appStoreBundleId = [self.appStoreBundleId mutableCopy];
        copy.recommend = self.recommend;
        copy.defaultState = self.defaultState;
        copy.isCautious = self.isCautious;
        copy.showAction = self.showAction;
        copy.fastMode = self.fastMode;
        copy.title = [self.title mutableCopy];
        copy.tips = [self.tips mutableCopy];
        copy->m_actionItemArray = [[NSMutableArray alloc] initWithArray:m_actionItemArray copyItems:YES];
        copy->m_resultItemArray = [[NSMutableArray alloc] init];
        copy.isScanning = self.isScanning;
        copy.isScaned = self.isScaned;
        copy.isCleanning = self.isCleanning;
    }
    
    return copy;
}

- (void)refreshResultSize
{
    uint64 size = 0;
    NSArray * array = [self resultItemArray];
    for (int i = 0; i < [array count]; i++)
    {
        QMResultItem * item = [array objectAtIndex:i];
        size += [item resultFileSize];
    }
    m_totalSize = size;
}

// 结果大小
- (NSUInteger)resultFileSize
{
    if (m_resultItemArray.count > 0)
        return m_totalSize;
    else
    {
        NSUInteger size = 0;
        for (QMActionItem * subItem in m_actionItemArray)
        {
            size += subItem.resultFileSize;
        }
        return size;
    }
}

#pragma mark-
#pragma mark 初始化XML

- (void)setRecommend:(BOOL)value
{
    recommend = value;
    if ((value == NSOnState) && (self.m_stateValue == NSMixedState)) {
        return;
    }
    if (value == NSOffState) {
        [self setState:NSOffState];
        return;
    }
    self.m_stateValue = (recommend ? NSOnState : NSOffState);
}

- (void)addActionItem:(QMActionItem *)item
{
    if (!m_actionItemArray)    m_actionItemArray = [[NSMutableArray alloc] init];
    [m_actionItemArray addObject:item];
    if ([item state] == NSOffState && self.m_stateValue == NSOnState) {
        self.m_stateValue = NSMixedState;
    }
}

#pragma mark-
#pragma 结果显示
- (void)sortResultItem {
    [self sortItemArray:m_resultItemArray];
}

- (void)sortItemArray:(NSMutableArray *)result {
    if (!result || [result count] == 0)
        return;
    [result sortUsingComparator:^NSComparisonResult(QMResultItem * item1, QMResultItem * item2) {
        NSUInteger size1 = [item1 resultFileSize];
        NSUInteger size2 = [item2 resultFileSize];
        if (size1 > size2)
            return NSOrderedAscending;
        else if (size1 < size2)
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
}

- (void)addResultItem:(QMResultItem *)item
{
    if (item == nil) {
        return;
    }
    @synchronized (self) {
        if (![m_resultItemArray containsObject:item])
        {
            [m_resultItemArray addObject:item];
            m_totalSize += [item resultFileSize];
        }
    }
    item.state = self.state;
}

- (NSArray *)resultItemArray
{
    if ([self showAction])
    {
        NSMutableArray * array = [NSMutableArray array];
        for (QMActionItem * subItem in [self m_actionItemArray]){
            NSArray *resultItemArray = [subItem resultItemArray];
            if (resultItemArray != nil) {
                [array addObjectsFromArray:resultItemArray];
            }
        }
        
        return array;
    }
    else
    {
        return m_resultItemArray;
    }
}

-(NSUInteger)scanFileNums{
    NSUInteger fileNum = 0;
    for (QMActionItem * actionItem in [self m_actionItemArray]){
        fileNum += [actionItem scanFileNums];
    }
    
    return fileNum;
}

// 需要显示结果，返回result，否则返回action
- (NSMutableArray *)subItemArray
{
    if (![self showAction])
        return m_resultItemArray;
    return m_actionItemArray;
}

#pragma mark-
#pragma mark 刷新选择状态

- (void)resetItemState {
    if (![self showAction])
        self.m_stateValue = (!recommend ? NSOffState : NSOnState);
    else
    {
        for (QMActionItem * subItem in m_actionItemArray)
        {
            [subItem resetItemState];
        }
        [self refreshStateValue];
    }
}

@end

@interface QMCategoryItem ()

@property (nonatomic, strong) NSRecursiveLock *lock;

@end

@implementation QMCategoryItem
@synthesize categoryID;
@synthesize title;
@synthesize tips;
@synthesize m_categorySubItemArray;
@synthesize recommend;

- (id)init
{
    if (self = [super init])
    {
        _lock = [[NSRecursiveLock alloc] init];
        recommend = YES;
        self.m_stateValue = NSOnState;
        m_resultItemArray = [[NSMutableArray alloc] init];
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone{
    QMCategoryItem *copy = [super copyWithZone:zone];
    if (copy) {
        copy.categoryID = [self.categoryID mutableCopy];
        copy.m_id = self.m_id;
        copy.title = [self.title mutableCopy];
        copy.tips = [self.tips mutableCopy];
        copy.subItems = [[NSArray alloc] initWithArray:self.subItems copyItems:YES];
        copy->m_categorySubItemArray = [[NSMutableArray alloc] initWithArray:m_categorySubItemArray copyItems:YES];
        copy->m_resultItemArray = [[NSMutableArray alloc] init];
        copy.recommend = self.recommend;
        copy.showResult = self.showResult;
        copy.isScanning = self.isScanning;
        copy.showHighlight = self.showHighlight;
        copy.isCleanning = self.isCleanning;
        copy.showHignlightClean = self.showHignlightClean;
    }
    
    return copy;
}

-(id)mutableCopyWithZone:(NSZone *)zone{
    QMCategoryItem *copy = [super mutableCopyWithZone:zone];
    if (copy) {
        copy.categoryID = [self.categoryID mutableCopy];
        copy.m_id = self.m_id;
        copy.title = [self.title mutableCopy];
        copy.tips = [self.tips mutableCopy];
        copy.subItems = [[NSArray alloc] initWithArray:self.subItems copyItems:YES];
        copy->m_categorySubItemArray = [[NSMutableArray alloc] initWithArray:m_categorySubItemArray copyItems:YES];
        copy->m_resultItemArray = [[NSMutableArray alloc] init];
        copy.recommend = self.recommend;
        copy.showResult = self.showResult;
        copy.isScanning = self.isScanning;
        copy.showHighlight = self.showHighlight;
        copy.isCleanning = self.isCleanning;
        copy.showHignlightClean = self.showHignlightClean;
    }
    
    return copy;
}

// 结果大小
- (NSUInteger)resultFileSize
{
    if (m_resultItemArray.count > 0)
        return m_totalSize;
    else
    {
        NSUInteger size = 0;
        for (QMCategorySubItem * subItem in m_categorySubItemArray)
        {
            size += subItem.resultFileSize;
        }
        return size;
    }
}

#pragma mark-
#pragma mark 初始化XML

- (void)addSubCategoryItem:(QMCategorySubItem *)subItem
{
    if (!m_categorySubItemArray)    m_categorySubItemArray = [[NSMutableArray alloc] init];
    [m_categorySubItemArray addObject:subItem];
}

- (void)setRecommend:(BOOL)value
{
    recommend = value;
    self.m_stateValue = (recommend ? NSOnState : NSOffState);
}

- (void)addResultItem:(QMResultItem *)item
{
    if (![m_resultItemArray containsObject:item])
    {
        [m_resultItemArray addObject:item];
        m_totalSize += [item resultFileSize];
    }
    item.state = self.state;
}

#pragma mark-
#pragma 结果显示

// 只有一项，直接显示结果
- (BOOL)showResult
{
    return [[self m_categorySubItemArray] count] == 0;
}

// 需要显示结果，返回result，否则返回action
- (NSMutableArray *)subItemArray
{
    if ([self showResult])
        return m_resultItemArray;
    return m_categorySubItemArray;
}

- (NSArray *)resultItemArray
{
    if ([self showResult])
    {
        return m_resultItemArray;
    }
    else
    {
        NSMutableArray * array = [NSMutableArray array];
        for (QMCategorySubItem * subItem in m_categorySubItemArray){
            if ([subItem resultItemArray] != nil) {
                [array addObjectsFromArray:[subItem resultItemArray]];
            }
        }
        return array;
    }
}

-(NSUInteger)scanFileNums{
    NSUInteger fileNum = 0;
    for (QMCategorySubItem * subItem in m_categorySubItemArray){
        fileNum += [subItem scanFileNums];
    }
    
    return fileNum;
}

#pragma mark-
#pragma mark 选择状态刷新

- (void)resetItemScanState
{
    if (recommend)
        self.m_stateValue = NSOnState;
    if (![self showResult])
    {
        for (QMCategorySubItem * subItem in m_categorySubItemArray)
            [subItem resetItemState];
        [self refreshStateValue];
    }
}

//

- (void)sortItemArray:(NSMutableArray *)result
{
    if (!result || [result count] == 0)
        return;
    [result sortUsingComparator:^NSComparisonResult(QMResultItem * item1, QMResultItem * item2) {
        NSUInteger size1 = [item1 resultFileSize];
        NSUInteger size2 = [item2 resultFileSize];
        if (size1 > size2)
            return NSOrderedAscending;
        else if (size1 < size2)
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
    for (QMResultItem * resultItem in result)
    {
        NSMutableArray * array = (NSMutableArray*)[resultItem subItemArray];
        if (array)
            [self sortItemArray:array];
    }
}
- (void)sortResultItem
{
    if ([self showResult])
    {
        [self sortItemArray:m_resultItemArray];
    }
    else
    {
        for (QMCategorySubItem * subItem in m_categorySubItemArray)
            [self sortItemArray:(NSMutableArray *)[subItem resultItemArray]];
    }

}
- (void)refreshResultSize
{
    uint64 size = 0;
    NSArray * array = [self resultItemArray];
    for (int i = 0; i < [array count]; i++)
    {
        QMResultItem * item = [array objectAtIndex:i];
        size += [item resultFileSize];
    }
    m_totalSize = size;
}

-(NSUInteger)getCleanFileNums{
    NSUInteger cleanFileNum = 0;
    NSUInteger size = 0;
    NSArray *resultItemArr = [self removeSelectedResultItem:&size];
    if (resultItemArr) {
        for (QMResultItem *resultItem in resultItemArr) {
            NSArray *filePaths = [[resultItem resultPath] allObjects];
            cleanFileNum += [filePaths count];
        }
    }
    
    return cleanFileNum;
}

#pragma mark - setter or getter

- (NSArray *)m_categorySubItemArray {
    [_lock lock];
    NSArray *array = [m_categorySubItemArray copy];
    [_lock unlock];
    return array;
}

- (void)setM_categorySubItemArray:(NSArray *)array {
    [_lock lock];
    m_categorySubItemArray = array.mutableCopy;
    [_lock unlock];
}

@end
