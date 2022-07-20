//
//  PathSelectViewController.h
//  PathSelect
//
//  
//  Copyright © 2019 xuanqi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QMBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN


@protocol LMFolderSelectorDelegate <NSObject>

- (NSArray *)duplicateViewAllowFilePaths:(NSArray *)filePaths;

- (void)duplicateChoosePathChanged:(NSString *)path isRemove:(BOOL)remove;

- (void)removeAllChoosePath;

- (void)addFolderAction;  // TODO: Fix spell error
- (void)cancelAddAction;

@end


@interface PathSelectViewController : QMBaseViewController

@property(nonatomic) NSString *addTips;  //  add 按钮的提示语

@property(assign) id <LMFolderSelectorDelegate> delegate;

/**
 标识应用场景 1:相似照片；2:重复文件
 */
@property int sourceType;

/**
 获取选择的路径
 
 @return 文件路径
 */
- (NSArray *)getChoosePaths;

/**
 添加单个路径
 
 @param path 路径
 */
- (void)addFilePathToView:(NSString *)path;

/**
 添加路径可以是单个路径也可以是数组
 
 @param sender string or array
 @return 是否添加成功
 */
- (BOOL)addFilePath:(id)sender;


@end

NS_ASSUME_NONNULL_END
