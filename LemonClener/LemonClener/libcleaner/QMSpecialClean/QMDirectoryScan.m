//
//  QMDirectoryScan.m
//  QMCleanDemo
//

//

#import "QMDirectoryScan.h"
#import "QMFilterParse.h"
#import "QMActionItem.h"
#import "QMFilterItem.h"
#import "QMCleanUtils.h"
#import "QMResultItem.h"

@implementation QMDirectoryScan
@synthesize delegate;

- (id)init
{
    if (self = [super init])
    {
        //m_CacheDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

// 扫描目录内的文件
- (void)scanActionWithItem:(QMActionItem *)actionItem {
    [self __scanActionWithItem:actionItem];
    [self scanActionCompleted];
}

- (void)__scanActionWithItem:(QMActionItem *)actionItem
{
    QMFilterParse * filterParse = [[QMFilterParse alloc] initFilterDict:[delegate xmlFilterDict]];
    NSArray * pathArray = [filterParse enumeratorAtFilePath:actionItem];//通过扫描规则和过滤规则，返回所有路径
    for (int i = 0; i < [pathArray count]; i++)
    {
        NSString * result = [pathArray objectAtIndex:i];
        
        if (![filterParse filterPathWithFilters:result])
            continue;
        
        // 文件置空类型，判断子目录
        NSMutableArray * resultPathArray = [NSMutableArray array];
        if (actionItem.cleanType == QMCleanTruncate)
        {
            NSArray * subPaths = [QMCleanUtils processDirTruncatePath:result];
            if (subPaths)
            {
                for (NSString * subPath in subPaths)
                {
                    [resultPathArray addObject:subPath];
                }
            }
            else
            {
                [resultPathArray addObject:result];
            }
        }
        else
        {            
            [resultPathArray addObject:result];
        }
        
        if ([resultPathArray count] == 0)
            continue;
        
        QMResultItem * resultItem = nil;
        NSString * fileName = [result lastPathComponent];
        NSString * appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:fileName];
        if (appPath)
        {
            resultItem = [[QMResultItem alloc] initWithPath:appPath];
            resultItem.path = result;
        }
        else
        {
            resultItem = [[QMResultItem alloc] initWithPath:result];
        }
        resultItem.cleanType = actionItem.cleanType;
        
        // 添加结果
        if (resultItem) [resultItem addResultWithPathArray:resultPathArray];
        if ([delegate scanProgressInfo:(i + 1.0) / [pathArray count] scanPath:result resultItem:resultItem])
            break;
    }
}


@end
