//
//  QMStatusTextField.m
//  LemonMonitor
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMStatusTextField.h"
#import <QuartzCore/QuartzCore.h>

@implementation QMStatusTextField
@synthesize progress;

- (double)progress
{
    return progress;
}

- (void)setProgress:(double)value
{
    if (progress != value)
    {
        progress = value;
        NSString *string = [NSString stringWithFormat:@"%2.0f%%",MIN(round(value*100), 99)];
        if (![string isEqualToString:self.stringValue])
        {
            [self setStringValue:string];
            [self setNeedsDisplay];
        }
    }
}

//这就是你需要去实现的一个方法，根据属性返回一个动画对象
+ (id)defaultAnimationForKey:(NSString *)key
{
    if ([key isEqualToString:@"progress"])
    {
        return [CABasicAnimation animation];
    }else
    {
        return [super defaultAnimationForKey:key];
    }
}

@end
