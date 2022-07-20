//
//  NSString+PathExtension.m
//  QMCoreFunction
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "NSString+PathExtension.h"
#import "McCoreFunction.h"
#import "NSString+Extension.h"

@implementation NSString (Path)
- (NSString *)stringByExpandingTildeInPathIgnoreSandbox{
    
    NSString *tempValue;
    if ([McCoreFunction isAppStoreVersion]){
        if ([self containsString:@"~"]) {
            NSString *homePath = [NSString getUserHomePath];
            NSString *newValue = [self stringByReplacingOccurrencesOfString:@"~" withString:@""];
            //NSLog(@"tempValue: %@, \nhomePath: %@", tempValue, homePath);
            tempValue = [NSString stringWithFormat:@"%@%@", homePath, newValue];
        }else{
            tempValue = [self stringByStandardizingPath];
        }
    } else {
        tempValue = [self stringByExpandingTildeInPath];
    }
    return tempValue;
}
@end
