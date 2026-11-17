//
//  LMTrashCodeSign.m
//  LemonUninstaller
//

#import "LMTrashCodeSign.h"
#import <Security/Security.h>

@implementation LMTrashCodeSign

+ (NSString *)teamIDOfCodeAtPath:(NSString *)path {
    if (![path isKindOfClass:[NSString class]] || path.length == 0) {
        return nil;
    }
    NSURL *url = [NSURL fileURLWithPath:path];
    if (!url) {
        return nil;
    }

    SecStaticCodeRef staticCode = NULL;
    OSStatus status = SecStaticCodeCreateWithPath((__bridge CFURLRef)url, kSecCSDefaultFlags, &staticCode);
    if (status != errSecSuccess || !staticCode) {
        return nil;
    }

    CFDictionaryRef signingInfo = NULL;
    status = SecCodeCopySigningInformation(staticCode, kSecCSSigningInformation, &signingInfo);
    CFRelease(staticCode);
    if (status != errSecSuccess || !signingInfo) {
        if (signingInfo) {
            CFRelease(signingInfo);
        }
        return nil;
    }

    NSString *teamID = ((__bridge NSDictionary *)signingInfo)[(NSString *)kSecCodeInfoTeamIdentifier];
    CFRelease(signingInfo);
    if (![teamID isKindOfClass:[NSString class]] || teamID.length == 0) {
        return nil;
    }
    return teamID;
}

@end
