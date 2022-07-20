//
//  LMSystemPhotoCleanerHelper.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMSystemPhotoCleanerHelper.h"
#import <QMCoreFunction/NSString+Extension.h>
@interface LMSystemPhotoCleanerHelper()

@property NSMutableArray *systemPhotoPathArray;
@property BOOL authorizedForCreateAlbum;

@end


@implementation LMSystemPhotoCleanerHelper

/**
 将所有照片再次扫描
 */
-(void)scanPhotoLibrary{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self getSystemPhotos];
    });
}

/**
 将图片添加到相册中

 @param systemPhotoArray 系统相册中的图片
 */
-(void)addPhotoToAlbumWith:(NSMutableArray*)systemPhotoArray{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self addAlbumsWith:systemPhotoArray];
    });
}

/**
 获取系统相册中的图片
 */
- (void)getSystemPhotos{
    self.systemPhotoPathArray = [NSMutableArray new];
    NSString *photoPath = [NSString stringWithFormat:@"%@/Pictures", [NSString getUserHomePath]];
    NSString *photoslibraryPath = @"photoslibrary";
    
    for (LMSimilarPhotoGroup *photoGroup in [self.similarPhotoGroups mutableCopy]) {
        for (NSInteger index = 0; index < photoGroup.items.count;index ++) {
            LMPhotoItem *item  =  photoGroup.items[index];
            if([item.path containsString:photoPath]&& [item.path containsString:photoslibraryPath] &&item.isSelected == YES){
                [self.systemPhotoPathArray addObject:[item.path componentsSeparatedByString:@"/"].lastObject];
            }
        }
    }
    @try{
        [self addAlbumsWith:self.systemPhotoPathArray];
    }@catch(NSException *exception){
        NSLog(@"exception = %@", exception);
    }
    
}

//appscript 参数长度过长会发生Stack overflow异常，长度阈值大约在180000字符左右。 //5000
//所以需要分组执行applescript
-(void)addAlbumsWith:(NSMutableArray *)pathArray{
    if(pathArray.count < 5000){
        [self addAlbumsWithSubArray:pathArray isLastArray:YES];
        return;
    }
    NSInteger count = pathArray.count / 5000;
    for(NSInteger i = 0; i <= count; i++){
        if(i < count){
            //如果执行过程中出现问题，取消后续执行
           if(![self addAlbumsWithSubArray:[pathArray subarrayWithRange:NSMakeRange(i * 5000, 5000)] isLastArray: NO]){
                return;
           }
        }else{
           if(![self addAlbumsWithSubArray:[pathArray subarrayWithRange:NSMakeRange(i * 5000, (pathArray.count - i * 5000))] isLastArray:YES]){
                 return;
            }
        }
    }
}

/**
 创建相册并添加需要清理的图片

 @param pathArray 系统相册图片
 @param isLastArray 是否是最后一个数组 如果是执行完applescript需要通知完成
 @return 返回是否成功执行
 */
-(BOOL)addAlbumsWithSubArray:(NSArray *)pathArray isLastArray:(BOOL)isLastArray{
    if ((pathArray == nil) || ([pathArray count] == 0)) {
        return NO;
    }
    NSString *jsonString = @"";
    for (NSInteger i = 0; i < [pathArray count]; i++) {
        NSString *_str = [pathArray objectAtIndex:i];
        [_str stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
        jsonString = [jsonString stringByAppendingString:@"\""];
        jsonString = [jsonString stringByAppendingString:_str];
        if(i == [pathArray count] - 1){
            jsonString = [jsonString stringByAppendingString:@"\""];
        } else {
            jsonString = [jsonString stringByAppendingString:@"\","];
        }
    }
    
    
    NSAppleScript *script = nil;
    
    NSString *addItemScript1 = [NSString stringWithFormat:[LMSystemPhotoCleanerHelper getAppScriptForCreateAlbum1014],jsonString];

    // 10.15系统上Photo Library 中存储的文件名为: B4F3A06E-040A-42F7-B84B-F2084623C922.jpeg
    // 而相册中 中显示的文件名为 "Photo_aaa.jpg",两者无法匹配.
    // 解决办法: 利用 id of _mediaItem 获取 mediaid后,这个 id 可与真实的文件名进行匹配.
    NSString *addItemScript2 = [NSString stringWithFormat:[LMSystemPhotoCleanerHelper getAppScriptForCreateAlbum1015],jsonString];
    NSString *addItemScript = NULL;
        if(@available(macOS 10.15,*)){ //macOS 15以上版本applescript 语法变了！！！
            addItemScript = addItemScript2;
            NSLog(@"os version over 10.15, user addItemScript2");
    //        NSLog(@"addItemScript2 is \n    %@", addItemScript2);

        }else{
            addItemScript = addItemScript1;
        }
    script = [[NSAppleScript alloc] initWithSource:addItemScript];
    
    NSDictionary *dict = nil;
    @try{
        [script executeAndReturnError:&dict];
        if(dict){
            NSLog(@"LM_Cleaner_photo_addAlbumsWith_dict-->%@",dict);
            self.authorizedForCreateAlbum = NO;
            //            NSNumber *number = [dict objectForKey:@"NSAppleScriptErrorNumber"];
            //            if([number shortValue] == -1743){ //错误码-1743 应该是没有权限,但是目前不知道会不会返回其他错误码，所以执行出错了就提示没有权限
            //                authorizedForCreateAlbum = false;
            //            }
        }else{
            self.authorizedForCreateAlbum = YES;
        }
        if(isLastArray || !self.authorizedForCreateAlbum){    //如果是最后一个数组或者没有权限，需要发送通知
            [[NSNotificationCenter defaultCenter] postNotificationName:LM_NOTIFCATION_CREAT_ALBUM_FINISHED object:[NSNumber numberWithBool: self.authorizedForCreateAlbum]];
        }
        
        return self.authorizedForCreateAlbum;
    }
    @catch(NSException *exception){
        NSLog(@"LM_Cleaner_photo_addAlbumsWith exception = %@", exception);
        //如果抛出异常，默认用户授予了权限
        self.authorizedForCreateAlbum = YES;
        if(isLastArray || !self.authorizedForCreateAlbum){
             [[NSNotificationCenter defaultCenter] postNotificationName:LM_NOTIFCATION_CREAT_ALBUM_FINISHED object:[NSNumber numberWithBool: self.authorizedForCreateAlbum]];
        }
        return YES;
    }
    
}

+(NSString *)getAppleScriptForCreateAlbum: (Boolean *)b{
    return @"";
}

+(NSString *)getAppScriptForCreateAlbum1014{
    return @"tell application \"Photos\"\n"
    "set mediaItems to every media item \n"
    "set listImages to {%@} \n"
    
    "repeat with mediaItem in mediaItems \n"
    "set mdate to (filename of mediaItem) \n"
    "if listImages contains mdate then \n"
    "set finalAlbum to my makeAlbum(\"LemonCleaner\") \n"
    "add {mediaItem} to finalAlbum \n"
    "end if \n"
    "end repeat \n"
    "end tell \n"
    
    "on makeAlbum(albName) \n"
    "tell application \"Photos\" \n"
    "if exists container albName then \n"
    "return container albName \n"
    "else \n"
    "return make new album named albName \n"
    "end if \n"
    "end tell \n"
    "end makeAlbum";
}

+(NSString *)getAppScriptForCreateAlbum1015{
    return @"tell application \"Photos\"\n"
                         "set finalAlbum to my makeAlbum(\"LemonCleaner\") \n"
                         "set mediaItems to every media item \n"
                         "set listImages to {%@} \n"
                         "set imageNames to my getFileNamesAndRemoveExtensions(listImages)\n"

                         "repeat with _mediaItem in mediaItems \n"
                         "set _item_id to ( id of _mediaItem) \n"
                         "set _item_id_splits to my theSplit(_item_id, \"/\") \n"
                         "set len to length of _item_id_splits \n"
                         "if (len > 0) then \n"
                         "set _id to item 1 of _item_id_splits \n"
                         "if imageNames contains _id then \n"
                         "add {_mediaItem} to finalAlbum \n"
                         "end if \n"
                         "end if \n"
                         "end repeat \n"
                         "end tell \n"
    
                         "\n"
                        
                         "on makeAlbum(albName) \n"
                         "tell application \"Photos\" \n"
                         "repeat with _album in every album \n"
                         "set _name to name of _album \n"
                         "if (_name = albName) then \n"
                         "return _album \n"
                         "end if \n"
                         "end repeat \n"
                         "return make new album named albName \n"
                         "end tell \n"
                         "end makeAlbum \n"
                        
                         "\n"
                        
                         "on getFileNamesAndRemoveExtensions(fileNames) \n"
                         "set _names to {} \n"
                         "repeat with fileName in fileNames \n"
                         "set name_splits to my theSplit(fileName, \".\") \n"
                         "set len to length of name_splits \n"
                         "if (len > 0) then \n"
                         "set end of _names to (item 1 of name_splits) \n"
                         "end if \n"
                         "end repeat \n"
                         "return _names \n"
                         "end getFileNamesAndRemoveExtensions \n"
                        
                        
                         "\n"
                        
                        
                         "on theSplit(theString, theDelimiter) \n"
                         "set oldDelimiters to AppleScript's text item delimiters \n"
                         "set AppleScript's text item delimiters to theDelimiter \n"
                         "set theArray to every text item of theString \n"
                         "set AppleScript's text item delimiters to oldDelimiters \n"
                         "return theArray \n"
    "end theSplit \n";
}

@end
