//
//  RegisterUtil.h
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RegisterUtil : NSObject

+ (NSString *)getRegisterTokenAtLocal;
+ (void)storeRegisteTokenAtLocal:(NSString *)token;
+ (BOOL)equalToOrigin:(NSString *)cryptoToken;
+ (NSString *)cryptoNetworkToken:(NSString *)token;
@end
