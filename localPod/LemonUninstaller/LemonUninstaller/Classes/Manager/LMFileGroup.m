//
//  LMFileGroup.m
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "LMFileGroup.h"
#import <QMCoreFunction/NSString+Extension.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <QMCoreFunction/LoginItemManager.h>


@interface LMFileGroup () {
    NSMutableArray<LMFileItem *> *_fileItems;
    NSInteger _totalSize;
}


@end

@implementation LMFileGroup

- (instancetype)init {
    self = [super init];
    if (self) {
        _fileItems = [[NSMutableArray alloc] init];
        _totalSize = 0;
    }
    return self;
}

- (NSControlStateValue)selectedState {
    NSInteger selectedCount = [self selectedCount];

    if (selectedCount == 0) {
        return NSOffState;
    }

    if (selectedCount == self.filePaths.count) {
        return NSOnState;
    }

    return NSMixedState;
}

- (NSInteger)selectedCount {
    NSInteger selectedCount = 0;
    for (LMFileItem *item in self.filePaths) {
        if (item.isSelected) {
            selectedCount++;
        }
    }
    return selectedCount;
}

- (NSInteger)selectedSize {
    NSInteger size = 0;
    for (LMFileItem *item in self.filePaths) {
        if (item.isSelected) {
            size += item.size;
        }
    }
    return size;
}


- (NSString *)description {
    //    NSString *typeName = [NSString stringWithCString:LMFileTypeName[self.fileType]  encoding:NSASCIIStringEncoding];
    return [NSString stringWithFormat:@"GroupType: %ld, items:%@", (long)self.fileType, self.filePaths];
}

- (NSArray<LMFileItem *> *)filePaths {
    NSArray *ret = [_fileItems copy];
    return ret;
}


- (void)setFilePaths:(NSArray<LMFileItem *> *)filePaths {
    _fileItems = [filePaths mutableCopy];
    _totalSize = 0;
    for (LMFileItem *item in _fileItems) {
        // 优化代码. fileGroup 大小计算应该依赖于子 Item 的大小, 不然会重复计算.
//        _totalSize = _totalSize + [[NSFileManager defaultManager] diskSizeAtPath:item.path];
        _totalSize = _totalSize + item.size;

    }
}

// _totalSize的大小 是 merge, addItem, removeItem时改变.
- (NSInteger)totalSize {
    if (_totalSize < 0) {
        NSLog(@"warnging _totalsize is %ld, reset to 0,", (long) _totalSize);
        _totalSize = 0;
    }
    return _totalSize;
}

- (BOOL)containsPath:(NSString *)path {
    NSArray<LMFileItem *> *paths = self.filePaths;
    for (NSUInteger i = 0; i < [paths count]; i++) {
        if ([path isEqualToString:paths[i].path]) {
            return YES;
        }
    }
    return NO;
}

- (void)merge:(LMFileGroup *)group {
    for (LMFileItem *item in group.filePaths) {
        if ([self containsPath:item.path]) {
            continue;
        }

        BOOL isParent = NO;
        for (NSUInteger i = 0; i < [_fileItems count]; i++) {
            LMFileItem *selfItem = _fileItems[i];

            if ([selfItem.path isParentPath:item.path]) {
                isParent = YES;
                break;
            }

            if ([item.path isParentPath:selfItem.path]) {
                _totalSize -= _fileItems[i].size;
                _totalSize += item.size;
                _fileItems[i] = item;
                isParent = YES;
            }
        }
        if (isParent) {
            continue;
        }

        [self addFileItem:item];
    }
}

- (void)removeItem:(LMFileItem *)item {
    [_fileItems removeObject:item];
    _totalSize -= item.size;
}

- (void)removeItemAtIndex:(NSUInteger)index {
    if ([_fileItems count] > index) {
        _totalSize -= _fileItems[index].size;
        [_fileItems removeObjectAtIndex:index];
    }
}

- (void)addFileItem:(LMFileItem *)item {
    [_fileItems addObject:item];
    _totalSize += item.size;
}

- (void)delSelectedItem:(void (^)(LMFileItem *deletedItem))itemDeletedHandler {
    NSMutableArray *removedObjects = [NSMutableArray array];
    for (LMFileItem *item in _fileItems) {
        if (!item.isSelected) {
            continue;
        }
        NSLog(@"%s %@", __FUNCTION__, item.path);

        
        // TODO 是否需要下面的文件删除操作.
        BOOL stillNeedRemoveFile = TRUE;
        if (item.type == LMFileTypeBundle) {
            // 为了弹窗提示, 提示杀进程的部分提到了前面.
        } else if (item.type == LMFileTypeDaemon) {  //TODO 这个是否需要
            [self launchUnloadItem:item];
        } else if (item.type == LMFileTypeKextWithBundleId) {
            stillNeedRemoveFile = FALSE;
            [self uninstallKextItemWithBunldId:item];
        } else if (item.type == LMFileTypeKextWithPath) {
            stillNeedRemoveFile = FALSE;
            [self uninstallKextItemWithPath:item];
        } else if (item.type == LMFileTypeSignal) {
            stillNeedRemoveFile = FALSE;
            [self signalKillItem:item];
        } else if (item.type == LMFileTypeLoginItem) {
            stillNeedRemoveFile = FALSE;
            [self removeLoginItemBy:item];
        }


        if (stillNeedRemoveFile && [self isFileExist:item.path]) {
            if (_fileType == LMFileTypeOther) {
                [[McCoreFunction shareCoreFuction] cleanItemAtPath:item.path array:nil removeType:McCleanMoveTrashRoot];
            } else {
                [[McCoreFunction shareCoreFuction] cleanItemAtPath:item.path array:nil removeType:McCleanRemoveRoot];
            }
        }
        //由于内部LSSharedFileListCreate方法，在10.11以后的系统已经不支持，苹果也没有给替换的解决方案，故去除该点
        //[self removeLoginItems:item];

        [removedObjects addObject:item];

        item.isDeleted = YES;

        if (itemDeletedHandler) {
            itemDeletedHandler(item);
        }

    }
    for (LMFileItem *removedItem in removedObjects) {
        [self removeItem:removedItem];
    }
}

- (void)cleanDeletedItem {
    NSMutableArray *delectedItem = [NSMutableArray array];
    for (LMFileItem *item in _fileItems) {
        if (item.isDeleted) {
            [delectedItem addObject:item];
        }
    }
    [_fileItems removeObjectsInArray:delectedItem];
}

- (BOOL)isFileExist:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm fileExistsAtPath:path];
}


- (void)uninstallKextItemWithBunldId:(LMFileItem *)fileItem {
    NSLog(@"%s, %@", __FUNCTION__, fileItem);
    [[McCoreFunction shareCoreFuction] uninstallKextWithBundleId:fileItem.path];
}

- (void)uninstallKextItemWithPath:(LMFileItem *)fileItem {
    NSLog(@"%s, %@", __FUNCTION__, fileItem);
    
    [[McCoreFunction shareCoreFuction] uninstallKextWithPath:fileItem.path];
    
}

- (void)removeLoginItemBy:(LMFileItem *)fileItem {
    NSLog(@"%s, %@", __FUNCTION__, fileItem);

    // 注意 root 态的进程无法正常删除 LoginItem
//    [[McCoreFunction shareCoreFuction] removeLoginItem:fileItem.path];
    [LoginItemManager removeLoginItemsByName:fileItem.path];

//    NSString *loginItemName = fileItem.path;
//    [self removeLoginItemByTerminal:loginItemName];
}

// LSSharedFileListRef等 api 过时,无法保证正常使用.
// 注意 测试发现 root 态的进程无法正常删除 LoginItem. 用户态的进程可以正常删除
// 但是 10.14的机器上发现,利用System Events删除 LoginItem 需要隐私设置(自动化权限)系统会弹出提醒.
- (BOOL)removeLoginItemByTerminal:(NSString *)loginItemName {
    NSLog(@"%s remove loginItem:%@ by NSAppleScript", __FUNCTION__, loginItemName);

    NSString *removeCmd = [NSString stringWithFormat:@"tell application \"System Events\" to delete every login item whose name is \"%@\"", loginItemName];
    NSLog(@"%s: exec cmd str is %@", __func__, removeCmd);
    NSAppleScript *scriptObject = [[NSAppleScript alloc] initWithSource:removeCmd];
    NSDictionary *error = nil;
    NSAppleEventDescriptor *output = [scriptObject executeAndReturnError:&error];
    NSLog(@"%s execute result is %@", __func__, error == nil ? @"success" : @"fail");
    if (error) {
        NSLog(@"applescript error is = %@", error);
        return false;
    } else {
        NSLog(@"applescript output is = %@", output.stringValue);
        return true;
    }
}

- (void)signalKillItem:(LMFileItem *)fileItem {
    // 和 killProcess 冲突?
    NSLog(@"%s, %@", __FUNCTION__, fileItem);
}


//卸载launch
- (void)launchUnloadItem:(LMFileItem *)fileItem {
    NSLog(@"%s, %@", __FUNCTION__, fileItem);
    if ([[[fileItem.path pathExtension] lowercaseString] isEqualToString:@"plist"]) {
        NSString *commandString = [NSString stringWithFormat:@"launchctl unload %@", fileItem.path];
        //普通权限
        system([commandString UTF8String]);
        //ROOT权限
#ifndef DEBUG
        [[McCoreFunction shareCoreFuction] unInstallPlist:fileItem.path];
#endif
    }
}


- (id)copyWithZone:(NSZone *)zone {
    LMFileGroup *model = [[LMFileGroup allocWithZone:zone] init];
    model->_fileType = _fileType;
    model->_totalSize = _totalSize;
    model->_fileItems = [_fileItems mutableCopy];
    return model;
}

@end
