//
//  CategoryProgressView.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QMDataConst.h"

//@protocol CategoryProgressViewDelegate
//
//- (void) onProgressViewMouseEnter:(id)sender;
//- (void) onProgressViewMouseExit:(id)sender;
//
//@end

@interface CategoryProgressView : NSImageView

@property (strong, nonatomic) NSColor *radianColor;
@property (assign, nonatomic) NSInteger offset;
@property (strong, nonatomic) NSColor *circleColor;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSImageView *animateImageView;

//@property (nonatomic, weak) id<CategoryProgressViewDelegate> delegate;

-(void)setProgressType:(ProgressViewType) type;

-(void)startAni;

-(void)stopAni;

-(void)setPicEnAble:(BOOL) isEnable;

-(NSImage *)getAnimateImage;

-(NSInteger)getLineWidth;

@end
