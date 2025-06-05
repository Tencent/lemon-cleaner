//
//  Owl2SelectAppItem.h
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2AppItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface Owl2SelectAppItem : Owl2AppItem

- (instancetype)initWithAppItem:(Owl2AppItem *)appItem;

@property (nonatomic) BOOL isSelected;

@end

NS_ASSUME_NONNULL_END


