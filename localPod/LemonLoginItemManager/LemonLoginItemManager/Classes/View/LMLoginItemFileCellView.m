//
//  LMLoginItemFileCellView.m
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "LMLoginItemFileCellView.h"
#import <QMUICommon/COSwitch.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <QMCoreFunction/LanguageHelper.h>

@interface LMLoginItemFileCellView ()

@property (weak, nonatomic) IBOutlet NSImageView *fileIcon;
@property (weak, nonatomic) IBOutlet NSTextField *fileNameLabel;
@property (weak, nonatomic) IBOutlet NSButton *openFileButton;
@property (weak, nonatomic) IBOutlet NSTextField *switchBtnLabel;
@property (weak, nonatomic) IBOutlet COSwitch *switchButton;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *switchButtonLeadingConstraint;

@end

@implementation LMLoginItemFileCellView

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
    //为了防止swtichButton 赋值的时候触发setOnValueChanged回调，所以在赋值前设置为nil
    self.switchButton.onValueChanged = nil;
    [super updateFileNameLabel:self.fileNameLabel fileImage:self.fileIcon filePath:self.filePath withLoginItem:self.loginItem];
    [super updateSwitchBtn:self.switchButton switchBtnLabel:self.switchBtnLabel withLoginItem:self.loginItem];
    [self.switchButton setOnValueChanged:^(COSwitch *button) {
        [super updateLoginItem:self.loginItem switchLabel:self.switchBtnLabel withSwtichBtn:self.switchButton];
        [self.delegate clickSwitchButton:button onCellView:self];
    }];
    self.filePath = [super getFilePathForLoginItem:self.loginItem];
}

- (void)initUI {
    self.openFileButton.hidden = YES;
    [LMAppThemeHelper setTitleColorForTextField:self.fileNameLabel];
    if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
        self.switchButtonLeadingConstraint.constant = 509;
    } else {
        self.switchButtonLeadingConstraint.constant = 500;
    }
}

- (void)mouseEntered:(NSEvent *)event {
    [super mouseEntered:event];
    self.openFileButton.hidden = NO;
}

- (void)mouseExited:(NSEvent *)event {
    [super mouseExited:event];
    self.openFileButton.hidden = YES;
}

- (IBAction)openFileButtonOnClick:(id)sender {
    [[NSWorkspace sharedWorkspace] selectFile:self.filePath
    inFileViewerRootedAtPath:[self.filePath stringByDeletingLastPathComponent]];
}

@end
