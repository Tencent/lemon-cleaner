//
//  TrashCheckMonitor.h
//  LemonMonitor
//
//  Created by junior on 2019/10/31.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TrashCheckMonitor : NSObject

- (NSArray *)getNewTashApps;

-(BOOL)isTrashItemsChanged;

@end

NS_ASSUME_NONNULL_END
