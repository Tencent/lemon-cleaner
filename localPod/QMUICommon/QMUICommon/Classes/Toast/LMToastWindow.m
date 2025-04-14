//
//  LMToastWindow.m
//  LemonGetText
//
//

#import "LMToastWindow.h"
#import <Masonry/Masonry.h>

@interface LMToastPanel : NSPanel

@end

@implementation LMToastPanel

- (BOOL)canBecomeKeyWindow {
    return NO;
}

- (BOOL)isMovable {
    return NO;
}

@end

@interface LMToastWindow ()

@property (nonatomic, strong) LMToastContentView *contentView;

@end

@implementation LMToastWindow

+ (instancetype)toastViewWithStyle:(LMToastViewStyle)style title:(NSString *)title {
    LMToastWindow *toastView = [[LMToastWindow alloc] init];
    toastView.style = style;
    toastView.title = title;
    return toastView;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 默认3秒后消失
        self.duration = 3;

        [self _setupWindow];
        [self _setupSubviews];
    }
            
    return self;
}

- (void)_setupWindow {
    self.window = [[LMToastPanel alloc] initWithContentRect:CGRectZero styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel backing:NSBackingStoreBuffered defer:NO];
    [self.window setLevel:kCGMainMenuWindowLevel];
    self.window.backgroundColor = [NSColor clearColor];
}

- (void)_setupSubviews {
    [self.window.contentView addSubview:self.contentView];
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
}

- (BOOL)isMovable {
    return NO;
}

#pragma mark - Public

- (void)showAtPoint:(NSPoint)point {
    CGSize labelSize = [self.title sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:self.contentView.textLabel.font, NSFontAttributeName, nil]];
    CGRect rect = CGRectMake(point.x, point.y, labelSize.width + 60, 38);
    [self.window setFrame:rect display:NO];
    [self.window orderFront:nil];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_hideToast) object:nil];
    [self performSelector:@selector(_hideToast) withObject:nil afterDelay:self.duration];
}

- (void)showAtPoint:(NSPoint)point duration:(NSTimeInterval)duration {
    self.duration = duration;
    
    [self showAtPoint:point];
}

#pragma mark - Hide

- (void)_hideToast {
    [self.window orderOut:nil];
}

#pragma mark - Setter

- (void)setStyle:(LMToastViewStyle)style {
    _style = style;
    [self.contentView updateImageViewWithStyle:style];
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.contentView.textLabel.stringValue = title ?: @"";
}

#pragma mark - Getter

- (LMToastContentView *)contentView {
    if (!_contentView) {
        _contentView = [[LMToastContentView alloc] init];
    }
    return _contentView;
}

@end
