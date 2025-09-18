//
//  LMFileScanTask.m
//  Lemon
//
//  
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "LMFileScanTask.h"
#import "LMItem.h"
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/attr.h>
#include <sys/errno.h>
#include <sys/vnode.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <assert.h>
#include <stddef.h>
#include <string.h>
#include <stdbool.h>
#import <QMCoreFunction/MdlsToolsHelper.h>
#import <QMCoreFunction/NSFileManager+iCloudHelper.h>

typedef struct val_attrs {
    uint32_t          length;
    attribute_set_t   returned;
    uint32_t          error;
    attrreference_t   name_info;
    char              *name;
    fsobj_type_t      obj_type;
    off_t             fileSize;
} val_attrs_t;

static BOOL isOperatingSystemAtLeastMacOS13 = NO;

@interface LMFileScanTask ()
@property (atomic, assign) BOOL isCancel;
@end

@implementation LMFileScanTask

+ (void)initialize {
    if (self == [LMFileScanTask class]) {
        if (@available(macOS 13.0, *)) {
            isOperatingSystemAtLeastMacOS13 = YES;
        }
    }
}

- (id)initWithRootDirItem:(LMItem *)dirItem{
    
    self = [super init];
    if (self) {
        _dirItem = dirItem;
        _skipICloudFiles = NO;
        
    }
    return self;
}

#pragma mark - iCloud文件检测

/**
 * 检查是否应该跳过该iCloud文件
 * @param filePath 文件路径
 * @return YES表示应该跳过，NO表示可以处理
 */
- (BOOL)shouldSkipICloudFile:(NSString *)filePath {
    if (!self.skipICloudFiles) {
        return NO;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager qm_isICloudFileAtPath:filePath]) {
        // 只有已下载的iCloud文件才不跳过
        return ![fileManager qm_isICloudFileDownloadedAtPath:filePath];
    }
    return NO;
}

- (void)cancel {
    self.isCancel = YES;
}

-(void)starTaskWithBlock:(LMFileScanTaskBlock)block{
    // 降低内存峰值，减少一个数量级 27G到2.7G
    @autoreleasepool {
        [self __starTaskWithBlock:block];
    }
}

-(void)__starTaskWithBlock:(LMFileScanTaskBlock)block{
    LMItem *parentItem = [self dirItem];
    NSString *parentFullPath = [parentItem fullPath];
    parentItem.specialFileExtensions = self.specialFileExtensions;
    
    if ([parentItem.fullPath hasSuffix:@"com.apple.metadata.mdworker"]) {
        return;
    }
    
    int error;
    int dirfd;
    struct attrlist attrList;
    char *entry_start;
    char attrBuf[10000];

    memset(&attrList, 0, sizeof(attrList));
    attrList.bitmapcount = ATTR_BIT_MAP_COUNT;
    attrList.commonattr  = ATTR_CMN_RETURNED_ATTRS |
                            ATTR_CMN_ERROR |
                           ATTR_CMN_NAME |
                           ATTR_CMN_OBJTYPE;
    attrList.fileattr  = ATTR_FILE_ALLOCSIZE;
    error = 0;
    const char * dirpath = [parentFullPath fileSystemRepresentation];
    dirfd = open(dirpath, O_RDONLY, 0);
    if (dirfd < 0) {
       
        error = errno;
        printf("Could not open directory %s", dirpath);
        perror("Error was ");
    } else {
        for (;;) {
            if (self.isCancel) {
                break;
            }
            
            int retcount;

            retcount = getattrlistbulk(dirfd, &attrList, &attrBuf[0],sizeof(attrBuf), 0);
            if (retcount == -1) {
                error = errno;
                
                break;
            } else if (retcount == 0) {
                /* No more entries in directory */
                error = 0;
                
                break;
            } else {
                int    index;
                uint32_t total_length;
                char   *field;
                entry_start = &attrBuf[0];
                total_length = 0;
                for (index = 0; index < retcount; index++) {
                    LMItem *fileItem = [[LMItem alloc] init];
//                    fileItem.sizeInBytes = 0;
                    fileItem.parentDirectory = parentItem;
                    fileItem.specialFileExtensions = self.specialFileExtensions;
                    
                    val_attrs_t    attrs = {0};
                    field = entry_start;
                    attrs.length = *(uint32_t *)field;
                    /* set starting point for next entry */
                    entry_start += attrs.length;
                    //从参数length到参数returned
                    field += sizeof(uint32_t);
                    //把field把returned的东西给了attrs.returned.
                    attrs.returned = *(attribute_set_t *)field;
                    field += sizeof(attribute_set_t);

                    if (attrs.returned.commonattr & ATTR_CMN_ERROR) {
                        attrs.error = *(uint32_t *)field;
                        field += sizeof(uint32_t);
                    }

                    if (attrs.returned.commonattr & ATTR_CMN_NAME) {
                        attrs.name =  field;
                        attrs.name_info = *(attrreference_t *)field;
                        field += sizeof(attrreference_t);
//                        printf("  %s ", (attrs.name +
//                            attrs.name_info.attr_dataoffset));
                        NSString *path = [NSString stringWithUTF8String:(attrs.name +
                                                                         attrs.name_info.attr_dataoffset)];

                        fileItem.fileName = path;
                        fileItem.fullPath = [parentFullPath stringByAppendingPathComponent:path];
                    }
                    /* Check for error for this entry */
                    if (attrs.error) {
                        /*
                         * Print error and move on to next
                         * entry
                         */
                        printf("Error in reading attributes for directory                                entry %d", attrs.error);
                        continue;
                    }
                    
                    if (isOperatingSystemAtLeastMacOS13) {
                        // 检查是否应该跳过iCloud文件
                        if ([self shouldSkipICloudFile:fileItem.fullPath]) {
                            // 跳过未下载的iCloud文件，避免触发同步
                            continue;
                        }
                    }
                    
                    if (attrs.returned.commonattr & ATTR_CMN_OBJTYPE) {
                        attrs.obj_type = *(fsobj_type_t *)field;
                        field += sizeof(fsobj_type_t);

                        switch (attrs.obj_type) {
                            case VREG:
                                fileItem.isDirectory = NO;

                                break;
                            case VDIR:
                                fileItem.isDirectory = YES;

                                break;
                            default:
                                fileItem.isDirectory = NO;

                                break;
                        }
                    }
                    if (fileItem.isDirectory == NO && (attrs.returned.fileattr & ATTR_FILE_ALLOCSIZE)) {
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        
                        BOOL isICloudFile = NO;
                        if (isOperatingSystemAtLeastMacOS13) {
                            // 13及以上调用qm_isICloudFileAtPath，避免多线程问题。
                            isICloudFile = [fileManager qm_isICloudFileAtPath:fileItem.fullPath];
                        }
                        if (isICloudFile) {
                            // iCloud文件，使用安全方法获取大小，避免触发下载
                            fileItem.sizeInBytes = [fileManager qm_safeFileSizeAtPath:fileItem.fullPath];
                            field += sizeof(off_t); // 跳过field指针，不读取可能触发下载的数据
                        } else {
                            // 非iCloud文件，正常获取大小
                            attrs.fileSize = *(off_t *)field;
                            field += sizeof(off_t);
                            fileItem.sizeInBytes = attrs.fileSize;
                        }
//                        NSLog(@"%@==>%lld",fileItem.fullPath,fileItem.sizeInBytes);
                    } else {
                        NSString *pathExtension = [[fileItem.fullPath pathExtension] lowercaseString];
                        if (pathExtension.length > 0 && [self.specialFileExtensions containsObject:pathExtension]) {
                            NSMetadataItem *metadataItem = [[NSMetadataItem alloc] initWithURL:[NSURL fileURLWithPath:fileItem.fullPath]];
                            fileItem.sizeInBytes = [[metadataItem valueForAttribute:NSMetadataItemFSSizeKey] unsignedLongLongValue];
                            if (fileItem.sizeInBytes > 0) {
                                fileItem.isDirectory = NO; // 元数据读取到size将其标记为文件而非目录
                            }
                        }
                    }

                    [[parentItem childItems] addObject:fileItem];
                    if (fileItem.isDirectory == NO && ![fileItem.fullPath isEqualToString:@"/System/Volumes"]) {
                        if ([self.delegate respondsToSelector:@selector(fileScanTaskFinishOneFile:)]) {
                            [self.delegate fileScanTaskFinishOneFile:fileItem.sizeInBytes];
                        }
                    }

                    if (fileItem.isDirectory && ![fileItem.fullPath isEqualToString:@"/System/Volumes"] && ![fileItem.fullPath isEqualToString:@"/Volumes"] && ![fileItem.fullPath containsString:@"/private/tmp/msu-"]) {
                        
                        block(fileItem);
                    }
                }
            }
        }
        (void)close(dirfd);
    }

}

@end
