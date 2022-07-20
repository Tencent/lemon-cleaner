//
//  QMWarnReultItem.h
//  QMCleaner
//

//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMXMLItemDefine.h"

@interface QMWarnReultItem : NSObject
{
    NSMutableDictionary * m_resultPathDict;
}

@property (nonatomic, assign) pid_t pid;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * showPath;
@property (nonatomic, retain) NSImage * iconImage;
@property (nonatomic, assign) NSUInteger resultSize;
@property (nonatomic, assign) BOOL selected;

- (id)initWithPath:(NSString *)path;

- (void)addResultPathArray:(NSArray *)pathArray cleanType:(QMCleanType)type;
- (NSDictionary *)resultPathDict;

@end
