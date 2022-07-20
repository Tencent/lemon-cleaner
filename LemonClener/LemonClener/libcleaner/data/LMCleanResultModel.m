//
//  LMCleanResultModel.m
//  TestFMDB
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMCleanResultModel.h"

@implementation LMCleanResultModel

-(id)initWithCreateTime:(long long) createTime{
    self = [super init];
    if (self) {
        self.resultId = 0;
        self.totalSize = 0;
        self.sysSize = 0;
        self.appSize = 0;
        self.intSize = 0;
        self.cleanType = CleanResultTypeRemove;
        self.fileNum = 0;
        self.oprateTime = 0;
        self.createTime = createTime;
    }
    
    return self;
}

-(id)initWithResultId:(NSInteger) resultId totalSize:(long long) totalSize sysSize:(long long)sysSize appSize:(long long)appSize intSize:(long long)intSize cleanType:(CleanResultType) cleanType fileNum:(NSUInteger) fileNum oprateTime:(long long)oprateTime createTime:(long long) createTime{
    self = [super init];
    if(self){
        self.resultId = resultId;
        self.totalSize = totalSize;
        self.sysSize = sysSize;
        self.appSize = appSize;
        self.intSize = intSize;
        self.cleanType = cleanType;
        self.fileNum = fileNum;
        self.oprateTime = oprateTime;
        self.createTime = createTime;
    }
    
    return self;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"resultId = [%ld], totalSize = [%lld], sysSize = [%lld], appSize = [%lld], intSize = [%lld], cleanType = [%u], fileNum = [%ld], oprateTime = [%lld,] createTime = [%lld]", self.resultId, self.totalSize, self.sysSize, self.appSize, self.intSize, self.cleanType, self.fileNum, self.oprateTime, self.createTime];
}

@end
