//
//  LMLoginItemAppInfoCellView.m
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "LMLoginItemAppInfoCellView.h"
#import "LMAppLoginItemInfo.h"
#import <QMUICommon/COSwitch.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/LanguageHelper.h>

#define LMLocalizedString(key,className)  NSLocalizedStringFromTableInBundle(key, nil, [NSBundle bundleForClass:className], @"");

@interface LMLoginItemAppInfoCellView()

@property(weak, nonatomic) IBOutlet NSImageView *appIcon;
@property(weak, nonatomic) IBOutlet NSTextField *appNameLable;
@property(weak, nonatomic) IBOutlet NSTextField *statusLabel;
@property(weak, nonatomic) IBOutlet NSTextField *switchLabel;
@property(weak, nonatomic) IBOutlet COSwitch *switchButton;
@property(weak, nonatomic) IBOutlet NSTextField *countLabel;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *statusBgViewWidth;
@property(weak, nonatomic) IBOutlet NSView *statusBgView;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *switchButtonLeadingConstraint;

@end

@implementation LMLoginItemAppInfoCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Drawing code here.
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initUI];
}

- (void)setLoginItemInfo:(LMAppLoginItemInfo *)loginItemInfo {
    _loginItemInfo = loginItemInfo;
    [self.loginItemInfo updateEnableStatus];
    [self updateUI];
    [self addKVOForLoginItemEnableStatus];
}

- (void)initUI {
    [LMAppThemeHelper setTitleColorForTextField:self.appNameLable];
    [LMAppThemeHelper setTitleColorForTextField:self.statusLabel];
    [LMAppThemeHelper setTitleColorForTextField:self.countLabel];
    self.statusBgView.wantsLayer = YES;
    self.statusBgView.layer.cornerRadius = 10;
    self.statusBgView.layer.backgroundColor = [NSColor colorWithHex:0x94979B alpha:0.15].CGColor;
    if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
        self.statusBgViewWidth.constant = 104;
        self.switchButtonLeadingConstraint.constant = 541;
    } else {
        self.statusBgViewWidth.constant = 68;
        self.switchButtonLeadingConstraint.constant = 533;
    }
}


- (void)updateUI {
    NSString *localString = LMLocalizedString(@"LemonLoginItemManagerViewController_item_count", self.class);
    if ((self.loginItemInfo.totalItemCount <= 1) && ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish) ) {
        localString = [localString substringToIndex:localString.length - 1];
    }
    self.countLabel.stringValue = [NSString stringWithFormat:localString,(long)self.loginItemInfo.totalItemCount];
    NSString *appShowName = self.loginItemInfo.appName;
    if ([appShowName containsString:@".app"]) {
        appShowName = [self.loginItemInfo.appName substringToIndex:self.loginItemInfo.appName.length - 4];
    }
    self.appNameLable.stringValue = appShowName;
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSImage *image = [workspace iconForFile:self.loginItemInfo.appPath];
    [self.appIcon setImage:image];
    [self updateStatusLabelStyle];
}

- (void)updateStatusLabelStyle {
    NSColor *textColor = [NSColor colorWithHex:0x1A83F7];
    NSColor *bgColor = [NSColor colorWithHex:0x1A83F7 alpha:0.15];
    NSString *statusText = LMLocalizedString(@"LemonLoginItemManagerViewController_status_partial_enable", self.class);
    if (self.loginItemInfo.enableStatus == LMAppLoginItemEnableStatusAllEnabled) {
        textColor = [NSColor colorWithHex:0x04D999];
        statusText = LMLocalizedString(@"LemonLoginItemManagerViewController_status_all_enabled",self.class);
        bgColor = [NSColor colorWithHex:0x04D999 alpha:0.15];

    } else if (self.loginItemInfo.enableStatus == LMAppLoginItemEnableStatusAllDisabled) {
        textColor = [NSColor colorWithHex:0x94979B];
        statusText = LMLocalizedString(@"LemonLoginItemManagerViewController_status_all_disabled",self.class);
        bgColor = [NSColor colorWithHex:0x94979B alpha:0.15];
    }
    self.statusLabel.stringValue = statusText;
    self.statusLabel.textColor = textColor;
    self.statusBgView.layer.backgroundColor = bgColor.CGColor;
    self.switchButton.onValueChanged = nil;
    if (self.loginItemInfo.enableStatus != LMAppLoginItemEnableStatusAllDisabled) {
        self.switchButton.on = YES;
        self.switchLabel.stringValue = LMLocalizedString(@"LemonLoginItemManagerViewController_setting_status_enabled",self.class);
    } else {
        self.switchButton.on = NO;
        self.switchLabel.stringValue = LMLocalizedString(@"LemonLoginItemManagerViewController_setting_status_disabled",self.class);
    }
    [self.switchButton setOnValueChanged:^(COSwitch *button) {
        [self.delegate clickSwitchButton:button onCellView:self];
        self.loginItemInfo.enableStatus = button.on ? LMAppLoginItemEnableStatusAllEnabled : LMAppLoginItemEnableStatusAllDisabled;
    }];
}

//通过KVO监听EnableStatus的更改
- (void)addKVOForLoginItemEnableStatus {
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
    [self.loginItemInfo addObserver:self forKeyPath:@"enableStatus" options:options context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"enableStatus"] && (object == self.loginItemInfo)) {
        LMAppLoginItemEnableStatus new = (LMAppLoginItemEnableStatus)[change valueForKey:@"new"];
        LMAppLoginItemEnableStatus old = (LMAppLoginItemEnableStatus)[change valueForKey:@"old"];
        if (new != old) {
            [self updateStatusLabelStyle];
        }
    }
}


@end
