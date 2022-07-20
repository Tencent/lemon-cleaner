//
//  LMCleanResultModel.h
//  TestFMDB
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    CleanResultTypeScan = 1,
    CleanResultTypeRemove,
} CleanResultType;

@interface LMCleanResultModel : NSObject

@property (nonatomic, assign) NSInteger resultId;
@property (nonatomic, assign) long long totalSize;
@property (nonatomic, assign) long long sysSize;
@property (nonatomic, assign) long long appSize;
@property (nonatomic, assign) long long intSize;
@property (nonatomic, assign) CleanResultType cleanType;
@property (nonatomic, assign) NSUInteger fileNum;
@property (nonatomic, assign) long long oprateTime;
@property (nonatomic, assign) long long createTime;

-(id)initWithCreateTime:(long long) createTime;

-(id)initWithResultId:(NSInteger) resultId totalSize:(long long) totalSize sysSize:(long long)sysSize appSize:(long long)appSize intSize:(long long)intSize cleanType:(CleanResultType) cleanType fileNum:(NSUInteger) fileNum oprateTime:(long long)oprateTime createTime:(long long) createTime;

@end
