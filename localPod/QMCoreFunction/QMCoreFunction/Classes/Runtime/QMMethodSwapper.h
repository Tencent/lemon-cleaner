//
//  QMMethodSwapper.h
//  AFNetworking
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QMMethodSwapper : NSObject

// 交换实例方法
+ (void)swapInstanceMethodInClass:(Class)class
                originalSelector:(SEL)originalSelector
                swappedSelector:(SEL)swappedSelector;

// 交换类方法
+ (void)swapClassMethodInClass:(Class)class
              originalSelector:(SEL)originalSelector
              swappedSelector:(SEL)swappedSelector;

@end

NS_ASSUME_NONNULL_END
