//
//  LoginItemManager.m
//
//  
//

#import "LoginItemManager.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@implementation LMLoginItem : NSObject
@end


@implementation LoginItemManager


+ (LMLoginItem *)loginItemAt:(NSString *)bundlePath {
    if (!bundlePath || bundlePath.length == 0) {
        return nil;
    }

    NSArray<LMLoginItem *> *allLoginItems = [self getAllValidLoginItems];
    return [self loginItemAt:bundlePath in:allLoginItems];
}

+ (LMLoginItem *)loginItemAt:(NSString *)bundlePath in:(NSArray<LMLoginItem *> *)allLoginItems {
    for (LMLoginItem *loginItem in allLoginItems) {
        NSString *urlPath = loginItem.bundlePath;
        if (!urlPath || urlPath.length < 2) {
            continue;
        }
        // LoginItem对应的 app 可能对应的不是主 bundle,而在其 bundle 下面.
        if ([bundlePath isEqualToString:urlPath] || [urlPath containsString:bundlePath]) {
            loginItem.hostBundlePath = bundlePath;
            return loginItem;
        }
    }

    return nil;
}

+ (NSArray<LMLoginItem *> *)getAllValidLoginItems {

    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seedValue;
        //Retrieve the list of Login Items and cast them to a NSArray so that it will be easier to iterate.
        NSArray *loginItemsArray = (__bridge_transfer NSArray *) LSSharedFileListCopySnapshot(loginItems, &seedValue);


        NSMutableArray *returnArray = [NSMutableArray array];
        for (NSUInteger i = 0; i < [loginItemsArray count]; i++) {
            id item = loginItemsArray[i];
            LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef) item;
            if (itemRef == NULL)
                continue;

            CFStringRef displayName = LSSharedFileListItemCopyDisplayName(itemRef);
            NSString *aNSString = (__bridge NSString *) displayName;
            if (!aNSString)
                continue;
            CFErrorRef error = NULL;  //  struct CF_BRIDGED_TYPE(NSError) __CFError * CFErrorRef

            // 特别注意:
            // 当登录项 Item 是一个Folder 类型(登录项可以添加文件夹),而这个 Foloer是对应一个远程服务器(通过 Finder-> Connect To Server添加远程文件夹,远程服务器的地址以 smb://开头)
            // 当利用LSSharedFileListItemCopyResolvedURL访问这个 LoginItem 对应的文件夹时, 会被弹窗提示是否允许访问啥的.
            // 解决办法: 方法参数LSSharedFileListResolutionFlags 有个值NoUserInteraction
            //                kLSSharedFileListNoUserInteraction = 1 << 0, /* no user interaction during resolution */
            //                kLSSharedFileListDoNotMountVolumes = 1 << 1

            // 另外,可以看到 LoginItem 有 Kind 标明类型(是 Foloer 还是 Application) 但暂未找到获取 Kind 类型的方法.  可能的方法: LSSharedFileListItemCopyProperty(LSSharedFileListItemRef   inItem,CFStringRef     inPropertyName)

            CFURLRef url = LSSharedFileListItemCopyResolvedURL(itemRef, kLSSharedFileListNoUserInteraction, &error);
            if (url == NULL || error != NULL) {
                if (error != NULL) {
                    CFRelease(error);
                }
                continue;
            }

            NSString *urlPath = [(__bridge NSURL *) url path];
            if (!urlPath) {
                continue;
            }

            LMLoginItem *loginItem = [[LMLoginItem alloc] init];
            loginItem.displayName = aNSString;
            loginItem.bundlePath = urlPath;
            [returnArray addObject:loginItem];

            CFRelease(url);
        }

        CFRelease(loginItems);

        return returnArray;
    }

    return nil;
}



+ (BOOL)removeLoginItemsByName:(NSString *)loginItemDisplayName {

    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seedValue;
        //Retrieve the list of Login Items and cast them to
        // a NSArray so that it will be easier to iterate.
        NSArray *loginItemsArray = (__bridge_transfer NSArray *) LSSharedFileListCopySnapshot(loginItems, &seedValue);

        for (NSUInteger i = 0; i < [loginItemsArray count]; i++) {
            id item = loginItemsArray[i];
            LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef) item;
            if (itemRef == NULL)
                continue;

            CFStringRef displayName = LSSharedFileListItemCopyDisplayName(itemRef);
            NSString *aNSString = (__bridge NSString *) displayName;
            if (!aNSString)
                continue;

            if ([loginItemDisplayName isEqualToString:aNSString]) {
                LSSharedFileListItemRemove(loginItems, itemRef);
            }
        }
        CFRelease(loginItems);
        return true;
    }

    return false;
}

@end

#pragma clang diagnostic pop
