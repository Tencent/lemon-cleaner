//
//  QMHeaderResponse.h
//  QMDownload
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMHeaderResponse : NSObject

+ (NSHTTPURLResponse *)headerResponse:(NSURL *)url error:(NSError **)error;

@end
