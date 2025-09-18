//
//  LMFileScanTask.h
//  Lemon
//
//  
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LMItem;

typedef void(^LMFileScanTaskBlock)(LMItem*);

@protocol LMFileScanTaskDelegate <NSObject>

- (void)fileScanTaskFinishOneFile:(long long)size;

@end


@interface LMFileScanTask : NSObject

@property(retain, nonatomic) LMItem *dirItem;
@property (nonatomic, weak) id<LMFileScanTaskDelegate> delegate;
@property (nonatomic, assign) BOOL skipICloudFiles; // 是否跳过iCloud未下载文件
@property (nonatomic, copy) NSSet<NSString *> *specialFileExtensions; // 尝试将如下后缀文件夹当作文件处理

- (id)initWithRootDirItem:(LMItem *)dirItem;
-(void)starTaskWithBlock:(LMFileScanTaskBlock)block;
-(void)cancel;

@end

