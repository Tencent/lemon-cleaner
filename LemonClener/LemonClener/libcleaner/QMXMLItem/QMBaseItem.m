//
//  QMBaseItem.m
//  libcleaner
//

//  Copyright (c) 2013年 Magican Software Ltd. All rights reserved.
//

#import "QMBaseItem.h"
#import "QMResultItem.h"
#import "QMCategoryItem.h"
#import "QMCleanUtils.h"

@implementation QMBaseItem
@synthesize progressValue;
@synthesize state;

-(id)copyWithZone:(NSZone *)zone{
    QMBaseItem *copy = [[[self class] alloc] init];
    if (copy) {
        copy.progressValue = self.progressValue;
        copy.state = self.state;
        copy->m_totalSize = self->m_totalSize;
        copy->_m_stateValue = self->_m_stateValue;
    }
    
    return copy;
}

-(id)mutableCopyWithZone:(NSZone *)zone{
    QMBaseItem *copy = [[[self class] alloc] init];
    if (copy) {
        copy.progressValue = self.progressValue;
        copy.state = self.state;
        copy->m_totalSize = self->m_totalSize;
        copy->_m_stateValue = self->_m_stateValue;
    }
    
    return copy;
}

// 检查系统版本
- (BOOL)checkVersion:(NSString *)curSysVersion
{
    BOOL retValue = NO;
    NSString * regexStr = self.os;
    if (regexStr
        && ![@"" isEqualToString:regexStr])
    {
        retValue = [QMCleanUtils assertRegex:regexStr matchStr:curSysVersion];
        if (!retValue)  return NO;
        
    }
    return YES;
}

- (NSArray *)resultItemArray
{
    return [self subItemArray];
}
- (NSMutableArray *)subItemArray
{
    return nil;
}
- (void)removeAllResultItem
{
    // 清空上次的直
    progressValue = 0;
    m_totalSize = 0;
    NSMutableArray * array = [self subItemArray];
    if ([self isKindOfClass:[QMCategoryItem class]])
    {
        if ([[(QMCategoryItem *)self m_categorySubItemArray] count] >= 1)
        {
            for (QMCategorySubItem * subItem in array)
                [subItem removeAllResultItem];
        }
        else
        {            
            [array removeAllObjects];
        }
    }
    else if ([self isKindOfClass:[QMCategorySubItem class]])
    {
         if ([(QMCategorySubItem *)self showAction])
         {
             for (QMActionItem * actionItem in array)
                 [actionItem removeAllResultItem];
         }
        else
        {
            [array removeAllObjects];
        }
    }
    else if ([self isKindOfClass:[QMActionItem class]])
    {
        [array removeAllObjects];
    }
}

- (NSArray *)removeSelectedResultItem:(NSUInteger *)size
{
    NSMutableArray * retArray = [NSMutableArray array];
    if (_m_stateValue == NSOnState) {
        // 全部选中
        *size += [self resultFileSize];
        NSArray * resultArray = [self resultItemArray];
        if ([resultArray count] > 0)
        {
            for (QMResultItem * resultItem in resultArray)
            {
                if ([[resultItem subItemArray] count] > 0)
                {
                    [retArray addObjectsFromArray:[resultItem subItemArray]];
                }
                else
                {
                    [retArray addObject:resultItem];
                }
            }
            
            [self removeAllResultItem];
        }
    }
    else
    {
        // 部分选中
        NSMutableArray * array = [self subItemArray];
        // 如果是QMesultItem，并且没有子项，不用递归
        BOOL isResultItem = NO;
        if ([array count] > 0)
        {
            QMBaseItem * baseItem = [array lastObject];
            if ([baseItem isKindOfClass:[QMResultItem class]])
                isResultItem = YES;
        }
        NSMutableArray * removeArray = [NSMutableArray array];
        for (QMBaseItem * baseItem in array)
        {
            if (isResultItem && [baseItem state] == NSOnState)
            {
                *size += [baseItem resultFileSize];
                if ([[baseItem subItemArray] count] == 0)
                {
                    [retArray addObject:baseItem];
                }
                else
                {
                    [retArray addObjectsFromArray:[baseItem subItemArray]];
                }
                [removeArray addObject:baseItem];
            }
            else
            {
                NSArray * array = [baseItem removeSelectedResultItem:size];//递归拿到所有的resultItem
                [retArray addObjectsFromArray:array];
                [removeArray addObjectsFromArray:array];
            }
        }
        // 如果是QMesultItem，并且没有子项，因为没有选中，直接移除结果
        if (isResultItem)
            [array removeObjectsInArray:removeArray];
    }
    return retArray;
}


- (NSArray *)getSelectedResultItem:(NSUInteger *)size
{
    NSMutableArray * retArray = [NSMutableArray array];
    if (_m_stateValue == NSOnState) {
        // 全部选中
        *size += [self resultFileSize];
        NSArray * resultArray = [self resultItemArray];
        if ([resultArray count] > 0)
        {
            for (QMResultItem * resultItem in resultArray)
            {
                if ([[resultItem subItemArray] count] > 0)
                {
                    [retArray addObjectsFromArray:[resultItem subItemArray]];
                }
                else
                {
                    [retArray addObject:resultItem];
                }
            }
        }
    }
    else
    {
        // 部分选中
        NSMutableArray * array = [self subItemArray];
        // 如果是QMesultItem，并且没有子项，不用递归
        BOOL isResultItem = NO;
        if ([array count] > 0)
        {
            QMBaseItem * baseItem = [array lastObject];
            if ([baseItem isKindOfClass:[QMResultItem class]])
                isResultItem = YES;
        }
//        NSMutableArray * removeArray = [NSMutableArray array];
        for (QMBaseItem * baseItem in array)
        {
            if (isResultItem && [baseItem state] == NSOnState)
            {
                *size += [baseItem resultFileSize];
                if ([[baseItem subItemArray] count] == 0)
                {
                    [retArray addObject:baseItem];
                }
                else
                {
                    [retArray addObjectsFromArray:[baseItem subItemArray]];
                }
            }
            else
            {
                NSArray * array = [baseItem getSelectedResultItem:size];//递归拿到所有的resultItem
                [retArray addObjectsFromArray:array];
            }
        }
    }
    return retArray;
}

#pragma mark-
#pragma mark 结果大小


- (NSUInteger)resultSelectedCount:(uint64 *)size
{
    NSUInteger selectedCount = 0;
    if (_m_stateValue == NSOnState) {
        // 全部选中
        *size += [self resultFileSize];
        NSArray * resultArray = [self resultItemArray];
        if ([resultArray count] > 0)
        {
            for (QMResultItem * resultItem in resultArray)
            {
                if ([[resultItem subItemArray] count] > 0)
                {
                    selectedCount += [[resultItem subItemArray] count];
                }
                else
                {
                    selectedCount++;
                }
            }
        }
    }
    else
    {
        // 部分选中
        NSMutableArray * array = [self subItemArray];
        // 如果是QMesultItem，并且没有子项，不用递归
        BOOL isResultItem = NO;
        if ([array count] > 0)
        {
            QMBaseItem * baseItem = [array lastObject];
            if ([baseItem isKindOfClass:[QMResultItem class]])
                isResultItem = YES;
        }
        NSMutableArray * removeArray = [NSMutableArray array];
        for (QMBaseItem * baseItem in array)
        {
            if (isResultItem && [baseItem state] == NSOnState)
            {
                *size += [baseItem resultFileSize];
                if ([[baseItem subItemArray] count] == 0)
                {
                    selectedCount++;
                }
                else
                {
                    selectedCount += [baseItem subItemArray].count;
                }
                [removeArray addObject:baseItem];
            }
            else
            {
                selectedCount += [baseItem resultSelectedCount:size];
            }
        }
    }
    return selectedCount;
}

- (NSUInteger)resultFileSize
{
//    m_totalSize = 0;
//    NSArray * array = [self resultItemArray];
//    for (int i = 0; i < [array count]; i++)
//    {
//        QMResultItem * item = [array objectAtIndex:i];
//        m_totalSize += [item resultFileSize];
//    }
    return m_totalSize;
}
- (NSUInteger)resultSelectedFileSize
{
    if (_m_stateValue == NSOnState)
        return [self resultFileSize];
    if (_m_stateValue == NSOffState)
        return 0;
    NSUInteger retTotalSize = 0;
    NSArray * array = [self resultItemArray];
    for (int i = 0; i < [array count]; i++)
    {
        QMResultItem * item = [array objectAtIndex:i];
        retTotalSize += [item resultSelectedFileSize];
    }
    return retTotalSize;
}

//扫描的数量
-(NSUInteger)scanFileNums{
    return 0;
}

#pragma mark-
#pragma mark 选择状态

- (void)setState:(NSCellStateValue)stateValue
{
    // 过滤相同值，以及mixed状态
//    if (m_stateValue == stateValue)
//        return;
    _m_stateValue = stateValue;
    if (_m_stateValue == NSMixedState)
        return;
    NSMutableArray * array = [self subItemArray];
    
    if ([self isKindOfClass:[QMCategoryItem class]])
    {
        // 有子项分类
        for (QMBaseItem * subItem in array)
            [subItem setState:_m_stateValue];
    }
    else if ([self isKindOfClass:[QMCategorySubItem class]])
    {
        if ([(QMCategorySubItem *)self showAction])
        {
            // 根据action刷新
            for (QMActionItem * subItem in array){
                if (_m_stateValue == NSOffState) {
                    [subItem setState:NSOffState];
                }else{
                    //NOTE:之前点击一级框，默认智能勾选，改为全选。
                    NSCellStateValue stateValue = NSOnState;//subItem.recommend ? NSOnState : NSOffState;
                    [subItem setState:stateValue];
                }
                
            }
        }
        else
        {
            // 根据结果刷新
            for (QMResultItem * subItem in [self resultItemArray])
                [subItem setState:_m_stateValue];
        }
    }
    else if ([self isKindOfClass:[QMActionItem class]])
    {
        for (QMResultItem * subItem in [self resultItemArray])
            [subItem setState:_m_stateValue];
    }
    else
    {
        for (QMResultItem * subItem in [self subItemArray])
            [subItem setState:_m_stateValue];
    }
}

- (NSCellStateValue)state
{
    return _m_stateValue;
}

- (void)refreshStateValue
{
    int checkOnFlags = 0;
    int checkMixFlags = 0;
    NSUInteger totalSubCount = 0;
    NSMutableArray * array = [self subItemArray];
    if ([self isKindOfClass:[QMCategoryItem class]])
    {
        if ([(QMCategoryItem *)self showResult])
        {
            // 没有子项，根据结果刷新
            for (QMResultItem * subItem in [self resultItemArray])
            {
                if (subItem.state == NSOnState)
                    checkOnFlags++;
                else if (subItem.state == NSMixedState)
                    checkMixFlags++;
            }
            totalSubCount = [[self resultItemArray] count];
        }
        else
        {
            // 有子项分类
            for (QMCategorySubItem * subItem in array)
            {
                if (subItem.state == NSOnState)
                    checkOnFlags++;
                else if (subItem.state == NSMixedState)
                    checkMixFlags++;
            }
            totalSubCount = [array count];
        }
        
    }
    else if ([self isKindOfClass:[QMCategorySubItem class]])
    {
        if ([(QMCategorySubItem *)self showAction])
        {
            // 根据行为刷新
            for (QMActionItem * subItem in array)
            {
                if (subItem.state == NSOnState)
                    checkOnFlags++;
                else if (subItem.state == NSMixedState)
                    checkMixFlags++;
            }
            totalSubCount = [array count];
        }
        else
        {
            // 根据结果刷新
            for (QMResultItem * subItem in [self resultItemArray])
            {
                if (subItem.state == NSOnState)
                    checkOnFlags++;
                else if (subItem.state == NSMixedState)
                    checkMixFlags++;
            }
            totalSubCount = [[self resultItemArray] count];
        }
    }
    else if ([self isKindOfClass:[QMResultItem class]] || [self isKindOfClass:[QMActionItem class]])
    {
        if ([array count] == 0)
            return;
        // 有子项分类
        for (QMResultItem * subItem in array)
        {
            if (subItem.state == NSOnState)
                checkOnFlags++;
            else if (subItem.state == NSMixedState)
                checkMixFlags++;
        }
        totalSubCount = [array count];
    }
    if (totalSubCount == 0)
    {
        _m_stateValue = (_m_stateValue != NSOffState ? NSOnState :NSOffState);
    }
    else
    {
        if (checkOnFlags == totalSubCount)
            _m_stateValue = NSOnState;
        else if (checkOnFlags == 0 && checkMixFlags ==0)
            _m_stateValue = NSOffState;
        else
            _m_stateValue = NSMixedState;
    }
}


- (NSString *)itemID
{
    if ([self isKindOfClass:[QMCategoryItem class]])
        return [(QMCategoryItem *)self categoryID];
    if ([self isKindOfClass:[QMCategorySubItem class]])
        return [(QMCategorySubItem *)self subCategoryID];
    return nil;
}

@end
