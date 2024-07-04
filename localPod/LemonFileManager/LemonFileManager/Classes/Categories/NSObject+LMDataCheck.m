//
//  NSObject+LMDataCheck.m
//  LemonFileManager
//
//

#import "NSObject+LMDataCheck.h"

@implementation NSObject (LMDataCheck)

- (BOOL)traverseDataStructureAndCheckForNullValues {
    BOOL containNull = NO; // 默认无null
    if ([self isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)self;
        for (id key in dictionary) {
            id value = [dictionary objectForKey:key];
            containNull = [value traverseDataStructureAndCheckForNullValues];
            if (containNull) {
                // 有null 跳出循环
                break;
            }
        }
    } else if ([self isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray *)self;
        for (int i = 0; i < array.count; i++) {
            id item = [array objectAtIndex:i];
            containNull = [item traverseDataStructureAndCheckForNullValues];
            if (containNull) {
                // 有null 跳出循环
                break;
            }
        }
    } else if ([self isKindOfClass:[NSNull class]]) {
        return YES;
    }
    return containNull;
}

@end
