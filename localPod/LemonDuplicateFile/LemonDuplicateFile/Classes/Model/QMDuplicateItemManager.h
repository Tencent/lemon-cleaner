//
//  QMDuplicateItemManager.h
//  QMDuplicateFile
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMDuplicateBatch.h"
#import <QMCoreFunction/QMFileClassification.h>

@interface QMDuplicateItemManager : NSObject

- (void)removeAllResult;
- (void)addDuplicateItem:(NSArray *)pathArray fileSize:(uint64)size;

- (NSArray *)duplicateArrayWithType:(QMFileTypeEnum)type;
- (NSArray *)resultKindsArray;

- (void)cancelAllSelectedResult;

- (void)removeDuplicateItem:(NSArray *)itemArray toTrash:(BOOL)toTrash block:(void(^)(uint64_t value))block;

- (uint64)duplicateResultSize;

+ (NSInteger)autoSelectedResult:(NSArray *)itemArray;


@end
