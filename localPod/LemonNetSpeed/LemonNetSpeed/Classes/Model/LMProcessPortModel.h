//
//  LMProcessPortModel.h
//  LemonNetSpeed
//
//  
//  Copyright © 2019年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMProcessPortModel : NSObject

@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSImage *appIcon;
@property (nonatomic, strong) NSString *protocol;
@property (nonatomic, strong) NSString *socketType;
@property (nonatomic, strong) NSString *srcIpPort;
@property (nonatomic, strong) NSString *destIpPort;
@property (nonatomic, strong) NSString *connectState;
@property (nonatomic, assign) int pid;

@end
