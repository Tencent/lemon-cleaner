//
//  LMFileMoveProcessCell.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveProcessCell.h"
#import "LMFileMoveCommonDefines.h"
#import "LMFileMoveManger.h"
#import "LMFileMoveCommonDefines.h"

#define LMFileMoveProcessCellInset 8

@implementation LMFileMoveProcessRowView

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    [lm_backgroundColor() setFill];
    NSRectFill(dirtyRect);
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    [lm_backgroundColor() setFill];
    NSRectFill(dirtyRect);
}

@end

@interface LMFileMoveProcessCell ()

@property (nonatomic, strong) NSView *bgView;

@property (nonatomic, strong) NSImageView *appImageView;
@property (nonatomic, strong) NSTextField *appNameLabel;
@property (nonatomic, strong) NSTextField *totalSizeLabel;

@property (nonatomic, strong) NSImageView *fileImageView;
@property (nonatomic, strong) NSTextField *fileNameLabel;
@property (nonatomic, strong) NSTextField *fileSizeLabel;

@property (nonatomic, strong) NSTextField *statusLabel;

@end

@implementation LMFileMoveProcessCell

+ (NSString *)cellID {
    return NSStringFromClass(self);
}

+ (CGFloat)cellHeight {
    return 72 + LMFileMoveProcessCellInset * 2;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self _setupViews];
    }
    return self;
}

- (void)_setupViews {
    self.bgView = [[NSView alloc] init];
    self.bgView.wantsLayer = YES;
    self.bgView.layer.backgroundColor = [self _cellBGColor].CGColor;
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithHex:0x000000 alpha:0.05]];
    [shadow setShadowOffset:NSMakeSize(0,1)];
    shadow.shadowBlurRadius = 24;
    [self.bgView setShadow:shadow];
    
    [self addSubview:self.bgView];
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(50);
        make.right.equalTo(self).offset(-50);
        make.top.equalTo(self).offset(LMFileMoveProcessCellInset);
        make.bottom.equalTo(self).offset(-LMFileMoveProcessCellInset);
    }];

    // 左
    self.appImageView = [[NSImageView alloc] init];
    [self addSubview:self.appImageView];
    self.appImageView.image = [NSImage imageNamed:@"wecom_big_icon" withClass:[self class]];
    [self.appImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(16+50);
        make.centerY.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(48, 48));
    }];

    self.appNameLabel = [NSTextField labelWithStringCompat:@"企业微信"];
    self.appNameLabel.font = [NSFont fontWithName:@"PingFangSC-Semibold" size:16];
    self.appNameLabel.textColor = [self _appNameLabelColor];
    [LMAppThemeHelper setTitleColorForTextField:self.appNameLabel];
    [[self.appNameLabel cell] setUsesSingleLineMode:YES];
    [[self.appNameLabel cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    [self addSubview:self.appNameLabel];
    [self.appNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(17 + LMFileMoveProcessCellInset);
        make.left.equalTo(self.appImageView.mas_right).offset(8);
    }];

    self.totalSizeLabel = [NSTextField labelWithStringCompat:@""];
    self.totalSizeLabel.font = [NSFont systemFontOfSize:14];
    [self addSubview:self.totalSizeLabel];
    [self.totalSizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self).offset(-(17 + LMFileMoveProcessCellInset));
        make.left.equalTo(self.appNameLabel);
    }];
    
    // 右
    self.fileNameLabel = [NSTextField labelWithStringCompat:@"企业微信"];
    self.fileNameLabel.font = [NSFont systemFontOfSize:12];
    [[self.fileNameLabel cell] setUsesSingleLineMode:YES];
    [[self.fileNameLabel cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
    self.fileNameLabel.alignment = NSTextAlignmentRight;
    [self addSubview:self.fileNameLabel];

    self.fileImageView = [[NSImageView alloc] init];
    [self addSubview:self.fileImageView];
    
    self.fileSizeLabel = [NSTextField labelWithStringCompat:@"10MB"];
    self.fileSizeLabel.font = [NSFont systemFontOfSize:12];
    self.fileSizeLabel.textColor = LM_COLOR_GRAY;
    [self addSubview:self.fileSizeLabel];
    
    [self.fileNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(20 + LMFileMoveProcessCellInset);
        make.right.equalTo(self).offset(-(16+50));
        make.width.lessThanOrEqualTo(@260);
        make.width.greaterThanOrEqualTo(@56);
    }];

    [self.fileImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.fileNameLabel.mas_left).offset(-8);
        make.centerY.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(32, 32));
    }];

    [self.fileSizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self).offset(-(20 + LMFileMoveProcessCellInset));
        make.right.equalTo(self.fileNameLabel);
    }];
    
    // 导出状态
    self.statusLabel = [NSTextField labelWithStringCompat:@""];
    self.statusLabel.font = [NSFont systemFontOfSize:12];
    [LMAppThemeHelper setTitleColorForTextField:self.statusLabel];
    [self addSubview:self.statusLabel];
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.right.equalTo(self.fileSizeLabel);
    }];
    [self _updateWithStatus:LMFileMoveProcessCellStatusPending];
}

- (void)updateLayer {
    self.bgView.layer.backgroundColor = [self _cellBGColor].CGColor;
    self.appNameLabel.textColor = [self _appNameLabelColor];
}

- (NSColor *)_cellBGColor {
    if ([LMAppThemeHelper isDarkMode]) {
        return [NSColor colorWithHex:0x2D2D40];
    } else {
        return [NSColor whiteColor];
    }
}

- (NSColor *)_appNameLabelColor {
    if ([LMAppThemeHelper isDarkMode]) {
        return [NSColor whiteColor];
    } else {
        return [NSColor colorWithHex:0x28283C];
    }
}

#pragma mark - Setter

- (void)setViewItem:(LMFileMoveProcessCellViewItem *)viewItem {
    if (_viewItem == viewItem) {
        return;
    }
    if (_viewItem) {
        [self _unobserveForViewItem:_viewItem];
    }
    if (viewItem) {
        _viewItem = viewItem;
        [self _observeViewItem:_viewItem];
    }
    
    [self refreshAllValues];
}

#pragma mark - KVO

- (void)_observeViewItem:(LMFileMoveProcessCellViewItem *)viewItem
{
    for (NSString *keyPath in [self observingKeyPathsForViewItem]) {
        [viewItem addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)_unobserveForViewItem:(LMFileMoveProcessCellViewItem *)viewItem
{
    for (NSString *keyPath in [self observingKeyPathsForViewItem]) {
        [viewItem removeObserver:self forKeyPath:keyPath context:NULL];
    }
}

- (void)_observeValueForKeyPath:(NSString *)keyPath
{
    dispatch_block_t refreshValue = ^{
        [self refreshValueForKeyPath:keyPath];
    };
    [NSThread isMainThread] ? refreshValue() : dispatch_async(dispatch_get_main_queue(), refreshValue);
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context
{
    if (object == self.viewItem) {
        [self _observeValueForKeyPath:keyPath];
    }
}

- (nullable NSArray<NSString *> *)observingKeyPathsForViewItem
{
    static NSArray<NSString *> *observingKeyPaths = nil;
    if (observingKeyPaths == nil) {
        observingKeyPaths = @[ @"title", @"attributedDetail", @"imageName", @"status", @"movingFileImage", @"movingFileName", @"movingFileSizeText"];
    }
    return observingKeyPaths;
}

- (void)updateValueForKeyPath:(NSString *)keyPath
{
#define is(_keyPath) \
    [keyPath isEqualToString:_keyPath]
    
    if (is(@"title")) {
        self.appNameLabel.stringValue = self.viewItem.title ?: @"";
    } else if (is(@"attributedDetail")) {
        self.totalSizeLabel.attributedStringValue = self.viewItem.attributedDetail ?: [[NSAttributedString alloc] init];
    } else if (is(@"imageName")) {
        self.appImageView.image = LM_IMAGE_NAMED(self.viewItem.imageName);
    } else if (is(@"status")) {
        [self _updateWithStatus:self.viewItem.status];
    } else if (is(@"movingFileImage")) {
        self.fileImageView.image = self.viewItem.movingFileImage;
    } else if (is(@"movingFileName")) {
        self.fileNameLabel.stringValue = self.viewItem.movingFileName ?: @"";
    } else if (is(@"movingFileSizeText")) {
        self.fileSizeLabel.stringValue = self.viewItem.movingFileSizeText ?: @"";
    }
#undef is
}

- (void)updateAllValues
{
    for (NSString *keyPath in [self observingKeyPathsForViewItem]) {
        [self updateValueForKeyPath:keyPath];
    }
}

- (void)refreshValueForKeyPath:(NSString *)keyPath
{
    [self updateValueForKeyPath:keyPath];
    [self setNeedsLayout:YES];
}

- (void)refreshAllValues
{
    [self updateAllValues];
    [self setNeedsLayout:YES];
}

#pragma mark - Private

- (void)_updateWithStatus:(LMFileMoveProcessCellStatus)status {
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    switch (self.viewItem.status) {
        case LMFileMoveProcessCellStatusPending:
            LM_APPEND_ICON_AND_STRING(text, LM_IMAGE_NAMED(@"file_move_pending_icon"), CGSizeMake(16, 16), LM_LOCALIZED_STRING(@" Pending"), [NSFont systemFontOfSize:12], LM_COLOR_GRAY);
            [self _hideStatus:NO];
            break;
        case LMFileMoveProcessCellStatusMoving:
            [self _hideStatus:YES];
            break;
        case LMFileMoveProcessCellStatusDone:
            LM_APPEND_ICON_AND_STRING(text, LM_IMAGE_NAMED(@"file_move_done_icon"), CGSizeMake(16, 16), LM_LOCALIZED_STRING(@" Done"), [NSFont systemFontOfSize:12], LM_COLOR_GRAY);
            [self _hideStatus:NO];
            break;
        case LMFileMoveProcessCellStatusError: {
            NSString *errorString = [NSString stringWithFormat:LM_LOCALIZED_STRING(@" %@ were not transferred"), [[LMFileMoveManger shareInstance] sizeNumChangeToStr:self.viewItem.moveFailedFileSize]];
            LM_APPEND_ICON_AND_STRING(text, LM_IMAGE_NAMED(@"file_move_error_icon"), CGSizeMake(16, 16), errorString, [NSFont systemFontOfSize:12], LM_COLOR_GRAY);
            [self _hideStatus:NO];
        }
            break;
    }
    self.statusLabel.attributedStringValue = text;
}

- (void)_hideStatus:(BOOL)toHide {
    self.statusLabel.hidden = toHide;
    self.fileImageView.hidden = !toHide;
    self.fileNameLabel.hidden = !toHide;
    self.fileSizeLabel.hidden = !toHide;
}

@end
