//
//  LMLoginItemTypeCellView.m
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "LMLoginItemTypeCellView.h"
#import "LMAppLoginItemInfo.h"
#import <QMUICommon/LMAppThemeHelper.h>

#define LMLocalizedString(key,className)  NSLocalizedStringFromTableInBundle(key, nil, [NSBundle bundleForClass:className], @"");

@interface LMLoginItemTypeCellView()

@property (weak, nonatomic) IBOutlet NSTextField *typeLabel;
@property (weak, nonatomic) IBOutlet NSTextField *countLabel;
@property (nonatomic) LMAppLoginItemTypeInfo *loginItemTypeInfo;
@end

@implementation LMLoginItemTypeCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initUI];
}

- (void)setLoginItemTypeInfo:(LMAppLoginItemTypeInfo *)loginItemTypeInfo {
    _loginItemTypeInfo = loginItemTypeInfo;
    [self updateUI];
}

- (void)updateUI {
    NSString *localString = LMLocalizedString(@"LemonLoginItemManagerViewController_item_count", self.class);
    self.countLabel.stringValue = [NSString stringWithFormat:localString,(long)self.loginItemTypeInfo.itemCount];
    if (self.loginItemTypeInfo.itemType == LoginItemTypeAppItem) {
        self.typeLabel.stringValue = LMLocalizedString(@"LemonLoginItemManagerViewController_item_type_app", self.class);
    } else {
        self.typeLabel.stringValue = LMLocalizedString(@"LemonLoginItemManagerViewController_item_type_service", self.class);
    }
}

- (void)initUI {
    [LMAppThemeHelper setTitleColorForTextField:self.typeLabel];
    [LMAppThemeHelper setTitleColorForTextField:self.countLabel];
}

@end
