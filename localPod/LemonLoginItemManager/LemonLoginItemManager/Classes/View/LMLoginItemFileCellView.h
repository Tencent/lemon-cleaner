//
//  LMLoginItemFileCellView.h
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMAppLoginItemManage/QMAppLoginItemManage.h>
#import "LMBaseHoverTableCellView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMLoginItemFileCellView : LMBaseHoverTableCellView

@property (nonatomic) QMBaseLoginItem *loginItem;

- (void)setLoginItem:(QMBaseLoginItem *)loginItem;

@property (nonatomic) NSString *filePath;

@end

NS_ASSUME_NONNULL_END
