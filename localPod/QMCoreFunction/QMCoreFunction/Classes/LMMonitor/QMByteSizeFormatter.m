//
//  QMMiniWindowFileSizeFormatter.m
//  LemonMonitor
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMByteSizeFormatter.h"
#import "NSString+Extension.h"

@interface QMByteSizeFormatter () <NSDecimalNumberBehaviors>

@end

@implementation QMByteSizeFormatter
{
    NSRegularExpression *_regex;
}

+ (instancetype)networkSpeedFormatter
{
    QMByteSizeFormatter *ret = [[QMByteSizeFormatter alloc] init];
    ret.suffix = @"/s";
    return ret;
}

- (NSString *)stringForObjectValue:(NSNumber *)obj
{
    NSString *ret = [NSString stringFromDiskSize:[obj longLongValue]];
    if (self.suffix) {
        return [ret stringByAppendingString:self.suffix];
    }
    return ret;
}

- (BOOL)getObjectValue:(out id *)obj forString:(NSString *)string errorDescription:(out NSString **)error
{
    if (obj) {
        *obj = [self numberFromString:string];
        return YES;
    }
    return NO;
}

- (NSNumber *)numberFromString:(NSString *)string
{
    static NSDictionary *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{@"b" : @1, @"kb" : @1024, @"mb": @(1024*1024), @"gb": @(1024*1024*1024),
                @"tb": @(1024*1024*1024*1024L), @"pb": [NSDecimalNumber decimalNumberWithString:@"1125899906842624"]};
    });
    NSRegularExpression *regex = [self regex];
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    if (matches.count > 0) {
        NSTextCheckingResult *match = matches[0];
        if (match.numberOfRanges == 4) {
            NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:[string substringWithRange:[match rangeAtIndex:1]]];
            NSString *unit = [string substringWithRange:[match rangeAtIndex:2]];
            NSDecimalNumber *unitSize = map[[unit lowercaseString]];
            if (![unitSize isKindOfClass:[NSDecimalNumber class]]) {
                unitSize = [[NSDecimalNumber alloc] initWithDecimal:[unitSize decimalValue]];
            }
            NSDecimalNumber *ret = [[number decimalNumberByMultiplyingBy:unitSize] decimalNumberByRoundingAccordingToBehavior:self];
            return ret;
        }
    }
    return @0;
}

- (NSRegularExpression *)regex
{
    if (!_regex) {
        NSError *error = nil;
        _regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\d+\\.?\\d*)((K|M|G|T|P)?B)$" options:NSRegularExpressionCaseInsensitive error:&error];
    }
    return _regex;
}

#pragma mark - NSDecimalNumberBehaviors

- (NSRoundingMode)roundingMode
{
    return NSRoundPlain;
}

- (short)scale
{
    return 0;
}

- (NSDecimalNumber *)exceptionDuringOperation:(SEL)operation error:(NSCalculationError)error leftOperand:(NSDecimalNumber *)leftOperand rightOperand:(NSDecimalNumber *)rightOperand
{
    return [[NSDecimalNumber defaultBehavior] exceptionDuringOperation:operation error:error leftOperand:leftOperand rightOperand:rightOperand];
}

@end
