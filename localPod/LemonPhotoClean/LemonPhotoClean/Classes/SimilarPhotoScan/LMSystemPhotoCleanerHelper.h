//
//  LMSystemPhotoCleanerHelper.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMSimilarPhotoGroup.h"


NS_ASSUME_NONNULL_BEGIN

/**
 处理系统相册中的照片
 */
@interface LMSystemPhotoCleanerHelper : NSObject

@property NSMutableArray<LMSimilarPhotoGroup *> *similarPhotoGroups;//扫描的所有图片
//@property NSMutableArray *systemPhotoArray;//系统相册中的图片

-(void)scanPhotoLibrary;
-(void)addPhotoToAlbumWith:(NSMutableArray*)systemPhotoArray;
+(NSString *)getAppScriptForCreateAlbum1014;
+(NSString *)getAppScriptForCreateAlbum1015;
@end

NS_ASSUME_NONNULL_END
