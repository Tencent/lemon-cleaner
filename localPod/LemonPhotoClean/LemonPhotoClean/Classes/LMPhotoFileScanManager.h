//
//  LMPhotoFileScanManager.h
//  FileCleanDemo
//
//  
//  Copyright (c) 2014年 yuanwen. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const float kMaxSearchProgress;

// 文件扫描后的对象
@interface LMPhotoFileItem : NSObject
{
    NSMutableArray * _childrenItemArray;
}

@property (nonatomic, assign) UInt64 fileSize;
@property (nonatomic, assign) BOOL isDir;
@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, weak) LMPhotoFileItem * parentItem;
@property (nonatomic, retain) NSMutableSet * equalItem;
@property (nonatomic, retain) NSString * hashStr;

- (void)addChildrenItem:(LMPhotoFileItem *)item;
- (NSArray *)childrenItemArray;

@end

@protocol LMPhotoFileScanManagerDelegate <NSObject>

- (BOOL)scanFileItemProgress:(LMPhotoFileItem *)item progress:(CGFloat)value;
- (void)scanFileItemDidEnd:(BOOL)userCancel;

@end

@interface LMPhotoFileScanManager : NSObject

+ (instancetype)sharedManager;

- (void)listPathContent:(NSArray *)paths
           excludeArray:(NSArray *)array
               delegate:(id<LMPhotoFileScanManagerDelegate>)delegate;
- (NSArray *)protectedFolderArray;

+ (uint64)caluactionSize:(NSString *)path;

+ (NSArray *)systemProtectPath;

@end
