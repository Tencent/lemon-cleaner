//
//  ImageComparator.m
//  FirmToolsDuplicatePhotoFinder
//
//  
//  Copyright © 2018年 Hank. All rights reserved.
//

#import "ImageComparator.h"
#import "NSDataProcessor.h"
#import "FileMangerHelper.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import <QMCoreFunction/NSString+Extension.h>
#import <FMDB/FMDB.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <QMCoreFunction/LanguageHelper.h>

@interface ImageComparator ()
@property (nonatomic) BOOL isCancelCollectPath;
/**
 保存相册中的已经被删除的图片名称 用于过滤已删除的照片
 */
@property NSMutableArray *imageNamesDeletedOfAlbum;
@end
@implementation ImageComparator

- (instancetype)init
{
    self = [super init];
    if (self) {
        _allPaths = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)cancelCollectPath{
    self.isCancelCollectPath = YES;
}

- (NSArray<NSString *> *)collectImagePathsInRootPath:(NSArray<NSString *> *)rootPath{
    NSLog(@"LMPhotoCleaner--->collectImagePathsInRootPath begin");
    if([FileMangerHelper isContainPhotoLibraryWithPathArray:rootPath]){
        [self getImageNamesDeletedOfSystemAlbum];
    }
    NSMutableArray<NSString *> *resultPaths = [[NSMutableArray alloc] init];
    for (NSString *path in rootPath) {
//        NSLog(@"select path = %@", path);
        NSString *outputString = nil;
        NSString *onlyinPath = path;
        if ([path containsString:@".photoslibrary"]) {
            onlyinPath = [NSString stringWithFormat:@"%@/Pictures",[NSString getUserHomePath]];
//            onlyinPath = [path stringByDeletingLastPathComponent];
//            onlyinPath = photoPath;
        }
//        NSString *lastComponent = [path lastPathComponent];

//        if ([onlyinPath containsString:@""]) {
//            onlyinPath = [onlyinPath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
//        }
//        onlyinPath = @"/Users/junior/photo";
        NSString *shellString = [NSString stringWithFormat:@"find \"%@\" -type f \\( -iname \\*.jpg -o -iname \\*.jpeg -o -iname \\*.png -o -iname \\*.gif \\)", onlyinPath];
        outputString = [QMShellExcuteHelper excuteCmd:shellString];
//        NSLog(@"outputString = %@", outputString);
        
        NSArray *picArr = [outputString componentsSeparatedByString:@"\n"];
        if ([path containsString:@".photoslibrary"]) {
             for (NSString *picPath in picArr) {
                 //TODO:如果存在多个图库的情况，扫描结果会不正确
                if (([picPath containsString:@"photoslibrary/Masters"]||[picPath containsString:@"photoslibrary/originals"]) && [picPath containsString:onlyinPath]) {
                    if(@available(macOS 10.15,*)){//macOS 15以上版本数据库变了！！！
                        [resultPaths addObject:picPath];
                    }else{
                        if(![self isDeletedWithPhotoName:[picPath lastPathComponent]]){
    //                            NSLog(@"add result path name:%@",[picPath lastPathComponent]);
                            [resultPaths addObject:picPath];
                        }
                    }
                    
                }
                
             }
        }else{
            for (NSString *picPath in picArr) {
                if ([picPath containsString:onlyinPath]) {
                    [resultPaths addObject:picPath];
                }
            }
        }
        
    }
    NSLog(@"LMPhotoCleaner_collectImagePathsInRootPath end");
//    [self.allPaths removeAllObjects];
    return resultPaths;
}

-(NSString *)photoDirectory{
    if(@available(macOS 10.15, *)){//macOS 15以上版本照片文件夹改为ooriginals
        return @"photoslibrary/originals";
    }
    return @"photoslibrary/Masters";
}

/**
 获取已被删除的照片名称
 */
-(void)getImageNamesDeletedOfSystemAlbum{
    self.imageNamesDeletedOfAlbum = [[NSMutableArray alloc]init];
    NSString *dbPath = [self getPhotoDBPath];
    NSLog(@"getImageNamesDeletedOfSystemAlbum dbPath---%@",dbPath);
//    if(dbPath == nil)
//        return;
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    NSLog(@"LMPhotoCleaner--->getImageNamesDeletedOfSystemAlbum_dbPath:%@",dbPath);
    if([db open]){
        FMResultSet *resultSet = [db executeQuery:@"select * from RKMaster where isInTrash = 1"];
        while([resultSet next]){
            NSString *fileName = [resultSet stringForColumn:@"fileName"];
//            NSLog(@"LMPhotoCleaner--->not delete album fileName in db:%@",fileName);
            [self.imageNamesDeletedOfAlbum addObject:fileName];
        }
        
    }else{
        NSLog(@"LMPhotoCleaner--->getImageNamesDeletedOfSystemAlbum_openDB_failed");
    }
    NSLog(@"imageNamesDeletedOfAlbum count---%lu",(unsigned long)self.imageNamesDeletedOfAlbum.count);
    //outputString = [QMShellExcuteHelper excuteCmd:[NSString stringWithFormat:@"mdfind -onlyin \"%@\" 'kMDItemKind = \"*PNG*\" || kMDItemKind = \"*JPEG*\" || kMDItemKind = \"*image*\"'", onlyinPath]];
    //
}

/**
 获取系统相册数据库地址
 
 由于无法直接访问系统相册的数据库，所以需要将数据库复制到其他目录进行访问

 @return 数据库地址
 */
-(NSString *)getPhotoDBPath{
    NSString *home = NSHomeDirectory();
    NSString *systemPhotoPath = @""; //相册的路径
    NSString *targetPathForDB = @""; //数据库拷贝的目标路径photos.db
    NSString *resourcePathForDB = @""; //数据库拷贝的源路径photos.db
//    NSString *targetPathForDBWAL = @""; //数据库拷贝的目标路径photos.db-wal
    NSString *resourcePathForDBWAL = @""; //数据库拷贝的源路径photos.db-wal
    NSString *dbPath = @"";            //拷贝后的数据库路径 函数返回结果
    if ([McCoreFunction isAppStoreVersion]) {
        targetPathForDB = [home stringByAppendingPathComponent:@"Library/Application\\ Support/com.tencent.LemonLite/"];
        dbPath = [home stringByAppendingPathComponent:@"Library/Application Support/com.tencent.LemonLite/"];
    } else {
        targetPathForDB = [home stringByAppendingPathComponent:@"Library/Application\\ Support/com.tencent.Lemon/"];
        dbPath = [home stringByAppendingPathComponent:@"Library/Application Support/com.tencent.Lemon/"];
    }
    
    systemPhotoPath = [NSString stringWithFormat:@"%@/Pictures/照片图库.photoslibrary", [NSString getUserHomePath]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    Boolean isExist = [fileManager fileExistsAtPath:systemPhotoPath];
    if(!isExist){
        systemPhotoPath = [NSString stringWithFormat:@"%@/Pictures/Photos\\ Library.photoslibrary", [NSString getUserHomePath]];
        isExist = [fileManager fileExistsAtPath:systemPhotoPath];
    }
    
//    if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese){
//        systemPhotoPath = [NSString stringWithFormat:@"%@/Pictures/照片图库.photoslibrary", [NSString getUserHomePath]];
//    }else{
//        systemPhotoPath = [NSString stringWithFormat:@"%@/Pictures/Photos\\ Library.photoslibrary", [NSString getUserHomePath]];
//    }
    //复制photos.db
    resourcePathForDB = [systemPhotoPath stringByAppendingString:@"/database/photos.db"];
    isExist = [fileManager fileExistsAtPath:resourcePathForDB];     //判断数据库是否存在
    NSLog(@"resourcePathForDB：%@ -- isExist---%d",resourcePathForDB,isExist);
//    if(!isExist){
////        NSLog(@"resourcePathForDB：%@ isExist---%d",resourcePathForDB,isExist);
//        return nil;
//    }
    NSString *cmdString = [NSString stringWithFormat: @"cp %@ %@",resourcePathForDB,targetPathForDB];
    [QMShellExcuteHelper excuteCmd:cmdString];
    //复制photos.db-wal
    resourcePathForDBWAL = [systemPhotoPath stringByAppendingString:@"/database/photos.db-wal"];
    cmdString = [NSString stringWithFormat: @"cp %@ %@",resourcePathForDBWAL,targetPathForDB];
    [QMShellExcuteHelper excuteCmd:cmdString];
    return [dbPath stringByAppendingPathComponent:@"photos.db"];
}

/**x
 判断照片是否被删除
 @param name 照片名称
 @return 是：YES，否：NO
 */
-(Boolean)isDeletedWithPhotoName:(NSString*)name{
    for (NSString *temp in self.imageNamesDeletedOfAlbum) {
        if ([temp isEqualToString:name]) {
            return YES;
        }
    }
    return NO;
}

/**
 获取相册中的所有图片的名称
 用于过滤已删除的照片
 */
//-(void)getImageNamesOfSystemAlbum{
////    self.autoClearPhotosArray = [[NSMutableArray alloc]init];
//    NSString *scriptString = @"tell application \"Photos\" \n"
//    "set mediaItems to every media item \n"
//    "set resultList to {} \n"
//    "repeat with mediaItem in mediaItems \n"
//    "set itemName to (filename of mediaItem) \n"
//    "set the end of resultList to itemName \n"
//    "end repeat \n"
//    "return resultList \n"
//    "end tell";
//    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptString];
//    NSDictionary *dic;
//    @try {
//        NSAppleEventDescriptor *descriptor = [appleScript executeAndReturnError:&dic];
//        if(dic){
//            NSLog(@"getImageNamesOfSystemAlbum_AppleScript_dic-->%@",dic);
//        }
//        self.imageNamesOfAlbum = [[NSMutableSet alloc] init];
//        for(int i = 1; i <= [descriptor numberOfItems]; i++){
//            NSString* name = [descriptor descriptorAtIndex:i].stringValue;
//            [self.imageNamesOfAlbum addObject:name];
//        }
//    } @catch (NSException *exception) {
//        NSLog(@"getImageNamesOfSystemAlbum_AppleScript_exception = %@",exception);
//    }
//
//}

- (void)showFiles:(NSArray *)paths{
    NSMutableArray *pathArray = [[NSMutableArray alloc] init];
    NSLog(@"showFiles :%@",paths);
    
    for (NSString *path in paths) {
        NSLog(@"showFiles one for %@",path);
        
        BOOL isIncludeByOtherPath = NO;
        for (NSString *comparePath in paths) {
            NSLog(@"showFiles two for %@",paths);
            
            @autoreleasepool {
                // path 自身不需要同自己比较.
                if (comparePath == path)
                    continue;
                // path 是否是其他 path 的子目录
                if (comparePath.length < path.length
                    && [[path stringByDeletingLastPathComponent] hasPrefix:comparePath]) {
                    isIncludeByOtherPath = YES;
                    break;
                }
            }
            
        }
        if (isIncludeByOtherPath)
            continue;
        [pathArray addObject:path];
    }
    paths = nil;
    
    NSLog(@"step one pathArray: %@",pathArray);
    
    //该循环只是过滤掉不需要查找的文件
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *photoPath = [NSString stringWithFormat:@"%@/Pictures",[NSString getUserHomePath]];

    for (NSInteger index = 0;index < pathArray.count; index ++) {
        NSString *path = [pathArray objectAtIndex:index];
        @autoreleasepool {
            if(self.isCancelCollectPath == YES){
                return;
            }
            NSDirectoryEnumerator *dirEnumerator;
            NSURL *url =  [NSURL fileURLWithPath:path];
            NSLog(@"fileURLWithPath: %@",url);
            
            if ([path containsString:photoPath]) {
                dirEnumerator = [fm enumeratorAtURL:url
                         includingPropertiesForKeys:nil
                                            options:NSDirectoryEnumerationSkipsHiddenFiles
                                       errorHandler:nil];
            } else {
                dirEnumerator = [fm enumeratorAtURL:url
                         includingPropertiesForKeys:nil
                                            options:NSDirectoryEnumerationSkipsPackageDescendants
                                       errorHandler:nil];
            }
            url = nil;
            NSLog(@"NSDirectoryEnumerator: %@,url:%@",dirEnumerator,url);
            
            [self.allPaths addObject:path];
            //            [pathArray removeObjectAtIndex:index];
            
            int i = 0;
            for (NSURL *contentURL in dirEnumerator) {
                NSLog(@"contentURL: %@",contentURL);
                
                if(self.isCancelCollectPath == YES){
                    return;
                }
                @autoreleasepool {
                    // 过滤快捷方式
                    NSNumber *result = nil;
                    [contentURL getResourceValue:&result forKey:NSURLIsAliasFileKey error:NULL];
                    if (result && [result boolValue])
                        continue;
                    
                    NSNumber *dir = nil;
                    NSLog(@"NSURLIsAliasFileKey");
                    
                    [contentURL getResourceValue:&dir forKey:NSURLIsDirectoryKey error:NULL];
                    
                    NSString *resultPath = [contentURL path];
                    
                    NSNumber *hidden = nil;
                    NSLog(@"NSURLIsDirectoryKey");
                    
                    [contentURL getResourceValue:&hidden forKey:NSURLIsHiddenKey error:NULL];
                    if ([hidden boolValue]) {
                        if ([dir boolValue])
                            [dirEnumerator skipDescendants];
                        else if ([[resultPath lastPathComponent] isEqualToString:@".DS_Store"])
                            continue;
                    }
                    NSLog(@"NSURLIsHiddenKey");
                    
                    [self.allPaths addObject:resultPath];
                    resultPath = nil;
                    i++;
                }
            } //内层for 结束
            
            dirEnumerator = nil;
        }
        
    }
    photoPath = nil;
    fm = nil;
    //    [pathArray removeAllObjects];
    pathArray = nil;
}


-(void)dealloc{
    NSLog(@"Super Dealloc _______________________ ，%@",[self className]);
}
@end
