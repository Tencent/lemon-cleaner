//
//  QMFileScanManager.h
//  FileCleanDemo
//
//  
//  Copyright (c) 2014年 yuanwen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "McDuplicateFilesDelegate.h"

//@class QMDuplicateFiles

extern const float kDuplicateMaxSearchProgress;

// 文件扫描后的对象
@interface QMFileItem : NSObject {
    NSMutableArray *_childrenItemArray;
}

@property(nonatomic, assign) UInt64 fileSize;
@property(nonatomic, assign) BOOL isDir;
@property(nonatomic, retain) NSString *filePath;
@property(nonatomic, weak) QMFileItem *parentItem;
@property(nonatomic, retain) NSMutableSet *equalItem;
@property(nonatomic, retain) NSString *hashStr;

- (void)addChildrenItem:(QMFileItem *)item;

- (NSArray *)childrenItemArray;

@end

@protocol QMFileScanManagerDelegate <NSObject>

- (BOOL)scanFileItemProgress:(QMFileItem *)item progress:(CGFloat)value scanPath:(NSString *)path;

- (void)scanFileItemDidEnd:(BOOL)userCancel;

@end

@interface QMDuplicateFileScanManager : NSObject


- (void)listPathContent:(NSArray *)paths
               delegate:(id <QMFileScanManagerDelegate>)managerDelegate;

- (NSArray *)protectedFolderArray;

+ (uint64)calculateSize:(NSString *)path delegate:(id<McDuplicateFilesDelegate>) showDelegate;

+ (NSArray *)systemProtectPath;

@end
