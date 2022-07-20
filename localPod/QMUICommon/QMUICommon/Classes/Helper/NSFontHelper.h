//
//  NSFontHelper.h
//  LemonDuplicateFile
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFontHelper : NSObject

+(NSFont *) getLightPingFangFont:(CGFloat)fontsize;
+(NSFont *) getRegularPingFangFont:(CGFloat)fontsize;
+(NSFont *) getMediumPingFangFont:(CGFloat)fontsize;

+(NSFont *) getLightSystemFont:(CGFloat)fontsize;
+(NSFont *) getRegularSystemFont:(CGFloat)fontsize;
+(NSFont *) getMediumSystemFont:(CGFloat)fontsize;
@end
