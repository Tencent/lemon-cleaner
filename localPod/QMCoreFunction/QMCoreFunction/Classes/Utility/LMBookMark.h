//
//  LMBookMark.h
//  Lemon
//
//  
//  Copyright © 2019年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMBookMark : NSObject

+ (LMBookMark *)defaultShareBookmark;

-(NSData *)saveBookmarkWithFilePath:(NSString *)filePath;

-(BOOL)accessingSecurityScopedResourceWithFilePath:(NSString *)filePath;

-(BOOL)stopAccessingSecurityScopedResourceWithFilePath:(NSString *)filePath;

@end
