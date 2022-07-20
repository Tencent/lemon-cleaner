//
//  LMLoginItemAppInfoCellView.h
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMAppLoginItemInfo.h"
#import "LMBaseHoverTableCellView.h"
#import <QMUICommon/COSwitch.h>

NS_ASSUME_NONNULL_BEGIN

@class LMLoginItemAppInfoCellView;

//@protocol LMLoginItemAppInfoCellDelegate <NSObject>
//
//- (void)clickSwitchButton:(COSwitch *)switchBtn onCellView: (LMLoginItemAppInfoCellView *)cellView;
//
//@end

@interface LMLoginItemAppInfoCellView : LMBaseHoverTableCellView

@property(nonatomic) LMAppLoginItemInfo *loginItemInfo;

- (void)setLoginItemInfo:(LMAppLoginItemInfo *)loginItemInfo;

@end

NS_ASSUME_NONNULL_END
