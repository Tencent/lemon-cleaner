//
//  LMCategoryStateImageView.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol CategoryProgressViewDelegate

- (void) onProgressViewMouseEnter:(id)sender;
- (void) onProgressViewMouseExit:(id)sender;

@end

@interface LMCategoryStateImageView : NSImageView

@property (nonatomic, weak) id<CategoryProgressViewDelegate> delegate;

@end
