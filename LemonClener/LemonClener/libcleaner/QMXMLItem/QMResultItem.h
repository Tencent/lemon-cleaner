//
//  QMResultItem.h
//  QMCleaner
//

//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMBaseItem.h"
#import "QMXMLItemDefine.h"
#import <QMCoreFunction/McCoreFunction.h>


@interface QMResultBrowerItem : QMBaseItem

@property (strong, nonatomic) NSString *itemId;
@property (strong, nonatomic) NSString *key;
@property (assign, nonatomic) NSInteger value;
@property (assign, nonatomic) BOOL isSelect;

@end

@interface QMResultItem : QMBaseItem
{
    NSMutableSet * m_pathSet;
    NSMutableArray * m_subItemArray;
    NSUInteger m_resultFileSize;
}

// 图标
@property (nonatomic, strong) NSImage * iconImage;
// 标题
@property (nonatomic, strong) NSString * title;
// 路径
@property (nonatomic, strong) NSString * path;
@property (nonatomic, strong) NSString * showPath;

@property (nonatomic, strong) NSString * languageKey;

@property (nonatomic, readonly, strong) NSArray * subItemArray;

@property (nonatomic, assign) NSInteger showHierarchyType;

@property (nonatomic, assign) QMCleanType cleanType;

@property (nonatomic, strong) NSString * cautionID;

//app macos二进制的架构
@property (nonatomic, assign) AppBinaryType binaryType;

- (id)initWithPath:(NSString *)rpath;

- (id)initWithLanguageKey:(NSString *)key;

- (void)addResultWithPathArray:(NSArray *)pathArray;
- (void)addResultWithPath:(NSString *)rpath;
//需要提权来获取文件大小
- (void)addResultWithPathByDeamonCalculateSize:(NSString *)rpath;
- (void)addSubResultItem:(QMResultItem *)item;

- (void)setFileSize:(NSUInteger)size;

- (NSSet *)resultPath;



@end
