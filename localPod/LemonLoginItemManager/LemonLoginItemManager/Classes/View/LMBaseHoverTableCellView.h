//
//  LMBaseHoverTableCellView.h
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/COSwitch.h>
#import <QMAppLoginItemManage/QMAppLoginItemManage.h>
#import <QMUICommon/LMPathBarView.h>
#import <QMUICommon/COSwitch.h>

NS_ASSUME_NONNULL_BEGIN

@class LMBaseHoverTableCellView;

@protocol LMLoginItemCellViewDelegate <NSObject>

- (void)clickSwitchButton:(COSwitch *)switchBtn onCellView: (LMBaseHoverTableCellView *)cellView;

@end

@interface LMBaseHoverTableCellView : NSTableCellView

@property (weak, nonatomic) id<LMLoginItemCellViewDelegate> delegate;

- (void)updateFileNameLabel:(NSTextField *)nameLabel fileImage:(NSImageView *)fileIcon filePath:(NSString *)filePath withLoginItem:(QMBaseLoginItem *)loginItem;

- (void)updateSwitchBtn:(COSwitch *)switchBtn switchBtnLabel:(NSTextField *)label withLoginItem:(QMBaseLoginItem *)loginItem;

- (void)updateLoginItem:(QMBaseLoginItem *)loginItem switchLabel:(NSTextField *)label withSwtichBtn:(COSwitch *)button;

- (NSString *)getFilePathForLoginItem:(QMBaseLoginItem *)loginItem;

@end

NS_ASSUME_NONNULL_END
