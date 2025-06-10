//
//  OwlWhiteListViewController.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlWhiteListViewController.h"
#import "OwlTableRowView.h"
#import "OwlSelectViewController.h"
#import "OwlWindowController.h"
#import "Owl2Manager.h"
#import "OwlConstant.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import "LMGradientTitleButton.h"
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/MMScroller.h>
#import <QMUICommon/LMCheckboxButton.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSButton+Extension.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/LMBorderButton.h>
#import <QMUICommon/LMTitleButton.h>
#import "OwlViewController.h"
#import <QMCoreFunction/LanguageHelper.h>
#import "OwlListPlaceHolderView.h"
#import "utilities.h"
#import "Owl2AppItem.h"
#import <QMCoreFunction/LMReferenceDefines.h>
#import "NSAlert+OwlExtend.h"

typedef void(^removeOwlWhiteListItem)(NSInteger);
typedef void(^checkOwlWhiteListItemCamera)(NSInteger, LMCheckboxButton *btn);
typedef void(^checkOwlWhiteListItemAudio)(NSInteger, LMCheckboxButton *btn);
typedef void(^checkOwlWhiteListItemSpeaker)(NSInteger, LMCheckboxButton *btn);

@interface OwlWhiteListCell : NSTableCellView{
    
}
@property (nonatomic, strong) NSImageView *appIcon;
@property (nonatomic, strong) NSTextField *tfAppName;
@property (nonatomic, strong) NSTextField *tfKind;
@property (nonatomic, strong) LMCheckboxButton *cameraCheck;
@property (nonatomic, strong) LMCheckboxButton *audioCheck;
@property (nonatomic, strong) LMCheckboxButton *speakerCheck;
@property (nonatomic, strong) LMCheckboxButton *screenCheck;
@property (nonatomic, assign) NSInteger indexRow;
@property (nonatomic, strong) removeOwlWhiteListItem action;
@property (nonatomic, strong) checkOwlWhiteListItemCamera cameraCheckAction;
@property (nonatomic, strong) checkOwlWhiteListItemAudio audioCheckAction;
@property (nonatomic, strong) checkOwlWhiteListItemSpeaker speakerCheckAction;
@property (nonatomic, strong) checkOwlWhiteListItemSpeaker screenCheckAction;
@property (nonatomic, strong) NSTextField *checkLabelCamera;
@property (nonatomic, strong) NSTextField *checkLabelAudio;
@property (nonatomic, strong) NSTextField *checkLabelSpeaker;
@property (nonatomic, strong) NSTextField *checkLabelScreen;

@end

@implementation OwlWhiteListCell

- (instancetype)initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    if (self) {
        
        _appIcon = [[NSImageView alloc] init];
        [self addSubview:_appIcon];
        
        _tfAppName = [OwlWhiteListViewController buildLabel:@"" font:[NSFontHelper getRegularSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
        [_tfAppName setLineBreakMode:NSLineBreakByTruncatingTail];
        [self addSubview:_tfAppName];
        
        _tfKind = [OwlWhiteListViewController buildLabel:@"" font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
        [self addSubview:_tfKind];
        
        _cameraCheck = [[LMCheckboxButton alloc] init];
        _cameraCheck.imageScaling = NSImageScaleProportionallyDown;
        _cameraCheck.title = @"";
//        NSMutableAttributedString *attrTitleCamera = [[NSMutableAttributedString alloc] initWithString:@" 摄像头"];
//        NSUInteger len = [attrTitleCamera length];
//        NSRange range = NSMakeRange(0, len);
//        [attrTitleCamera addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x94979B] range:range];
//        [attrTitleCamera addAttribute:NSFontAttributeName value:[NSFontHelper getLightSystemFont:12] range:range];
//        [attrTitleCamera fixAttributesInRange:range];
//        [cameraCheck setAttributedTitle:attrTitleCamera];
        [_cameraCheck setButtonType:NSButtonTypeSwitch];
        _cameraCheck.allowsMixedState = NO;
        [_cameraCheck setTarget:self];
        [_cameraCheck setAction:@selector(checkCamera:)];
        [self addSubview:_cameraCheck];
        
        _checkLabelCamera = [OwlWhiteListViewController buildLabel:LMLocalizedSelfBundleString(@"摄像头", nil) font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x94979B]];
        [self addSubview:_checkLabelCamera];
        
        _audioCheck = [[LMCheckboxButton alloc] init];
        _audioCheck.imageScaling = NSImageScaleProportionallyDown;
        _audioCheck.title = @"";
//        NSMutableAttributedString *attrTitleAudio = [[NSMutableAttributedString alloc] initWithString:@" 麦克风"];
//        len = [attrTitleAudio length];
//        range = NSMakeRange(0, len);
//        [attrTitleAudio addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x94979B] range:range];
//        [attrTitleAudio addAttribute:NSFontAttributeName value:[NSFontHelper getLightSystemFont:12] range:range];
//        [attrTitleAudio fixAttributesInRange:range];
//        [audioCheck setAttributedTitle:attrTitleAudio];
        [_audioCheck setButtonType:NSButtonTypeSwitch];
        _audioCheck.allowsMixedState = YES;
        [_audioCheck setTarget:self];
        [_audioCheck setAction:@selector(checkAudio:)];
        [self addSubview:_audioCheck];
        
        _checkLabelAudio = [OwlWhiteListViewController buildLabel:LMLocalizedSelfBundleString(@"麦克风", nil) font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x94979B]];
        [self addSubview:_checkLabelAudio];
        
        _speakerCheck = [[LMCheckboxButton alloc] init];
        _speakerCheck.imageScaling = NSImageScaleProportionallyDown;
        _speakerCheck.title = @"";
        [_speakerCheck setButtonType:NSButtonTypeSwitch];
        _speakerCheck.allowsMixedState = YES;
        [_speakerCheck setTarget:self];
        [_speakerCheck setAction:@selector(checkSpeaker:)];
        [self addSubview:_speakerCheck];
        _checkLabelSpeaker = [OwlWhiteListViewController buildLabel:LMLocalizedSelfBundleString(@"录制音频", nil) font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x94979B]];
        [self addSubview:_checkLabelSpeaker];
        
        _screenCheck = [[LMCheckboxButton alloc] init];
        _screenCheck.imageScaling = NSImageScaleProportionallyDown;
        _screenCheck.title = @"";
        [_screenCheck setButtonType:NSButtonTypeSwitch];
        _screenCheck.allowsMixedState = YES;
        [_screenCheck setTarget:self];
        [_screenCheck setAction:@selector(checkScreen:)];
        [self addSubview:_screenCheck];
        _checkLabelScreen = [OwlWhiteListViewController buildLabel:LMLocalizedSelfBundleString(@"截屏&录屏", nil) font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x94979B]];
        [self addSubview:_checkLabelScreen];
        
        LMTitleButton *removeBtn = [[LMTitleButton alloc] initWithFrame:NSMakeRect(0, 0, 36, 20)];
        [removeBtn setBezelStyle:NSBezelStylePush];
        removeBtn.bordered = NO;
                
        NSDictionary *attributes = @{
            NSFontAttributeName: [NSFont systemFontOfSize:12 weight:NSFontWeightLight],
            NSForegroundColorAttributeName: [NSColor colorWithHex:0x1A83F7]
        };
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:LMLocalizedSelfBundleString(@"移除", nil) attributes:attributes];
        [removeBtn setAttributedTitle:attributedTitle];
        [removeBtn setTarget:self];
        [removeBtn setAction:@selector(clickRemoveOwlItem:)];
        
        [self addSubview:removeBtn];
        
        [_appIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            if (@available(macOS 11.0, *)) {
                make.left.equalTo(@0).offset(OwlElementLeft - 5);
            } else {
                make.left.equalTo(@0).offset(OwlElementLeft);
            }
            make.height.equalTo(@22);
            make.width.equalTo(@(22));
        }];
        [_tfKind mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            if (@available(macOS 11.0, *)) {
                make.left.equalTo(@0).offset(158 -5);
            } else {
                make.left.equalTo(@0).offset(158);
            }
            make.width.equalTo(@(100));
        }];
        [_tfAppName mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(_appIcon.mas_right).offset(10);
            make.right.lessThanOrEqualTo(self.tfKind.mas_left).offset(-4);
        }];
        [_cameraCheck mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            CGFloat value = 266;
            if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
                value = 256;
            }
            if (@available(macOS 11.0, *)) {
                make.left.equalTo(@0).offset(value - 5);
            } else {
                make.left.equalTo(@0).offset(value);
            }
            
            make.height.width.equalTo(@(14));
        }];
        [_checkLabelCamera mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.cameraCheck.mas_right).offset(4);
            make.centerY.equalTo(self);
        }];
        CGFloat deviceSpace = 12;
        if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
            deviceSpace = 8;
        }
        [_audioCheck mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.mas_equalTo(self.checkLabelCamera.mas_right).offset(deviceSpace);
            make.height.width.equalTo(@(14));
        }];
        [_checkLabelAudio mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.audioCheck.mas_right).offset(4);
            make.centerY.equalTo(self);
        }];
        
        [_speakerCheck mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(0);
            make.left.mas_equalTo(self.checkLabelAudio.mas_right).offset(deviceSpace);
            make.height.width.equalTo(@(14));
        }];
        [_checkLabelSpeaker mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.speakerCheck.mas_right).offset(4);
            make.centerY.equalTo(self);
        }];
        
        [_screenCheck mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(0);
            make.left.mas_equalTo(self.checkLabelSpeaker.mas_right).offset(deviceSpace);
            make.height.width.equalTo(@(14));
        }];
        [_checkLabelScreen mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.screenCheck.mas_right).offset(4);
            make.centerY.equalTo(self);
        }];
        
        [removeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            CGFloat leftMargin = 627;
            if (@available(macOS 11, *)) {
                make.left.equalTo(self.mas_left).offset(leftMargin - 5);
            } else {
                make.left.equalTo(self.mas_left).offset(leftMargin);
            }
            make.width.equalTo(@(60));
            make.height.equalTo(@(24));
        }];
    }
    return self;
}

- (void)updateAppItem:(Owl2AppItem *)appItem {
    NSString *iconPath;
    
    iconPath = appItem.iconPath;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (iconPath && [iconPath length] > 0 && [fm fileExistsAtPath:iconPath]) {
        NSImage * iconImage = nil;
        iconImage = [[NSImage alloc] initWithContentsOfFile:iconPath];
        //iconImage = [[NSWorkspace sharedWorkspace] iconForFile:iconPath];
        if (iconImage != nil)
        {
            [iconImage setSize:NSMakeSize(64, 64)];
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
            [_appIcon setImage:image];
        }
    }
    
    if (appItem.sysApp) {
        _tfKind.stringValue = LMLocalizedSelfBundleString(@"系统应用", nil);
    } else {
        _tfKind.stringValue = LMLocalizedSelfBundleString(@"第三方应用", nil);
    }
    _cameraCheck.state = appItem.isWatchCamera;
    _audioCheck.state = appItem.isWatchAudio;
    _speakerCheck.state = appItem.isWatchSpeaker;
    _screenCheck.state = appItem.isWatchScreen;
    
    [self updateCameraLabel];
    [self updateAudioLabel];
    [self updateSpeakerLabel];
    [self updateScreenLabel];
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

- (void)clickRemoveOwlItem:(id)sender{
    if (self.action) {
        self.action(self.indexRow);
    }
}
- (void)updateCameraLabel{
    if (self.cameraCheck.state) {
        self.checkLabelCamera.textColor = [LMAppThemeHelper getTitleColor];
    } else {
        self.checkLabelCamera.textColor = [NSColor colorWithHex:0x94979B];
    }
}
- (void)updateAudioLabel{
    if (self.audioCheck.state) {
        self.checkLabelAudio.textColor = [LMAppThemeHelper getTitleColor];
    } else {
        self.checkLabelAudio.textColor = [NSColor colorWithHex:0x94979B];
    }
}

- (void)updateSpeakerLabel {
    if (self.speakerCheck.state) {
        self.checkLabelSpeaker.textColor = [LMAppThemeHelper getTitleColor];
    } else {
        self.checkLabelSpeaker.textColor = [NSColor colorWithHex:0x94979B];
    }
}

- (void)updateScreenLabel {
    if (self.screenCheck.state) {
        self.checkLabelScreen.textColor = [LMAppThemeHelper getTitleColor];
    } else {
        self.checkLabelScreen.textColor = [NSColor colorWithHex:0x94979B];
    }
}

- (BOOL)wantRemove{
    if (self.action) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = [NSString stringWithFormat:LMLocalizedSelfBundleString(@"摄像头和麦克风都取消信任会把app移出白名单。需要移除吗？", nil)];
        alert.informativeText = @"";
        [alert addButtonWithTitle:LMLocalizedSelfBundleString(@"移除", nil)];
        [alert addButtonWithTitle:LMLocalizedSelfBundleString(@"保留", nil)];
        
        NSInteger responseTag = [alert runModal];
        if (responseTag == NSAlertFirstButtonReturn) {
            self.action(self.indexRow);
            return YES;
        } else {
            return NO;
        }
    }
    return NO;
}
- (void)checkCamera:(id)sender{
    if (self.cameraCheckAction) {
        if (!self.audioCheck.state && !self.cameraCheck.state && !self.speakerCheck.state && !self.screenCheck.state) {
            if (![self wantRemove]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.cameraCheck.state = !self.cameraCheck.state;
                    [self updateCameraLabel];
                });
            }
        } else {
            self.cameraCheckAction(self.indexRow, self.cameraCheck);
            [self updateCameraLabel];
        }
    }
}
- (void)checkAudio:(id)sender{
    if (self.audioCheckAction) {
        if (!self.audioCheck.state && !self.cameraCheck.state && !self.speakerCheck.state && !self.screenCheck.state) {
            if (![self wantRemove]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.audioCheck.state = !self.audioCheck.state;
                    [self updateAudioLabel];
                });
            }
        } else {
            self.audioCheckAction(self.indexRow, self.audioCheck);
            [self updateAudioLabel];
        }
    }
}

- (void)checkSpeaker:(id)sender {
    if (self.speakerCheckAction) {
        if (!self.audioCheck.state && !self.cameraCheck.state && !self.speakerCheck.state && !self.screenCheck.state) {
            if (![self wantRemove]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.speakerCheck.state = !self.speakerCheck.state;
                    [self updateSpeakerLabel];
                });
            }
        } else {
            self.speakerCheckAction(self.indexRow, self.speakerCheck);
            [self updateSpeakerLabel];
        }
    }
}

- (void)checkScreen:(id)sender {
    if (self.screenCheckAction) {
        if (!self.audioCheck.state && !self.cameraCheck.state && !self.speakerCheck.state && !self.screenCheck.state) {
            if (![self wantRemove]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.screenCheck.state = !self.screenCheck.state;
                    [self updateScreenLabel];
                });
            }
        } else {
            self.screenCheckAction(self.indexRow, self.screenCheck);
            [self updateScreenLabel];
        }
    }
}

// fix 不同系统选中下，textfield的文字颜色不同，有些是黑有些是白的问题
- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle{
    [super setBackgroundStyle:NSBackgroundStyleLight];
}



@end

@interface OwlWhiteListViewController () <NSTableViewDelegate, NSTableViewDataSource>{
    NSTableView *tableView;
    NSScrollView *scrollView;
    NSButton *cancelBtn;
    NSButton *addBtn;
    NSString *identifier;
}
@property(weak) NSView *contentView;
@property(weak) NSView *bLineview;
@property(weak) MMScroller *scroller;
@property (nonatomic, strong) OwlListPlaceHolderView *listPlaceHolderView;

@property (nonatomic, strong) NSMutableArray<Owl2AppItem *> *wlList;
@end

@implementation OwlWhiteListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}
                      
-(void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.contentView];
    [LMAppThemeHelper setDivideLineColorFor:self.bLineview];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.scroller];
}


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
- (instancetype)initWithFrame:(NSRect)frame{
    self = [super init];
    if (self) {
        NSView *contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height - 0/*OwlWindowTitleHeight*/)];
        contentView.wantsLayer = YES;
        CALayer *layer = [[CALayer alloc] init];
        layer.backgroundColor = [NSColor whiteColor].CGColor;
        contentView.layer = layer;
        self.contentView = contentView;
        
        NSRect scrollViewRect = NSMakeRect(0, 52, frame.size.width, frame.size.height-OwlWindowTitleHeight*2 - 52);
        
        // list 为空占位图 “暂无白名单应用”
        self.listPlaceHolderView = [[OwlListPlaceHolderView alloc] initWithTitle:LMLocalizedSelfBundleString(@"暂无白名单应用", nil)];
        self.listPlaceHolderView.frame = scrollViewRect;
        [self.contentView addSubview:self.listPlaceHolderView];
        
        scrollView = [[NSScrollView alloc] initWithFrame:scrollViewRect];
        
        tableView = [[NSTableView alloc] init];
        [tableView setDelegate:self];
        [tableView setDataSource:self];
        [tableView setBackgroundColor:[NSColor whiteColor]];
        //[tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
        [tableView setAutoresizesSubviews:YES];
        tableView.intercellSpacing = NSMakeSize(0, 0);
        identifier = @"OwlWhiteListCell";
        //[tableView registerNib:nil forIdentifier:identifier];
        if (@available (macOS 11.0, *)) {
            tableView.style = NSTableViewStyleFullWidth;
        }
        
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutohidesScrollers:YES];
        [scrollView setAutoresizesSubviews:YES];
        [scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [scrollView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
        [scrollView setDocumentView:tableView];
        
        MMScroller *scroller = [[MMScroller alloc] init];
        self.scroller = scroller;
        [scroller setWantsLayer:YES];
        
//        scroller.layer.backgroundColor = [NSColor whiteColor].CGColor;
        [self->scrollView setVerticalScroller:scroller];
        [tableView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
        
        [tableView setHeaderView:nil];
        NSTableColumn *timeColumn = [[NSTableColumn alloc] initWithIdentifier:identifier];
        timeColumn.width = scrollView.frame.size.width;
        [tableView addTableColumn:timeColumn];
        
        //        [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        //            make.top.equalTo(scrollView.mas_top).offset(20);
        //            make.height.equalTo(@(frame.size.height-20));
        //            make.width.equalTo(scrollView);
        //        }];
        tableView.frame = NSMakeRect(0, 0, scrollView.frame.size.width, scrollView.frame.size.height);
        
        cancelBtn = [[LMBorderButton alloc] init];
        cancelBtn.title = LMLocalizedSelfBundleString(@"取消", nil);
        cancelBtn.target = self;
        cancelBtn.action = @selector(cancelBtnClicked:);
        cancelBtn.font = [NSFontHelper getRegularSystemFont:12];
        cancelBtn.hidden = YES;
        
        addBtn = [LMViewHelper createSmallGreenButton:12 title:LMLocalizedSelfBundleString(@"添加应用", nil)];
        addBtn.wantsLayer = YES;
        addBtn.layer.cornerRadius = 2;
        addBtn.target = self;
        addBtn.action = @selector(clickBtn:);
        
        [contentView addSubview:scrollView];
        [contentView addSubview:cancelBtn];
        [contentView addSubview:addBtn];
        self.view = contentView;
        
        NSTextField *tfTitle = [[NSTextField alloc] initWithFrame:NSZeroRect];
        tfTitle.alignment = NSTextAlignmentCenter;
        tfTitle.bordered = NO;
        tfTitle.editable = NO;
        tfTitle.backgroundColor = [NSColor clearColor];
        
        tfTitle.font = [NSFontHelper getMediumSystemFont:16];
        tfTitle.textColor = [LMAppThemeHelper getTitleColor];
        tfTitle.stringValue = LMLocalizedSelfBundleString(@"白名单", nil);
        [contentView addSubview:tfTitle];
        
        NSTextField *labelSpecApp = [OwlWhiteListViewController buildLabel:LMLocalizedSelfBundleString(@"应用程序", nil) font:[NSFontHelper getRegularSystemFont:12]color:[LMAppThemeHelper getTitleColor]];
        [contentView addSubview:labelSpecApp];
        NSTextField *labelSpecType = [OwlWhiteListViewController buildLabel:LMLocalizedSelfBundleString(@"应用类型", nil) font:[NSFontHelper getRegularSystemFont:12]color:[LMAppThemeHelper getTitleColor]];
        [contentView addSubview:labelSpecType];
        NSTextField *labelSpecOp = [OwlWhiteListViewController buildLabel:LMLocalizedSelfBundleString(@"允许权限类型", nil) font:[NSFontHelper getRegularSystemFont:12]color:[LMAppThemeHelper getTitleColor]];
        [contentView addSubview:labelSpecOp];
        
        NSTextField *labelSpecOperation = [OwlWhiteListViewController buildLabel:LMLocalizedSelfBundleString(@"操作", nil) font:[NSFontHelper getRegularSystemFont:12]color:[LMAppThemeHelper getTitleColor]];
        [contentView addSubview:labelSpecOperation];
        
        NSView *bLineview = [[NSView alloc] init];
        bLineview.wantsLayer = YES;
        CALayer *lineLayer = [[CALayer alloc] init];
        lineLayer.backgroundColor = [NSColor colorWithWhite:0.96 alpha:1].CGColor;
        bLineview.layer = lineLayer;
        self.bLineview = bLineview;
        [contentView addSubview:bLineview];
        
        [tfTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@9);
            make.centerX.equalTo(contentView);
        }];
        [addBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(@(-16));
            make.right.equalTo(contentView).offset(-16);
            make.height.equalTo(@24);
            if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
                make.size.mas_equalTo(NSMakeSize(100, 24));
            } else {
                make.size.mas_equalTo(NSMakeSize(68, 24));
            }
        }];
        [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(addBtn);
            make.right.mas_equalTo(addBtn.mas_left).offset(-8);
            if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
                make.size.mas_equalTo(NSMakeSize(52, 24));
            } else {
                make.size.mas_equalTo(NSMakeSize(44, 24));
            }
            
        }];
        [labelSpecApp mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@0).offset(OwlElementLeft);
            make.top.equalTo(@52);
            make.width.equalTo(@160);
        }];
        [labelSpecType mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@0).offset(158);
            make.top.equalTo(@52);
            make.width.equalTo(@160);
        }];
        [labelSpecOp mas_makeConstraints:^(MASConstraintMaker *make) {
            if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
                make.left.equalTo(@0).offset(254);
            } else {
                make.left.equalTo(@0).offset(264);
            }
            make.top.equalTo(@52);
            make.width.equalTo(@160);
        }];
        [labelSpecOperation mas_makeConstraints:^(MASConstraintMaker *make) {
            if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
                make.left.equalTo(self.view.mas_left).offset(630);
            } else {
                make.left.equalTo(self.view.mas_left).offset(642);
            }
            make.top.equalTo(@52);
        }];
        [bLineview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(OwlWindowTitleHeight));
            make.left.equalTo(contentView);
            make.height.equalTo(@1);
            make.width.equalTo(contentView);
        }];
        
        [self reloadData];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(whiteListChange:) name:OwlWhiteListChangeNotication object:nil];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.selectWindowController) {
        [self.selectWindowController close];
        //[[self.selectWindowController.window parentWindow] removeChildWindow:self.selectWindowController.window];
        self.selectWindowController = nil;
    }
}
- (void)whiteListChange:(NSNotification*)no{
    [self reloadData];
}

- (void)cancelBtnClicked:(NSButton *)btn {
    [self.view.window close];
    ((OwlViewController*)self.view.window.parentWindow.contentViewController).wlWindowController = nil;
}

- (void)clickBtn:(id)sender{
    if (!self.selectWindowController || !self.selectWindowController.window.contentViewController) {
        NSRect prect = self.view.window.frame;
        NSRect srect = NSMakeRect(prect.origin.x + (prect.size.width - self.view.frame.size.width) / 2, prect.origin.y + (prect.size.height - self.view.frame.size.height) / 2, self.view.frame.size.width, self.view.frame.size.height);
        NSLog(@"clickBtn: %@", NSStringFromRect(srect));
        NSViewController *viewController = [[OwlSelectViewController alloc] initWithFrame:srect];
        self.selectWindowController = [[OwlWindowController alloc] initViewController:viewController];
        [self.selectWindowController.window setReleasedWhenClosed:NO];
        [self.view.window addChildWindow:self.selectWindowController.window ordered:NSWindowAbove];
        [self.selectWindowController showWindow:nil];
        [self.selectWindowController.window setFrame:srect display:NO];
    } else {
        [(OwlSelectViewController*)(self.selectWindowController).window.contentViewController reloadData];
        [self.selectWindowController showWindow:nil];
    }
}

- (void)reloadData {
    NSArray *wlList = [Owl2Manager sharedManager].wlDic.allValues ? : @[];
    NSArray *sortWlList = [wlList sortedArrayUsingComparator:^NSComparisonResult(Owl2AppItem *obj1, Owl2AppItem *obj2) {
        return [obj1.name compare:obj2.name]; // 升序
    }];
    self.wlList = [[NSMutableArray alloc] initWithArray:sortWlList];
    
    [self reloadWhiteList];
}

- (void)reloadWhiteList{
    // 是否展示占位图
    scrollView.hidden = (0 == self.wlList.count);
    self.listPlaceHolderView.hidden = (0 != self.wlList.count);
    
    [tableView reloadData];
}

#pragma mark NSTableViewDelegate
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    return 40;
}

//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//    return [NSString stringWithFormat:@"%ld", row];
//}

//- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//    NSTextField *textField = [[NSTextField alloc] initWithFrame:(NSRect){.size = {100, 15}}];
//    textField.stringValue = [NSString stringWithFormat:@"%ld", row];
//    return textField;
//}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    OwlWhiteListCell *view = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if (view == nil) {
        view = [[OwlWhiteListCell alloc] initWithFrame:NSMakeRect(0, 0, tableView.frame.size.width, 24)];
        view.identifier = tableColumn.identifier;
    }
    
    @weakify(self);
    view.action = ^(NSInteger indexRow) {
        @strongify(self);
        NSLog(@"action row: %ld", (long)indexRow);
        if (indexRow < self.wlList.count) {
            Owl2AppItem *removeItem = self.wlList[indexRow];
            // 移除中有通知，会导致刷新，故此处不再刷新
            [[Owl2Manager sharedManager] removeAppWhiteItemWithIdentifier:removeItem.identifier];
            [self.wlList removeObject:removeItem];
        }
    };
    
    void (^updateSwitchStateBlock)(NSInteger indexRow, BOOL enable, Owl2LogHardware hardware) = ^(NSInteger indexRow, BOOL enable, Owl2LogHardware hardware) {
        @strongify(self);
        if (indexRow >= self.wlList.count) {
            return;
        }
        Owl2AppItem *item = self.wlList[indexRow];
        [item setWatchValue:enable forHardware:hardware];
        [[Owl2Manager sharedManager] addWhiteWithAppItem:item];
    };
    view.cameraCheckAction = ^(NSInteger indexRow, LMCheckboxButton *btn) {
        updateSwitchStateBlock(indexRow, btn.state, Owl2LogHardwareVedio);
    };
    view.audioCheckAction = ^(NSInteger indexRow, LMCheckboxButton *btn) {
        updateSwitchStateBlock(indexRow, btn.state, Owl2LogHardwareAudio);
    };
    view.speakerCheckAction = ^(NSInteger indexRow, LMCheckboxButton *btn) {
        updateSwitchStateBlock(indexRow, btn.state, Owl2LogHardwareSystemAudio);
    };
    view.screenCheckAction = ^(NSInteger indexRow, LMCheckboxButton *btn) {
        updateSwitchStateBlock(indexRow, btn.state, Owl2LogHardwareScreen);
        if (@available(macOS 15.0, *)) {
            // nothing
        } else {
            if (btn.state) {
                [NSAlert owl_showScreenPrivacyProtection];
            }
        }
    };
    view.indexRow = row;
    [view updateAppItem:self.wlList[row]];
    return view;
}

- (nullable NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row{
    return [[OwlTableRowView alloc] initWithFrame:NSZeroRect];
}

#pragma mark NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.wlList.count;
}

@end
