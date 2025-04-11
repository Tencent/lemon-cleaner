//
//  LMBubbleView.m
//  LemonAIAssistant
//
//

#import "LMBubbleView.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <Masonry/Masonry.h>

#define LM_BUBBLE_HEIGHT 42.f

@interface LMBubbleView ()

@property (nonatomic, strong) QMBubbleView *bubbleBGView;
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSButton *button;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *buttonText;
@property (nonatomic, copy) dispatch_block_t buttonClickCallback;

@end

@implementation LMBubbleView

@synthesize arrowOffset = _arrowOffset;
@synthesize arrowDirection = _arrowDirection;
@synthesize isDarkModeSupported = _isDarkModeSupported;
@synthesize style = _style;

+ (instancetype)bubbleWithStyle:(LMBubbleStyle)style arrowDirection:(LMBubbleArrowDirection)direction {
    LMBubbleView *bubble = [[LMBubbleView alloc] init];
    bubble.style = style;
    bubble.arrowDirection = direction;
    return bubble;
}

- (instancetype)init {
    if (self = [super init]) {
        self.isDarkModeSupported = YES;
        self.autoHide = YES;

        [self _setupSubviews];
        [self _updateSubviewsColor];
    }
    return self;
}

- (void)_setupSubviews {
    [self addSubview:self.bubbleBGView];
    [self.bubbleBGView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
}

#pragma mark - Setter

- (void)setStyle:(LMBubbleStyle)style {
    _style = style;
    
    [_titleLabel removeFromSuperview];
    [_button removeFromSuperview];
    
    switch (style) {
        case LMBubbleStyleCustom: {
            // 纯气泡，无内容，外部自定义
            break;
        }
        case LMBubbleStyleText: {
            [self addSubview:self.titleLabel];
            [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(self);
            }];
            break;
        }
        case LMBubbleStyleTextButton: {
            [self addSubview:self.titleLabel];
            [self addSubview:self.button];
            [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.mas_equalTo(10);
            }];
            [self.button mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.titleLabel.mas_right);
                make.centerY.equalTo(self.titleLabel);
            }];
            break;
        }
    }
}

- (void)setArrowDirection:(LMBubbleArrowDirection)arrowDirection {
    _arrowDirection = arrowDirection;
    switch (arrowDirection) {
        case LMBubbleArrowDirectionTopLeft:
            self.bubbleBGView.direction = QMArrowTopLeft;
            break;
        case LMBubbleArrowDirectionTopRight:
            self.bubbleBGView.direction = QMArrowTopRight;
            break;
        case LMBubbleArrowDirectionBottomLeft:
            self.bubbleBGView.direction = QMArrowBottomLeft;
            break;
        case LMBubbleArrowDirectionBottomRight:
            self.bubbleBGView.direction = QMArrowBottomRight;
            break;
    }
}

- (void)setArrowOffset:(CGFloat)arrowOffset {
    _arrowOffset = arrowOffset;
    self.bubbleBGView.arrowDistance = arrowOffset;
}

#pragma mark - Public

- (void)setBubbleTitle:(NSString *)title {
    _title = title;
    self.titleLabel.stringValue = title ?: @"";
}

- (void)setBubbleButtonText:(NSString *)text clickCallback:(dispatch_block_t)buttonClickCallback {
    _buttonText = text;
    _buttonClickCallback = buttonClickCallback;
    
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:text attributes:[self _buttonAttributed]];
    self.button.attributedTitle = string;
}

- (void)showInView:(NSView *)inView pointAtView:(NSView *)pointAtView {
    [self showInView:inView pointAtView:pointAtView horizontalOffset:0];
}

- (void)showInView:(NSView *)inView pointAtView:(NSView *)pointAtView horizontalOffset:(CGFloat)horizontalOffset {
    if (![pointAtView isDescendantOf:inView]) {
        // pointAtView 必须是 inView 的子类，否则请使用 showInView:atPosition:
        return;
    }
    if (self.superview == inView) {
        // 已经添加在 inView 上了
        return;
    }
    
    [self removeFromSuperview];
    [inView addSubview:self];
        
    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo([self _calculateViewWidth]);
        make.height.equalTo(pointAtView).offset(LM_BUBBLE_HEIGHT);
        if ([self _isArrowVerticalDirectionTop]) { // 箭头指上
            make.top.equalTo(pointAtView).offset(2);
        } else { // 箭头指下
            make.bottom.equalTo(pointAtView).offset(-2);
        }
        if ([self _isArrowHorizontalAlignmentLeft]) { // 箭头左对齐
            make.left.equalTo(pointAtView.mas_centerX).offset(-self.arrowOffset + horizontalOffset);
        } else { // 箭头右对齐
            make.right.equalTo(pointAtView.mas_centerX).offset(self.arrowOffset + horizontalOffset);
        }
    }];
    
    [self _updateLayout];
}

- (void)showInView:(NSView *)inView atPosition:(CGPoint)position {
    if (self.superview == inView) {
        // 已经添加在 inView 上了
        return;
    }
    
    [self removeFromSuperview];
    [inView addSubview:self];
        
    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo([self _calculateViewWidth]);
        make.height.mas_equalTo(LM_BUBBLE_HEIGHT);
        make.left.mas_equalTo(position.x);
        make.top.mas_equalTo(position.y);
    }];
    
    [self _updateLayout];
}

- (CGSize)calculateViewSize {
    return CGSizeMake([self _calculateViewWidth], LM_BUBBLE_HEIGHT);
}

#pragma mark - Mouse Events

- (void)layout {
    [super layout];
    [self updateTrackingAreas];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];

    for (NSTrackingArea *area in self.trackingAreas) {
        [self removeTrackingArea:area];
    }
    NSTrackingAreaOptions options = NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingActiveInKeyWindow;
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                                options:options
                                                                  owner:self
                                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
    
}

- (void)mouseEntered:(NSEvent *)event {
    [super mouseEntered:event];
}

- (void)mouseExited:(NSEvent *)event {
    [super mouseExited:event];
    if (self.autoHide) {
        [self removeFromSuperview];
    }
}

#pragma mark - Getter

- (QMBubbleView *)bubbleBGView {
    if (!_bubbleBGView) {
        _bubbleBGView = [[QMBubbleView alloc] init];
        _bubbleBGView.drawArrow = YES;
        _bubbleBGView.arrowHeight = 6;
        _bubbleBGView.arrowWidth = 12;
        _bubbleBGView.cornerRadius = 4;
        _bubbleBGView.borderWidth = 1;
    }
    return _bubbleBGView;
}

- (NSTextField *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
        _titleLabel.editable = NO;
        _titleLabel.bordered = NO;
        _titleLabel.backgroundColor = [NSColor clearColor];
        _titleLabel.font = [NSFont systemFontOfSize:12];
        _titleLabel.textColor = [LMAppThemeHelper getColor:LMColor_SubText_Dark];
    }
    return _titleLabel;
}

- (NSButton *)button {
    if (!_button) {
        _button = [[NSButton alloc] initWithFrame:NSZeroRect];
        [_button setButtonType:NSButtonTypeMomentaryPushIn];
        [_button setBezelStyle:NSBezelStyleRounded];
        [_button setTarget:self];
        [_button setAction:@selector(buttonClicked:)];
        _button.enabled = YES;
        _button.bordered = NO;
        _button.wantsLayer = YES;
        _button.layer.backgroundColor = NSColor.clearColor.CGColor;
    }
    return _button;
}

#pragma mark - Action

- (void)buttonClicked:(id)sender {
    !self.buttonClickCallback ?: self.buttonClickCallback();
}

#pragma mark - Dark Mode

- (void)setIsDarkModeSupported:(BOOL)isDarkModeSupported {
    _isDarkModeSupported = isDarkModeSupported;
    [self _updateSubviewsColor];
}

- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
    [self _updateSubviewsColor];
}

- (void)_updateSubviewsColor {
    self.bubbleBGView.backgroudColor = self.isDarkModeSupported && [LMAppThemeHelper isDarkMode] ? [LMAppThemeHelper getColor:LMColor_DefaultBackground] : [LMAppThemeHelper getColor:LMColor_White];
    self.bubbleBGView.borderColor = [LMAppThemeHelper getColor:LMColor_Border2 lightModeOnly:!self.isDarkModeSupported];
    self.titleLabel.textColor = [LMAppThemeHelper getColor:LMColor_SubText_Dark lightModeOnly:!self.isDarkModeSupported];
}

#pragma mark - Private

- (NSDictionary<NSAttributedStringKey, id> *)_buttonAttributed {
    return @{
        NSFontAttributeName: [NSFont systemFontOfSize:12],
        NSForegroundColorAttributeName:[LMAppThemeHelper getColor:LMColor_Blue_Normal]
    };
}

// 箭头垂直方向是否朝上
- (BOOL)_isArrowVerticalDirectionTop {
    return self.arrowDirection == LMBubbleArrowDirectionTopLeft || self.arrowDirection == LMBubbleArrowDirectionTopRight;
}

// 箭头水平方向是否左对齐
- (BOOL)_isArrowHorizontalAlignmentLeft {
    return self.arrowDirection == LMBubbleArrowDirectionTopLeft || self.arrowDirection == LMBubbleArrowDirectionBottomLeft;
}

- (CGFloat)_calculateViewWidth {
    CGSize labelSize = [self.title sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:self.titleLabel.font, NSFontAttributeName, nil]];
    CGSize buttonSize = [self.buttonText sizeWithAttributes:[self _buttonAttributed]];
    CGFloat margin = self.style == LMBubbleStyleTextButton ? 28 : 20;
    return labelSize.width + buttonSize.width + margin;
}

- (void)_updateLayout {
    // 气泡框
    [self.bubbleBGView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.height.mas_equalTo(LM_BUBBLE_HEIGHT);
        if ([self _isArrowVerticalDirectionTop]) { // 箭头指上
            make.bottom.equalTo(self);
        } else { // 箭头指下
            make.top.equalTo(self);
        }
    }];
    
    CGFloat arrowHeight = self.bubbleBGView.arrowHeight;
    [self.titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bubbleBGView).offset([self _isArrowVerticalDirectionTop] ? (arrowHeight / 2) : (-arrowHeight / 2));
    }];
}

@end
