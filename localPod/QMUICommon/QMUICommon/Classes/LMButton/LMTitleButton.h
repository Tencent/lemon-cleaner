//
//  LMButton.h
//  LemonClener
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LMTitleButton : NSButton
{
    BOOL _hover;
    BOOL _down;
    NSTrackingArea * _trackingArea;
}

@property (nonatomic, retain) NSColor * defaultTitleColor;
@property (nonatomic, retain) NSColor * downTitleColor;
@property (nonatomic, retain) NSColor * hoverTitleColor;

- (void)setUp;

- (void)applyTitleColor;

@end
