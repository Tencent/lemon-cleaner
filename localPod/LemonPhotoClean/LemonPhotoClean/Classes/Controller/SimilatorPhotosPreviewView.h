//
//  SimilatorPhotosPreviewView.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMSimilarPhotoGroup.h"

NS_ASSUME_NONNULL_BEGIN

@interface SimilatorPhotosPreviewView : NSView

- (void)showSimilatorPhotosGroup:(LMSimilarPhotoGroup *)similarPhotoGroup firstShow:(NSInteger)index;
- (void)drawContentviewWithBgimage:(NSImage*)image;
@end

NS_ASSUME_NONNULL_END
