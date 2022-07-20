//
//  LMLoginItemTypeCellView.h
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMAppLoginItemInfo.h"
#import "LMBaseHoverTableCellView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMLoginItemTypeCellView : LMBaseHoverTableCellView

- (void)setLoginItemTypeInfo:(LMAppLoginItemTypeInfo *)loginItemTypeInfo;

@end

NS_ASSUME_NONNULL_END
