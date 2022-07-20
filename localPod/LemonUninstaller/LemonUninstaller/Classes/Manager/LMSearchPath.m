//
//  LMSearchPath.m
//  LemonUninstaller
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMSearchPath.h"

@implementation LMSearchPath

+ (NSArray *) supportPaths {
    NSArray *searchPaths = @[@"/Library/Application Support",
                             [@"~/Library/Application Support" stringByExpandingTildeInPath]
                             ];
    return searchPaths;
}

+ (NSArray *) cachesPaths {
    NSString *tempPathT = NSTemporaryDirectory();
    NSString *tempPathC = [[tempPathT stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"C"];
    NSArray *searchPaths = @[@"/Library/Caches",
                             [@"~/Library/Caches" stringByExpandingTildeInPath],
                             tempPathT,tempPathC];
    return searchPaths;
}

+ (NSArray *) preferencesPaths {
    NSArray *searchPaths = @[@"/Library/Preferences",
                             [@"~/Library/Preferences" stringByExpandingTildeInPath]
                             ];
    return searchPaths;
}

+ (NSArray *) statePaths {
    NSArray *searchPaths = @[
                             [@"~/Library/Saved Application State" stringByExpandingTildeInPath]
                             ];
    return searchPaths;
}

+ (NSArray *) crashReportPaths {
    NSArray *searchPaths = @[@"/Library/Application Support/CrashReporter",
                             @"/Library/Logs/DiagnosticReports",
                             [@"~/Library/Application Support/CrashReporter" stringByExpandingTildeInPath],
                             [@"~/Library/Logs/DiagnosticReports" stringByExpandingTildeInPath]
                             ];
    return searchPaths;
}

+ (NSArray *) logPaths {
    NSArray *searchPaths = @[@"/Library/Logs",
                             [@"~/Library/Logs" stringByExpandingTildeInPath]
                             ];
    return searchPaths;
}

+ (NSArray *)sandboxsPaths {
    NSArray *searchPaths = @[
                             [@"~/Library/Containers" stringByExpandingTildeInPath]
                             ];
    return searchPaths;
}

+ (NSArray *) daemonPaths {
    NSArray *searchPaths = @[@"/Library/LaunchAgents",
                             @"/Library/LaunchDaemons",
                             @"/Library/StartupItems",
                             [@"~/Library/LaunchAgents" stringByExpandingTildeInPath],
                             [@"~/Library/LaunchDaemons" stringByExpandingTildeInPath]];
    return searchPaths;
}

@end
