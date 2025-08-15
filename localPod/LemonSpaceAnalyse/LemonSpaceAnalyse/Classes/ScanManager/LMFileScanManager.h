//
//  LMFileScanManager.h
//  Lemon
//
//  
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMFileScanTask.h"

@class LMItem;

@protocol LMFileScanManagerDelegate <NSObject>

- (void)progressRate:(float)value progressStr:(NSString *)path;
- (void)end;

@end

@interface LMFileScanManager : NSObject

@property(nonatomic, weak) id<LMFileScanManagerDelegate> delegate;
@property(nonatomic, strong) LMItem *topItem;
@property (nonatomic, assign) BOOL isCancel;
@property (nonatomic, assign) BOOL isFinish;
@property (nonatomic, assign) BOOL skipICloudFiles; // 是否跳过iCloud未下载文件
@property (nonatomic, copy) NSSet<NSString *> *specialFileExtensions; // 尝试将如下后缀文件夹当作文件处理

- (void)startWithRootPath:(NSString *)path;
- (void)cancel;
@end

