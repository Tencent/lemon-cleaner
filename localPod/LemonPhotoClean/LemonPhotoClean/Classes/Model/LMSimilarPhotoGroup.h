//
//  SimilarPhotoGroup.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMPhotoItem.h"

@interface LMSimilarPhotoGroup : NSObject

@property NSString *groupName;
@property NSMutableArray<LMPhotoItem*> *items;
@property (readonly) int selectedItemCount;
@property BOOL isDeleted;


- (void)delSelectedPhotos;

@end
