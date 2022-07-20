//
//  NSAttributedString+Extension.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSAttributedString(StringSize)

- (NSSize)sizeForWidth:(float)width height:(float)height;

+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;

@end
