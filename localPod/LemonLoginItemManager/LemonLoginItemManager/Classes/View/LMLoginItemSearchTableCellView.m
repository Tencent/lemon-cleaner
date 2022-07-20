//
//  LMLoginItemSearchTableCellView.m
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "LMLoginItemSearchTableCellView.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSColor+Extension.h>

@interface LMLoginItemSearchTableCellView()

@property (weak, nonatomic) IBOutlet NSImageView *appIcon;
@property (weak, nonatomic) IBOutlet NSTextField *nameLabel;
@property (weak, nonatomic) IBOutlet LMPathBarView *pathBarView;
@property (weak, nonatomic) IBOutlet COSwitch *switchButton;
@property (weak, nonatomic) IBOutlet NSButton *openFileButton;
@property (weak, nonatomic) IBOutlet NSTextField *switchBtnLabel;
@property (nonatomic) QMBaseLoginItem *loginItem;
@property (nonatomic) NSString *filePath;

@end

@implementation LMLoginItemSearchTableCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Drawing code here.
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initUI];
}

- (void)setLoginItem:(QMBaseLoginItem *)loginItem {
    _loginItem = loginItem;
    [self updateUI];
}

- (void)updateUI {
    //app name and icon
    [super updateFileNameLabel:self.nameLabel fileImage:self.appIcon filePath:self.filePath withLoginItem:self.loginItem];
    [super updateSwitchBtn:self.switchButton switchBtnLabel:self.switchBtnLabel withLoginItem:self.loginItem];
    self.filePath = [super getFilePathForLoginItem:self.loginItem];
    self.pathBarView.path = self.filePath;
}

- (void)initUI {
    self.wantsLayer = YES;
    self.openFileButton.hidden = YES;
    self.pathBarView.hidden = YES;
    [LMAppThemeHelper setTitleColorForTextField:self.nameLabel];
    [self.switchButton setOnValueChanged:^(COSwitch *button) {
        [super updateLoginItem:self.loginItem switchLabel:self.switchBtnLabel withSwtichBtn:self.switchButton];
        [self.delegate clickSwitchButton:button onCellView:self];
    }];
}

- (void)mouseEntered:(NSEvent *)event {
    if ([LMAppThemeHelper isDarkMode]) {
        self.layer.backgroundColor = [NSColor colorWithHex:0x21202A].CGColor;
    } else {
        self.layer.backgroundColor = [NSColor colorWithHex:0xE8E8E8 alpha:0.4].CGColor;
    }
    self.openFileButton.hidden = NO;
    self.pathBarView.hidden = NO;
}

- (void)mouseExited:(NSEvent *)event {
    self.layer.backgroundColor = [NSColor clearColor].CGColor;
    self.openFileButton.hidden = YES;
    self.pathBarView.hidden = YES;
}

- (IBAction)openFileButtonOnClick:(id)sender {
    [[NSWorkspace sharedWorkspace] selectFile:self.filePath
    inFileViewerRootedAtPath:[self.filePath stringByDeletingLastPathComponent]];
}


@end
