//
//  Owl2AppItem.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2AppItem.h"

static NSString * kAppName(NSBundle *bundle) {
    NSString *appName = nil;
    appName = [bundle localizedInfoDictionary][@"CFBundleDisplayName"];
    if (!appName) {
        appName = [bundle localizedInfoDictionary][@"CFBundleName"];
    }
    if (!appName) {
        appName = [bundle infoDictionary][@"CFBundleName"];
    }
    if (!appName) {
        appName = [bundle infoDictionary][@"CFBundleExecutable"];
    }
    return appName;
}

@interface Owl2AppItem ()
// 白名单开关修改记录
// key Owl2LogHardware
// value bool
@property (nonatomic, strong) NSMutableDictionary *watchModifyRecords;
@end

@implementation Owl2AppItem

- (void)dealloc{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithAppPath:(NSString *)appPath {
    self = [super init];
    if (self) {
        [self updateAppInfoWithAppPath:appPath];
        [self addNotificationObserver];
    }
    return self;
}

- (instancetype)initWithDic:(NSDictionary *)dic {
    self = [super init];
    if (self) {
        _name = dic[OwlAppName];
        _executableName = dic[OwlExecutableName];
        _iconPath = dic[OwlAppIcon];
        _identifier = dic[OwlIdentifier];
        _appPath = dic[OwlBubblePath];
        _sysApp = [dic[OwlAppleApp] boolValue];
        _isWatchAudio = [dic[OwlWatchAudio] boolValue];
        _isWatchCamera = [dic[OwlWatchCamera] boolValue];
        _isWatchSpeaker = [dic[OwlWatchSpeaker] boolValue];
        _isWatchScreen = [dic[OwlWatchScreen] boolValue];
        _isWatchAutomatic = [dic[OwlWatchAutomatic] boolValue];
        [self addNotificationObserver];
    }
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *muDic = [[NSMutableDictionary alloc] init];
    if (self.name) [muDic setObject:self.name forKey:OwlAppName];
    if (self.executableName) [muDic setObject:self.executableName forKey:OwlExecutableName];
    if (self.iconPath) [muDic setObject:self.iconPath forKey:OwlAppIcon];
    if (self.identifier) [muDic setObject:self.identifier forKey:OwlIdentifier];
    if (self.appPath) [muDic setObject:self.appPath forKey:OwlBubblePath];
    [muDic setObject:@(self.sysApp) forKey:OwlAppleApp];
    [muDic setObject:@(self.isWatchAudio) forKey:OwlWatchAudio];
    [muDic setObject:@(self.isWatchCamera) forKey:OwlWatchCamera];
    [muDic setObject:@(self.isWatchSpeaker) forKey:OwlWatchSpeaker];
    [muDic setObject:@(self.isWatchScreen) forKey:OwlWatchScreen];
    [muDic setObject:@(self.isWatchAutomatic) forKey:OwlWatchAutomatic];
    return muDic.copy;
}

- (void)addNotificationObserver {
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(userChangeLanguage:)
                                                            name:@"user_language_change"
                                                          object:nil];
}

- (void)userChangeLanguage:(NSNotification *)notification {
    [self updateAppInfoWithAppPath:self.appPath];
}

- (void)updateAppInfoWithAppPath:(NSString *)appPath {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:appPath]){
        return;
    }
    NSBundle *bundle = [NSBundle bundleWithPath:appPath];
    if (!bundle) {
        return;
    }
    
    NSString *icon = nil;
    if ([[[bundle infoDictionary] allKeys] containsObject:@"CFBundleIconFile"]) {
        icon = [[bundle infoDictionary] objectForKey:@"CFBundleIconFile"];
        icon = [[bundle resourcePath] stringByAppendingPathComponent:icon];
        if ([[icon pathExtension] isEqualToString:@""]) {
            icon = [icon stringByAppendingPathExtension:@"icns"];
        }
    }
    _iconPath = icon;
    _name = kAppName(bundle);
    _identifier = [[bundle infoDictionary] objectForKey:@"CFBundleIdentifier"];
    _executableName = [[bundle infoDictionary] objectForKey:@"CFBundleExecutable"];
    _sysApp = [self.identifier hasPrefix:@"com.apple"];
    _appPath = appPath;
}

- (void)syncUpdateWL:(NSDictionary *)dic {
    if (![self.identifier isKindOfClass:NSString.class]) {
        return;
    }
    if (self.identifier.length == 0) {
        return;
    }
    Owl2AppItem *appItem = dic[self.identifier];
    _isWatchAudio = appItem.isWatchAudio;
    _isWatchCamera = appItem.isWatchCamera;
    _isWatchSpeaker = appItem.isWatchSpeaker;
    _isWatchScreen = appItem.isWatchScreen;
    _isWatchAutomatic = appItem.isWatchAutomatic;
}

- (void)setWatchValue:(BOOL)value forHardware:(Owl2LogHardware)hardware {
    [self.watchModifyRecords setObject:@(YES) forKey:@(hardware)];
    switch (hardware) {
        case Owl2LogHardwareAudio:
            _isWatchAudio = value;
            break;
        case Owl2LogHardwareVedio:
            _isWatchCamera = value;
            break;
        case Owl2LogHardwareSystemAudio:
            _isWatchSpeaker = value;
            break;
        case Owl2LogHardwareScreen:
            _isWatchScreen = value;
            break;
        case Owl2LogHardwareAutomation:
            _isWatchAutomatic = value;
            break;
            
        default:
            break;
    }
}

- (void)mergeWithAnother:(Owl2AppItem *)another {
    if (self.identifier && another.identifier) {
        if (![self.identifier isEqualToString:another.identifier]) {
            // 不一致直接返回
            return;
        }
    }
    
    _name           = another.name;
    _executableName = another.executableName;
    _iconPath       = another.iconPath;
//    _identifier     = another.identifier;  完全一致才能合并
    _appPath        = another.appPath;
    _sysApp         = another.sysApp;
    
    if ([another.watchModifyRecords[@(Owl2LogHardwareAudio)] boolValue]) {
        _isWatchAudio = another.isWatchAudio;
    }
    
    if ([another.watchModifyRecords[@(Owl2LogHardwareVedio)] boolValue]) {
        _isWatchCamera = another.isWatchCamera;
    }
    
    if ([another.watchModifyRecords[@(Owl2LogHardwareSystemAudio)] boolValue]) {
        _isWatchSpeaker = another.isWatchSpeaker;
    }
    
    if ([another.watchModifyRecords[@(Owl2LogHardwareScreen)] boolValue]) {
        _isWatchScreen = another.isWatchScreen;
    }
    
    if ([another.watchModifyRecords[@(Owl2LogHardwareAutomation)] boolValue]) {
        _isWatchAutomatic = another.isWatchAutomatic;
    }
}

- (void)enableAllWatchSwitch {
    [self setWatchValue:YES forHardware:Owl2LogHardwareAudio];
    [self setWatchValue:YES forHardware:Owl2LogHardwareVedio];
    [self setWatchValue:YES forHardware:Owl2LogHardwareSystemAudio];
    [self setWatchValue:YES forHardware:Owl2LogHardwareScreen];
    [self setWatchValue:YES forHardware:Owl2LogHardwareAutomation];
}

#pragma mark - getter

- (NSMutableDictionary *)watchModifyRecords {
    if (!_watchModifyRecords) {
        _watchModifyRecords = [[NSMutableDictionary alloc] init];
    }
    return _watchModifyRecords;
}

@end

