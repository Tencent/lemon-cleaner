//
//  QMFullDiskAccessManager.m
//  QMCoreFunction
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "QMFullDiskAccessManager.h"
#import "NSString+Extension.h"

@implementation QMFullDiskAccessManager

// app store 模式下一次探测，【完全磁盘访问权限】应用列表无lemon lite
// macos 13.0以下 一次探测，【完全磁盘访问权限】应用列表无lemon monitor
// 最初修改为单例的原因是UI上调用getFullDiskAuthorationStatus时，日志过多
+(QMFullDiskAuthorationStatus)getFullDiskAuthorationStatus{
    return [self __getFullDiskAuthorationStatusWithLog:YES];
}

+ (QMFullDiskAuthorationStatus)getFullDiskAuthorationStatusWithoutLog {
    return [self __getFullDiskAuthorationStatusWithLog:NO];
}

+(QMFullDiskAuthorationStatus)__getFullDiskAuthorationStatusWithLog:(BOOL)hasLog {
    if (@available(macOS 10.14, *)) {
        //用户目录可能获取不准确，所以通过两种方法获取用户路径并进行验证
        NSString *userHomePath = [NSString getUserHomePath];
        NSString *userHomePath2 = [@"~" stringByExpandingTildeInPath];
        NSString *safariHomePath = [userHomePath stringByAppendingPathComponent:@"/Library/Safari"];
        NSError *error = nil;
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:safariHomePath error:&error];
        if(contents){
            !hasLog ?: NSLog(@"%s, safari contents count : %lu", __FUNCTION__, (unsigned long)contents.count);
            return QMFullDiskAuthorationStatusAuthorized;
        }else{
            !hasLog ?: NSLog(@"%s, safari contents is null,safariHomePath = %@", __FUNCTION__,safariHomePath);
            userHomePath = userHomePath2;
        }
        
        safariHomePath = [userHomePath stringByAppendingPathComponent:@"/Library/Safari"];
        contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:safariHomePath error:&error];
        if(contents){
            !hasLog ?: NSLog(@"%s, safari contents count : %lu", __FUNCTION__, (unsigned long)contents.count);
            return QMFullDiskAuthorationStatusAuthorized;
        }else{
            !hasLog ?: NSLog(@"%s, safari contents is null,safariHomePath = %@", __FUNCTION__,safariHomePath);
        }
        
        NSString *path = [userHomePath stringByAppendingPathComponent:@"/Library/Safari/LastSession.plist"];
        !hasLog ?: NSLog(@"%s,path: %@",__FUNCTION__, path);
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
        //发现有用户的系统上没有Bookmarks.plist文件，所以添加对其他文件进行检查
        if(!fileExists){
            !hasLog ?: NSLog(@"%s,%@ is not exist", __FUNCTION__, path);
            path = [userHomePath stringByAppendingPathComponent:@"Library/Safari/Bookmarks.plist"];
            fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
        }
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data == nil && fileExists)
        {
            return QMFullDiskAuthorationStatusDenied;
        }
        else if (fileExists)
        {
            return QMFullDiskAuthorationStatusAuthorized;
        }
        else
        {
            return QMFullDiskAuthorationStatusNotDetermined;
        }
    }else{
        return QMFullDiskAuthorationStatusAuthorized;
    }
    
}

+(void)openFullDiskAuthPrefreence{
    NSURL *URL = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"];
    [[NSWorkspace sharedWorkspace] openURL:URL];
}

@end
