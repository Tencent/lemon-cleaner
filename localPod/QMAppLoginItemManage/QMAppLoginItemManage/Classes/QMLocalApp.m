//
//  QMLocalApp.m
//  QMAppLoginItemManage
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "QMLocalApp.h"

///app model
@implementation QMLocalApp

- (instancetype)initWithBundlePath:(NSString *)path
{
    self = [super init];
    if (self) {
        _bundlePath = path;
    }
    return self;
}
- (NSDictionary *)infoDict {
    if (!_infoDict) {
        /*
         获取info信息，先通过读取plist文件，这样的效率更高，如果读取失败(比如文件名不是Info.plist),
         则直接调用infoDictionary方法获取到Info信息。
         */

        NSDictionary *dict = nil;
        NSString *infoPath = [_bundlePath stringByAppendingString:@"/Contents/Info.plist"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:infoPath]) {
            dict = [[NSDictionary alloc] initWithContentsOfFile:infoPath];
        }
        if (!dict) {
            NSBundle *bundle = [NSBundle bundleWithPath:_bundlePath];
            dict = [bundle infoDictionary];
        }
        if (!dict) {
            return nil;
        }
        _infoDict = dict;
    }
    return _infoDict;
}

- (NSString *)bundleId {
    if (!_bundleId) {
        //获取bundleID
        _bundleId = self.infoDict[(NSString *) kCFBundleIdentifierKey];
        if ([_bundleId length] == 0) {
            return nil;
        }
    }
    return _bundleId;
}

- (NSString *)appName {
    if (!_appName) {
        _appName = [self.bundlePath lastPathComponent];
    }
    return _appName;
}

@end
