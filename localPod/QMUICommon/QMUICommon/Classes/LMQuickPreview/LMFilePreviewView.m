//
//  LMFilePreviewView.m
//  LemonBigOldFile
//
//  Created by tencent on 2025/9/25.
//

#import "LMFilePreviewView.h"
#import <Quartz/Quartz.h>

// 导入 QuickLookThumbnailing 框架
#if __has_include(<QuickLookThumbnailing/QuickLookThumbnailing.h>)
#import <QuickLookThumbnailing/QuickLookThumbnailing.h>
#define HAS_QLTHUMBNAIL_GENERATOR 1
#else
#define HAS_QLTHUMBNAIL_GENERATOR 0
#endif

@interface LMFilePreviewView () <QLPreviewItem>

// QLPreviewView 方案（10.15以下）
@property (nonatomic, strong) QLPreviewView *previewView;

// QLThumbnailGenerator 方案（10.15+）
@property (nonatomic, strong) NSImageView *thumbnailImageView;
@property (nonatomic, strong) NSCache *previewCache;
@property (nonatomic, strong) NSOperationQueue *thumbnailQueue;

// 当前预览的文件路径
@property (nonatomic, copy) NSString *currentFilePath;

@end

@implementation LMFilePreviewView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupPreviewComponents];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupPreviewComponents];
    }
    return self;
}

- (void)setupPreviewComponents {
    if ([self shouldUseModernThumbnailAPI]) {
        // 使用现代缩略图方案
        [self setupThumbnailComponents];
    } else {
        // 使用传统 QLPreviewView
        [self setupQLPreviewComponents];
    }
}

- (void)setupThumbnailComponents {
    // 初始化缩略图组件
    _thumbnailImageView = [[NSImageView alloc] initWithFrame:self.bounds];
    _thumbnailImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    _thumbnailImageView.imageAlignment = NSImageAlignCenter;
    _thumbnailImageView.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
    
    // 初始化缓存
    _previewCache = [[NSCache alloc] init];
    _previewCache.countLimit = 50;
    
    // 初始化队列
    _thumbnailQueue = [[NSOperationQueue alloc] init];
    _thumbnailQueue.maxConcurrentOperationCount = 2;
    _thumbnailQueue.name = @"LMFilePreviewThumbnailQueue";
    
    [self addSubview:_thumbnailImageView];
}

- (void)setupQLPreviewComponents {
    // 初始化 QLPreviewView
    _previewView = [[QLPreviewView alloc] initWithFrame:self.bounds style:QLPreviewViewStyleCompact];
    _previewView.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
    [self addSubview:_previewView];
}

#pragma mark - Public Methods

- (BOOL)shouldUseModernThumbnailAPI {
    // MacOS 26以上使用自定义预览图。QLPreviewView支持视频播放，自定义的预览图暂不支持。
    if (@available(macOS 26.0, *)) {
        return YES;
    }
    return NO;
}

- (void)showPreviewForFilePath:(NSString *)filePath {
    if (!filePath || filePath.length == 0) {
        [self clearPreview];
        return;
    }
    
    // 检查文件是否存在
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSLog(@"LMFilePreviewView: 文件不存在 - %@", filePath);
        [self clearPreview];
        return;
    }
    
    _currentFilePath = [filePath copy];
    
    if ([self shouldUseModernThumbnailAPI]) {
        [self generateThumbnailForFilePath:filePath];
    } else {
        [self showQLPreviewForFilePath:filePath];
    }
}

- (void)clearPreview {
    _currentFilePath = nil;
    
    if ([self shouldUseModernThumbnailAPI]) {
        if (_thumbnailImageView) {
            _thumbnailImageView.image = nil;
        }
        if (_thumbnailQueue) {
            [_thumbnailQueue cancelAllOperations];
        }
    } else {
        if (_previewView) {
            [_previewView setPreviewItem:nil];
        }
    }
}

- (void)cancelAllOperations {
    if ([self shouldUseModernThumbnailAPI]) {
        if (_thumbnailQueue) {
            [_thumbnailQueue cancelAllOperations];
        }
    }
}

#pragma mark - QLPreviewView Methods (10.15以下)

- (void)showQLPreviewForFilePath:(NSString *)filePath {
    [_previewView setPreviewItem:self];
    [_previewView refreshPreviewItem];
}

#pragma mark - QLPreviewItem Protocol

- (NSURL *)previewItemURL {
    if (!_currentFilePath) {
        return nil;
    }
    return [NSURL fileURLWithPath:_currentFilePath];
}

- (NSString *)previewItemTitle {
    if (!_currentFilePath) {
        return nil;
    }
    return [[NSFileManager defaultManager] displayNameAtPath:_currentFilePath];
}

#pragma mark - Thumbnail Methods (10.15+)

- (void)generateThumbnailForFilePath:(NSString *)filePath {
    if (!filePath) return;
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    // 检查缓存
    NSString *cacheKey = filePath;
    NSImage *cachedImage = [_previewCache objectForKey:cacheKey];
    if (cachedImage) {
        [self displayThumbnail:cachedImage];
        return;
    }
    
    // 显示加载状态
    [self displayLoadingState];
    
    // 异步生成缩略图
    __weak typeof(self) weakSelf = self;
    [_thumbnailQueue addOperationWithBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || ![strongSelf.currentFilePath isEqualToString:filePath]) {
            return; // 已经切换到其他文件或视图已销毁
        }
        
#if HAS_QLTHUMBNAIL_GENERATOR
        if (@available(macOS 10.15, *)) {
            CGSize size = CGSizeMake(300, 300);
            QLThumbnailGenerationRequest *request = [[QLThumbnailGenerationRequest alloc]
                initWithFileAtURL:fileURL
                size:size
                scale:1.0
                representationTypes:QLThumbnailGenerationRequestRepresentationTypeAll];
            
            [[QLThumbnailGenerator sharedGenerator] generateBestRepresentationForRequest:request
                completionHandler:^(QLThumbnailRepresentation * _Nullable thumbnail, NSError * _Nullable error) {
                
                if (thumbnail && !error) {
                    NSImage *image = thumbnail.NSImage;
                    if (image) {
                        [strongSelf.previewCache setObject:image forKey:cacheKey];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // 再次检查是否还是当前文件
                            if ([strongSelf.currentFilePath isEqualToString:filePath]) {
                                [strongSelf displayThumbnail:image];
                            }
                        });
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([strongSelf.currentFilePath isEqualToString:filePath]) {
                                [strongSelf displayFallbackIcon:fileURL];
                            }
                        });
                    }
                } else {
                    NSLog(@"LMFilePreviewView: 缩略图生成失败 - %@", error.localizedDescription);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([strongSelf.currentFilePath isEqualToString:filePath]) {
                            [strongSelf displayFallbackIcon:fileURL];
                        }
                    });
                }
            }];
        }
#endif
    }];
}

- (void)displayThumbnail:(NSImage *)image {
    if (!image) return;
    _thumbnailImageView.image = image;
}

- (void)displayLoadingState {
    // 显示加载图标
    NSImage *loadingImage = [NSImage imageNamed:NSImageNameRefreshTemplate];
    _thumbnailImageView.image = loadingImage;
}

- (void)displayFallbackIcon:(NSURL *)fileURL {
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:fileURL.path];
    if (icon) {
        [self displayThumbnail:icon];
    }
}

#pragma mark - Layout

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    [super resizeSubviewsWithOldSize:oldSize];
    
    // 确保子视图正确调整大小
    if ([self shouldUseModernThumbnailAPI]) {
        if (_thumbnailImageView) {
            _thumbnailImageView.frame = self.bounds;
        }
    } else {
        if (_previewView) {
            _previewView.frame = self.bounds;
        }
    }
}

#pragma mark - Private Methods

- (void)teardownPreviewComponents {
    // 清理现有组件
    if (_thumbnailImageView) {
        [_thumbnailImageView removeFromSuperview];
        _thumbnailImageView = nil;
    }
    
    if (_previewView) {
        [_previewView removeFromSuperview];
        _previewView = nil;
    }
    
    if (_thumbnailQueue) {
        [_thumbnailQueue cancelAllOperations];
        _thumbnailQueue = nil;
    }
    
    if (_previewCache) {
        [_previewCache removeAllObjects];
        _previewCache = nil;
    }
}

#pragma mark - Cleanup

- (void)dealloc {
    [self teardownPreviewComponents];
}

@end
