//
//  QMDuplicateItemManager.m
//  QMDuplicateFile
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMDuplicateItemManager.h"
#import <LemonFileManager/LMAppleScriptTool.h>

@interface QMDuplicateItemManager () {
    NSMutableArray *_resultItemArray;
}
@end

@implementation QMDuplicateItemManager


- (void)removeAllResult {
    [_resultItemArray removeAllObjects];
    _resultItemArray = nil;
}


// 时间
//- (NSTimeInterval)_lastAccessTime:(NSString *)filePath
//{
//    struct stat output;
//    int ret = lstat([filePath UTF8String], &output);
//    if (ret)
//        return 0;
//    struct timespec accessTime = output.st_atimespec;
//    return accessTime.tv_sec;
//}
- (NSTimeInterval)_createTime:(NSString *)filePath {
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    return [attr[NSFileCreationDate] timeIntervalSince1970];
}

- (NSTimeInterval)_lastModificationTime:(NSString *)filePath {
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    return [attr[NSFileModificationDate] timeIntervalSince1970];
}


- (void)addDuplicateItem:(NSArray *)pathArray fileSize:(uint64)size {
    if (!_resultItemArray) _resultItemArray = [[NSMutableArray alloc] init];
    // 创建RootItem
    NSString *filePath = pathArray[0];
    NSString *fileName = [[NSFileManager defaultManager] displayNameAtPath:filePath];
    QMDuplicateBatch *item = [[QMDuplicateBatch alloc] init];
    item.fileName = fileName;
    item.fileSize = size;
    item.fileType = [QMFileClassification fileExtensionType:filePath];
    item.iconImage = [[NSWorkspace sharedWorkspace] iconForFile:pathArray[0]];
    [item.iconImage setSize:NSMakeSize(32, 32)];
    // 创建子项
    for (NSUInteger i = 0; i < [pathArray count]; i++) {
        QMDuplicateFile *subItem = [[QMDuplicateFile alloc] init];
        subItem.filePath = pathArray[i];
        subItem.fileSize = size;
        //subItem.lastAccessTime = [self _lastAccessTime:subItem.filePath];
        subItem.modifyTime = [self _lastModificationTime:subItem.filePath];
        subItem.createTime = [self _createTime:subItem.filePath];
        [item addSubItem:subItem];
    }
    [_resultItemArray addObject:item];
}


- (NSArray *)duplicateArrayWithType:(QMFileTypeEnum)type {

    NSMutableArray *retArray = [NSMutableArray array];

    for (QMDuplicateBatch *item in _resultItemArray) {
        if ((item.fileType & type) == item.fileType) {

            // order : file size
            NSUInteger insertIndex = 0;
            for (QMDuplicateBatch *item2 in retArray) {

                UInt64 itemSize = item.fileSize * item.subItems.count;
                UInt64 itemSize2 = item2.fileSize * item2.subItems.count;

                //从大到小排列
                if (itemSize2 > itemSize) {
                    insertIndex++;
                    continue;
                } else {
                    break;
                }
            }

            [retArray insertObject:item atIndex:insertIndex];

        }

    }
    return retArray;
}

#pragma mark-
#pragma mark 自动选择,返回大于compareTime 时间的

+ (NSArray *)compareDuplicateFileTime:(NSArray *)subItems time:(NSTimeInterval)compareTime flags:(int)flags {
    NSMutableArray *retArray = [NSMutableArray array];
    for (QMDuplicateFile *subItem in subItems) {
        NSTimeInterval tempTime = subItem.createTime;
        if (flags == 1) tempTime = subItem.modifyTime;
        if (tempTime >= compareTime) {
            [retArray addObject:subItem];
        }
    }
    return retArray;
}

+ (void)selectedDuplicateItem:(NSArray *)array {
    for (QMDuplicateFile *subItem in array) {
        subItem.selected = YES;
    }
}


#pragma mark-
#pragma mark remove item

- (void)removeDuplicateItem:(NSArray *)itemArray toTrash:(BOOL)toTrash block:(void (^)(uint64_t value))block {
    NSMutableArray *needRemovePathArray = [NSMutableArray array];
    NSMutableArray *tempRemoveItemArrayForRefresh = [NSMutableArray array];
    uint64_t removeSize = 0;
    

    // 计算出所有需要移除的 path,并且更新原有的 array
    for (QMDuplicateBatch *item in itemArray) {
        NSMutableArray *tempSubItemArray = [NSMutableArray array];
        for (QMDuplicateFile *subItem in item.subItems) {
            if (subItem.selected) {
                removeSize += subItem.fileSize;
                [tempSubItemArray addObject:subItem];
            }

        }
        if ([tempSubItemArray count] > 0) {
            // 移除sub item (如果所有的 subItemd 都要移除,则直接移除上一级(即 Item)
            if ([tempSubItemArray count] >= item.subItems.count - 1) {
                [tempRemoveItemArrayForRefresh addObject:item];
            } else {
                [(NSMutableArray *) item.subItems removeObjectsInArray:tempSubItemArray];
            }

            [needRemovePathArray addObjectsFromArray:tempSubItemArray];
        }
    }
    // 移除item(避免遍历时移除,遍历结束后再移除)
    [_resultItemArray removeObjectsInArray:tempRemoveItemArrayForRefresh];
    dispatch_queue_t removeQueue =  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t removeGroup =  dispatch_group_create();
    LMAppleScriptTool *removeTool = [[LMAppleScriptTool alloc] init];
    
    for (QMDuplicateFile *needRemoveItem in needRemovePathArray) {
        dispatch_group_async(removeGroup, removeQueue, ^{
            NSString *path = [needRemoveItem filePath];
            NSFileManager *fm = [NSFileManager defaultManager];
            if (![fm fileExistsAtPath:path]) {
                return;
            }
            [removeTool removeFileToTrash:path];
        });
    }
    dispatch_group_notify(removeGroup, dispatch_get_main_queue(), ^{
        block(removeSize);
    });
}

- (uint64)duplicateResultSize {
    UInt64 totalSize = 0;
    for (QMDuplicateBatch *item in _resultItemArray) {
        totalSize += item.fileSize * item.subItems.count;
    }
    return totalSize;
}


- (BOOL)trashPath:(NSString *)path
     scriptFinder:(BOOL)scriptFinder {

    BOOL ok = YES;
    if (scriptFinder) {
        NSString *source = [NSString stringWithFormat:
                /**/@"with timeout 15 seconds\n"
                    /**/  @"tell application \"Finder\"\n"
                    /**/    @"delete POSIX file \"%@\"\n"
                    /**/  @"end tell\n"
                    /**/@"end timeout\n",
                    path];
        NSAppleScript *script = [[NSAppleScript alloc] initWithSource:source];
        NSDictionary *errorDic = [[NSMutableDictionary alloc] init];
        [script executeAndReturnError:&errorDic];
        //当大批量删除的时候,会出错...(目测超过50个)
        if (errorDic) {
            ok = NO;
            NSLog(@"exec trash file script error : %@", errorDic);
        }
    } else {
        NSArray *urls = @[[NSURL fileURLWithPath:path]];
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        dispatch_queue_t aSerialQueue = dispatch_queue_create(
                "com.sheepsystems.NSFileManager.SomeMore",
                DISPATCH_QUEUE_SERIAL
        );
        dispatch_async(aSerialQueue, ^{
            [[NSWorkspace sharedWorkspace] recycleURLs:urls
                                     completionHandler:^void(NSDictionary *newURLs,
                                             NSError *recycleError) {

                                         NSLog(@"exec recycleURLs error : %@", recycleError);

                                         dispatch_semaphore_signal(sem);
                                     }];
        });


        // Wait here in case error is set by completionHandler block
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }

    return ok;
}


+ (NSInteger)autoSelectedResult:(NSArray *)itemArray {

    NSInteger retSelectedCount = 0;
    for (QMDuplicateBatch *dupBatch in itemArray) {

        
        if(! dupBatch.subItems || dupBatch.subItems.count == 0){
            continue;
        }
        
        // 重置为未选中状态
        for (QMDuplicateFile *subItem in dupBatch.subItems) {
            subItem.selected = NO;
        }

        // 比较名称(名称中含有 Copy,副本的,都默认选择)
        NSMutableArray *copyFilesArray = [NSMutableArray array];
        for (QMDuplicateFile *dupFile in dupBatch.subItems) {
            NSString *fileName = [[dupFile.filePath lastPathComponent] stringByDeletingPathExtension];
            
            // \s 匹配任何空白字符，包括空格、制表符、换页符等等。
            // \d 匹配一个数字字符。等价于 [0-9]。
            if ([self assertRegex:@".+\\s[0-9]\\d*" matchStr:fileName] || [fileName hasSuffix:@"的副本"] || [fileName hasSuffix:@" Copy"]  | [fileName hasSuffix:@" copy"]) {
                [copyFilesArray addObject:dupFile];
            }
        }

        // 优先判断名称.  如果名称可以完全确定哪条默认不选择,则直接返回
        NSArray *unSelectedArray = nil;
        if (copyFilesArray.count == dupBatch.subItems.count - 1) {      // 只有一个名称不带有 Copy 字样.
            
            NSMutableArray *allItems = [dupBatch.subItems mutableCopy];
            [allItems removeObjectsInArray:copyFilesArray];
            unSelectedArray = allItems;
            
            
        } else {   // 通过名称无法判断, 那么从排除副本类型(或者全都是副本类型), 从中选取时间最新的
            
            NSMutableArray *leaveArray = nil;
            if(copyFilesArray.count == dupBatch.subItems.count) {
                leaveArray = copyFilesArray;
            }else{
                leaveArray = [dupBatch.subItems mutableCopy];
                [leaveArray removeObjectsInArray:copyFilesArray];
            }
            

            // 比较时间, 优先按照修改时间进行选取, 如果 修改时间多个相同,  则再按照创建时间进行比较.
            NSTimeInterval newsetModifyTime = -1;
            NSTimeInterval newestCreateTime = -1;
            for (QMDuplicateFile *subItem in leaveArray) {  //找出最老的时间
                if (newsetModifyTime < subItem.modifyTime || newsetModifyTime < 0)
                    newsetModifyTime = subItem.modifyTime;
                if (newestCreateTime < subItem.createTime || newestCreateTime < 0)
                    newestCreateTime = subItem.createTime;
            }
            
            NSArray *newestModifyArray = [self compareDuplicateFileTime:leaveArray time:newsetModifyTime flags:1];
            NSArray *newestCreateArray = [self compareDuplicateFileTime:leaveArray time:newestCreateTime flags:2];
            
            NSMutableSet *modifySet = [NSMutableSet setWithArray:newestModifyArray];
            NSMutableSet *createSet = [NSMutableSet setWithArray:newestCreateArray];
            [modifySet intersectSet:createSet];  // 取两个集合的交集

            QMDuplicateFile *fitObj = nil;
            if(modifySet.count > 0){
                fitObj = [modifySet anyObject]; // anyObject NSSet任意一个元素
            }else{  // 两个集合没有交集,选取相同修改时间集合中,创建时间最新的那个.
                
                for(QMDuplicateFile *loopFile in newestModifyArray){
                    
                    if(!fitObj || fitObj.createTime > loopFile.createTime){
                        fitObj = loopFile;
                    }
                }
            }
            
            if(fitObj){
                unSelectedArray = [@[fitObj] mutableCopy];
            }
            
        }
        
        
        if(!unSelectedArray || unSelectedArray.count == 0 ){
            unSelectedArray = @[dupBatch.subItems[0]]; //前面已经做了 items 判断. (多线程??? 这种数组越界还可能发生)
        }
        
        for(QMDuplicateFile *file in dupBatch.subItems){
            if(![unSelectedArray containsObject:file]){
                file.selected = YES;
            }
        }

        retSelectedCount += unSelectedArray.count;;

    }
    return retSelectedCount;
}


// 正则比较
+ (BOOL)assertRegex:(NSString *)regexString matchStr:(NSString *)str {
    NSPredicate *regex = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexString];
    return [regex evaluateWithObject:str];
}

@end
