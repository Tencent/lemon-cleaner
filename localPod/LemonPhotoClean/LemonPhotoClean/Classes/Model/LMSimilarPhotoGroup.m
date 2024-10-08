//
//  SimilarPhotoGroup.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMSimilarPhotoGroup.h"
#import <QMCoreFunction/McCoreFunction.h>
#import <QMCoreFunction/NSString+Extension.h>
@implementation LMSimilarPhotoGroup


+ (NSOperationQueue *)deletingOperationQueue {
    static NSOperationQueue *queue;
    if (queue == nil) {
        queue = [[NSOperationQueue alloc] init];
        queue.name = @"Delete Queue";
        queue.maxConcurrentOperationCount = 1;
    }
    return queue;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _items = [[NSMutableArray<LMPhotoItem*> alloc] init];
    }
    return self;
}

// 注意，只能在主线程中调用，会在子线程中执行真正的del操作，成功删除后在主线程中更新删除items元素，并且发送notification
- (void)delSelectedPhotos {
    NSMutableArray *copyItem = [NSMutableArray new];
    copyItem = [self.items mutableCopy];
    [[LMSimilarPhotoGroup deletingOperationQueue] addOperationWithBlock:^{
        NSString *photoPath = [NSString stringWithFormat:@"%@/Pictures",[NSString getUserHomePath]];
        NSString *photoslibraryPath = @"photoslibrary";

        NSMutableArray *photoPathsNeedToDeleteArray = [[NSMutableArray alloc] init];
        
        for (int i = (int)(copyItem.count - 1); i>=0; i--) {
            LMPhotoItem* item = copyItem[i];
            NSLog(@"delSelectedPhotos for index:%d, %@", i, [NSThread currentThread]);
            if (item.isSelected&&!([item.path containsString:photoPath]&&[item.path containsString:photoslibraryPath])) {
                NSLog(@"delSelectedPhotos at index:%d", i);
#ifndef APPSTORE_VERSION
                
                [[McCoreFunction shareCoreFuction] cleanItemAtPath:item.path array:nil removeType:McCleanMoveTrashRoot];
#else
                [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
                                                                            source:[item.path stringByDeletingLastPathComponent]
                                                                       destination:@""
                                                                             files:@[[item.path lastPathComponent]]
                                                                               tag:nil];
#endif
                [self itemDeletedAtIndex:i];
            } else if (item.isSelected){
                [photoPathsNeedToDeleteArray addObject:[item.path componentsSeparatedByString:@"/"].lastObject];
                [self itemDeletedAtIndex:i];
            }
            
//            if (i == 0) {
//                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                    [self postNotifacation]; //不知道为什么发送这个通知。。。
//                }];
//            }
        }
        
//        if(photoPathsNeedToDeleteArray.count > 0){
//            @try{
//                dispatch_async(dispatch_get_global_queue(0, 0), ^{
//                    [self addAlbumsWith:photoPathsNeedToDeleteArray];
//                });
//            }@catch(NSException *exception){
//                NSLog(@"exception = %@", exception);
//            }
//        }
        
    }];
}

- (void)itemDeletedAtIndex:(int)index {
    LMPhotoItem *item = [self.items objectAtIndex:index];
    item.isDeleted = YES;
//    [self.items removeObjectAtIndex:index];
//    NSLog(@"itemDeleted at index %d, item:%@", index, self.items);
}

- (void)postNotifacation{
    [[NSNotificationCenter defaultCenter] postNotificationName:LM_NOTIFICATION_ITEM_DELECTED object:self userInfo:@{LM_KEY_ITEM:self}];
}

- (int)selectedItemCount {
    int count = 0;
    for (LMPhotoItem *item in self.items) {
        if (item.isSelected) count++;
    }
    return count;
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
//
//    NSAppleScript *script = nil;
//
//    NSString *addItemScript = [NSString stringWithFormat:@"tell application \"Photos\"\n"
//                               "set mediaItems to every media item \n"
//                               "set listImages to {%@} \n"
//
//                               "repeat with mediaItem in mediaItems \n"
//                               "set mdate to (filename of mediaItem) \n"
//                               "if listImages contains mdate then \n"
//                               "set finalAlbum to my makeAlbum(\"LemonCleaner\") \n"
//                               "add {mediaItem} to finalAlbum \n"
//                               "end if \n"
//                               "end repeat \n"
//                               "end tell \n"
//
//                               "on makeAlbum(albName) \n"
//                               "tell application \"Photos\" \n"
//                               "if exists container albName then \n"
//                               "return container albName \n"
//                               "else \n"
//                               "return make new album named albName \n"
//                               "end if \n"
//                               "end tell \n"
//                               "end makeAlbum",jsonString];
//
////    SInt32 versionMajor=0, versionMinor=0;
////    Gestalt(gestaltSystemVersionMajor, &versionMajor);
////    Gestalt(gestaltSystemVersionMinor, &versionMinor);
//    script = [[NSAppleScript alloc] initWithSource:addItemScript];
//    NSDictionary *dict = nil;
//    @try{
//        [script executeAndReturnError:&dict];
//        if (dict != nil) {
//            NSLog(@"dict error =%@", dict);
//        }
//    }
//    @catch(NSException *exception){
//        NSLog(@"addAlbumsWith exception = %@", exception);
//    }
//
//}
@end
