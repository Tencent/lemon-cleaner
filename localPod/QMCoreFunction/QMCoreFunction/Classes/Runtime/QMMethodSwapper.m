//
//  QMMethodSwapper.m
//  AFNetworking
//
//

#import "QMMethodSwapper.h"
#import <objc/runtime.h>

@implementation QMMethodSwapper

+ (void)swapInstanceMethodInClass:(Class)class
                originalSelector:(SEL)originalSelector
                swappedSelector:(SEL)swappedSelector {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swappedMethod = class_getInstanceMethod(class, swappedSelector);
    
    if (originalMethod && swappedMethod) {
        method_exchangeImplementations(originalMethod, swappedMethod);
    } else {
        NSLog(@"Instance method swap failed: One of the methods does not exist.");
    }
}

+ (void)swapClassMethodInClass:(Class)class
              originalSelector:(SEL)originalSelector
              swappedSelector:(SEL)swappedSelector {
    Method originalMethod = class_getClassMethod(class, originalSelector);
    Method swappedMethod = class_getClassMethod(class, swappedSelector);
    
    if (originalMethod && swappedMethod) {
        method_exchangeImplementations(originalMethod, swappedMethod);
    } else {
        NSLog(@"Class method swap failed: One of the methods does not exist.");
    }
}

@end
