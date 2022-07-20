//
//  NSString+PathExtension.h
//  QMCoreFunction
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Path)
- (NSString *)stringByExpandingTildeInPathIgnoreSandbox;
@end
