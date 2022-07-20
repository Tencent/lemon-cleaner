//
//  QMFileClassification.m
//  QMCoreFunction
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "QMFileClassification.h"

@implementation QMFileClassification

+ (QMFileTypeEnum)fileExtensionType:(NSString *)filePath
{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist= [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
    if(!isExist){
        NSLog(@"QMFileClassification fileExtensionType file exist");
    }
    
    if(isExist && isDir){
        return QMFileTypeFolder;
    }
    
    NSString * fileExtension = [[filePath pathExtension] lowercaseString];
    if ([QMFileClassification assertRegex:@"(flac|mp3|wav|wma|ogg|ape|acc|cda|aiff|aif|aifc|mid|midi|au|snd|mpga)" matchStr:fileExtension])
        return QMFileTypeMusic;
    if ([QMFileClassification assertRegex:@"(gif|jpg|jpeg|bmp|png|tiff|tif)" matchStr:fileExtension])
        return QMFileTypePicture;
    if ([QMFileClassification assertRegex:@"(mkv|swf|flv|mp4|rm|rvm|rmvb|rmhd|avi|mpg|mpeg|ra|ram|mov|wmv)" matchStr:fileExtension])
        return QMFileTypeVideo;
    if ([QMFileClassification assertRegex:@"(key|pages|numbers|pdf|md|doc|docx|xls|xlsx|ppt|pptx|txt|rtf|h|m|c|mm|html|htm|xml|xmind)" matchStr:fileExtension])
        return QMFileTypeDocument;
    if ([QMFileClassification assertRegex:@"(zip|rar|7z|cab|arj|lzh|tar|gz|ace|bz2|jar|iso)" matchStr:fileExtension])
        return QMFileTypeArchive;
    if ([QMFileClassification assertRegex:@"(pkg|dmg)" matchStr:fileExtension])
        return QMFileTypeInstall;
    return QMFileTypeOther;
}

// 正则比较
+ (BOOL)assertRegex:(NSString*)regexString matchStr:(NSString *)str
{
    NSPredicate *regex = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexString];
    return [regex evaluateWithObject:str];
}

@end
