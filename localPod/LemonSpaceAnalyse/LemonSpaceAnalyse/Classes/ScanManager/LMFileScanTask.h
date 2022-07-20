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

- (id)initWithRootDirItem:(LMItem *)dirItem;
-(void)starTaskWithBlock:(LMFileScanTaskBlock)block;

@end

