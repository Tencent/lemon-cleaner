//
//  LMFilePreviewView.h
//  LemonBigOldFile
//
//  Created by tencent on 2025/9/25.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMFilePreviewView : NSView

/**
 * 显示文件预览
 * @param filePath 文件路径
 */
- (void)showPreviewForFilePath:(NSString *)filePath;

/**
 * 清除预览内容
 */
- (void)clearPreview;

/**
 * 取消所有正在进行的预览操作
 */
- (void)cancelAllOperations;

/**
 * 判断是否使用现代缩略图API
 * 可以在此方法内修改判断逻辑，方便测试
 * @return YES 使用现代缩略图API，NO 使用传统QLPreviewView
 */
- (BOOL)shouldUseModernThumbnailAPI;

@end

NS_ASSUME_NONNULL_END
