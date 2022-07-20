//
//  NSFontHelper.m
//  LemonDuplicateFile
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "NSFontHelper.h"
#import <AppKit/AppKit.h>

@implementation NSFontHelper

+(NSFont *)getLightPingFangFont:(CGFloat)fontsize{
    NSFont *font = [NSFont fontWithName:@"PingFangSC-Light" size:fontsize];
    if (font){
        return font;
    }else{
        return [self getLightSystemFont:fontsize];
    }
}

+(NSFont *)getRegularPingFangFont:(CGFloat)fontsize{
    NSFont *font = [NSFont fontWithName:@"PingFangSC-Regular" size:fontsize];
    
    if (font){
        return font;
    }else{
        return [self getRegularSystemFont:fontsize];
    }
}

+(NSFont *)getMediumPingFangFont:(CGFloat)fontsize{
    
    NSFont *font = [NSFont fontWithName:@"PingFangSC-Medium" size:fontsize];
    
    if (font){
        return font;
    }else{
        return [self getMediumSystemFont:fontsize];
    }
}

+(NSFont *)getLightSystemFont:(CGFloat)fontsize{
    if (@available(macOS 10.11, *)) {
        return [NSFont systemFontOfSize:fontsize weight:NSFontWeightLight];
    } else {
        return [NSFont systemFontOfSize:fontsize];
    }
}

+(NSFont *)getRegularSystemFont:(CGFloat)fontsize{
    if (@available(macOS 10.11, *)) {
        return [NSFont systemFontOfSize:fontsize weight:NSFontWeightRegular];
    } else {
        return [NSFont systemFontOfSize:fontsize];
    }
}

+(NSFont *)getMediumSystemFont:(CGFloat)fontsize{
    if (@available(macOS 10.11, *)) {
        return [NSFont systemFontOfSize:fontsize weight:NSFontWeightMedium];
    } else {
        return [NSFont systemFontOfSize:fontsize];
    }
}
@end
