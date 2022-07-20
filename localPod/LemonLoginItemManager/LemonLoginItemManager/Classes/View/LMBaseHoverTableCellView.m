//
//  LMBaseHoverTableCellView.m
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "LMBaseHoverTableCellView.h"

#define LMLocalizedString(key,className)  NSLocalizedStringFromTableInBundle(key, nil, [NSBundle bundleForClass:className], @"");

@interface LMBaseHoverTableCellView ()

@property (nonatomic) NSTrackingArea *trackingArea;

@end

@implementation LMBaseHoverTableCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:self.trackingArea]) {
        [self addTrackingArea:self.trackingArea];
    }
}

- (void)ensureTrackingArea {
    if (_trackingArea == nil) {
        _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                    options:NSTrackingInVisibleRect | NSTrackingActiveAlways |
                        NSTrackingMouseEnteredAndExited
                                                      owner:self userInfo:nil];
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
    }
}

- (void)updateFileNameLabel:(NSTextField *)nameLabel fileImage:(NSImageView *)fileIcon filePath:(NSString *)filePath withLoginItem:(QMBaseLoginItem *)loginItem{
    NSString *iconPath = @"";
    if ([loginItem isKindOfClass:QMAppLaunchItem.class]) {
        QMAppLaunchItem *launchItem = (QMAppLaunchItem *)loginItem;
        iconPath = launchItem.filePath;
        nameLabel.stringValue = launchItem.fileName;
    } else if ([loginItem isKindOfClass:QMAppLoginItem.class]){
        QMAppLoginItem *appLoginItem = (QMAppLoginItem *)loginItem;
        iconPath = appLoginItem.loginItemPath;
        nameLabel.stringValue = appLoginItem.loginItemAppName;
    } else {
        iconPath = loginItem.appPath;
        nameLabel.stringValue = loginItem.appName;
    }
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSImage *image = [workspace iconForFile:iconPath];
    [fileIcon setImage:image];
//    filePath = iconPath;
//    if (pathBarView) {
//        [pathBarView setPath:filePath];
//    }
}

- (NSString *)getFilePathForLoginItem:(QMBaseLoginItem *)loginItem {
    NSString *filePath = @"";
    if ([loginItem isKindOfClass:QMAppLaunchItem.class]) {
        QMAppLaunchItem *launchItem = (QMAppLaunchItem *)loginItem;
        filePath = launchItem.filePath;
    } else if ([loginItem isKindOfClass:QMAppLoginItem.class]){
        QMAppLoginItem *appLoginItem = (QMAppLoginItem *)loginItem;
        filePath = appLoginItem.loginItemPath;
    } else {
        filePath = loginItem.appPath;
    }
    return filePath;
}

- (void)updateSwitchBtn:(COSwitch *)switchBtn switchBtnLabel:(NSTextField *)label withLoginItem:(QMBaseLoginItem *)loginItem {
    if (loginItem.isEnable) {
        switchBtn.on = YES;
    } else {
        switchBtn.on = NO;
    }
    [self updateSwitchLabel:label withSwitchBtn:switchBtn];
}

- (void)updateLoginItem:(QMBaseLoginItem *)loginItem switchLabel:(NSTextField *)label withSwtichBtn:(COSwitch *)button {
    loginItem.isEnable = button.on;
    [self updateSwitchLabel:label withSwitchBtn:button];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (button.on) {
            [loginItem enableLoginItem];
        } else {
            [loginItem disableLoginItem];
        }
    });
}

- (void)updateSwitchLabel:(NSTextField *)label withSwitchBtn:(COSwitch *)button {
    if (button.on) {
        label.stringValue = LMLocalizedString(@"LemonLoginItemManagerViewController_setting_status_enabled",self.class);
    } else {
        label.stringValue = LMLocalizedString(@"LemonLoginItemManagerViewController_setting_status_disabled",self.class);
    }
}

@end
