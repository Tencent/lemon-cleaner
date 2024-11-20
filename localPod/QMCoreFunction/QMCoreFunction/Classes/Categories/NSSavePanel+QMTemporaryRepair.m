//
//  NSSavePanel+QMTemporaryRepair.m
//  AFNetworking
//
//

#import "NSSavePanel+QMTemporaryRepair.h"
#import "QMMethodSwapper.h"

@implementation NSSavePanel (QMTemporaryRepair)

// 大于15的系统才生效
// MacOS 15 directoryURL设置失效
// 将来若系统修复该bug，则可将该类删除
+ (void)load {
    if (@available(macOS 15.0, *)) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [QMMethodSwapper swapInstanceMethodInClass:NSSavePanel.class originalSelector:@selector(setDirectoryURL:) swappedSelector:@selector(qm_setDirectoryURL:)];
        });
    }
}

- (void)qm_setDirectoryURL:(NSURL *)directoryURL {
    [self qm_setDirectoryURL:directoryURL];
    NSLog(@"(%s %s) directoryURL is %@", __FILE__, __PRETTY_FUNCTION__, directoryURL);
    NSLog(@"(%s %s) self.directoryURL is %@", __FILE__, __PRETTY_FUNCTION__, self.directoryURL);
    if (!self.directoryURL) {
        self.directory = directoryURL.absoluteString;
    }
}

@end
