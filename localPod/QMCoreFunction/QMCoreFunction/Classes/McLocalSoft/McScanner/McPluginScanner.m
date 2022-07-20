//
//  McPluginScanner.m
//  McSoftware
//
//  Created by developer on 10/18/12.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import "McPluginScanner.h"

@interface McScanner (Private)
- (void)updateResult:(McLocalSoft *)localSoft;
@end

@implementation McInternetScanner

- (NSArray *)scanPaths
{
    return  @[@"/Library/Internet Plug-Ins",
              [@"~/Library/Internet Plug-Ins" stringByExpandingTildeInPath]];
}

- (McLocalType)scanType
{
    return kMcLocalFlagInternet;
}

- (BOOL)fileVaild:(NSString *)filePath
{
    if (![super fileVaild:filePath])
    {
        return NO;
    }
    
    NSString *extension = [[filePath pathExtension] lowercaseString];
    if ([extension isEqualToString:@"plugin"] ||
        [extension isEqualToString:@"bundle"] ||
        [extension isEqualToString:@"webplugin"])
    {
        return YES;
    }
    
    return NO;
}

- (void)updateResult:(McLocalSoft *)localSoft
{
    //获取插件的名字属性
    if (localSoft)
    {
        NSBundle *bundle = [NSBundle bundleWithPath:localSoft.bundlePath];
        if (bundle)
        {
            NSString *webPluginName = [bundle objectForInfoDictionaryKey:@"WebPluginName"];
            if (webPluginName && [webPluginName isKindOfClass:[NSString class]])
            {
                localSoft.showName = webPluginName;
            }
        }
    }
    
    [super updateResult:localSoft];
}

@end

#pragma mark -

@implementation McSpotlightScanner

- (NSArray *)scanPaths
{
    return  @[@"/Library/Spotlight",
              [@"~/Library/Spotlight" stringByExpandingTildeInPath]];
}

- (McLocalType)scanType
{
    return kMcLocalFlagSpotlight;
}

- (BOOL)fileVaild:(NSString *)filePath
{
    if (![super fileVaild:filePath])
    {
        return NO;
    }
    
    NSString *extension = [[filePath pathExtension] lowercaseString];
    if ([extension isEqualToString:@"mdimporter"])
    {
        return YES;
    }
    return NO;
}

@end

#pragma mark -

@implementation McQuickLookScanner

- (NSArray *)scanPaths
{
    return  @[@"/Library/QuickLook",
              [@"~/Library/QuickLook" stringByExpandingTildeInPath]];
}

- (McLocalType)scanType
{
    return kMcLocalFlagQuickLook;
}

- (BOOL)fileVaild:(NSString *)filePath
{
    if (![super fileVaild:filePath])
    {
        return NO;
    }
    
    NSString *extension = [[filePath pathExtension] lowercaseString];
    if ([extension isEqualToString:@"qlgenerator"])
    {
        return YES;
    }
    return NO;
}

@end

#pragma mark -

@implementation McDictionaryScanner

- (NSArray *)scanPaths
{
    return  @[@"/Library/Dictionaries",
              [@"~/Library/Dictionaries" stringByExpandingTildeInPath]];
}

- (McLocalType)scanType
{
    return kMcLocalFlagDictionary;
}

- (BOOL)fileVaild:(NSString *)filePath
{
    if (![super fileVaild:filePath])
    {
        return NO;
    }
    
    NSString *extension = [[filePath pathExtension] lowercaseString];
    if ([extension isEqualToString:@"dictionary"])
    {
        return YES;
    }
    return NO;
}

@end

#pragma mark -

@implementation McPreferencePaneScanner

- (NSArray *)scanPaths
{
    return @[@"/Library/PreferencePanes",
             [@"~/Library/PreferencePanes" stringByExpandingTildeInPath]];
}

- (McLocalType)scanType
{
    return kMcLocalFlagPreferencePane;
}

- (BOOL)fileVaild:(NSString *)filePath
{
    if (![super fileVaild:filePath])
    {
        return NO;
    }
    
    NSString *extension = [[filePath pathExtension] lowercaseString];
    if ([extension isEqualToString:@"prefpane"])
    {
        return YES;
    }
    return NO;
}

@end

#pragma mark -

@implementation McScreensaverScanner

- (NSArray *)scanPaths
{
    return @[@"Library/Screen Savers",
             [@"~/Library/Screen Savers" stringByExpandingTildeInPath]];
}

- (McLocalType)scanType
{
    return kMcLocalFlagScreenSaver;
}

- (BOOL)fileVaild:(NSString *)filePath
{
    if (![super fileVaild:filePath])
    {
        return NO;
    }
    
    NSString *extension = [[filePath pathExtension] lowercaseString];
    if ([extension isEqualToString:@"saver"])
    {
        return YES;
    }
    return NO;
}

@end

#pragma mark -

@implementation McWidgetScanner

- (NSArray *)scanPaths
{
    return @[@"/Library/Widgets",
             [@"~/Library/Widgets" stringByExpandingTildeInPath]];
}

- (McLocalType)scanType
{
    return kMcLocalFlagWidget;
}

- (BOOL)fileVaild:(NSString *)filePath
{
    if (![super fileVaild:filePath])
    {
        return NO;
    }
    
    NSString *extension = [[filePath pathExtension] lowercaseString];
    if ([extension isEqualToString:@"wdgt"])
    {
        return YES;
    }
    return NO;
}

@end