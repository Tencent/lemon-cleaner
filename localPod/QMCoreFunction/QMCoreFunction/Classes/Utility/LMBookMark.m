//
//  LMBookMark.m
//  Lemon
//
//  
//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "LMBookMark.h"

static LMBookMark *instance = nil;

@implementation LMBookMark

+ (LMBookMark *)defaultShareBookmark{
    if (instance == nil) {
        instance = [[LMBookMark alloc]init];
    }
    return instance;
}

-(NSData *)saveBookmarkWithFilePath:(NSString *)filePath{
    BOOL isSuccess = NO;
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    NSError *error;
    NSData *bookmarkData = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                             includingResourceValuesForKeys:nil
                                              relativeToURL:nil
                                                      error:&error];
    if (error) {
        NSLog(@"(%s %s)bookmarkData is %@, error is %@", __FILE__, __PRETTY_FUNCTION__, bookmarkData, error);
    }
    if (bookmarkData != nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        //保存文件路径
        [defaults setObject:bookmarkData forKey:filePath];
        [defaults synchronize];
        isSuccess = YES;
    }
    return bookmarkData;
}

-(BOOL)accessingSecurityScopedResourceWithFilePath:(NSString *)filePath{
    BOOL isSuccess = NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *bookmarkData =  [defaults objectForKey:filePath];
    if (bookmarkData !=nil) {
        BOOL isStale;
        NSURL *allowedUrl = [NSURL URLByResolvingBookmarkData:bookmarkData
                                                      options:NSURLBookmarkResolutionWithSecurityScope
                                                relativeToURL:nil
                                          bookmarkDataIsStale:&isStale
                                                        error:NULL];
        if (allowedUrl) {
            isSuccess =[allowedUrl startAccessingSecurityScopedResource];
        }
    }
    return isSuccess;
}

-(BOOL)stopAccessingSecurityScopedResourceWithFilePath:(NSString *)filePath{
    BOOL isSuccess = NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *bookmarkData =  [defaults objectForKey:filePath];
    if (bookmarkData !=nil) {
        BOOL isStale;
        NSURL *allowedUrl = [NSURL URLByResolvingBookmarkData:bookmarkData
                                                      options:NSURLBookmarkResolutionWithSecurityScope
                                                relativeToURL:nil
                                          bookmarkDataIsStale:&isStale
                                                        error:NULL];
        if (allowedUrl) {
            [allowedUrl stopAccessingSecurityScopedResource];
            isSuccess = YES;
        }
    }
    return isSuccess;
}

@end
