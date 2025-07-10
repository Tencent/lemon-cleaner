//
//  OwlWhitelistCell.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "OwlWhitelistCell.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/LMBorderButton.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/LMReferenceDefines.h>
#import "utilities.h"

@implementation OwlWhitelistCell

+ (NSTextField*)buildLabel:(NSString*)title font:(NSFont*)font color:(NSColor*)color{
    NSTextField *labelTitle = [[NSTextField alloc] init];
    labelTitle.stringValue = title;
    labelTitle.font = font;
    labelTitle.alignment = NSTextAlignmentLeft;
    labelTitle.bordered = NO;
    labelTitle.editable = NO;
    labelTitle.textColor = color;
    labelTitle.backgroundColor = [NSColor clearColor];
    return labelTitle;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupSubviews];
        [self setupSubviewsLayout];
    }
    return self;
}

- (void)setupSubviews {
    [self addSubview:self.appIcon];
    [self addSubview:self.tfAppName];
    [self addSubview:self.tfKind];
    [self addSubview:self.grantedPermissionStackView];
    [self addSubview:self.foldOrExpandButton];
    [self addSubview:self.removeBtn];
}

- (void)setupSubviewsLayout {
    [self.appIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(OwlElementLeft - kOwlLeftRightMarginForTableCell);
        make.centerY.mas_equalTo(0);
        make.size.mas_equalTo(CGSizeMake(20, 20));
    }];
    [self.tfAppName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(52 - kOwlLeftRightMarginForTableCell);
        make.centerY.mas_equalTo(0);
        make.width.mas_lessThanOrEqualTo(116 - kOwlHorizontalTextSpacing);
    }];
    [self.tfKind mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(168 - kOwlLeftRightMarginForTableCell);
        make.centerY.mas_equalTo(0);
    }];
    [self.grantedPermissionStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(278 - kOwlLeftRightMarginForTableCell);
        make.centerY.mas_equalTo(0);
        make.width.mas_lessThanOrEqualTo(250 - kOwlHorizontalTextSpacing);
    }];
    [self.tfItem setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    
    [self.foldOrExpandButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(526 - kOwlLeftRightMarginForTableCell);
        make.centerY.mas_equalTo(0);
    }];

    [self.removeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-(30 - kOwlLeftRightMarginForTableCell)).priorityLow();
        make.left.mas_greaterThanOrEqualTo(self.foldOrExpandButton.mas_right).offset(4);
        make.centerY.mas_equalTo(0);
    }];
}

- (void)updateAppItem:(Owl2AppItem *)appItem {
    
    NSString *iconPath = appItem.iconPath;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (iconPath && [iconPath length] > 0 && [fm fileExistsAtPath:iconPath]) {
        NSImage * iconImage = nil;
        iconImage = [[NSImage alloc] initWithContentsOfFile:iconPath];
        //iconImage = [[NSWorkspace sharedWorkspace] iconForFile:iconPath];
        if (iconImage != nil)
        {
            [iconImage setSize:NSMakeSize(20, 20)];
            [_appIcon setImage:iconImage];
        }
    } else {
        NSImage *image = nil;
        NSString *appPath = appItem.appPath;
        if ([appPath isKindOfClass:NSString.class]) {
            image = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
        }
        
        if (image) {
            [_appIcon setImage:image];
        } else if ([iconPath isEqualToString:@"console"]) {
            NSBundle *bundle = [NSBundle bundleForClass:[self class]];
            [_appIcon setImage:[bundle imageForResource:@"defaultTeminate"]];
        } else {
            [_appIcon setImage:[self getDefaultAppIcon]];
        }
    }
    
    // 特殊处理，在MacOS 15以上 图书应用的/System/Applications/Books.app/Contents/Resources/AppIcon.icns
    // 是一张纯黑图片
    if (@available(macOS 15.0, *)) {
        NSImage *image = getAppImage(appItem, AppleIBookIdentifier);
        if (image) {
            [self.appIcon setImage:image];
        }
    }
    
    self.tfAppName.stringValue = appItem.name ?: @"";
    if (appItem.sysApp) {
        self.tfKind.stringValue = LMLocalizedSelfBundleString(@"系统应用", nil);
    } else {
        self.tfKind.stringValue = LMLocalizedSelfBundleString(@"第三方应用", nil);
    }
    
    // 处理‘已允许权限类型’
    [self updateGrantedPermissionTextWithAppItem:appItem];
}

- (void)updateGrantedPermissionTextWithAppItem:(Owl2AppItem *)appItem {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:5];
    NSInteger count = 0;
    dispatch_block_t block = ^{
        if (array.count == 0) return;
        if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
            [array addObject:@"/"];
        } else {
            [array addObject:@"、"];
        }
    };
    if (appItem.isWatchCamera) {
        [array addObject:LMLocalizedSelfBundleString(@"摄像头", nil)];
        count++;
    }
    if (appItem.isWatchAudio) {
        block();
        [array addObject:LMLocalizedSelfBundleString(@"麦克风", nil)];
        count++;
    }
    if (appItem.isWatchSpeaker) {
        block();
        [array addObject:LMLocalizedSelfBundleString(@"录制音频", nil)];
        count++;
    }
    if (appItem.isWatchScreen) {
        block();
        [array addObject:LMLocalizedSelfBundleString(@"截屏&录屏", nil)];
        count++;
    }
    if (appItem.isWatchAutomatic) {
        block();
        [array addObject:LMLocalizedSelfBundleString(@"自动操作", nil)];
        count++;
    }
    NSString *text = QMRetStrIfEmpty([array componentsJoinedByString:@""]);
//    self.tfGrantedPermission.toolTip = text;
    self.tfGrantedPermission.stringValue = text;    
    [self.bubbleView setBubbleTitle:text];
    self.tfItem.stringValue = [NSString stringWithFormat:@"(%ld%@)", count, LMLocalizedSelfBundleString(@"项", nil)];
 }

- (NSImage*)getDefaultAppIcon{
    static NSImage *defaultIcon = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
        [defaultIcon setSize:NSMakeSize(64, 64)];
    });
    return defaultIcon;
}

// fix 不同系统选中下，textfield的文字颜色不同，有些是黑有些是白的问题
- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle{
    [super setBackgroundStyle:NSBackgroundStyleLight];
}

- (NSImage *)imageFoldOrExpandButton {
    return nil;
}

#pragma mark - action

- (void)clickRemoveOwlItem:(id)sender{
    if (self.removeAction) {
        self.removeAction();
    }
}

- (void)clickFoldOrExpandButton:(id)sender{
    if (self.foldOrExpandAction) {
        self.foldOrExpandAction();
    }
}

#pragma mark - getter

- (NSImageView *)appIcon {
    if (!_appIcon) {
        _appIcon = [[NSImageView alloc] init];
    }
    return _appIcon;
}

- (NSTextField *)tfAppName {
    if (!_tfAppName) {
        _tfAppName = [OwlWhitelistCell buildLabel:@"" font:[NSFontHelper getRegularSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
        [_tfAppName setLineBreakMode:NSLineBreakByTruncatingTail];
    }
    return _tfAppName;
}

- (NSTextField *)tfKind {
    if (!_tfKind) {
        _tfKind = [OwlWhitelistCell buildLabel:@"" font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
    }
    return _tfKind;
}

- (NSTextField *)tfGrantedPermission {
    if (!_tfGrantedPermission) {
        _tfGrantedPermission = [OwlWhitelistCell buildLabel:@"" font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
        _tfGrantedPermission.lineBreakMode = NSLineBreakByTruncatingTail;
        _tfGrantedPermission.maximumNumberOfLines = 1;
    }
    return _tfGrantedPermission;
}

- (NSTextField *)tfItem {
    if (!_tfItem) {
        _tfItem = [OwlWhitelistCell buildLabel:@"" font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
        _tfItem.maximumNumberOfLines = 1;
    }
    return _tfItem;
}

- (QMHoverStackView *)grantedPermissionStackView {
    if (!_grantedPermissionStackView) {
        _grantedPermissionStackView = [QMHoverStackView stackViewWithViews:@[self.tfGrantedPermission, self.tfItem]];
        _grantedPermissionStackView.alignment = NSLayoutAttributeLeading;
        _grantedPermissionStackView.spacing = 0;
        _grantedPermissionStackView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
        @weakify(self);
        _grantedPermissionStackView.hoverDidChange = ^(id<QMHoverProtocol> view) {
            @strongify(self);
            if (view.isHovered) {
                NSPoint point = [self.grantedPermissionStackView convertPoint:NSMakePoint(0, -4) toView:nil];
                point = NSMakePoint(point.x, self.window.contentView.frame.size.height - point.y);
                [self.bubbleView showInView:self.window.contentView atPosition:point];
            } else {
                [self.bubbleView removeFromSuperview];
            }
        };
    }
    return _grantedPermissionStackView;
}

- (LMBubbleView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [LMBubbleView bubbleWithStyle:LMBubbleStyleText arrowDirection:LMBubbleArrowDirectionTopLeft];
    }
    return _bubbleView;
}

- (LMTitleButton *)foldOrExpandButton {
    if (!_foldOrExpandButton) {
        _foldOrExpandButton = [[LMTitleButton alloc] initWithFrame:NSZeroRect];
        [_foldOrExpandButton setBezelStyle:NSBezelStylePush];
        _foldOrExpandButton.bordered = NO;
        NSDictionary *attributes = @{
            NSFontAttributeName: [NSFont systemFontOfSize:12 weight:NSFontWeightLight],
            NSForegroundColorAttributeName: [NSColor colorWithHex:0x1A83F7]
        };
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:LMLocalizedSelfBundleString(@"允许权限管理", nil) attributes:attributes];
        [_foldOrExpandButton setAttributedTitle:attributedTitle];
        [_foldOrExpandButton setTarget:self];
        [_foldOrExpandButton setAction:@selector(clickFoldOrExpandButton:)];
        [_foldOrExpandButton setImage:[self imageFoldOrExpandButton]];
        [_foldOrExpandButton setImagePosition:NSImageRight];
        [_foldOrExpandButton setImageScaling:NSImageScaleNone];
    }
    return _foldOrExpandButton;
}

- (LMTitleButton *)removeBtn {
    if (!_removeBtn) {
        _removeBtn = [[LMTitleButton alloc] initWithFrame:NSMakeRect(0, 0, 36, 20)];
        [_removeBtn setBezelStyle:NSBezelStylePush];
        _removeBtn.bordered = NO;
        NSDictionary *attributes = @{
            NSFontAttributeName: [NSFont systemFontOfSize:12 weight:NSFontWeightLight],
            NSForegroundColorAttributeName: [NSColor colorWithHex:0x1A83F7]
        };
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:LMLocalizedSelfBundleString(@"移除", nil) attributes:attributes];
        [_removeBtn setAttributedTitle:attributedTitle];
        [_removeBtn setTarget:self];
        [_removeBtn setAction:@selector(clickRemoveOwlItem:)];
    }
    return _removeBtn;
}

@end
