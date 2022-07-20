
//
//  QMBaseItem.h
//  libcleaner
//

//  Copyright (c) 2013年 Magican Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QMResultItem;
@interface QMBaseItem : NSObject<NSCopying, NSMutableCopying>
{
    NSUInteger m_totalSize;

}
// 进度信息
@property (nonatomic, assign) float progressValue;
// 选中状态, on 选中， off没选中，mix部分选中
@property (nonatomic, assign) NSCellStateValue state;

@property(nonatomic, assign) NSCellStateValue m_stateValue;

// 扫描结果
- (NSArray *)resultItemArray;
// 移除所有结果
- (void)removeAllResultItem;

- (NSUInteger)resultSelectedCount:(uint64 *)size;

// 结果大小
- (NSUInteger)resultFileSize;
// 选择的结果大小
- (NSUInteger)resultSelectedFileSize;

//扫描的数量
-(NSUInteger)scanFileNums;

// 子项目，必须实现，Category子项目SubCategory...必须是NSMutable格式
- (NSMutableArray *)subItemArray;
// 刷新state
- (void)refreshStateValue;

- (NSArray *)removeSelectedResultItem:(NSUInteger *)size;

- (NSArray *)getSelectedResultItem:(NSUInteger *)size;

- (NSString *)itemID;

@end
