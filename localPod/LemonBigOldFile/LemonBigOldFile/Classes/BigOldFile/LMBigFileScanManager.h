//
//  LMBigFileScanManager.h
//  FileCleanDemo
//
//  
//  Copyright (c) 2014年 yuanwen. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const float kMaxSearchProgress;

// 文件扫描后的对象
@interface LMBigFileItem : NSObject
{
    NSMutableArray * _childrenItemArray;
}

@property (nonatomic, assign) UInt64 fileSize;
@property (nonatomic, assign) BOOL isDir;
@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, weak) LMBigFileItem * parentItem;
@property (nonatomic, retain) NSMutableSet * equalItem;
@property (nonatomic, retain) NSString * hashStr;

- (void)addChildrenItem:(LMBigFileItem *)item;
- (NSArray *)childrenItemArray;

@end

@protocol LMBigFileScanManagerDelegate <NSObject>

- (BOOL)scanFileItemProgress:(LMBigFileItem *)item progress:(CGFloat)value scanPath:(NSString *)path;
- (void)scanFileItemDidEnd:(BOOL)userCancel;

@end

@interface LMBigFileScanManager : NSObject

//+ (instancetype)sharedManager;

- (void)listPathContent:(NSArray *)paths
           excludeArray:(NSArray *)array
               delegate:(id<LMBigFileScanManagerDelegate>)delegate;
- (NSArray *)protectedFolderArray;

+ (uint64)caluactionSize:(NSString *)path;

+ (NSArray *)systemProtectPath;

@end
