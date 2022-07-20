//
//  LMCleanShowModel.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMCleanResultModel.h"

@interface LMCleanShowModel : NSObject

@property (nonatomic, assign) long long totalSize;
@property (nonatomic, assign) long long systemJunkSize;
@property (nonatomic, assign) long long appJunkSize;
@property (nonatomic, assign) long long internetJunkSize;
@property (nonatomic, strong) NSString *dateTime;

-(id)initWithDateTime:(NSString *)dateTime;

-(id)initTotalSize:(long long) totalSize sysJunkModel:(long long)systemJunkSize appJunkModel:(long long)appJunkSize interJunkModel:(long long)internetJunkSize dateTime:(NSString *) dateTime;

@end
