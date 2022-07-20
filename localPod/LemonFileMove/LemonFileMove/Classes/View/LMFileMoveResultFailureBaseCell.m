//
//  LMFileMoveResultFailureBaseCell.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveResultFailureBaseCell.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/NSFontHelper.h>
#import "LMFileMoveManger.h"
#import "LMResultItem.h"
#import "LMFileMoveCommonDefines.h"

@interface LMFileMoveResultFailureBaseCell() {
    NSTrackingArea *trackingArea;
}

@end

@implementation LMFileMoveResultFailureBaseCell

+ (NSString *)cellID {
    return NSStringFromClass(self);
}

+ (CGFloat)cellHeight {
    return 32;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self _setupBaseViews];
    }
    return self;
}

- (void)_setupBaseViews {
    self.iconView = [[NSImageView alloc] init];
    [self addSubview:self.iconView];
    [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.left.equalTo(self).offset(25);
        make.size.mas_equalTo(CGSizeMake(18, 18));
    }];

    self.titleLabel = [NSTextField labelWithStringCompat:@""];
    self.titleLabel.maximumNumberOfLines = 1;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.titleLabel.font = [NSFont systemFontOfSize:12];
    [LMAppThemeHelper setTitleColorForTextField:self.titleLabel];
    [self addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.iconView.mas_right).offset(9);
        make.centerY.equalTo(self.iconView);
        make.width.mas_equalTo(124);
    }];

    self.sizeLabel = [NSTextField labelWithStringCompat:@""];
    self.sizeLabel.font = [NSFont systemFontOfSize:12];
    self.sizeLabel.alignment = NSTextAlignmentRight;
    [LMAppThemeHelper setTitleColorForTextField:self.sizeLabel];
    [self addSubview:self.sizeLabel];
}

- (void)setCellData:(LMBaseItem *)item {
    [_iconView setImageScaling:NSImageScaleAxesIndependently];
    
    if ([item title] != nil) {
        [_titleLabel setStringValue:[item title]];
    }
    // 显示大小
    NSString *sizeStr = [[LMFileMoveManger shareInstance] sizeNumChangeToStr:[item moveFailedFileSize]];
    if (![item isKindOfClass:[LMResultItem class]]) {
        sizeStr = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Total %@", nil, [NSBundle bundleForClass:[self class]], @""),sizeStr];
    }
    [_sizeLabel setStringValue:sizeStr];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:trackingArea]) {
        [self addTrackingArea:trackingArea];
    }
}

- (void)ensureTrackingArea {
    if (trackingArea == nil) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    }
}

- (void)mouseEntered:(NSEvent *)event {
    [self updateRowViewSelectState:YES];
}

- (void)mouseExited:(NSEvent *)event {
    [self updateRowViewSelectState:NO];
}

- (void)updateRowViewSelectState:(BOOL)selected {
    NSView *superView = self.superview;
    if (superView != nil && [superView isKindOfClass:NSTableRowView.class]) {
        NSTableRowView *rowView = (NSTableRowView *) superView;
        [rowView setSelected:selected];
        [self setHightLightStyle:selected];
    }
}

- (void)setHightLightStyle:(BOOL)hight {
    if (m_hight == hight) {
        return;
    }
    m_hight = hight;
    [self _refreshDisplayState:m_hight];
}

- (void)_refreshDisplayState:(BOOL)hight {
    
}

@end
