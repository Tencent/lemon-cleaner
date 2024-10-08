//
//  QMActionItem.m
//  QMCleanDemo
//

//  Copyright (c) 2013年 yuanwen. All rights reserved.
//

#import "QMActionItem.h"
#import "QMCleanUtils.h"
#import "QMResultItem.h"

@implementation QMActionAtomItem
@synthesize resultFilters;

-(id)copyWithZone:(NSZone *)zone{
    QMActionAtomItem *copy = [[QMActionAtomItem alloc] init];
    if (copy) {
        copy.resultFilters = [self.resultFilters copy];
    }
    
    return self;
}

-(id)mutableCopyWithZone:(NSZone *)zone{
    QMActionAtomItem *copy = [[QMActionAtomItem alloc] init];
    if (copy) {
        copy.resultFilters = [self.resultFilters copy];
    }
    
    return self;
}

@end

@implementation QMActionPathItem
@synthesize type;
@synthesize value;
@synthesize filename;
@synthesize level;
@synthesize scanFilters;

- (id)init
{
    if (self = [super init])
    {
        level = 1;
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone{
    QMActionPathItem *copy = [[QMActionPathItem alloc] init];
    if (copy) {
        copy.filename = [self.filename mutableCopy];
        copy.level = self.level;
        copy.type = [self.type mutableCopy];
        copy.value = [self.value mutableCopy];
        copy.value1 = [self.value1 mutableCopy];
        copy.scanFilters = [self.scanFilters copy];
    }
    
    return self;
}

-(id)mutableCopyWithZone:(NSZone *)zone{
    QMActionPathItem *copy = [[QMActionPathItem alloc] init];
    if (copy) {
        copy.filename = [self.filename mutableCopy];
        copy.level = self.level;
        copy.type = [self.type mutableCopy];
        copy.value = [self.value mutableCopy];
        copy.value1 = [self.value1 mutableCopy];
        copy.scanFilters = [self.scanFilters copy];
    }
    
    return self;
}

@end

@implementation QMActionItem
@synthesize actionID;
@synthesize type;
@synthesize os;
@synthesize recommend;
@synthesize cleanemptyfolder;
@synthesize cleanhiddenfile;
@synthesize showResult;
@synthesize atomItem;
@synthesize pathItemArray;
@synthesize title;
@synthesize cautionID;
@synthesize cleanType;
@synthesize appPath;
@synthesize bundleID;
@synthesize appVersion;
@synthesize buildVersion;

- (id)init
{
    if (self = [super init])
    {
        cleanType = QMCleanRemove;
        os = nil;
        cleanemptyfolder = NO;
        cleanhiddenfile = NO;
        recommend = YES;
        showResult = NO;
        pathItemArray = [[NSMutableArray alloc] init];
        self.m_resultItemSet = [[NSMutableSet alloc] init];
        self.m_resultItemArray = [[NSMutableArray alloc] init];
        self.m_stateValue = NSOnState;
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone{
    QMActionItem *copy = [super copyWithZone:zone];
    if (copy) {
        copy.actionID = [self.actionID mutableCopy];
        copy.type = self.type;
        copy.os = [self.os mutableCopy];
        copy.recommend = self.recommend;
        copy.showResult = self.showResult;
        copy.cleanemptyfolder = self.cleanemptyfolder;
        copy.cleanhiddenfile = self.cleanhiddenfile;
        copy.title = [self.title mutableCopy];
        copy.atomItem = [self.atomItem mutableCopy];
        copy->pathItemArray = [[NSMutableArray alloc] initWithArray:self->pathItemArray copyItems:YES];
        copy.m_resultItemSet = [[NSMutableSet alloc] init];
        copy.m_resultItemArray = [[NSMutableArray alloc] init];
        copy.cautionID = [self.cautionID mutableCopy];
        copy.cleanType = self.cleanType;
        copy.appPath = [self.appPath mutableCopy];
        copy.bundleID = [self.bundleID mutableCopy];
        copy.appstoreBundleID = [self.appstoreBundleID mutableCopy];
        copy.appSearchName = [self.appSearchName mutableCopy];
        copy.appVersion = [self.appVersion mutableCopy];
        copy.buildVersion = [self.buildVersion mutableCopy];
        copy.scanFileNum = self.scanFileNum;
        copy.sandboxType = self.sandboxType;
    }
    
    return copy;
}

-(id)mutableCopyWithZone:(NSZone *)zone{
    QMActionItem *copy = [super mutableCopyWithZone:zone];
    if (copy) {
        copy.actionID = [self.actionID mutableCopy];
        copy.type = self.type;
        copy.os = [self.os mutableCopy];
        copy.recommend = self.recommend;
        copy.showResult = self.showResult;
        copy.cleanemptyfolder = self.cleanemptyfolder;
        copy.cleanhiddenfile = self.cleanhiddenfile;
        copy.title = [self.title mutableCopy];
        copy.atomItem = [self.atomItem mutableCopy];
        copy->pathItemArray = [[NSMutableArray alloc] initWithArray:self->pathItemArray copyItems:YES];
        copy.m_resultItemSet = [[NSMutableSet alloc] init];
        copy.m_resultItemArray = [[NSMutableArray alloc] init];
        copy.cautionID = [self.cautionID mutableCopy];
        copy.cleanType = self.cleanType;
        copy.appPath = [self.appPath mutableCopy];
        copy.bundleID = [self.bundleID mutableCopy];
        copy.appstoreBundleID = [self.appstoreBundleID mutableCopy];
        copy.appSearchName = [self.appSearchName mutableCopy];
        copy.appVersion = [self.appVersion mutableCopy];
        copy.buildVersion = [self.buildVersion mutableCopy];
        copy.scanFileNum = self.scanFileNum;
        copy.sandboxType = self.sandboxType;
    }
    
    return copy;
}

- (void)addActionPathItem:(QMActionPathItem *)item
{
    if ([pathItemArray containsObject:item])
        return;
    [pathItemArray addObject:item];
}

- (void)addResultItem:(QMResultItem *)item
{
    @synchronized (self) {
        /// array 中元素较多时 containsObject：耗时较高
        /// set的containsObject 的时间复杂度为O(1)
        if (![self.m_resultItemSet containsObject:item])
        {
            [self.m_resultItemSet addObject:item];
            m_totalSize += [item resultFileSize];
        }
    }
    item.state = self.state;
    if([item.title containsString:@"IntelliJIdea"]){
        item.state = NSOffState;
    }
}

- (void)addResultCompleted {
    NSArray *resultItems = self.m_resultItemSet.allObjects;
    if (resultItems.count > 0) {
        [self.m_resultItemArray addObjectsFromArray:resultItems];
    }
    [self.m_resultItemSet removeAllObjects];
}

- (NSMutableArray *)subItemArray
{
    return self.m_resultItemArray;
}

-(NSUInteger)scanFileNums{
    return self.scanFileNum;
}

- (void)resetItemState
{
    self.m_stateValue = (recommend ? NSOnState : NSOffState);
}

- (void)setRecommend:(BOOL)value
{
    recommend = value;
    self.m_stateValue = (recommend ? NSOnState : NSOffState);
}

// 检查软件版本
- (BOOL)checkAppVersion:(NSBundle *)bundle
{
    if (!bundle) return NO;
    NSString * shortVersion = [[bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString * bundleVersion = [[bundle infoDictionary] objectForKey:@"CFBundleVersion"];
    return ([QMCleanUtils assertRegex:appVersion matchStr:shortVersion]
            || [QMCleanUtils assertRegex:buildVersion matchStr:bundleVersion]);
}

- (BOOL)checkAppVersion
{
    if (appPath)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:appPath])
            return [self checkAppVersion:[NSBundle bundleWithPath:appPath]];
        
    }
    if (bundleID)
    {
        return [self checkAppVersion:[NSBundle bundleWithIdentifier:bundleID]];
    }
    return YES;
}


@end
