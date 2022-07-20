//
//  LemonVCModel.m
//  Lemon
//

//  Copyright © 2021 Tencent. All rights reserved.
//

#import "LemonVCModel.h"

@implementation LemonVCModel

- (instancetype)init{
    self = [super init];
    if (self) {
        _toolConMap = [NSMutableDictionary dictionary];
    }
    return self;
}

+(LemonVCModel *)shareInstance{
    static LemonVCModel *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[LemonVCModel alloc] init];
    });
    
    return shareInstance;
}

@end
