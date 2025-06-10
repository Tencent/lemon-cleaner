//
//  Owl2SelectAppItem.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2SelectAppItem.h"

@implementation Owl2SelectAppItem

- (instancetype)initWithAppItem:(Owl2AppItem *)appItem {
    self = [super init];
    if (self) {
         _name           = appItem.name;
         _executableName = appItem.executableName;
         _iconPath       = appItem.iconPath;
         _identifier     = appItem.identifier;
         _appPath        = appItem.appPath;
         _sysApp         = appItem.sysApp;
         _isWatchAudio   = appItem.isWatchAudio;
         _isWatchCamera  = appItem.isWatchCamera;
         _isWatchSpeaker = appItem.isWatchSpeaker;
    }
    return self;
}

@end
