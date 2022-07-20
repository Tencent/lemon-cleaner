//
//  QMFileClassification.h
//  QMCoreFunction
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

// NS_OPTIONS 的用法:  if( (item.type & XXTyped的集合) == item.type) // 证明是 XXType集合中的一种..
typedef NS_OPTIONS(NSInteger, QMFileTypeEnum)
{
    QMFileTypeAll = -1, // -1 利用补码机制,所有bit位上都是 1//对于 all 类型应该是所有类型的超集. 所以每一位都应该有 flag. (item.type & AllType 总是== item.type)
    QMFileTypeOther = 1 << 0,
    QMFileTypeMusic = 1 << 1,
    QMFileTypeVideo = 1 << 2,
    QMFileTypeDocument = 1 << 3,
    QMFileTypePicture = 1 << 4,
    QMFileTypeArchive = 1 << 5,
    QMFileTypeFolder = 1 << 6, //非文件 是文件夹类
    QMFileTypeInstall = 1 << 7,
};

@interface QMFileClassification : NSObject

+ (QMFileTypeEnum)fileExtensionType:(NSString *)filePath;

@end
