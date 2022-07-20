//
//  SharedPrefrenceManager.h
//  Worth
//
//
//  Copyright © 2016年 yangwenjun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SharedPrefrenceManager : NSObject

+(NSString *)getString:(NSString *)key;

+(NSString *)getString:(NSString *)key default:(NSString *)defulString;

+(void) putString:(NSString *)value withKey:(NSString *)key;

+(NSInteger) getInteger:(NSString *)key;

+(void)putInteger:(NSInteger )value withKey:(NSString *)key;

+(BOOL) getBool:(NSString *)key;

+(void)putBool:(BOOL )value withKey:(NSString *)key;

@end
