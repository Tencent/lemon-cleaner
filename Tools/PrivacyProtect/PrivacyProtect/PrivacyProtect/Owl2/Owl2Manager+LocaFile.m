//
//  Owl2Manager+LocaFile.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2Manager+LocaFile.h"
#import <QMCoreFunction/QMCryptUtility.h>

@implementation Owl2Manager (LocaFile)

- (NSString *)iconLocalPathWithAppPath:(NSString *)appPath {
    NSLog(@"Icon(%@) will save", appPath);
    if (!appPath) {
        return nil;
    }
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
    icon = [self generateThumbnailFromImage:icon targetSize:NSMakeSize(32, 32)];
    if (!icon) {
        return nil;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *home = NSHomeDirectory();
    NSString *supportPath = [home stringByAppendingPathComponent:@"Library/Application Support/com.tencent.lemon/Owl/Image"];
    
    // 创建目录（如果不存在）
    if (![fm fileExistsAtPath:supportPath]) {
        [fm createDirectoryAtPath:supportPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
      
      // 设置要保存的文件名
    NSString *iconName =  [QMCryptUtility hashString:appPath with:QMHashKindMd5];
    NSString *filePath = [supportPath stringByAppendingPathComponent:iconName];
      
    // 将 NSImage 转换为 NSData
    NSData *data = [icon TIFFRepresentation];
    if (!data) {
        return nil;
    }
    // 保存 NSData 到文件
    if ([data writeToFile:filePath atomically:YES]) {
        NSLog(@"Icon saved success to: %@", filePath);
        return filePath;
    }
    NSLog(@"Icon saved fail to: %@", filePath);
    return nil;
}

// 生成缩略图的核心方法
- (NSImage *)generateThumbnailFromImage:(NSImage *)originalImage targetSize:(NSSize)targetSize {
    // 1. 计算缩放比例（保持宽高比）
    NSSize originalSize = originalImage.size;
    CGFloat widthRatio = targetSize.width / originalSize.width;
    CGFloat heightRatio = targetSize.height / originalSize.height;
    CGFloat scaleFactor = MIN(widthRatio, heightRatio); // 选择较小的比例
    
    // 2. 计算缩放后的实际尺寸
    NSSize scaledSize = NSMakeSize(
        originalSize.width * scaleFactor,
        originalSize.height * scaleFactor
    );
    
    // 3. 创建目标图像画布
    NSImage *thumbnail = [[NSImage alloc] initWithSize:targetSize];
    [thumbnail lockFocus]; // 开启绘图上下文
    
    // 4. 设置高质量绘制参数
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    
    // 5. 绘制原始图像到缩略图画布（居中显示）
    NSRect drawRect = NSMakeRect(
        (targetSize.width - scaledSize.width) / 2.0,  // 水平居中
        (targetSize.height - scaledSize.height) / 2.0, // 垂直居中
        scaledSize.width,
        scaledSize.height
    );
    [originalImage drawInRect:drawRect];
    
    [thumbnail unlockFocus]; // 结束绘图上下文
    
    return thumbnail;
}

@end
