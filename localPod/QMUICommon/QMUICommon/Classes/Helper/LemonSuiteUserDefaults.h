//
//  LemonSuiteUserDefaults.h
//  LemonASMonitor
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LemonSuiteUserDefaults : NSObject

+(BOOL) getBool:(NSString *)key;

+(void)putBool:(BOOL )value withKey:(NSString *)key;

+(NSData *) getData:(NSString *)key;

+(void)putData:(NSData *)value withKey:(NSString *)key;

+(NSString *) getString:(NSString *)key;

+(void)putString:(NSString *)value withKey:(NSString *)key;
@end
