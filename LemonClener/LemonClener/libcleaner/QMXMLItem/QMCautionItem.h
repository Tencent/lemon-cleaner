//
//  QMCleanItem.h
//  libcleaner
//

//  Copyright (c) 2013年 Magican Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QMResultItem;
@interface QMCautionItem : NSObject

@property (nonatomic, strong) NSString * cautionID;
// 过滤对象
@property (nonatomic, strong) NSString * column;
// 过滤值
@property (nonatomic, strong) NSString * value;

@property (nonatomic, strong) NSString * bundleID;
@property (nonatomic, strong) NSString * appName;

- (BOOL)fliterCleanItem:(NSString *)path bundleID:(NSString **)bundle appName:(NSString **)name;

@end
