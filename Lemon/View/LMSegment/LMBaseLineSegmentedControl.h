//
//  LMBaseLineSegmentedControl.h
//  Lemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMBaseLineSegmentedControl : NSSegmentedControl

// 需要展示红点的标题，设置了才会在数组里面去匹配名称，名称相同 && 对应Preference Key为NO，才展示
- (void)updateRedPointInfo:(NSDictionary *)redPointDict;

@end

NS_ASSUME_NONNULL_END
