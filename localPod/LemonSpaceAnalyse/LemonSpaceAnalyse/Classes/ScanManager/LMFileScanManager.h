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

- (void)startWithRootPath:(NSString *)path;
- (void)cancel;
@end

