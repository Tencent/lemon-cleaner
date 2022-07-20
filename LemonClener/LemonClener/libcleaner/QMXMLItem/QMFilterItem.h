//
//  QMFilterItem.h
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMFilterItem : NSObject<NSCopying, NSMutableCopying>

// 唯一id
@property (nonatomic, strong) NSString * filterID;
// 过滤对象
@property (nonatomic, strong) NSString * column;
// 过滤方式
@property (nonatomic, strong) NSString * relation;
// 过滤值
@property (nonatomic, strong) NSString * value;
// 过滤行为
@property (nonatomic, strong) NSString * action;

@property (strong) QMFilterItem * andFilterItem;
@property (strong) QMFilterItem * orFilterItem;
@property (assign) int logicLevel;

- (BOOL)checkFilterWithPath:(NSString *)path;

@end
