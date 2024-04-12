//
//  QMDuplicateItemManager.h
//  QMDuplicateFile
//
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMDuplicateBatch.h"
#import <QMCoreFunction/QMFileClassification.h>

@protocol QMDuplicateItemManagerDelegate <NSObject>

- (void)cleanDuplicateItemBegin;
- (void)cleanDuplicateItem:(NSString *)path currentIndex:(NSInteger)index totalItemCounts:(NSInteger)total;
- (void)cleanDuplicateItemEnd:(uint64)cleanSize;

@end

@interface QMDuplicateItemManager : NSObject

@property (nonatomic, weak) id<QMDuplicateItemManagerDelegate> delegate;

// 正在清理
@property (nonatomic, assign, readonly) BOOL isCleaning;

- (void)removeAllResult;
- (void)addDuplicateItem:(NSArray *)pathArray fileSize:(uint64)size;

- (NSArray *)duplicateArrayWithType:(QMFileTypeEnum)type;
- (NSArray *)resultKindsArray;

- (void)cancelAllSelectedResult;

- (void)removeDuplicateItem:(NSArray *)itemArray toTrash:(BOOL)toTrash;

- (uint64)duplicateResultSize;

+ (NSInteger)autoSelectedResult:(NSArray *)itemArray;

// 取消清理
- (void)cancelCleaning;


@end
