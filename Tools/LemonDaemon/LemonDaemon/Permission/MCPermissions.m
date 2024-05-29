//
//  MCPermissions.m
//  LemonDaemon
//
//  Copyright © 2024 Tencent. All rights reserved.
//

#import "MCPermissions.h"
#import "NSString+Extension.h"

typedef NS_ENUM(NSUInteger, MCFullDiskAuthorationStatus) {
    MCFullDiskAuthorationStatusNotDetermined = 0,
    MCFullDiskAuthorationStatusDenied = 1,
    MCFullDiskAuthorationStatusAuthorized = 2,
};

int full_disk_access_permission(const char *__path__, const char *__path2__) {
    if (@available(macOS 10.14, *)) {
        //用户目录可能获取不准确，所以通过两种方法获取用户路径并进行验证
        NSString *userHomePath = [[NSString alloc] initWithUTF8String:__path__];
        NSString *userHomePath2 = [[NSString alloc] initWithUTF8String:__path2__];
        NSString *safariHomePath = [userHomePath stringByAppendingPathComponent:@"/Library/Safari"];
        NSError *error = nil;
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:safariHomePath error:&error];
        if(contents){
            NSLog(@"%s, safari contents count : %lu", __FUNCTION__, (unsigned long)contents.count);
            return MCFullDiskAuthorationStatusAuthorized;
        }else{
            NSLog(@"%s, safari contents is null,safariHomePath = %@", __FUNCTION__,safariHomePath);
            userHomePath = userHomePath2;
        }
        
        safariHomePath = [userHomePath stringByAppendingPathComponent:@"/Library/Safari"];
        contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:safariHomePath error:&error];
        if(contents){
            NSLog(@"%s, safari contents count : %lu", __FUNCTION__, (unsigned long)contents.count);
            return MCFullDiskAuthorationStatusAuthorized;
        }else{
            NSLog(@"%s, safari contents is null,safariHomePath = %@", __FUNCTION__,safariHomePath);
        }
        
        NSString *path = [userHomePath stringByAppendingPathComponent:@"/Library/Safari/LastSession.plist"];
        NSLog(@"%s,path: %@",__FUNCTION__, path);
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
        //发现有用户的系统上没有Bookmarks.plist文件，所以添加对其他文件进行检查
        if(!fileExists){
            NSLog(@"%s,%@ is not exist", __FUNCTION__, path);
            path = [userHomePath stringByAppendingPathComponent:@"Library/Safari/Bookmarks.plist"];
            fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
        }
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data == nil && fileExists)
        {
            return MCFullDiskAuthorationStatusDenied;
        }
        else if (fileExists)
        {
            return MCFullDiskAuthorationStatusAuthorized;
        }
        else
        {
            return MCFullDiskAuthorationStatusNotDetermined;
        }
    }else{
        return MCFullDiskAuthorationStatusAuthorized;
    }
}
