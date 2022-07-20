//
//  FileMangerHelper.h
//  QQMacMgr
//
//  
//  Copyright © 2018 Hank. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileMangerHelper : NSObject

+(NSData *)returnDataWithDictionary:(NSMutableData*)mutableData;
+(NSMutableData *)returnDictionaryWithDataPath:(NSString *)path;
/**
 判断路径中是否包含系统图库

 @param rootPath 选择的路径
 @return YES：是
 */
+(Boolean)isContainPhotoLibraryWithPathArray:(NSArray*)rootPath;
@end
