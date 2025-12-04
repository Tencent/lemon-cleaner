//
//  LMButton.h
//  LemonClener
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMImageButton.h"

@interface LMButton : LMImageButton

// 手动同步NSButtonCell属性到自定义Label
- (void)syncCellProperties;

@end
