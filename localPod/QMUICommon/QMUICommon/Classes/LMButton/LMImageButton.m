//
//  LMImageButton.m
//  LemonClener
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMImageButton.h"

@implementation LMImageButton

- (void)setUp
{    
    [super setUp];
    [self setImage];
}

- (void)applyImageAndColor {
    [self applyTitleColor];
    [self setImage];
}

- (void)setImage {
    if(!self.enabled) {
        return;
    }
    if(_down) {
        if(_downImage)
            [self setImage:_downImage];
    }
    else {
        if(_hover && _hoverImage)
            [self setImage:_hoverImage];
        else if(_defaultImage)
            [self setImage:_defaultImage];
    }
}

- (void)mouseEntered:(NSEvent *)event
{
    [super mouseEntered:event];
    [self setImage];
}

- (void)mouseExited:(NSEvent *)event
{
    [super mouseExited:event];
    [self setImage];
}

- (void)mouseDown:(NSEvent *)event
{
    [super mouseDown:event];
    [self setImage];
}

- (void)mouseUp:(NSEvent *)event
{
    [super mouseUp:event];
    [self setImage];
}

@end
