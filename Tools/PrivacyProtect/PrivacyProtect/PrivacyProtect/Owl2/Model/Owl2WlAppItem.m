//
//  Owl2WlAppItem.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2WlAppItem.h"

@implementation Owl2WlAppItem

- (instancetype)initWithAppItem:(Owl2AppItem *)appItem {
    self = [super init];
    if (self) {
        _name             = appItem.name;
        _executableName   = appItem.executableName;
        _iconPath         = appItem.iconPath;
        _identifier       = appItem.identifier;
        _appPath          = appItem.appPath;
        _sysApp           = appItem.sysApp;
        _isWatchAudio     = appItem.isWatchAudio;
        _isWatchCamera    = appItem.isWatchCamera;
        _isWatchSpeaker   = appItem.isWatchSpeaker;
        _isWatchScreen    = appItem.isWatchScreen;
        _isWatchAutomatic = appItem.isWatchAutomatic;
    }
    return self;
}

@end

@implementation NSDictionary (Owl2AppItem)

- (NSArray<Owl2WlAppItem *> *)owl_toWlAppItemsFromContainExpandWlList:(NSArray<Owl2WlAppItem *> *)list {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:self.count];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:list.count];
    for (Owl2WlAppItem *wlAppItem in list) {
        if (wlAppItem.identifier && wlAppItem.isExpand) {
            [dict setObject:wlAppItem forKey:wlAppItem.identifier];
        }
    }
    
    for (NSString *bundleId in self.allKeys) {
        Owl2AppItem *appItem = self[bundleId];
        Owl2WlAppItem *wlAppItem = [[Owl2WlAppItem alloc] initWithAppItem:appItem];
        Owl2WlAppItem *expandAppItem = dict[bundleId];
        wlAppItem.isExpand = expandAppItem.isExpand;
        [array addObject:wlAppItem];
    }
    return array.copy;
}

@end
