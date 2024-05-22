//
//  LMResultItem.m
//  LemonFileMove
//
//  
//

#import "LMResultItem.h"
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
#import <LemonFileManager/LMFileAttributesTool.h>

typedef struct val_attrs {
    uint32_t          length;
    attribute_set_t   returned;
    uint32_t          error;
    attrreference_t   name_info;
    char              *name;
    fsobj_type_t      obj_type;
    off_t             fileSize;
} val_attrs_t;

@implementation LMResultItem

- (instancetype)init {
    if (self = [super init]) {
        self.isMoveFailed = NO;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    LMResultItem *item = [super copyWithZone:zone];
    item.path = self.path;
    item.originPath = self.originPath;
    item.appType = self.appType;
    item.fileType = self.fileType;
    
    return item;
}

- (void)setOriginPath:(NSString *)originPath {
    _originPath = originPath;
    NSFileManager * manager = [NSFileManager defaultManager];
    NSDictionary * attributes = [manager attributesOfItemAtPath:originPath error:nil];
    NSNumber *theFileSize = [attributes objectForKey:NSFileSize];
    self.fileSize = [theFileSize longLongValue];
}

- (NSControlStateValue)updateSelectState {
    
    if (self.selecteState == NSControlStateValueOn) {
        return NSControlStateValueOn;
    } else {
        return  NSControlStateValueOff;
    }
}

- (void)setPath:(NSString *)path {
    _path = path;
    self.fileSize = [LMFileAttributesTool caluactionSize:path diskMode:YES];
}

- (NSString *)availableFilePath {
    if (self.path.length > 0) {
        return self.path;
    } else if (self.originPath.length > 0) {
        return self.originPath;
    }
    return nil;
}

@end
