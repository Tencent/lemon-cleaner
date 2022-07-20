//
//  QMSoftwareHelp.m
//  QMApplication
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMSoftwareHelp.h"
#import "NSString+Extension.h"

@implementation QMSoftwareHelp

+ (NSString *)dateDistance:(NSDate *)date
{
    NSLog(@"date %@", date);
    NSTimeInterval interval = [date timeIntervalSinceNow];
    NSString *showString = NSLocalizedStringFromTableInBundle(@"QMSoftwareHelp_dateDistance_showString _1", nil, [NSBundle bundleForClass:[self class]], @"");
    
    if (!date) {
        showString = NSLocalizedStringFromTableInBundle(@"QMSoftwareHelp_dateDistance_1553153166_2", nil, [NSBundle bundleForClass:[self class]], @"");
    }
    else if (interval < -90*24*60*60) {
        showString = NSLocalizedStringFromTableInBundle(@"QMSoftwareHelp_dateDistance_1553153166_3", nil, [NSBundle bundleForClass:[self class]], @"");
    }
    else if (interval < -30*24*60*60) {
        showString = NSLocalizedStringFromTableInBundle(@"QMSoftwareHelp_dateDistance_1553153166_4", nil, [NSBundle bundleForClass:[self class]], @"");
    }
    else if (interval < -7*24*60*60) {
        showString = NSLocalizedStringFromTableInBundle(@"QMSoftwareHelp_dateDistance_1553153166_5", nil, [NSBundle bundleForClass:[self class]], @"");
    }
    return showString;
}

+ (NSString *)dateStringWithInterval:(NSTimeInterval)interval
{
    // 发布时间
    if (interval > 0)
    {
        NSDate * releaseDate = [NSDate dateWithTimeIntervalSince1970:interval];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy.MM.dd"];
        return [df stringFromDate:releaseDate];
    }
    else
    {
        return @"N/A";
    }
}

+ (NSString *)downloadTime:(uint64_t)downSize speed:(uint64_t)downSpeed
{
    CFTimeInterval interval = downSize*1.0/downSpeed;
    
    if (interval < 60)
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"QMSoftwareHelp_downloadTime_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""),interval];
    
    if (interval < 60*60)
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"QMSoftwareHelp_downloadTime_NSString_2", nil, [NSBundle bundleForClass:[self class]], @""),interval/60];
    
    if (interval < 60*60*24)
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"QMSoftwareHelp_downloadTime_NSString_3", nil, [NSBundle bundleForClass:[self class]], @""),interval/60/60];
    
    return NSLocalizedStringFromTableInBundle(@"QMSoftwareHelp_downloadTime_1553153166_4", nil, [NSBundle bundleForClass:[self class]], @"");
}

+ (NSString *)getVersionOfBundlePath:(NSString *)bundlePath {
    NSDictionary *infoDict = [[NSBundle bundleWithPath:bundlePath] infoDictionary];
    
    NSString *shortVersion = nil;
    NSString *shortVersionStr = [infoDict objectForKey:@"CFBundleShortVersionString"];
    if ([shortVersionStr isKindOfClass:[NSString class]] && shortVersionStr.length > 0)
        shortVersion = [shortVersionStr versionString];
    
    if (shortVersion) {
        return shortVersion;
    }
    
    NSString *bundleVersion = nil;
    NSString *bundleVersionStr = [infoDict objectForKey:(NSString *)kCFBundleVersionKey];
    if ([bundleVersionStr isKindOfClass:[NSString class]] && bundleVersionStr.length > 0)
        bundleVersion = [bundleVersionStr versionString];
    return bundleVersion;
}

@end
