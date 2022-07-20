//
//  QMDataCenter.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const QMDataCenterDidChangeNotification;

@interface QMDataCenter : NSObject

+ (QMDataCenter *)defaultCenter;

//Getting Configuration Values
- (BOOL)boolForKey:(NSString *)aKey;
- (double)doubleForKey:(NSString *)aKey;
- (NSInteger)integerForKey:(NSString *)aKey;
- (NSString *)stringForKey:(NSString *)aKey;
- (NSData *)dataForKey:(NSString *)aKey;
- (id)objectForKey:(NSString *)aKey;
- (NSArray *)arrayForKey:(NSString *)aKey;

//Setting Configuration Values
- (BOOL)setBool:(BOOL)value forKey:(NSString *)aKey;
- (BOOL)setInteger:(NSInteger)value forKey:(NSString *)aKey;
- (BOOL)setDouble:(double)value forKey:(NSString *)aKey;
- (BOOL)setString:(NSString *)value forKey:(NSString *)aKey;
- (BOOL)setData:(NSData *)value forKey:(NSString *)aKey;
- (BOOL)setObject:(id)value forKey:(NSString *)aKey;

//Check Configuration Key
- (BOOL)valueExistsForKey:(NSString *)aKey;

//Remove Configuration Value
- (BOOL)removeValueForKey:(NSString *)aKey;

@end
