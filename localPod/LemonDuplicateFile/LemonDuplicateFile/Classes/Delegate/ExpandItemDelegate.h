//
//  ExpandItemDelegate.h
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/22.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ExpandItemDelegate <NSObject>
- (void)expandOrCollapseItem:(QMDuplicateBatch *)item;
@end
