//
//  NSScreen+Extension.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "NSScreen+Extension.h"

@implementation NSScreen (Extension)

+ (NSScreen *)workScreen
{
    NSArray *screenArray = [self screens];
    if (screenArray.count == 0)
        return [self mainScreen];
    
    NSPoint mousePoint = [NSEvent mouseLocation];
    for (NSScreen *oneScreen in screenArray)
    {
        NSRect screenFrame = [oneScreen frame];
        screenFrame.size.height += 1;
        if (NSPointInRect(mousePoint,screenFrame))
        {
            return oneScreen;
        }
    }
    return screenArray[0];
}

@end
