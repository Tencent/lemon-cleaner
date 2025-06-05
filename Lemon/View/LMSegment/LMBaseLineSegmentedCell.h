//
//  LMBaseLineSegmentedCell.h
//  Lemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMBaseLineSegmentedControl.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMBaseLineSegmentedCell : NSSegmentedCell

- (void)updateCellRedPointInfo:(NSDictionary *)redPointDict;

@end

NS_ASSUME_NONNULL_END
