//
//  LMXpcTest.m
//  QMCoreFunction
//
//  
//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "LMXpcTest.h"
#import "McCoreFunction.h"

@implementation LMXpcTest


-(void) testXpcSyncInSingleThread
{
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *beginString = [@"~/Downloads" stringByExpandingTildeInPath];
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:beginString];
    
    //    NSDirectoryEnumerator * dirEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:path]
    //                                     includingPropertiesForKeys:nil
    //                                                        options:NSDirectoryEnumerationSkipsPackageDescendants
    //                                                   errorHandler:nil];
    
    // 1. contentsOfDirectoryAtPath 所有内容
    // 2. subpathsOfDirectoryAtPath :recursively
    [fm contentsOfDirectoryAtPath:@"" error:nil];
    
    NSString *subFile ;
    while (subFile = [enumerator nextObject]) {
        NSString *subFullFile = [beginString stringByAppendingPathComponent:subFile];
        NSDictionary *fileInfoDic = [[McCoreFunction shareCoreFuction] getFileInfo:subFullFile];
        NSInteger filesize = [[fileInfoDic objectForKey:@"fileSize"] intValue];
        NSLog(@"subFile %@:filesize is %ld", subFullFile,(long)filesize);
    }
    
}


-(void) testXpcSyncInMultiThreads
{
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *beginString = [@"~/Downloads" stringByExpandingTildeInPath];
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:beginString];
    
    NSString *subFile ;
    while (subFile = [enumerator nextObject]) {
        
        NSString *subFullFile = [beginString stringByAppendingPathComponent:subFile];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            NSLog(@"thread is %@", [NSThread currentThread] );
            NSDictionary *fileInfoDic = [[McCoreFunction shareCoreFuction] getFileInfo:subFullFile];
            NSInteger filesize = [[fileInfoDic objectForKey:@"fileSize"] intValue];
            NSLog(@"subFile %@:filesize is %ld", subFullFile,(long)filesize);
        });
    }
    
}


@end
