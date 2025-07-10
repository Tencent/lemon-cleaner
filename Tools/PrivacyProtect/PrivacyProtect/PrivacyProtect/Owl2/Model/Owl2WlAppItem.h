//
//  Owl2WlAppItem.h
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2AppItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface Owl2WlAppItem : Owl2AppItem

- (instancetype)initWithAppItem:(Owl2AppItem *)appItem;

@property (nonatomic) BOOL isExpand; // 是否展开

@end

@interface NSDictionary (Owl2AppItem)
- (NSArray<Owl2WlAppItem *> *)owl_toWlAppItemsFromContainExpandWlList:(NSArray<Owl2WlAppItem *> *)list;
@end
NS_ASSUME_NONNULL_END
