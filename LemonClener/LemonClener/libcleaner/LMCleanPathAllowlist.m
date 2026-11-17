//
//  LMCleanPathAllowlist.m
//  LemonClener
//

#import "LMCleanPathAllowlist.h"
#import "QMCategoryItem.h"
#import "QMXMLItemDefine.h"
#import "QMResultItem.h"
#import <QMCoreFunction/NSString+Extension.h>
#import <QMCoreFunction/McCoreFunction.h>

@implementation LMCleanPathAllowlist

static NSArray<NSString *> *sPrefixes = nil;
static NSString *sHome = nil;
static NSString *sTempRoot = nil;
static NSMutableSet<NSString *> *sDroppedParents = nil;
static BOOL sLoggedEmptyAllowlist = NO;
static const NSUInteger kMaxDroppedParentLogs = 20;

+ (NSString *)canonicalPath:(NSString *)path
{
    if (path.length == 0) {
        return nil;
    }
    NSString *expanded = [path stringByExpandingTildeInPath];
    NSString *standardized = [expanded stringByStandardizingPath];
    NSString *resolved = [standardized stringByResolvingSymlinksInPath];
    if (resolved.length > 1 && [resolved hasSuffix:@"/"]) {
        resolved = [resolved substringToIndex:resolved.length - 1];
    }
    return resolved;
}

+ (NSString *)currentHome
{
    NSString *home = [NSString getUserHomePath];
    if (home.length == 0) {
        home = NSHomeDirectory();
    }
    return [self canonicalPath:home];
}

+ (NSString *)systemTempDirRoot
{
    NSString *temp = NSTemporaryDirectory();
    NSString *parent = [temp stringByDeletingLastPathComponent];
    NSString *root = [parent stringByAppendingPathComponent:@"C"];
    return [self canonicalPath:root];
}

+ (BOOL)isUnderPrefix:(NSString *)path prefix:(NSString *)prefix
{
    if (path.length == 0 || prefix.length == 0) {
        return NO;
    }
    if ([path isEqualToString:prefix]) {
        return YES;
    }
    NSString *bound = [prefix hasSuffix:@"/"] ? prefix : [prefix stringByAppendingString:@"/"];
    return [path hasPrefix:bound];
}

+ (BOOL)shouldKeepExportedPrefix:(NSString *)canonical home:(NSString *)home
{
    if (canonical.length == 0) {
        return NO;
    }
    if ([canonical isEqualToString:@"/Users/Shared"] || [canonical hasPrefix:@"/Users/Shared/"]) {
        return NO;
    }
    if ([canonical isEqualToString:@"/Users"] || [canonical isEqualToString:@"/Users/"]) {
        return NO;
    }
    if ([canonical hasPrefix:@"/Users/"]) {
        if (home.length == 0) {
            return NO;
        }
        return [self isUnderPrefix:canonical prefix:home];
    }
    return YES;
}

+ (NSString *)literalPrefixFromAbsValue:(NSString *)value
{
    if (value.length == 0) {
        return nil;
    }
    NSString *cut = value;
    NSRange regexStart = [cut rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"("]];
    if (regexStart.location != NSNotFound) {
        cut = [cut substringToIndex:regexStart.location];
    }
    if ([McCoreFunction isAppStoreVersion]) {
        if ([cut hasPrefix:@"~/"]) {
            cut = [cut substringFromIndex:2];
            NSString *home = [NSString getUserHomePath];
            cut = [NSString stringWithFormat:@"%@/%@", home, cut];
        }
    }
    return [self canonicalPath:cut];
}

+ (void)rebuildFromCategoryDict:(NSDictionary *)categoryDict
{
    NSString *home = [self currentHome];
    NSString *tempRoot = [self systemTempDirRoot];
    NSMutableArray<NSString *> *prefixes = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];

    void (^addPrefix)(NSString *) = ^(NSString *prefix) {
        if (prefix.length == 0 || [seen containsObject:prefix]) {
            return;
        }
        if (![self shouldKeepExportedPrefix:prefix home:home]) {
            return;
        }
        [seen addObject:prefix];
        [prefixes addObject:prefix];
    };

    addPrefix(home);
    addPrefix(tempRoot);

    for (QMCategoryItem *category in categoryDict.allValues) {
        for (QMCategorySubItem *sub in category.m_categorySubItemArray) {
            for (QMActionItem *action in sub.m_actionItemArray) {
                for (QMActionPathItem *pathItem in action.pathItemArray) {
                    NSString *type = pathItem.type;
                    if ([type isEqualToString:kXMLKeySpecial] && [pathItem.value isEqualToString:kXMLKeyTemp]) {
                        addPrefix(tempRoot);
                        continue;
                    }
                    if (![type isEqualToString:kXMLKeyAbs]) {
                        continue;
                    }
                    addPrefix([self literalPrefixFromAbsValue:pathItem.value]);
                }
            }
        }
    }

    @synchronized (self) {
        sHome = home;
        sTempRoot = tempRoot;
        sPrefixes = [prefixes copy];
        sDroppedParents = [NSMutableSet set];
        sLoggedEmptyAllowlist = NO;
    }
    NSLog(@"lm cleaner path allowlist prefixes = %lu home = %@ temp = %@",
          (unsigned long)prefixes.count, [self homePrefix], [self systemTempDirRootPrefix]);
    if (categoryDict.count == 0) {
        NSLog(@"ERROR lm cleaner path allowlist rebuilt from empty category dict");
    }
    if (prefixes.count == 0) {
        NSLog(@"ERROR lm cleaner path allowlist EMPTY after rebuild, all abs paths will be rejected");
    }
}

+ (NSString *)homePrefix
{
    @synchronized (self) {
        return sHome;
    }
}

+ (NSString *)systemTempDirRootPrefix
{
    @synchronized (self) {
        return sTempRoot;
    }
}

+ (BOOL)isAbsolutePathAllowed:(NSString *)path
{
    if (path.length == 0) {
        return YES;
    }
    if (![path hasPrefix:@"/"]) {
        return YES;
    }

    NSString *canonical = [self canonicalPath:path];
    if (canonical.length == 0) {
        return NO;
    }

    NSArray<NSString *> *prefixes = nil;
    @synchronized (self) {
        prefixes = sPrefixes;
    }
    if (prefixes.count == 0) {
        [self logEmptyAllowlistOnce];
        return NO;
    }
    for (NSString *prefix in prefixes) {
        if ([self isUnderPrefix:canonical prefix:prefix]) {
            return YES;
        }
    }
    return NO;
}

+ (void)logEmptyAllowlistOnce
{
    @synchronized (self) {
        if (sLoggedEmptyAllowlist) {
            return;
        }
        sLoggedEmptyAllowlist = YES;
    }
    NSLog(@"ERROR lm cleaner path allowlist empty, reject all abs paths (rebuildFromCategoryDict not called or failed)");
}

+ (void)logRejectedScanPath:(NSString *)path
{
    if (path.length == 0) {
        return;
    }
    NSArray<NSString *> *prefixes = nil;
    @synchronized (self) {
        prefixes = sPrefixes;
    }
    if (prefixes.count == 0) {
        [self logEmptyAllowlistOnce];
        return;
    }
    NSString *parent = [path stringByDeletingLastPathComponent];
    if (parent.length == 0) {
        parent = path;
    }
    BOOL shouldLog = NO;
    NSUInteger parentCount = 0;
    @synchronized (self) {
        if (!sDroppedParents) {
            sDroppedParents = [NSMutableSet set];
        }
        if (![sDroppedParents containsObject:parent] && sDroppedParents.count < kMaxDroppedParentLogs) {
            [sDroppedParents addObject:parent];
            shouldLog = YES;
        }
        parentCount = sDroppedParents.count;
    }
    if (shouldLog) {
        NSLog(@"lm cleaner drop abs path not in allowlist parent = %@ sample = %@", parent, path);
        if (parentCount == kMaxDroppedParentLogs) {
            NSLog(@"lm cleaner drop abs path log capped at %lu parents", (unsigned long)kMaxDroppedParentLogs);
        }
    }
}

+ (void)_collectDisallowedPathsFromItem:(QMResultItem *)item
                                blocked:(NSMutableArray<NSString *> *)blocked
                                   seen:(NSMutableSet<NSString *> *)seen
                                   size:(NSUInteger *)outSize
{
    if (![item isKindOfClass:[QMResultItem class]]) {
        return;
    }
    BOOL itemHasBlocked = NO;
    for (NSString *path in item.resultPath) {
        if (![path hasPrefix:@"/"]) {
            continue;
        }
        if ([self isAbsolutePathAllowed:path]) {
            continue;
        }
        itemHasBlocked = YES;
        NSString *canonical = [self canonicalPath:path] ?: path;
        if (![seen containsObject:canonical]) {
            [seen addObject:canonical];
            [blocked addObject:canonical];
        }
    }
    if (itemHasBlocked && outSize) {
        *outSize += [item resultFileSize];
    }
    for (QMResultItem *sub in item.subItemArray) {
        [self _collectDisallowedPathsFromItem:sub blocked:blocked seen:seen size:outSize];
    }
}

+ (BOOL)resultItemHasDisallowedAbsolutePath:(QMResultItem *)item
{
    if (!item) {
        return NO;
    }
    for (NSString *path in item.resultPath) {
        if ([path hasPrefix:@"/"] && ![self isAbsolutePathAllowed:path]) {
            return YES;
        }
    }
    for (QMResultItem *sub in item.subItemArray) {
        if ([self resultItemHasDisallowedAbsolutePath:sub]) {
            return YES;
        }
    }
    return NO;
}

+ (NSArray<NSString *> *)disallowedAbsolutePathsInResultDict:(NSDictionary *)resultDict
{
    return [self disallowedAbsolutePathsInResultDict:resultDict totalSize:NULL];
}

+ (NSArray<NSString *> *)disallowedAbsolutePathsInResultDict:(NSDictionary *)resultDict
                                                     totalSize:(NSUInteger *)outSize
{
    NSMutableArray<NSString *> *blocked = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    NSUInteger size = 0;
    for (NSDictionary *subItemDict in resultDict.allValues) {
        if (![subItemDict isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        for (NSArray *array in subItemDict.allValues) {
            if (![array isKindOfClass:[NSArray class]]) {
                continue;
            }
            for (QMResultItem *item in array) {
                [self _collectDisallowedPathsFromItem:item blocked:blocked seen:seen size:&size];
            }
        }
    }
    if (outSize) {
        *outSize = size;
    }
    return [blocked copy];
}

@end
