//
//  QMLargeOldManager.h
//  QMBigOldFile
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QMCoreFunction/QMFileClassification.h>

#ifndef kDayTime
#define kDayTime        24*60*60.0
#endif

typedef enum
{
    QMAnyTime = 0,
    QMWeekTime,
    QMTwoWeekTime,
    QMMothTime,
    QMTwoMothTime,
    QMThreeMothTime,
    QMSixMothTime,
    QMYearTime,
    QMTwoYearTime,
}QMAccessTimeEnum;

typedef enum
{
    QMResultOrderSize = 0,
    QMResultOrderAccessTime,
    QMResultOrderFileName,
    QMResultOrderKind,
    QMResultOrderFilePath,
}QMResultOrderEnum;

@interface QMLargeOldResultItem : NSObject

@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, assign) UInt64 fileSize;
@property (nonatomic, retain) NSImage * iconImage;
@property (nonatomic, assign) NSTimeInterval lastAccessTime;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) QMFileTypeEnum fileType;

@end

@interface QMLargeOldResultRoot : NSObject
{
    NSMutableArray * _subItem;
}
@property (nonatomic, assign) UInt64 minSize;
@property (nonatomic, assign) UInt64 maxSize;
@property (nonatomic, assign) UInt64 totalSize;
@property (nonatomic, assign) QMAccessTimeEnum accessTimeEnum;
@property (nonatomic, retain) NSString * typeName;
@property (nonatomic, retain) NSArray * subItemArray;

- (void)addSubItem:(QMLargeOldResultItem *)item;
- (void)sortedSubItem:(QMResultOrderEnum)orderType;

@end

@interface QMLargeOldManager : NSObject

+ (instancetype)sharedManager;
+ (void)destroyManager;


- (void)addLargeOldItem:(NSString *)path
               fileSize:(UInt64)size
             accessTime:(NSTimeInterval)accessTime;


- (void)resultWithFilter:(QMFileTypeEnum)type
                   order:(QMResultOrderEnum)orderType
                   block:(void(^)(NSArray *, NSArray *))block;

- (NSArray *)needRemoveItem;
- (NSArray *)resultItemArray;
- (void)removeAllResult;

- (void)stopRemove;

- (NSTimeInterval)resultItemMinAccessTime;
- (uint64)removeResultItem:(NSArray *)itemArray toTrash:(BOOL)toTrash block:(void(^)(float value, NSString* path))block;

- (NSArray *)sizeArray;
- (NSArray *)accessTimeArray;

@end
