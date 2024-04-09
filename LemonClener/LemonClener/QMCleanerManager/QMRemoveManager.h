//
//  QMRemoveManager.h
//  QMCleaner
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMCategoryItem.h"
#import "QMWarnReultItem.h"
#import "QMCleanerDefine.h"

@protocol QMRemoveManagerDelegate <NSObject>

- (void)cleanCategoryStart:(NSString *)categoryId;
- (void)cleanCategoryEnd:(NSString *)categoryId;
- (void)cleanProgressInfo:(float)value categoryKey:(NSString *)key path:(NSString *)path totalSize:(NSUInteger)totalSize;
- (void)cleanResultDidEnd:(NSUInteger)totalSize leftSize:(NSUInteger)leftSize;
- (void)cleanSubCategoryStart:(NSString *)subCategoryID;
- (void)cleanSubCategoryEnd:(NSString *)subCategoryID;
- (void)cleanFileNums:(NSUInteger) cleanFileNums;
- (BOOL)checkWarnItemAtPath:(QMResultItem *)resultItem bundleID:(NSString **)bundle appName:(NSString **)name;

@end

@protocol QMCleanWarnItemDelegate <NSObject>

- (void)startRemoveWarnItem:(QMWarnReultItem *)resultItem;
- (void)removeWarnItemEnd:(QMWarnReultItem *)resultItem;

@end

@interface QMRemoveManager : NSObject
{
    NSMutableDictionary * m_warnResultItemDict;
    
//    NSDictionary * m_categoryDict;
    NSMutableDictionary * m_curRemoveSizeDict;
    UInt64 _removeAllSize;
}
@property (nonatomic, weak) id<QMRemoveManagerDelegate> delegate;
@property (nonatomic, weak) id<QMCleanWarnItemDelegate> warnItemDelegate;
@property (nonatomic, assign) NSUInteger cleanFileNums;//清理的文件数量

+ (QMRemoveManager *)getInstance;

- (BOOL)startCleaner:(NSDictionary *)categoryDict actionSource:(QMCleanerActionSource)source;

- (NSArray *)warnResultItemArray;
- (BOOL)canRemoveWarnItem;
- (BOOL)cleanWarnResultItem:(QMWarnReultItem *)warnItem;

- (void)removeWarnItem;

@end
