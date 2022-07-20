//
//  QMWarnReultItem.m
//  QMCleaner
//

//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMWarnReultItem.h"
#import <Cocoa/Cocoa.h>

@implementation QMWarnReultItem
@synthesize pid;
@synthesize title;
@synthesize showPath;
@synthesize iconImage;
@synthesize resultSize;

- (id)initWithPath:(NSString *)path
{
    if (self = [super init])
    {
        showPath = path;
        title = [[NSFileManager defaultManager] displayNameAtPath:path];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            @try {
                iconImage = [[NSWorkspace sharedWorkspace] iconForFile:path];
                [iconImage setSize:NSMakeSize(16, 16)];
            }
            @catch (NSException *exception) {
                
            }
        }
    }
    return self;
}

- (NSDictionary *)resultPathDict
{
    return m_resultPathDict;
}

- (void)addResultPathArray:(NSArray *)pathArray cleanType:(QMCleanType)type
{
    if (!m_resultPathDict) m_resultPathDict = [NSMutableDictionary dictionary];
    NSString * key = [NSString stringWithFormat:@"%d", type];
    NSMutableArray * array = [m_resultPathDict objectForKey:key];
    if (!array) array = [NSMutableArray array];
    [array addObjectsFromArray:pathArray];
    [m_resultPathDict setObject:array forKey:key];
}

@end
