//
//  QMDisk.m
//  AFNetworking
//
//

#import "QMDisk.h"
#include <sys/mount.h>

int isReadOnly(const char *path) {
    struct statfs buf;

    // 获取文件系统信息
    if (statfs(path, &buf) != 0) {
        return -1; // 错误处理
    }

    // 检查文件系统是否为只读
    if (buf.f_flags & MNT_RDONLY) {
        return 1; // 只读
    }

    return 0; // 可写
}

@implementation QMDisk

+ (BOOL)isReadOnly:(NSString *)path {
    int result = isReadOnly([path UTF8String]);
    if (result == -1) {
        return NO;
    }
    if (result == 0) {
        // 可写
        return NO;
    }
    if (result == 1) {
        // 只读
        return YES;
    }
    return NO;
}

@end
