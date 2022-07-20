//
//  CheckBoxUpdateDelegate.h
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/24.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMDuplicateBatch.h"

//同步 checkBox 更新显示
@protocol CheckBoxUpdateDelegate <NSObject>

- (void)updateDupBatchSelectedState:(QMDuplicateBatch *)item button:(NSButton *)sender;

- (void)updateDupFileSelectedState:(QMDuplicateFile *)item button:(NSButton *)sender;

@end
