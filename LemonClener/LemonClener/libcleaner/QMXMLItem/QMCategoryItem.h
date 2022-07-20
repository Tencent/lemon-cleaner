//
//  QMCategoryItem.h
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMActionItem.h"
#import "QMResultItem.h"
#import "QMBaseItem.h"

// 清理字项
@interface QMCategorySubItem : QMBaseItem<NSCopying, NSMutableCopying>
{
    NSMutableArray * m_actionItemArray;
    NSMutableArray * m_resultItemArray;
}
@property (nonatomic, strong) NSString * subCategoryID;
//对应软件的bundleid 用来判断用户是否安装该软件
@property (nonatomic, strong) NSString *bundleId;
//如果是appstore上架的版本
@property (nonatomic, strong) NSString *appStoreBundleId;
// 是否推荐，默认为YES
@property (nonatomic, assign) BOOL recommend;
//默认选中样式（只当showaction=yes时候起作用）
@property (nonatomic, assign) NSCellStateValue defaultState;
//是否需要显示谨慎清理字样提示用户
@property (nonatomic, assign) BOOL isCautious;

@property (nonatomic, assign) BOOL showAction;//是否需要显示action子项

@property (nonatomic, assign) BOOL fastMode;

// 清理项标题
@property (nonatomic, strong) NSString * title;
// 清理项小提示
@property (nonatomic, strong) NSString * tips;
// 清理行为
@property (nonatomic, strong) NSArray * m_actionItemArray;
// 是否正在扫描
@property (nonatomic, assign) BOOL isScanning;
//是否已经扫描过
@property (nonatomic, assign) BOOL isScaned;
//是否正在清理
@property (nonatomic, assign) BOOL isCleanning;

- (void)refreshResultSize;
- (void)addActionItem:(QMActionItem *)item;
- (void)addResultItem:(QMResultItem *)item;
- (void)sortResultItem;
@end

// 清理大项
@interface QMCategoryItem : QMBaseItem<NSCopying, NSMutableCopying>
{
    NSMutableArray * m_categorySubItemArray;
    NSMutableArray * m_resultItemArray;
}

@property (nonatomic, strong) NSString * categoryID;

// 唯一ID
@property (nonatomic, assign) int m_id;
// 清理项标题
@property (nonatomic, strong) NSString * title;
// 清理项小提示
@property (nonatomic, strong) NSString * tips;
// 子项
@property (nonatomic, strong) NSArray * subItems;
// 清理小项
@property (nonatomic, strong) NSArray * m_categorySubItemArray;
// 是否推荐，默认为YES
@property (nonatomic, assign) BOOL recommend;
// 显示结果
@property (nonatomic, assign) BOOL showResult;
// 是否正在扫描
@property (nonatomic, assign) BOOL isScanning;
//是否显示高亮状态
@property (nonatomic, assign) BOOL showHighlight;
//是否正在清理
@property (nonatomic, assign) BOOL isCleanning;
//是否在清理时候显示高亮状态
@property (nonatomic, assign) BOOL showHignlightClean;

- (void)resetItemScanState;

- (void)addSubCategoryItem:(QMCategorySubItem *)subItem;

- (void)addResultItem:(QMResultItem *)item;

- (BOOL)showResult;

- (void)sortResultItem;

- (void)refreshResultSize;

-(NSUInteger)getCleanFileNums;

@end
