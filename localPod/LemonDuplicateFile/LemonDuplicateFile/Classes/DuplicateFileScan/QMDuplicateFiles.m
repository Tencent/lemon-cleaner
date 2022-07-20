//
//  QMDuplicateFiles.m
//  FileCleanDemo
//
//  
//  Copyright (c) 2014年 yuanwen. All rights reserved.
//

#import "QMDuplicateHelp.h"
#import <zlib.h>
#import "QMDuplicateFiles.h"
#import "SizeHelper.h"

#define kDefaultFilterSize   200 * 1024

const float kDuplicateFolderCalculateProgress = 0.1f;

@interface QMDuplicateFiles () {
    NSMutableDictionary *matchesFileSize;
    NSMutableDictionary *matchesDirSize;

    NSMutableArray *duplicateDirArray;

    __weak id <McDuplicateFilesDelegate> showDelegate;

    NSArray *excludeArray;
    dispatch_queue_t md5Queue;

    // 开始扫描时间
    CFAbsoluteTime _startScanTime;
    
    // 文件夹过大时的比对时间.
    CFAbsoluteTime _lastFolderCompareTime;
    // 文件过大时的比对时间.
    CFAbsoluteTime _lastFileCompareTime;

    NSInteger _compareDotNum;
    uint32_t _scanFileCount;
}

@property(nonatomic, assign) BOOL stopped;

@end

@implementation QMDuplicateFiles

- (BOOL)stopped {
    if (_stopped) {
        return YES;
    }
    if (!showDelegate) {
        return YES;
    }
    return [showDelegate cancelScan];
}

- (void)start:(id <McDuplicateFilesDelegate>)scanDelegate
         path:(NSArray *)path
 excludeArray:(NSArray *)array {
    _scanFileCount = 0;
    _startScanTime = CFAbsoluteTimeGetCurrent();

    md5Queue = dispatch_queue_create("md5", NULL);

    _stopped = YES;
    showDelegate = scanDelegate;
    excludeArray = array;

    duplicateDirArray = [NSMutableArray array];
    matchesFileSize = [NSMutableDictionary dictionary];
    matchesDirSize = [NSMutableDictionary dictionary];

    // 路径扫描
    QMDuplicateFileScanManager *scanManager = [[QMDuplicateFileScanManager alloc] init];
    [scanManager listPathContent:path
                        delegate:(id <QMFileScanManagerDelegate>) self];
}


- (void)dealloc {
//    dispatch_release(md5Queue);
}

- (void)stopScan {
    _stopped = YES;
}

#pragma mark-
#pragma mark 文件搜索委托

// return: 是否结束扫描
- (BOOL)scanFileItemProgress:(QMFileItem *)item progress:(CGFloat)value scanPath:(NSString *)path {
//    NSLog(@"scanFileItemProgress value:%f, path:%@", value, path);

    if (showDelegate) {
        _stopped = [showDelegate progressRate:(float) (value * kDuplicateMaxSearchProgress) progressStr:path];
    } else {
        _stopped = YES;
    }


    if (!item)
        return _stopped;


    _scanFileCount++;

    // 过滤不能删除的文件
    if (![self checkCanRemove:item.filePath])
        return _stopped;

    // 计算package 大小 // 如果文件比较大,可能会花不少时间, package 类型的手动计算大小
    if (item.isDir) {
        NSNumber *package = nil;
        [[NSURL fileURLWithPath:item.filePath] getResourceValue:&package forKey:NSURLIsPackageKey error:NULL];
        
        // package 类型的计算大小会花费不少时间
        // 对于 app 类型, 和 foler 类型一致, 都是要 迭代里面的所有文件将所有的文件大小加起来,
        // 如果文件数量太多, 会造成界面卡死的问题, 这里优化为一个文件夹 最多计算3w 个文件.
        
        // 对于 Finder ,会缓存 app 的大小进行显示. 但是这个 大小有可能不能实际代表 app 的大小, 比如将一些文件拖到 app contents目录中,会发现 Finder 显示的大小不会改变.
        if ([package boolValue]) {
            CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
            item.fileSize = [QMDuplicateFileScanManager calculateSize:item.filePath delegate:showDelegate];
            CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
            NSLog(@"calculate package %@ , cost time: %f s",item.filePath, (end - start));
        }
    }
    if (item.fileSize < kDefaultFilterSize)
        return _stopped;
    // 过滤包含.svn，.git文件夹路径
    QMFileItem *tempItem = item;
    while (tempItem.parentItem) {
        NSString *itemPath = [[tempItem filePath] stringByAppendingPathComponent:@".svn"];
        BOOL isDir = _stopped;
        if ([[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isDir] && isDir)
            return _stopped;
        itemPath = [[tempItem filePath] stringByAppendingPathComponent:@".git"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isDir] && isDir)
            return _stopped;
        tempItem = tempItem.parentItem;
    }

    // 过滤忽略列表
    if ([excludeArray count] > 0
            && [excludeArray containsObject:[item.filePath pathExtension]])
        return _stopped;

    // 根据大小和类型分类
    NSMutableDictionary *cacheDict = matchesFileSize;
    NSString *sizeKey = [NSString stringWithFormat:@"%lld", item.fileSize];
    if (item.isDir) {
        // 不存在子目录
        if (![self checkFileItemDirLevel:item])
            return _stopped;
        cacheDict = matchesDirSize;
        sizeKey = [NSString stringWithFormat:@"%@%@", kBundlePrefix, sizeKey];
    }

    NSMutableArray *keyArray = cacheDict[sizeKey];
    if (keyArray == nil) {
        // first item for the size
        keyArray = [NSMutableArray array];
        [keyArray addObject:item];
        cacheDict[sizeKey] = keyArray;
    } else {
        if (![keyArray containsObject:item]) {
            [keyArray addObject:item];
        }
    }

    return _stopped;
}

- (void)scanFileItemDidEnd:(BOOL)userCancel {
    [self searchDuplicateFiles];
}

// 检查当前项的最大子目录层
- (BOOL)checkFileItemDirLevel:(QMFileItem *)item {
    for (QMFileItem *subItem in item.childrenItemArray) {
        if ([subItem isDir] && subItem.fileSize >= kDefaultFilterSize) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)checkCanRemove:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:path isDirectory:&isDir])
        return NO;
    // 过滤只读目录
    if (isDir && ![fm isWritableFileAtPath:path])
        return NO;
    return [fm isDeletableFileAtPath:path];
}

- (void)sendResultToDelegate:(NSDictionary *)resultDic fileSize:(UInt64)fileSize {
    // 结果
    for (NSString *md5Str in [resultDic allKeys]) {
        NSMutableArray *sameHashArray = resultDic[md5Str];
        NSArray *fileCanRemoveArray = [self convertFileItemToPath:sameHashArray];

        if ([fileCanRemoveArray count] <= 1)
            continue;

        // find duplicate !
        // notify delegate
        [showDelegate addDuplicateFileRecord:fileCanRemoveArray
                                   totalSize:fileSize];
    }
}

#pragma mark-
#pragma mark 查找重复文件


// insert file to hash dictionary
// key of dictionary is hash string
// fileList是返回的 array
- (void)insertHashDictionary:(NSArray *)fileList process:(float)process {
    @autoreleasepool {
        if ([fileList count] < 2)
            return;
        
        //resultDict 用 md5做 key,item 做 value
        NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];

        // 文件大小
        uint32 chunkSize = 1024 * 1024;

        // 读取前面10MB数据
        @try{
//            for (QMFileItem *fileItem in fileList) {
//
//            }
            
            if ([fileList count] == 0)
                return;
            
            // 多线程计算md5(前10m 的数据)
            // dispatch_apply 阻塞的 apply 对 sync group 的封装
            dispatch_apply(fileList.count, dispatch_get_global_queue(0, 0), ^(size_t index) {
                @autoreleasepool{
                    if (index >= [fileList count]) {
                        return;
                    }
                    QMFileItem *fileItem = [fileList objectAtIndex:index];
                    if (fileItem.hashStr)
                        return;
                    
                    UInt64 fileSize = [fileItem fileSize];
                    NSFileHandle *innerFileHandle;
                    innerFileHandle = [NSFileHandle
                                  fileHandleForReadingAtPath:fileItem.filePath];
                NSString *md5Str = nil;
                @autoreleasepool{
                    NSMutableData *headData = [NSMutableData dataWithCapacity:MIN(fileSize, 10 * chunkSize)];
                    
                    // 读取10m 的数据
                    uint64 offset = 0;
                    NSData *readData = nil;
                    do {
                        @autoreleasepool{
                            @try {
                                readData = [innerFileHandle readDataOfLength:chunkSize];
                            } @catch (NSException *exception) {
                                NSLog(@"%s, exception = %@", __FUNCTION__, exception);
                                readData = nil;
                            } @finally {
                            
                            }
                            
                            if (readData)
                                [headData appendData:readData];
                            else
                                break;
                            offset += [readData length];
                            [innerFileHandle seekToFileOffset:offset];
                        }
                    } while ([readData length] > 0 && offset < 10 * chunkSize);
                    
                    [innerFileHandle closeFile];
                    if (headData.length == 0)
                        return;
                    
                    if (!self->showDelegate) {
                        self->_stopped = YES;
                        return;
                    }
                    
                    if (self.stopped)
                        return;
                    
                    //计算 md5
                    md5Str = (__bridge_transfer NSString *) (FileMD5HashWithData(headData, 0));
                    // 小文件用 md5 做 hash, 大文件用 md5 + crc 做 hash
                }
                    fileSize = [fileItem fileSize];
                    BOOL bigFile = NO;
                    if (fileSize > 1024 * 1024 * 10)
                        bigFile = YES;
                    else
                        fileItem.hashStr = md5Str;
                    
                    // 大文件需要计算crc
                    if (bigFile) {
                        // 头部hash和crc作为新的key
                        dispatch_sync(self->md5Queue, ^{
                            
                            NSMutableArray *sameHashArray = resultDict[md5Str];
                            if (sameHashArray == nil) {
                                sameHashArray = [NSMutableArray arrayWithCapacity:10];
                                resultDict[md5Str] = sameHashArray;
                            }
                            [sameHashArray addObject:fileItem];
                        });
                    }
                }
                
            });
            
            // 大文件进行crc算法比对
            if (resultDict.count > 0) {
                
                for (NSString *md5Str in [resultDict allKeys]) {
                    NSMutableArray *sameHashArray = resultDict[md5Str];
                    if ([sameHashArray count] <= 1)
                        continue;
                    
                    for (QMFileItem *fileItem in sameHashArray) {
                        @autoreleasepool{
                        // 计算文件的crc
                         NSFileHandle *fileHandle = [NSFileHandle
                                                    fileHandleForReadingAtPath:fileItem.filePath];
                        
                        uLong crc = crc32(0L, Z_NULL, 0);
                        uint64 offset = 0;
                        uint32 itemChunkSize = 1024 * 1024;     //Read 1M
                        [fileHandle seekToFileOffset:10 * itemChunkSize];
                        NSData *data = [fileHandle readDataOfLength:itemChunkSize];
                        
                        while ([data length] > 0) {
                            
                            @autoreleasepool {
                                //Make sure for the next line you choose the appropriate string encoding.
                                
                                crc = crc32(crc, data.bytes, (uInt) data.length);
                                /* PERFORM STRING PROCESSING HERE */
                                
                                /* END STRING PROCESSING */
                                offset += [data length];
                                
                                [fileHandle seekToFileOffset:offset];
                                data = [fileHandle readDataOfLength:itemChunkSize];
                                
                                if (!showDelegate) {
                                    _stopped = YES;
                                    return;
                                }
                                
                                // 显示文件比对进度.
                                CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
                                if(now - _lastFileCompareTime >= 0.3){
                                    
                                    NSString *dotString = @"";
                                    if(_compareDotNum % 3 == 0){
                                        dotString = @".";
                                    }else if(_compareDotNum % 3 == 1){
                                        dotString = @"..";
                                    }else if(_compareDotNum % 3 == 2){
                                        dotString = @"...";
                                    }
                                    
                                    NSString *processString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"QMDuplicateFiles_insertHashDictionary_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""),[SizeHelper getFileSizeStringBySize:fileItem.fileSize], dotString];
                                    
                                    if(showDelegate){
                                        [showDelegate progressRate:process progressStr:processString];
                                    }
                                    _lastFileCompareTime = now;
                                    _compareDotNum ++;
                                }
                                
                                
                                if (self.stopped) {
                                    return;
                                }
                               
                            }
                        }
                        
                        // 头部hash和crc作为新的key
                        NSString *md5Hash = [NSString stringWithFormat:@"%@_%lu", md5Str, crc];
                        fileItem.hashStr = md5Hash;
                        
                        [fileHandle closeFile];

                        if (self.stopped)
                            return;
                    }
                  }
                }
            }
        }@catch(NSException *exception){
            NSLog(@"duplicate file compare error : %@", exception);
        }@finally{
            
        }
       
    }
}

- (NSArray *)hashCompare:(NSArray *)pathArray dirType:(BOOL)dirType process:(float)process {
    NSArray *hashPathArray = pathArray;
    // 查看是否重复文件夹结果包含了该项
    if (!dirType) {
        NSMutableArray *tempArray = [NSMutableArray array];
        for (QMFileItem *item in pathArray) {
            BOOL flags = NO;
            QMFileItem *parentItem = item.parentItem;
            while (parentItem) {
                if ([duplicateDirArray containsObject:parentItem]) {
                    flags = YES;
                    break;
                }

                parentItem = parentItem.parentItem;
            }
            if (flags)
                continue;
            [tempArray addObject:item];
        }
        hashPathArray = tempArray;
    }
    // first time
    [self insertHashDictionary:hashPathArray process:process];
    return hashPathArray;
}

- (NSArray *)convertFileItemToPath:(NSArray *)fileItemArray {
    NSMutableArray *retArray = [NSMutableArray array];
    for (QMFileItem *item in fileItemArray) {
        if ([self checkCanRemove:item.filePath])
            [retArray addObject:item.filePath];
    }
    return retArray;
}

// 通过 item hashStr 作为 key 生成字典.
- (void)addDuplicateFileToResult:(NSArray *)resultArray fileSize:(NSString *)fileSize {
    if ([resultArray count] == 0)
        return;
    NSMutableDictionary *resultDic = [NSMutableDictionary dictionary];
    for (QMFileItem *item in resultArray) {
        if (!item.hashStr)
            continue;
        NSMutableArray *array = resultDic[item.hashStr];
        if (!array) {
            array = [NSMutableArray array];
            resultDic[item.hashStr] = array;
        }
        [array addObject:item];
    }

    [self sendResultToDelegate:resultDic
                      fileSize:(UInt64) [fileSize longLongValue]];
}

- (BOOL)dirContentsEqualAtItem:(QMFileItem *)item1 item2:(QMFileItem *)item2 layer:(int)layer process:(float)processRate {
    if (self.stopped)
        return NO;

    if (!item1 || !item2)
        return NO;
    if (item1 == item2)
        return NO;
    if (layer > 20)
        return NO;
    if (item1.fileSize != item2.fileSize)
        return NO;
    if ([item1.equalItem containsObject:item2.filePath])
        return YES;
//    if (layer > 0
//        && ![[item1.filePath lastPathComponent] isEqualToString:[item2.filePath lastPathComponent]])
//        return NO;
    if (item1.isDir && item2.isDir) {
        // 子项目数量相同
        if (item1.childrenItemArray.count == item2.childrenItemArray.count) {
            NSMutableArray *dirArray1 = [NSMutableArray array];
            NSMutableArray *itemArray1 = [NSMutableArray array];
            for (QMFileItem *item in item1.childrenItemArray) {
                if (item.isDir)
                    [dirArray1 addObject:item];
                else if (![excludeArray containsObject:[[item filePath] pathExtension]])
                    [itemArray1 addObject:item];
            }

            // 判断根据过滤后的文件
            if ([itemArray1 count] < item1.childrenItemArray.count - dirArray1.count)
                return NO;

            NSMutableArray *dirArray2 = [NSMutableArray array];
            NSMutableArray *itemArray2 = [NSMutableArray array];
            for (QMFileItem *item in item2.childrenItemArray) {
                if (item.isDir)
                    [dirArray2 addObject:item];
                else if (![excludeArray containsObject:[[item filePath] pathExtension]])
                    [itemArray2 addObject:item];
            }

            // 判断根据过滤后的文件
            if ([itemArray2 count] < item2.childrenItemArray.count - dirArray2.count)
                return NO;

            // 比较目录数量
            if ([dirArray1 count] != [dirArray2 count])
                return NO;

            // 将文件大小的分类, 计算文件hash
            for (QMFileItem *innerItem1 in itemArray1) {
                BOOL hasDuplicate = NO;
                for (NSUInteger i = 0; i < itemArray2.count; i++) {
                    QMFileItem *innerItem2 = itemArray2[i];
                    if (innerItem1.fileSize == innerItem2.fileSize) {
                        [self hashCompare:@[innerItem1, innerItem2] dirType:YES process:processRate];
                        if ([[innerItem1 hashStr] isEqualToString:[innerItem2 hashStr]]) {
                            hasDuplicate = YES;
                            [itemArray2 removeObject:innerItem2];
                            break;
                        }
                    }
                    if (self.stopped)
                        return NO;
                }
                if (!hasDuplicate)
                    return NO;
            }

            // 比较子目录
            NSMutableArray *removeDir = [NSMutableArray array];
            for (QMFileItem *innerItem1 in dirArray1) {
                BOOL result = NO;
                for (QMFileItem *innerItem2 in dirArray2) {
                    if ([removeDir containsObject:innerItem2])
                        continue;
                    result = [self dirContentsEqualAtItem:innerItem1 item2:innerItem2 layer:layer + 1 process:processRate];
                    if (result) {
                        [removeDir addObject:innerItem2];
                        break;
                    }
                }
                if (!result)
                    return NO;
            }
            return YES;
        }
    }
    return NO;
}

- (void)bundleCompare:(NSArray *)pathArray fileSize:(NSString *)fileSize process:(float)processRate {
    NSArray *filterArray = pathArray;
    NSMutableDictionary *tempMatchesDirDict = [NSMutableDictionary dictionary];
    // 比较的Array
    NSMutableArray *compareArray = [NSMutableArray arrayWithArray:filterArray];
    // 存放已经比较的Item
    NSMutableArray *compareItemArray = [NSMutableArray array];
    
    UInt64  uintFileSize = (UInt64) [fileSize longLongValue];
    BOOL needShowProcess = (uintFileSize * [pathArray count]) > 1024 * 1024 * 100; //大于100M 需要显示进度
    for (NSUInteger i = 0; i < [filterArray count]; i++) {
        QMFileItem *fileItem = pathArray[i];
        if ([compareItemArray containsObject:fileItem])
            continue;
        [compareItemArray addObject:fileItem];

        for (NSUInteger j = 0; j < [compareArray count]; j++) {
            QMFileItem *compareItem = compareArray[j];
            if (fileItem == compareItem)
                continue;
            QMFileItem *item1 = fileItem;
            QMFileItem *item2 = compareItem;
            QMFileItem *_item1 = nil;
            QMFileItem *_item2 = nil;
            
            // 显示文件夹比对进度.
            if(needShowProcess){
                CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
                if(now - _lastFolderCompareTime >= 0.3){
                    
                    NSString *dotString = @"";
                    if(_compareDotNum % 3 == 0){
                        dotString = @".";
                    }else if(_compareDotNum % 3 == 1){
                        dotString = @"..";
                    }else if(_compareDotNum % 3 == 2){
                        dotString = @"...";
                    }
                    
                    NSString *processString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"QMDuplicateFiles_bundleCompare_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""),[SizeHelper getFileSizeStringBySize:fileItem.fileSize], (unsigned long)[filterArray count], dotString];
                    
                    if(showDelegate){
                        [showDelegate progressRate:processRate progressStr:processString];
                    }
                    _lastFolderCompareTime = now;
                    _compareDotNum ++;
                }
            }
         
            
            while (YES) {
                if ([self dirContentsEqualAtItem:item1 item2:item2 layer:0 process:processRate]) {
                    _item1 = item1;
                    _item2 = item2;
                    if (!item1.equalItem) item1.equalItem = [NSMutableSet set];
                    if (!item2.equalItem) item2.equalItem = [NSMutableSet set];
                    [item1.equalItem addObject:item2.filePath];
                    [item2.equalItem addObject:item1.filePath];
                    item1 = item1.parentItem;
                    item2 = item2.parentItem;
                } else
                    break;
            }
            if (_item1 && _item2) {
                NSString *key = fileItem.filePath;
                NSMutableArray *array = tempMatchesDirDict[key];
                if (!array) array = [NSMutableArray array];
                if (![array containsObject:fileItem])
                    [array addObject:fileItem];
                if (![array containsObject:compareItem])
                    [array addObject:compareItem];
                tempMatchesDirDict[key] = array;

                if ([compareArray containsObject:fileItem]) {
                    [compareArray removeObject:fileItem];
                    j--;
                }
                if ([compareArray containsObject:compareItem]) {
                    [compareArray removeObject:compareItem];
                    j--;
                }
                [compareItemArray addObject:compareItem];
            }

            if (self.stopped)
                return;
        }
    }

    [self sendResultToDelegate:tempMatchesDirDict
                      fileSize:uintFileSize];
    for (NSString *key in tempMatchesDirDict.allKeys) {
        [duplicateDirArray addObjectsFromArray:tempMatchesDirDict[key]];
    }
}

- (void)searchDuplicateFiles {
    @autoreleasepool {
        //NSLog(@"searchDuplicateFiles start");

        NSUInteger keyCount = [[matchesFileSize allKeys] count];
        NSUInteger keyDirCount = [[matchesDirSize allKeys] count];

        // 首先比较目录
        for (NSUInteger i = 0; i < keyDirCount; i++) {
            @autoreleasepool {
                if (self.stopped)
                    break;

                NSString *key = [matchesDirSize allKeys][i]; //key
                NSMutableArray *array = matchesDirSize[key]; //value
                if ([array count] < 2)
                    continue;

                // set progress
                if (!showDelegate) {
                    _stopped = YES;
                    return;
                }
                //文件夹对比占0.1
                float rate = ((i + 1) / (float) (keyCount + keyDirCount)) * kDuplicateFolderCalculateProgress;
                
                //如果文件夹过多,这里遍历的时候时间过长,progressStr长时间为空,会造成类似卡死的假象
                
                // 文件夹的 key 都以 "F:"开头
                NSString *sizeKey = [key substringFromIndex:[kBundlePrefix length]];
                long long longSizeKey = [sizeKey longLongValue];

                NSString *progressStr = nil;
                if (longSizeKey * [array count] > 1024 * 1024 * 100) {
                    progressStr = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"QMDuplicateFiles_searchDuplicateFiles_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""), [SizeHelper getFileSizeStringBySize:longSizeKey * [array count]]];
                }

                float process = kDuplicateMaxSearchProgress + rate;
                _stopped = [showDelegate progressRate:process progressStr:progressStr];


                [self bundleCompare:array fileSize:sizeKey process:process];
            }
        }

        // 然后比较文件
        for (int i = 0; i < keyCount; i++) {
            @autoreleasepool {
                if (self.stopped)
                    break;

                NSString *key = [matchesFileSize allKeys][(NSUInteger) i];
                NSMutableArray *array = matchesFileSize[key];

                if ([array count] < 2)
                    continue;

                // set progress
                if (!showDelegate) {
                    _stopped = YES;
                    return;
                }
                float rate = ((i + 1 + keyDirCount) / (float) (keyCount + keyDirCount)) * (1.0f - kDuplicateMaxSearchProgress - kDuplicateFolderCalculateProgress);
                float process = kDuplicateMaxSearchProgress + rate + kDuplicateFolderCalculateProgress;
                _stopped = [showDelegate progressRate:process progressStr:@""];
                // 真正比较
                NSArray *resultArray = [self hashCompare:array dirType:NO process:process];
                
                //将 hashCompare 的数据
                [self addDuplicateFileToResult:resultArray fileSize:key];
            }
        }

        if (showDelegate)
            [showDelegate duplicateFileSearchEnd];
        duplicateDirArray = nil;
        matchesFileSize = nil;
        matchesDirSize = nil;
    }
}


@end
