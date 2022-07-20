//
//  LMLoginItemSearchTableCellView.h
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMBaseHoverTableCellView.h"
#import <QMAppLoginItemManage/QMAppLoginItemManage.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMLoginItemSearchTableCellView : LMBaseHoverTableCellView

- (void)setLoginItem:(QMBaseLoginItem *)loginItem;

@end

NS_ASSUME_NONNULL_END
