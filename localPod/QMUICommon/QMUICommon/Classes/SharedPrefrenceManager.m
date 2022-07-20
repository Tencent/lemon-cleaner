//
//  SharedPrefrenceManager.m
//  Worth
//
//  
//  Copyright © 2016年 yangwenjun. All rights reserved.
//

#import "SharedPrefrenceManager.h"

@implementation SharedPrefrenceManager

+(NSUserDefaults *)getUserDefaults{
    return [NSUserDefaults standardUserDefaults];
}

+(NSString *)getString:(NSString *)key{
    NSUserDefaults *defaults = [self getUserDefaults];
    return [defaults stringForKey:key];
}

+(NSString *)getString:(NSString *)key default:(NSString *)defulString{
    NSUserDefaults *defaults = [self getUserDefaults];
    return [defaults stringForKey:key].length == 0 ? defulString : [defaults stringForKey:key];
}

+(void) putString:(NSString *)value withKey:(NSString *)key{
    NSUserDefaults *defaults = [self getUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

+(NSInteger) getInteger:(NSString *)key{
    NSUserDefaults *defaults = [self getUserDefaults];
    return [defaults integerForKey:key];
}

+(void)putInteger:(NSInteger )value withKey:(NSString *)key{
    NSUserDefaults *defaults = [self getUserDefaults];
    [defaults setInteger:value forKey:key];
    [defaults synchronize];
}

+(BOOL) getBool:(NSString *)key{
    NSUserDefaults *defaults = [self getUserDefaults];
    return [defaults boolForKey:key];
}

+(void)putBool:(BOOL )value withKey:(NSString *)key{
    NSUserDefaults *defaults = [self getUserDefaults];
    [defaults setBool:value forKey:key];
    [defaults synchronize];
}

@end
