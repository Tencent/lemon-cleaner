//
//  QMAppLoginItem.m
//  LemonGroup
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "QMAppLoginItem.h"

@interface QMAppLoginItem(){
    
}

///save login item info
@property (nonatomic) NSDictionary *infoDict;

@end

/// App login item
@implementation QMAppLoginItem


-(instancetype)initWithAppPath:(NSString *)appPath loginItemPath: (NSString *) loginItempath  loginItemType: (LoginItemType) type{
    self = [super initWithAppPath:appPath loginItemType:type];
    self.loginItemPath = loginItempath;
    self.loginItemAppName = loginItempath.lastPathComponent;
    return self;
}

- (NSDictionary *)infoDict {
    if (!_infoDict) {
        /*
         获取info信息，先通过读取plist文件，这样的效率更高，如果读取失败(比如文件名不是Info.plist),
         则直接调用infoDictionary方法获取到Info信息。
         */

        NSDictionary *dict = nil;
        NSString *infoPath = [self.loginItemPath stringByAppendingString:@"/Contents/Info.plist"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:infoPath]) {
            dict = [[NSDictionary alloc] initWithContentsOfFile:infoPath];
        }
        if (!dict) {
            NSBundle *bundle = [NSBundle bundleWithPath:self.loginItemPath];
            dict = [bundle infoDictionary];
        }

        if (!dict) {
            return nil;
        }
        _infoDict = dict;
    }
    return _infoDict;
}

- (NSString *)loginItemBundleId {
    if (!_loginItemBundleId) {
        //获取bundleID
        _loginItemBundleId = self.infoDict[(NSString *) kCFBundleIdentifierKey];
        if ([_loginItemBundleId length] == 0) {
            return nil;
        }
    }
    return _loginItemBundleId;
}

@end
