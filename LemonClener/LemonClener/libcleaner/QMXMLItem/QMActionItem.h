//
//  QMActionItem.h
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMXMLItemDefine.h"
#import "QMBaseItem.h"

typedef NS_ENUM(NSUInteger, SandboxType) {
    SandboxTypeYes,
    SandboxTypeNot,
    SandboxTypeMulti,//手动适配软件 一个软件可能有两种bundleid 一种sandbox 一种非sandbox
                     //自适配不存在这种问题 直接判断出来
    SandboxTypeNotDetermine,
};

@interface QMActionAtomItem : NSObject<NSCopying, NSMutableCopying>

// 结果过滤规则
@property (nonatomic, strong) NSString  * resultFilters;


@end

@interface QMActionPathItem : NSObject<NSCopying, NSMutableCopying>

// 过滤文件名
@property (nonatomic, strong) NSString * filename;
// 目录扫描等级，默认为1，只扫描一级目录
@property (nonatomic, assign) int level;
@property (nonatomic, strong) NSString * type;
@property (nonatomic, strong) NSString * value;
@property (nonatomic, strong) NSString * value1;
// 扫描过滤规则
@property (nonatomic, strong) NSString  * scanFilters;

@end

@interface QMActionItem : QMBaseItem<NSCopying, NSMutableCopying>
{
    NSMutableArray * pathItemArray;
}
@property (atomic, strong) NSMutableSet * m_resultItemSet;
@property (atomic, strong) NSMutableArray * m_resultItemArray;
@property (nonatomic, strong) NSString * actionID;
// 清理种类
@property (nonatomic, assign) QMActionType type;

@property (nonatomic, assign) BOOL recommend;
@property (nonatomic, assign) BOOL showResult;

// 是否查找空目录，默认为YES
@property (nonatomic, assign) BOOL cleanemptyfolder;
@property (nonatomic, assign) BOOL cleanhiddenfile;

@property (nonatomic, strong) NSString * title;

@property (nonatomic, strong) QMActionAtomItem * atomItem;
@property (nonatomic, readonly, retain) NSArray * pathItemArray;

@property (nonatomic, strong) NSString * cautionID;
@property (nonatomic, assign) QMCleanType cleanType;
@property (nonatomic, assign) SandboxType sandboxType;

// 对应软件版本
@property (nonatomic, strong) NSString * appPath;
@property (nonatomic, strong) NSString * bundleID;
@property (nonatomic, strong) NSString * appstoreBundleID;
@property (nonatomic, strong) NSString * appSearchName;
@property (nonatomic, strong) NSString * appVersion;
@property (nonatomic, strong) NSString * buildVersion;
@property (nonatomic, assign) NSUInteger scanFileNum;

//浏览器 cookie 浏览、下载记录配置对象  用于查找结果



- (void)addActionPathItem:(QMActionPathItem *)item;

- (BOOL)checkAppVersion;

- (void)resetItemState;
- (void)addResultItem:(QMResultItem *)item;
- (void)addResultCompleted;

@end
