//
//  LMPhotoCleanViewController.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMPhotoCleanViewController.h"
#import <QMUICommon/QMProgressView.h>
#import "LMSimilarPhotoGroup.h"
#import "LMPhotoCleanerWndController.h"
#import <QMCoreFunction/NSString+Extension.h>
#import "LMSystemPhotoCleanerHelper.h"


@interface LMPhotoCleanViewController () {
    int totalCountToDel;
    int delCount;
    
    int selfFloderTotalCount;
    int photoFloderTotalCount;
    
    int selfFloderProcessCount;
    int photoFloderProcessCount;
    
    int progressCount;
    
    BOOL authorizedForCreateAlbum;
    NSDate *notificatinStartDate;
    
    Boolean albumCreateHasFinished;//标识相册是否已经创建完成
}

@property (weak) IBOutlet NSTextField *cleanningTitleTextFileld;
@property (weak) IBOutlet QMProgressView *progressView;
@property (weak) IBOutlet NSTextField *currentPath;
@property (nonatomic,strong) NSMutableArray *photoArray; //保存系统相册中的照片
@property (nonatomic,copy) NSMutableArray <LMSimilarPhotoGroup *>*resultArray;

@property (nonatomic,strong) NSTimer *progressTimer;
@property (nonatomic,strong) NSMutableArray *needDeletePathArray;

@end

@implementation LMPhotoCleanViewController


- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        //myBundle = [NSBundle bundleForClass:[self class]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self.cleanningTitleTextFileld setStringValue:NSLocalizedStringFromTableInBundle(@"LMPhotoCleanViewController_viewDidLoad_cleanningTitleTextFileld_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self setTitleColorForTextField:self.cleanningTitleTextFileld];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onItemDeleted:) name:LM_NOTIFICATION_ITEM_DELECTED object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onCreateAlbumFinished:) name:LM_NOTIFCATION_CREAT_ALBUM_FINISHED object:nil];
    
    [self.currentPath setLineBreakMode:NSLineBreakByTruncatingMiddle];

    self.progressView.value = 0;
    totalCountToDel = 0;
    delCount = 0;
    selfFloderTotalCount = 0;
    photoFloderTotalCount = 0;
    selfFloderProcessCount = 0;
    photoFloderProcessCount = 0;
    self.needDeletePathArray = [NSMutableArray new];
    albumCreateHasFinished = false;
}

- (void)timerProgressUpdate{
    progressCount++;
    float progress = (float)progressCount / self.needDeletePathArray.count;
    progress = progress > 1 ? 1 : progress;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger index = floor(progress*self.needDeletePathArray.count) -1;
        if(index <0) index = 0;
        if(index >= self.needDeletePathArray.count) index = self.needDeletePathArray.count - 1;
        if (self.needDeletePathArray.count>0) {
            self.currentPath.stringValue = self.needDeletePathArray[index];
            if (self.progressView.actionEnd ||  progress >= 1) {
                self.progressView.value = progress;
            }
        }
//        NSLog(@"progress--->%f",progress);
    });
    
    if (fabsf(progress - 1) < 0.01) {
        [self stopProgressTimer];
        if(self.photoArray.count == 0){//self.photoArray不为空则需要创建相册让用户清理  等待创建完相册，收到通知在进行跳转
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view.window.windowController showCleanFinishView:self->totalCountToDel];
            });
        }
        else{
            if(albumCreateHasFinished){//此时进度条已经跑完，如果相册已经创建完成，就跳转到结果页
                [self.view.window.windowController showCheckDeleteSystemPhotoViewController:self.resultArray:self->authorizedForCreateAlbum:self.photoArray];
                [[NSNotificationCenter defaultCenter] removeObserver:self name:LM_NOTIFCATION_CREAT_ALBUM_FINISHED object:nil];
            }
        }
//        else {
////            dispatch_async(dispatch_get_main_queue(), ^{
////                NSLog(@"showCheckDeleteSystemPhotoViewController__called");
////                [self.progressTimer invalidate];
////                self.progressTimer = nil;
////                [self.view.window.windowController showCheckDeleteSystemPhotoViewController:self.resultArray:self->authorizedForCreateAlbum];
////            });
//        }
    }
   
}

/**
 创建相册完成后，发送 LM_NOTIFCATION_CREAT_ALBUM_FINISHED通知 回调该方法，展示结果页面
 */
- (void)onCreateAlbumFinished:(NSNotification *)notification{
    NSLog(@"onCreateAlbumFinished called");
    NSNumber *number = [notification object];
    authorizedForCreateAlbum = [number boolValue];
    if(self.progressView.value < 1 && authorizedForCreateAlbum){  //如果相册已经创建完成，但是进度条还没跑完，需要跑完进度条再跳转
//        self.progressTimer.timeInterval = 0.02;
        albumCreateHasFinished = true;
        [self stopProgressTimer];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"----photoFloderTotalCount : %d  ----selfFloderTotalCount : %d",self->photoFloderTotalCount,self->selfFloderTotalCount);
            self.progressTimer = [NSTimer timerWithTimeInterval:0.02 target:self selector:@selector(timerProgressUpdate) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.progressTimer forMode:NSRunLoopCommonModes];
            [self.progressTimer fire];
            
        });
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopProgressTimer];
        [self.view.window.windowController showCheckDeleteSystemPhotoViewController:self.resultArray:self->authorizedForCreateAlbum:self.photoArray];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:LM_NOTIFCATION_CREAT_ALBUM_FINISHED object:nil];
    });
}

-(void)stopProgressTimer{
    if(self.progressTimer){
        [self.progressTimer invalidate];
        self.progressTimer = nil;
    }
}

- (void)deleteSelectItem:(NSMutableArray *)result {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self scanPhotoNumber:result];
    });
}

- (void)scanPhotoNumber:(NSMutableArray *)result{
    self.resultArray = [result mutableCopy];
    
    NSString *photoPath = [NSString stringWithFormat:@"%@/Pictures", [NSString getUserHomePath]];
    NSString *photoslibraryPath = @"photoslibrary";
    
    for (LMSimilarPhotoGroup *group in result) {
        for (LMPhotoItem *photoItem in group.items) {
            if(photoItem.isSelected == YES){
                [self.needDeletePathArray addObject:photoItem.path];
                if([photoItem.path containsString:photoPath] && [photoItem.path containsString:photoslibraryPath]){
                    photoFloderTotalCount++;
                } else {
                    selfFloderTotalCount++;
                }
            }
        }
        totalCountToDel += group.selectedItemCount;
    }
    
    double intervalTime = (0.05 * selfFloderTotalCount + 0.25 * photoFloderTotalCount) / (selfFloderTotalCount + photoFloderTotalCount);
    NSLog(@"intervalTime--->%f",intervalTime);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"----photoFloderTotalCount : %d  ----selfFloderTotalCount : %d",self->photoFloderTotalCount,self->selfFloderTotalCount);
        self.progressTimer = [NSTimer timerWithTimeInterval:intervalTime target:self selector:@selector(timerProgressUpdate) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.progressTimer forMode:NSRunLoopCommonModes];
        [self.progressTimer fire];
        
    });
    
    //自选文件夹和photolib文件夹同步删除 异步可能会出问题
    if (photoFloderTotalCount > 0) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self deletePhotosFloder:result];
        });
    }
    
    if (selfFloderTotalCount > 0) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self deleteSelfFloder:result];
        });
    }
}

- (void)deleteSelfFloder:(NSMutableArray *)result {
    for (LMSimilarPhotoGroup *group in result) {
        [group delSelectedPhotos];
    }
}

- (void)deletePhotosFloder:(NSMutableArray *)result {
    [self scanPhoto:result];
}
//
//-(void)scanSystemPhoto:(NSMutableArray *)result{
//    LMSystemPhotoCleanerHelper *helper = [[LMSystemPhotoCleanerHelper alloc]init];
//    helper.similarPhotoGroups = result;
//    [helper scanPhotoLibrary];
//}

- (void)scanPhoto:(NSMutableArray *)result {
    self.photoArray = [NSMutableArray new];
    NSString *photoPath = [NSString stringWithFormat:@"%@/Pictures", [NSString getUserHomePath]];
    NSString *photoslibraryPath = @"photoslibrary";

    for (LMSimilarPhotoGroup *photoGroup in [result mutableCopy]) {
        for (NSInteger index = 0; index < photoGroup.items.count;index ++) {
            LMPhotoItem *item  =  photoGroup.items[index];
            if([item.path containsString:photoPath]&& [item.path containsString:photoslibraryPath] &&item.isSelected == YES){
                [self.photoArray addObject:[item.path componentsSeparatedByString:@"/"].lastObject];
            }
        }
    }
    
    @try{
        LMSystemPhotoCleanerHelper *helper = [[LMSystemPhotoCleanerHelper alloc]init];
        [helper addPhotoToAlbumWith:self.photoArray];
    }@catch(NSException *exception){
        NSLog(@"exception = %@", exception);
    }
    
}

//-(void)addAlbumsWith:(NSArray *)pathArray{
//    if ((pathArray == nil) || ([pathArray count] == 0)) {
//        return;
//    }
//    NSString *jsonString = @"";
//    for (NSInteger i = 0; i < [pathArray count]; i++) {
//        NSString *_str = [pathArray objectAtIndex:i];
//        [_str stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
//        jsonString = [jsonString stringByAppendingString:@"\""];
//        jsonString = [jsonString stringByAppendingString:_str];
//        if(i == [pathArray count] - 1){
//            jsonString = [jsonString stringByAppendingString:@"\""];
//        } else {
//            jsonString = [jsonString stringByAppendingString:@"\","];
//        }
//    }
////    NSLog(@"%s pending remove photos :%@ ", __FUNCTION__ ,jsonString);
//
//    NSAppleScript *script = nil;
//
//    NSString *addItemScript1 = [NSString stringWithFormat:[LMSystemPhotoCleanerHelper getAppScriptForCreateAlbum1014],jsonString];
//
//
//    // 10.15系统上Photo Library 中存储的文件名为: B4F3A06E-040A-42F7-B84B-F2084623C922.jpeg
//    // 而相册中 中显示的文件名为 "Photo_aaa.jpg",两者无法匹配.
//    // 解决办法: 利用 id of _mediaItem 获取 mediaid后,这个 id 可与真实的文件名进行匹配.
//    NSString *addItemScript2 = [NSString stringWithFormat:[LMSystemPhotoCleanerHelper getAppScriptForCreateAlbum1015],jsonString];
//
    
    /*
     
    tell application "Photos"
    set finalAlbum to my makeAlbum("LemonCleaner")
    set mediaItems to every media item
    set listImages to {"B4F3A06E-040A-42F7-B84B-F2084623C922.jpeg", "F845225D-A4E8-4D42-AD22-7AB6554694AE.jpeg",  "8501BBC4-D030-4259-9FD1-175FE5A3639E.png"}
    set imageNames to my getFileNamesAndRemoveExtensions(listImages)
    repeat with _mediaItem in mediaItems
        set _item_id to (id of _mediaItem)
        set _item_id_splits to my theSplit(_item_id, "/")
        set len to length of _item_id_splits
        if (len > 0) then
            set _id to item 1 of _item_id_splits
            if imageNames contains _id then
                add {_mediaItem} to finalAlbum
            end if
        end if
    end repeat
end tell

on makeAlbum(albName)
    tell application "Photos"
        repeat with _album in every album
            set _name to name of _album
            if (_name = albName) then
                return _album
            end if
        end repeat
        return make new album named albName
    end tell
end makeAlbum

on getFileNamesAndRemoveExtensions(fileNames)
    set _names to {}
    repeat with fileName in fileNames
        set name_splits to my theSplit(fileName, ".")
        set len to length of name_splits
        if (len > 0) then
            set end of _names to (item 1 of name_splits)
        end if
    end repeat
    return _names
end getFileNamesAndRemoveExtensions


on theSplit(theString, theDelimiter)
    set oldDelimiters to AppleScript's text item delimiters
    set AppleScript's text item delimiters to theDelimiter
    set theArray to every text item of theString
    set AppleScript's text item delimiters to oldDelimiters
    return theArray
end theSplit
     */
    
    
    
    
//
//    NSString *addItemScript = NULL;
//    if(@available(macOS 10.15,*)){ //macOS 15以上版本applescript 语法变了！！！
//        addItemScript = addItemScript2;
//        NSLog(@"os version over 10.15, user addItemScript2");
////        NSLog(@"addItemScript2 is \n    %@", addItemScript2);
//
//    }else{
//        addItemScript = addItemScript1;
//    }
////    SInt32 versionMajor=0, versionMinor=0;
////    Gestalt(gestaltSystemVersionMajor, &versionMajor);
////    Gestalt(gestaltSystemVersionMinor, &versionMinor);
////    NSLog(@"addItemScript---%@",addItemScript);
//    script = [[NSAppleScript alloc] initWithSource:addItemScript];
//    NSDictionary *dict = nil;
//    @try{
//        NSDate *startDate = [NSDate date];
//        [script executeAndReturnError:&dict];
//        double dealTime = [[NSDate date] timeIntervalSinceDate:startDate];
//        NSLog(@"addAlbumsWith--->dealTime:%f",dealTime);
//        if(dict){
//            NSLog(@"addAlbumsWith_dict-->%@",dict);
//            authorizedForCreateAlbum = NO;
////            NSNumber *number = [dict objectForKey:@"NSAppleScriptErrorNumber"];
////            if([number shortValue] == -1743){ //错误码-1743 应该是没有权限,但是目前不知道会不会返回其他错误码，所以执行出错了就提示没有权限
////                authorizedForCreateAlbum = false;
////            }
//        }else{
//            authorizedForCreateAlbum = YES;
//        }
//        notificatinStartDate = [NSDate date];
//        [[NSNotificationCenter defaultCenter] postNotificationName:LM_NOTIFCATION_CREAT_ALBUM_FINISHED object:nil];
//    }
//    @catch(NSException *exception){
//        NSLog(@"addAlbumsWith exception = %@", exception);
//        //如果抛出异常，默认用户授予了权限
//        authorizedForCreateAlbum = YES;
//        [[NSNotificationCenter defaultCenter] postNotificationName:LM_NOTIFCATION_CREAT_ALBUM_FINISHED object:nil];
//    }
//
//}
//
//#pragma notification
//- (void) onItemDeleted:(NSNotification *)notifly {
////    LMPhotoItem *itemDeleted = [notifly.userInfo objectForKey:LM_KEY_ITEM];
////    delCount = delCount + 1;
////    NSLog(@"delCount %d， totalCountToDel %d", self->delCount, self->totalCountToDel);
////    if (delCount == totalCountToDel) {
////        [[NSNotificationCenter defaultCenter] removeObserver:self];
////        [self scanPhoto: self.resultArray];
////    }
////
////    float progerss = ((float)delCount) / totalCountToDel;
////    dispatch_async(dispatch_get_main_queue(), ^{
////        self.currentPath.stringValue = itemDeleted.path;
////        self.progressView.value = progerss;
////
////    });
//
//}

- (void)dealloc
{
    NSLog(@"dealloc__called");
    [[NSNotificationCenter defaultCenter]removeObserver:self name:LM_NOTIFCATION_CREAT_ALBUM_FINISHED object:nil];
}

@end
