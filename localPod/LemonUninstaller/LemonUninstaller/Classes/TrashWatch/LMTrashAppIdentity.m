//
//  LMTrashAppIdentity.m
//  LemonUninstaller
//

#import "LMTrashAppIdentity.h"

@implementation LMTrashAppIdentity

+ (instancetype)identityWithBundleID:(NSString *)bundleID
                             appName:(NSString *)appName
                     executableName:(NSString *)executableName
                           showName:(NSString *)showName {
    LMTrashAppIdentity *identity = [[LMTrashAppIdentity alloc] init];
    identity.bundleID = bundleID;
    identity.appName = appName;
    identity.executableName = executableName;
    identity.showName = showName;
    return identity;
}

@end

@implementation LMTrashInstalledMatch

+ (NSString *)normalizedString:(NSString *)string {
    if (![string isKindOfClass:[NSString class]] || string.length == 0) {
        return @"";
    }
    return [[string stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
}

+ (NSString *)regexEscape:(NSString *)string {
    if (string.length == 0) {
        return string ?: @"";
    }
    NSMutableString *result = [string mutableCopy];
    NSArray *escapes = @[@"\\", @"/", @"|", @"{", @"}", @"(", @")", @"[", @"]", @"*", @".", @"?", @"+", @"^", @"$"];
    for (NSString *aChar in escapes) {
        NSString *escapeChar = [@"\\" stringByAppendingString:aChar];
        [result replaceOccurrencesOfString:aChar withString:escapeChar options:0 range:NSMakeRange(0, result.length)];
    }
    return result;
}

+ (NSString *)companySegmentFromBundleID:(NSString *)bundleID {
    if (![bundleID isKindOfClass:[NSString class]] || bundleID.length == 0) {
        return nil;
    }
    if ([bundleID isEqualToString:@"com.jetbrains.apps.activator"]) {
        return @"jetbrains";
    }
    NSArray *bundleComponents = [bundleID componentsSeparatedByString:@"."];
    if (bundleComponents.count == 3) {
        NSString *companyName = bundleComponents[1];
        companyName = [self normalizedString:companyName];
        return companyName.length > 0 ? companyName : nil;
    }
    return nil;
}

+ (NSPredicate *)bundleIDPredicateForClaimedBundleID:(NSString *)bundleID {
    NSString *matchBundle = [self normalizedString:bundleID];
    if (matchBundle.length == 0) {
        return nil;
    }
    NSString *footerRegex = @"(\\..*){0,}\\b";
    NSString *bundleIDRegex = [NSString stringWithFormat:@"\\b(\\w+\\.)?(%@)%@", [self regexEscape:matchBundle], footerRegex];
    return [NSPredicate predicateWithFormat:@"SELF MATCHES %@", bundleIDRegex];
}

+ (BOOL)name:(LMTrashAppIdentity *)claimed matchesInstalled:(LMTrashAppIdentity *)installed {
    NSArray *claimedNames = @[
        [self normalizedString:claimed.appName],
        [self normalizedString:claimed.executableName],
        [self normalizedString:claimed.showName]
    ];
    NSArray *installedNames = @[
        [self normalizedString:installed.appName],
        [self normalizedString:installed.executableName],
        [self normalizedString:installed.showName]
    ];
    for (NSString *claimedName in claimedNames) {
        if (claimedName.length == 0) {
            continue;
        }
        for (NSString *installedName in installedNames) {
            if (installedName.length == 0) {
                continue;
            }
            if ([claimedName isEqualToString:installedName]) {
                return YES;
            }
        }
    }
    return NO;
}

+ (BOOL)claimedIdentity:(LMTrashAppIdentity *)claimed
     matchesInstalled:(NSArray<LMTrashAppIdentity *> *)installed {
    if (!claimed || installed.count == 0) {
        return NO;
    }
    NSPredicate *bundlePred = [self bundleIDPredicateForClaimedBundleID:claimed.bundleID];
    NSString *claimedCompany = [self companySegmentFromBundleID:claimed.bundleID];

    for (LMTrashAppIdentity *item in installed) {
        if (![item isKindOfClass:[LMTrashAppIdentity class]]) {
            continue;
        }
        if (bundlePred) {
            NSString *installedID = [self normalizedString:item.bundleID];
            if (installedID.length > 0 && [bundlePred evaluateWithObject:installedID]) {
                return YES;
            }
        }
        if ([self name:claimed matchesInstalled:item]) {
            return YES;
        }
        if (claimedCompany.length > 0) {
            NSString *installedCompany = [self companySegmentFromBundleID:item.bundleID];
            if (installedCompany.length > 0 && [claimedCompany isEqualToString:installedCompany]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
