//
//  CircleProportionView.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ChooseCategoryDelegate

-(void)selectCategory:(NSUInteger) categoryNum;

@end

@interface CircleProportionView : NSView

@property (nonatomic, weak) id<ChooseCategoryDelegate> delegate;

-(void)setSysFullSize:(NSUInteger) sysFullSize appFullSize:(NSUInteger) appFullSize intFullSize:(NSUInteger) intFullSize;

@end
