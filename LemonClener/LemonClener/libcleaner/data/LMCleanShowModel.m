//
//  LMCleanShowModel.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMCleanShowModel.h"
#import "DeamonTimeHelper.h"

@implementation LMCleanShowModel

-(id)initWithDateTime:(NSString *)dateTime{
    self = [super init];
    if (self) {
        self.totalSize = 0;
        self.systemJunkSize = 0;
        self.appJunkSize = 0;
        self.internetJunkSize = 0;
        self.dateTime = dateTime;
    }
    
    return self;
}

-(id)initTotalSize:(long long) totalSize sysJunkModel:(long long)systemJunkSize appJunkModel:(long long)appJunkSize interJunkModel:(long long)internetJunkSize dateTime:(NSString *) dateTime{
    self = [super init];
    if(self){
        self.totalSize = totalSize;
        self.systemJunkSize = systemJunkSize;
        self.appJunkSize = appJunkSize;
        self.internetJunkSize = internetJunkSize;
        self.dateTime = dateTime;
    }
    
    return self;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"totalSize = [%lld], systemJunkModel = [%lld], appJunkModel = [%lld], internetJunkModel = [%lld], dateTime = [%@]", self.totalSize, self.systemJunkSize, self.appJunkSize, self.internetJunkSize, self.dateTime];
}

@end
