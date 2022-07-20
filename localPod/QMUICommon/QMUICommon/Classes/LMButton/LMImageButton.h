//
//  LMImageButton.h
//  LemonClener
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMTitleButton.h"

@interface LMImageButton : LMTitleButton

@property (nonatomic, retain) NSImage * defaultImage;
@property (nonatomic, retain) NSImage * hoverImage;
@property (nonatomic, retain) NSImage * downImage;

- (void)applyImageAndColor;

@end
