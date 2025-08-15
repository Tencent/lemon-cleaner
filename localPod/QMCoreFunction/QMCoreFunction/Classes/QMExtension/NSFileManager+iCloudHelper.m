//
//  NSFileManager+iCloudHelper.m
//  QMCoreFunction
//
//  Copyright © 2024 Tencent. All rights reserved.
//

#import "NSFileManager+iCloudHelper.h"

@implementation NSFileManager (iCloudHelper)

- (BOOL)qm_isICloudFileAtPath:(NSString *)path {
    if (!path || path.length == 0) {
        return NO;
    }
    
    // 使用URL资源检查是否为iCloud文件
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    NSNumber *isUbiquitous = nil;
    
    BOOL success = [fileURL getResourceValue:&isUbiquitous 
                                      forKey:NSURLIsUbiquitousItemKey 
                                       error:&error];
    
    if (!success || error) {
        return NO;
    }
    
    return [isUbiquitous boolValue];
}

- (BOOL)qm_isICloudFileDownloadedAtPath:(NSString *)path {
    if (![self qm_isICloudFileAtPath:path]) {
        return YES; // 本地文件认为是"已下载"的
    }
    
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    NSString *downloadStatus = nil;
    
    BOOL success = [fileURL getResourceValue:&downloadStatus 
                                      forKey:NSURLUbiquitousItemDownloadingStatusKey 
                                       error:&error];
    
    if (!success || error) {
        return NO;
    }
    
    return [downloadStatus isEqualToString:NSURLUbiquitousItemDownloadingStatusCurrent];
}

- (nullable NSArray<NSString *> *)qm_safeContentsOfDirectoryAtPath:(NSString *)path {
    if (!path || ![self fileExistsAtPath:path]) {
        return nil;
    }
    
    // 检查是否为iCloud目录
    if ([self qm_isICloudFileAtPath:path]) {
        // 对于iCloud目录，使用URL方式安全获取内容，避免触发下载
        NSURL *dirURL = [NSURL fileURLWithPath:path];
        NSError *error = nil;
        
        NSArray<NSURL *> *urls = [self contentsOfDirectoryAtURL:dirURL 
                                     includingPropertiesForKeys:@[NSURLNameKey, NSURLIsUbiquitousItemKey] 
                                                        options:NSDirectoryEnumerationSkipsHiddenFiles 
                                                          error:&error];
        
        if (error || !urls) {
            NSLog(@"获取iCloud目录内容失败: %@, 错误: %@", path, error.localizedDescription);
            return nil;
        }
        
        NSMutableArray<NSString *> *names = [NSMutableArray arrayWithCapacity:urls.count];
        for (NSURL *url in urls) {
            NSString *name = nil;
            NSError *nameError = nil;
            BOOL success = [url getResourceValue:&name forKey:NSURLNameKey error:&nameError];
            if (success && name && !nameError) {
                [names addObject:name];
            }
        }
        
        return [names copy];
    } else {
        // 本地目录，使用标准方法
        NSError *error = nil;
        NSArray<NSString *> *contents = [self contentsOfDirectoryAtPath:path error:&error];
        if (error) {
            NSLog(@"获取本地目录内容失败: %@, 错误: %@", path, error.localizedDescription);
            return nil;
        }
        return contents;
    }
}

- (nullable NSDictionary<NSFileAttributeKey, id> *)qm_safeAttributesOfItemAtPath:(NSString *)path {
    if (!path || ![self fileExistsAtPath:path]) {
        return nil;
    }
    
    // 检查是否为iCloud文件
    if ([self qm_isICloudFileAtPath:path]) {
        // 对于iCloud文件，使用URL方式获取属性
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        NSError *error = nil;
        
        // 获取基本属性，不触发下载
        NSArray *keys = @[
            NSURLFileSizeKey,
            NSURLContentModificationDateKey,
            NSURLCreationDateKey,
            NSURLIsDirectoryKey
        ];
        
        NSDictionary *resourceValues = [fileURL resourceValuesForKeys:keys error:&error];
        if (!resourceValues) {
            NSLog(@"获取iCloud文件属性失败: %@, 错误: %@", path, error.localizedDescription);
            return nil;
        }
        
        // 转换为NSFileManager格式的属性字典
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        
        if (resourceValues[NSURLFileSizeKey]) {
            attributes[NSFileSize] = resourceValues[NSURLFileSizeKey];
        }
        if (resourceValues[NSURLContentModificationDateKey]) {
            attributes[NSFileModificationDate] = resourceValues[NSURLContentModificationDateKey];
        }
        if (resourceValues[NSURLCreationDateKey]) {
            attributes[NSFileCreationDate] = resourceValues[NSURLCreationDateKey];
        }
        if (resourceValues[NSURLIsDirectoryKey]) {
            BOOL isDirectory = [resourceValues[NSURLIsDirectoryKey] boolValue];
            attributes[NSFileType] = isDirectory ? NSFileTypeDirectory : NSFileTypeRegular;
        }
        
        return [attributes copy];
    } else {
        // 本地文件，使用标准方法
        NSError *error = nil;
        NSDictionary *attributes = [self attributesOfItemAtPath:path error:&error];
        if (error) {
            NSLog(@"获取本地文件属性失败: %@, 错误: %@", path, error.localizedDescription);
            return nil;
        }
        return attributes;
    }
}

- (uint64_t)qm_safeFileSizeAtPath:(NSString *)path {
    NSDictionary *attributes = [self qm_safeAttributesOfItemAtPath:path];
    if (!attributes) {
        return 0;
    }
    
    NSNumber *fileSize = attributes[NSFileSize];
    return fileSize ? [fileSize unsignedLongLongValue] : 0;
}

@end
