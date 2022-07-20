//

//  OutlineItemRootCellView.m
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/21.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "DuplicateRootCellView.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMViewHelper.h>
#import "SizeHelper.h"
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMCheckboxButton.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSImage+Extension.h>

@interface DuplicateRootCellView () {
    NSBundle *bundle;
    NSTrackingArea *trackingArea;
    NSImageView *_iconImageView;
    LMCheckboxButton *_checkBox;
    BOOL _isPreview;
}
@end

@implementation DuplicateRootCellView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        bundle = [NSBundle bundleForClass:self.class];
        [self initView];
    }

    return self;
}

- (void)initView {
    _iconImageView = [[NSImageView alloc] init];
    _iconImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    [self addSubview:_iconImageView];


    _fileNameLabel = [LMViewHelper createNormalLabel:14 fontColor:[LMAppThemeHelper getTitleColor]];
    [self addSubview:_fileNameLabel];
    _fileNameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [_fileNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_iconImageView.mas_right).offset(10);
        make.centerY.equalTo(self);
        make.width.lessThanOrEqualTo(@300);
    }];

    _totalItemLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979B]];
    [self addSubview:_totalItemLabel];
    // 用的 attributeString, 这里设置 font 无效.
    _totalItemLabel.font = [NSFontHelper getLightSystemFont:12];

    [_totalItemLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.left.equalTo(self->_fileNameLabel.mas_right).offset(12);
    }];


//    NSImage *arrowImage = [bundle imageForResource:@"icon_arrow_down"];triangleButton
    NSImage *arrowImage = [NSImage imageNamed:@"icon_arrow_down" withClass:self.class];
    NSImage *arrowUpImage = [NSImage imageNamed:@"triangleButtonSelected" withClass:self.class];

    _expandButton = [[NSButton alloc] init];
    _expandButton.image = arrowUpImage;
    _expandButton.target = self;
    _expandButton.action = @selector(expandItem);
    _expandButton.alternateImage = arrowImage;
    _expandButton.imageScaling = NSImageScaleProportionallyUpOrDown;
    _expandButton.bezelStyle = NSRoundedBezelStyle;
    [_expandButton setButtonType:NSButtonTypeToggle];
    _expandButton.bordered = NO;
    [self addSubview:_expandButton];
    [_expandButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.right.equalTo(self).offset(-42);
        make.width.mas_equalTo(15);
    }];


    _checkBox = [[LMCheckboxButton alloc] init];
    [self addSubview:_checkBox];
    _checkBox.allowsMixedState = YES;
    _checkBox.changeToMixStateNotOnStateWhenClick = YES;
    _checkBox.imageScaling = NSImageScaleProportionallyUpOrDown;
    _checkBox.title = @"";
    [_checkBox setButtonType:NSButtonTypeSwitch];
    _checkBox.target = self;
    [_checkBox setAction:@selector(updateSelectedInfo:)];


    [_iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(23);
        make.centerY.equalTo(self);
        make.left.equalTo(self->_checkBox.mas_right).offset(13);
    }];

    [_checkBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).mas_equalTo(38);
        make.width.height.equalTo(@14);
        make.centerY.equalTo(self);
    }];

}

// LMCheckboxButton 的 state 是从 0(off)转换为 1(on), 不会转换为-1(mixed)
- (void)updateSelectedInfo:(NSButton *)sender {
    if (self.checkBoxUpdateDelegate) {
        [self.checkBoxUpdateDelegate updateDupBatchSelectedState:_item button:sender];
    }
    [_checkBox setNeedsDisplay];
}

- (void)expandItem {
    [_expandItemDelegate expandOrCollapseItem:_item];
}

- (void)updateViewsWithItem:(QMDuplicateBatch *)item withPreview:(BOOL)isPreview {
    _isPreview = isPreview;
    self.fileNameLabel.stringValue = item.fileName;

    if (isPreview) {

        [_fileNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self->_iconImageView.mas_right).offset(11);
            make.top.equalTo(self).offset(5);
            make.width.lessThanOrEqualTo(@220);
        }];
        [_totalItemLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self->_fileNameLabel.mas_bottom).offset(2);
            make.left.equalTo(self->_fileNameLabel);
        }];
        [_expandButton setHidden:YES];
    } else {

        [_fileNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self->_iconImageView.mas_right).offset(10);
            make.centerY.equalTo(self);
            make.width.lessThanOrEqualTo(@300);
        }];
        [_totalItemLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self->_fileNameLabel.mas_right).offset(12);
        }];
        [_expandButton setHidden:NO];

    }

    if (item.subItems && item.subItems.count > 0) {
        QMDuplicateFile *subItem = item.subItems[0];
        NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
        NSImage *image = [workspace iconForFile:subItem.filePath];
        _iconImageView.image = image;
    }


    NSDictionary *normalAttributes = @{NSForegroundColorAttributeName: [NSColor colorWithHex:0x94979B],
            NSFontAttributeName: [NSFontHelper getLightSystemFont:12]
    };
    NSDictionary *colorAttributes = @{NSForegroundColorAttributeName: [NSColor colorWithHex:0xFFAA09],
            NSFontAttributeName: [NSFontHelper getLightSystemFont:12]
    };

    NSUInteger selectedNum = 0;
    for (QMDuplicateFile *subItem in item.subItems) {
        if (subItem.selected) {
            selectedNum += 1;
        }
    }

    if (selectedNum == 0) {
        float totalSize = item.fileSize * item.subItems.count;

        NSString *countStr = [NSString stringWithFormat:@"%lu", item.subItems.count];
        NSString *sizeStr = [SizeHelper getFileSizeStringBySize:totalSize];

        NSString *totalString = [[NSString alloc] initWithFormat:NSLocalizedStringFromTableInBundle(@"DuplicateRootCellView_updateViewsWithItem_totalString_1", nil, [NSBundle bundleForClass:[self class]], @""), countStr, sizeStr];
        NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:totalString attributes:normalAttributes];
        self.totalItemLabel.attributedStringValue = attributeString;

    } else {

        float selectedSize = selectedNum * item.fileSize;

        NSString *selectCountStr = [NSString stringWithFormat:@"%lu", item.subItems.count];
        NSString *selectSizeStr = [SizeHelper getFileSizeStringBySize:selectedSize];

        NSString *totalString = [[NSString alloc] initWithFormat:NSLocalizedStringFromTableInBundle(@"DuplicateRootCellView_updateViewsWithItem_prefixString_2", nil, [NSBundle bundleForClass:[self class]], @""), selectCountStr, selectSizeStr];
        NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:totalString attributes:normalAttributes];

        NSRange selectSizeRange = [totalString rangeOfString:selectSizeStr];
        [attributeString addAttributes:colorAttributes range:selectSizeRange];

        self.totalItemLabel.attributedStringValue = attributeString;
    }

    [_checkBox setState:item.selectState];
}


// MARK: hover 态

- (void)updateTrackingAreas {
    // 这样写会造成问题, 有时候mouseExited 得不到调用.比如滚动 外部outlineView 时,鼠标其实移动到了另外的 row 上面.这时候有些 row 的 mouseExited得不到调用.

//    NSArray *areaArray = [self trackingAreas];
//    for (NSTrackingArea *area in areaArray) {
//        [self removeTrackingArea:area];
//    }
//    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
//                                                                options:NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways owner:self
//                                                               userInfo:nil];
//    [self addTrackingArea:trackingArea];
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
    [self updateRowViewSelect:YES];
}

- (void)mouseExited:(NSEvent *)event {
    [self updateRowViewSelect:NO];
}

- (void)updateRowViewSelect:(BOOL)selected {
    NSView *superView = self.superview;
    if (!_isPreview && superView != nil && [superView isKindOfClass:NSTableRowView.class]) {
        NSTableRowView *rowView = (NSTableRowView *) superView;
        [rowView setSelected:selected];
    }
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
    [super setBackgroundStyle:NSBackgroundStyleLight];
}
@end
