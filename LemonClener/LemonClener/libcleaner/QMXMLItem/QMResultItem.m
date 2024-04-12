//
//  QMResultItem.m
//  QMCleaner
//

//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMResultItem.h"
#import "QMXMLItemDefine.h"
#import "QMCleanUtils.h"
#import <QMCoreFunction/McCoreFunction.h>

@implementation QMResultBrowerItem

-(id)init{
    self = [super init];
    if (self) {
        self.isSelect = NO;
    }
    
    return self;
}

@end

@implementation QMResultItem
@synthesize iconImage;
@synthesize title;
@synthesize path;
@synthesize showPath;
@synthesize subItemArray;
@synthesize languageKey;
@synthesize cautionID;

- (id)init
{
    if (self = [super init])
    {
        m_pathSet = [[NSMutableSet alloc] init];
        m_resultFileSize = 0;
        self.m_stateValue = NSOnState;
        self.showHierarchyType = 3;
    }
    return self;
}

- (id)initWithPath:(NSString *)rpath
{
    if (self = [self init])
    {
        @try {
            NSImage * image = nil;
            image = [[NSWorkspace sharedWorkspace] iconForFile:rpath];
            [image setSize:NSMakeSize(kIconImageSize, kIconImageSize)];
            iconImage = image;
        }
        @catch (NSException *exception) {
            
        }
        title = [[NSFileManager defaultManager] displayNameAtPath:rpath];
        path = rpath;
        showPath = rpath;
    }
    return self;
}

- (id)initWithPath:(NSString *)rpath icon:(NSImage *)icon
{
    if (self = [self init])
    {
        static CGSize size;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            size = NSMakeSize(kIconImageSize, kIconImageSize);
        });
        [icon setSize:size];
        iconImage = icon;
        title = [rpath lastPathComponent];
        path = rpath;
        showPath = rpath;
    }
    return self;
}

- (id)initWithLanguageKey:(NSString *)key
{
    if (self = [self init])
    {
        self.title = key;
    }
    return self;
}

- (void)setFileSize:(NSUInteger)size
{
    m_resultFileSize = size;
}

- (void)addResultWithPathArray:(NSArray *)pathArray
{
    for (NSString * rpath in pathArray)
    {
        [self addResultWithPath:rpath];
    }
}
- (void)addResultWithPath:(NSString *)rpath
{
    if ([m_pathSet containsObject:rpath])
        return;    
    [m_pathSet addObject:rpath];
    if (self.cleanType != QMCleanCutBinary && self.cleanType != QMCleanDeleteBinary)
        m_resultFileSize += [QMCleanUtils caluactionSize:rpath];
    if (self.cleanType == QMCleanDeleteBinary) {
        NSFileManager * manager = [NSFileManager defaultManager];
        NSDictionary * attributes = [manager attributesOfItemAtPath:rpath error:nil];
        NSNumber *theFileSize = [attributes objectForKey:NSFileSize];
        m_resultFileSize += [theFileSize intValue]/2;
    }
    if (m_resultFileSize == 0) {
        m_resultFileSize = 1000;
    }
}

//需要提权来获取文件大小
- (void)addResultWithPathByDeamonCalculateSize:(NSString *)rpath{
    if ([m_pathSet containsObject:rpath])
        return;
    [m_pathSet addObject:rpath];
    NSDictionary *fileInfoDic = [[McCoreFunction shareCoreFuction] getFileInfo:rpath];
    NSUInteger fileSize = [[fileInfoDic objectForKey:@"fileSize"] integerValue];
    m_resultFileSize += fileSize;
}

- (NSSet *)resultPath
{
    return m_pathSet;
}

- (void)addSubResultItem:(QMResultItem *)item
{
    if ([m_subItemArray containsObject:item])
        return;
    m_resultFileSize = 0;
    if (!m_subItemArray)
        m_subItemArray = [[NSMutableArray alloc] init];
    [m_subItemArray addObject:item];
    item.state = self.state;
}

- (NSArray *)subItemArray
{
    return m_subItemArray;
}

- (NSUInteger)resultFileSize
{
    if ([m_subItemArray count] > 0)
    {
        m_resultFileSize = 0;
        for (int i = 0; i < [m_subItemArray count]; i++)
        {
            QMResultItem * item = [m_subItemArray objectAtIndex:i];
            m_resultFileSize += [item resultFileSize];
        }
    }
    return m_resultFileSize;
}

- (void)setCleanType:(QMCleanType)cleanType
{
    if (_cleanType == cleanType)
        return;
    _cleanType = cleanType;
    for (int i = 0; i < [m_subItemArray count]; i++)
    {
        QMResultItem * item = [m_subItemArray objectAtIndex:i];
        item.cleanType = _cleanType;
    }
}
@end
