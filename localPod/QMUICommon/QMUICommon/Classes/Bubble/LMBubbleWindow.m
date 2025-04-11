//
//  LMBubbleWindow.m
//  LemonGetText
//
//

#import "LMBubbleWindow.h"
#import <Masonry/Masonry.h>

@interface LMBubbleWindow ()

@property (nonatomic, strong) LMBubbleView *bubbleView;

@end

@implementation LMBubbleWindow

@synthesize arrowOffset = _arrowOffset;
@synthesize arrowDirection = _arrowDirection;
@synthesize isDarkModeSupported = _isDarkModeSupported;
@synthesize style = _style;

- (BOOL)isMovable {
    return NO;
}

- (instancetype)init {
    if (self = [super init]) {
        [self _setupWindow];
    }
    return self;
}

- (void)_setupWindow {
    self.window = [[NSWindow alloc] initWithContentRect:CGRectZero styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel backing:NSBackingStoreBuffered defer:NO];
    [self.window setLevel:kCGMainMenuWindowLevel];
    self.window.backgroundColor = [NSColor clearColor];
}

#pragma mark - Bubble

+ (instancetype)bubbleWithStyle:(LMBubbleStyle)style arrowDirection:(LMBubbleArrowDirection)direction {
    LMBubbleWindow *window = [[LMBubbleWindow alloc] init];
    window.style = style;
    window.arrowDirection = direction;
    return window;
}

- (void)setStyle:(LMBubbleStyle)style {
    _style = style;
    self.bubbleView.style = style;
}

- (void)setArrowDirection:(LMBubbleArrowDirection)arrowDirection {
    _arrowDirection = arrowDirection;
    self.bubbleView.arrowDirection = arrowDirection;
}

- (void)setArrowOffset:(CGFloat)arrowOffset {
    _arrowOffset = arrowOffset;
    self.bubbleView.arrowOffset = arrowOffset;
}

- (void)setIsDarkModeSupported:(BOOL)isDarkModeSupported {
    _isDarkModeSupported = isDarkModeSupported;
    self.bubbleView.isDarkModeSupported = isDarkModeSupported;
}

- (void)setBubbleTitle:(NSString *)title {
    [self.bubbleView setBubbleTitle:title];
}

- (void)setBubbleButtonText:(NSString *)text clickCallback:(dispatch_block_t)buttonClickCallback {
    [self.bubbleView setBubbleButtonText:text clickCallback:buttonClickCallback];
}

#pragma mark - Getter

- (LMBubbleView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [LMBubbleView bubbleWithStyle:LMBubbleStyleCustom arrowDirection:LMBubbleArrowDirectionTopLeft];
        _bubbleView.autoHide = NO;
    }
    return _bubbleView;
}

#pragma mark - Public

- (void)showAndPointAtView:(NSView *)pointAtView {
    [self showAndPointAtView:pointAtView verticalOffset:0];
}

- (void)showAndPointAtView:(NSView *)pointAtView verticalOffset:(CGFloat)verticalOffset {
    // 获取pointAtView在其Window中的坐标
    NSRect pointAtViewFrameInWindow = [pointAtView convertRect:pointAtView.bounds toView:nil];
    // 将pointAtView的坐标转换为屏幕坐标
    NSRect pointAtViewFrameInScreen = [pointAtView.window convertRectToScreen:pointAtViewFrameInWindow];
    // 计算pointAtView的顶部中间点
    NSPoint pointAtViewTopCenter = NSMakePoint(NSMidX(pointAtViewFrameInScreen), NSMaxY(pointAtViewFrameInScreen));
    // 计算self.window的位置，使其底部中间点对齐viewB的顶部中间点
    CGSize size = [self.bubbleView calculateViewSize];
    NSPoint origin = NSMakePoint(pointAtViewTopCenter.x - size.width / 2, pointAtViewTopCenter.y + verticalOffset); // y + 外部传入的垂直方向偏移
    [self showAtPosition:origin];
}

- (void)showAtPosition:(CGPoint)position {
    CGSize size = [self.bubbleView calculateViewSize];
    CGRect rect = CGRectMake(position.x, position.y, size.width, size.height);
    [self.window setFrame:rect display:NO];
    [self.window orderFront:nil];
    [self.bubbleView showInView:self.window.contentView atPosition:CGPointZero];
}

- (void)hide {
    [self.window orderOut:nil];
}

@end
