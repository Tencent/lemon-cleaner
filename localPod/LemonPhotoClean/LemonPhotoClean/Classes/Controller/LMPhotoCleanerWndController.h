//
//  LMFloderAddWindowController.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseWindowController.h>

@class LMSimilarPhotoGroup;
@interface LMPhotoCleanerWndController : QMBaseWindowController
- (void)showAddView;
- (void)showScanView:(NSArray<NSString *> *)scanPaths;
- (void)showResultView:(NSMutableArray <LMSimilarPhotoGroup *>*)result;
- (void)showCleanView:(NSMutableArray *)result;
- (void)showCleanFinishView:(NSInteger)deleteCount;
- (void)showNoSimilarPhotoViewController:(NSString *)descriptionString;
- (void)showCheckDeleteSystemPhotoViewController :(NSMutableArray <LMSimilarPhotoGroup *>*)result :(Boolean)authorizedForCreateAlbum: (NSMutableArray *)systemPhotoArray;
@end
