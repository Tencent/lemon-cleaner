//
//  Owl2LogProcessItem.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2LogProcessItem.h"
#import "LemonDaemonConst.h"

static NSString * const kSuffixApp = @".app/";
static NSString * const kSuffixAppex = @".appex/";

@implementation Owl2LogProcessItem

- (instancetype)initWithProcessDic:(NSDictionary *)dic {
    self = [super init];
    if (self) {
        _originalDic = dic;
        
        _pid            = dic[OWL_PROC_ID];
        _name           = dic[OWL_PROC_NAME];
        _executablePath = dic[OWL_PROC_PATH];
        _deviceType     = dic[OWL_DEVICE_TYPE];
        _deviceExtra    = dic[OWL_DEVICE_EXTRA];
        _deviceName     = dic[OWL_DEVICE_NAME];
        _identifier     = dic[OWL_BUNDLE_ID];
        _delta          = dic[OWL_PROC_DELTA];
        [self updateAppInfoWithExecutablePath:self.executablePath];
    }
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *muDic = [[NSMutableDictionary alloc] init];
    if (self.pid) [muDic setObject:self.pid forKey:OWL_PROC_ID];
    if (self.name) [muDic setObject:self.name forKey:OWL_PROC_NAME];
    if (self.executablePath) [muDic setObject:self.executablePath forKey:OWL_PROC_PATH];
    if (self.deviceType) [muDic setObject:self.deviceType forKey:OWL_DEVICE_TYPE];
    if (self.deviceExtra) [muDic setObject:self.deviceExtra forKey:OWL_DEVICE_EXTRA];
    if (self.deviceName) [muDic setObject:self.deviceName forKey:OWL_DEVICE_NAME];
    if (self.identifier) [muDic setObject:self.identifier forKey:OWL_BUNDLE_ID];
    if (self.delta) [muDic setObject:self.delta forKey:OWL_PROC_DELTA];
    if (self.appItem) [muDic setObject:self.appItem.toDictionary forKey:Owl2AppItemKey];
    if (self.parentAppItem) [muDic setObject:self.parentAppItem.toDictionary forKey:Owl2ParentAppItemKey];
    return muDic.copy;
}

- (void)updateAppInfoWithExecutablePath:(NSString *)executablePath {
    if (![executablePath isKindOfClass:NSString.class]) {
        return;
    }
    NSInteger count = [self countAppAndAppExInString:executablePath];
    if (count == 0) {
        _appItem = nil;
        _parentAppItem = nil;
    } else if (count == 1) {
        _appItem = [self createAppItemWithExecutablePath:executablePath options:NSBackwardsSearch];
        _parentAppItem = nil;
    } else {
        _appItem = [self createAppItemWithExecutablePath:executablePath options:NSBackwardsSearch];
        _parentAppItem = [self createAppItemWithExecutablePath:executablePath options:0];
    }
}

- (Owl2AppItem *)createAppItemWithExecutablePath:(NSString *)executablePath options:(NSStringCompareOptions)mask {
    NSString *appPath = [self appPathFromExecutablePath:self.executablePath fileExtension:kSuffixApp options:mask];
    appPath = appPath ? : [self appPathFromExecutablePath:self.executablePath fileExtension:kSuffixAppex options:mask];
    return [[Owl2AppItem alloc] initWithAppPath:appPath];
}


// mask = 0 默认从前往后搜索；mask = NSBackwardsSearch 从后往前搜索
- (NSString *)appPathFromExecutablePath:(NSString *)executablePath fileExtension:(NSString *)fileExtension options:(NSStringCompareOptions)mask {
    NSRange range = [executablePath rangeOfString:fileExtension options:mask];
    if (range.location != NSNotFound) {
        return [executablePath substringToIndex:range.location + range.length];
    }
    return nil;
}

- (NSInteger)countAppAndAppExInString:(NSString *)string {
    // 定义要查找的后缀
    NSArray *extensions = @[kSuffixApp, kSuffixAppex];
    NSInteger count = 0;

    // 遍历后缀数组
    for (NSString *ext in extensions) {
        NSRange range = [string rangeOfString:ext];
        while (range.location != NSNotFound) {
            count++;
            // 从找到的位置开始，继续查找下一个
            range = [string rangeOfString:ext options:0 range:NSMakeRange(range.location + range.length, string.length - (range.location + range.length))];
        }
    }
    return count;
}

@end

@implementation Owl2LogProcessItem (QMConvenient)

- (Owl2AppItem *)convenient_mainAppItem {
    if (self.parentAppItem) {
        return self.parentAppItem;
    }
    if (self.appItem) {
        return self.appItem;
    }
    return nil;
}

- (NSString *)convenient_identifier {
    if (self.parentAppItem.identifier) {
        return self.parentAppItem.identifier;
    }
    
    if (self.appItem.identifier) {
        return self.appItem.identifier;
    }
    
    if (self.identifier) {
        return self.identifier;
    }
    
    return nil;
}

- (NSString *)convenient_name {
    if (self.parentAppItem.name) {
        return self.parentAppItem.name;
    }
    
    if (self.appItem.name) {
        return self.appItem.name;
    }
    
    if (self.name) {
        return self.name;
    }
    
    return nil;
}

- (NSString *)convenient_appPath {
    if (self.parentAppItem.appPath) {
        return self.parentAppItem.appPath;
    }
    
    if (self.appItem.appPath) {
        return self.appItem.appPath;
    }
    
    if (self.executablePath) {
        return self.executablePath;
    }
    
    return nil;
}

- (Owl2LogThirdAppAction)convenient_thirdAppAction {
    NSInteger count = self.delta.intValue;
    if (count > 0) {
        return Owl2LogThirdAppActionStart;
    } else if (count < 0) {
        return Owl2LogThirdAppActionStop;
    } else {
        return Owl2LogThirdAppActionNone;
    }
}

- (Owl2LogThirdAppAction)convenient_thirdAppActionForLog {
    Owl2LogThirdAppAction thirdAppAction = [self convenient_thirdAppAction];
    if (self.convenient_hardware == Owl2LogHardwareScreen) {
        if (thirdAppAction == Owl2LogThirdAppActionStart) {
            if ([self.deviceExtra boolValue]) {
                return Owl2LogThirdAppActionStartForScreenshot;
            }
            return Owl2LogThirdAppActionStartForScreenRecording;
        } else if (thirdAppAction == Owl2LogThirdAppActionStop) {
            if ([self.deviceExtra boolValue]) {
                return Owl2LogThirdAppActionStopForScreenshot;
            }
            return Owl2LogThirdAppActionStopForScreenRecording;
        }
    }
    return thirdAppAction;
}

- (Owl2LogHardware)convenient_hardware {
    return (Owl2LogHardware)self.deviceType.intValue;
}

- (BOOL)convenient_hitWhiteList {
    if (self.convenient_hardware == Owl2LogHardwareVedio) {
        if (self.convenient_mainAppItem.isWatchCamera) {
            return YES;
        }
    } else if (self.convenient_hardware == Owl2LogHardwareAudio) {
        if (self.convenient_mainAppItem.isWatchAudio) {
            return YES;
        }
    } else if (self.convenient_hardware == Owl2LogHardwareSystemAudio) {
        if (self.convenient_mainAppItem.isWatchSpeaker) {
            return YES;
        }
    } else if (self.convenient_hardware == Owl2LogHardwareScreen) {
        if (self.convenient_mainAppItem.isWatchScreen) {
            return YES;
        }
    }
    return NO;
}

@end
