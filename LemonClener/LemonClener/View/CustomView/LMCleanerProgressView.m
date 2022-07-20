//
//  LMCleanerProgressView.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMCleanerProgressView.h"

@implementation LMCleanerProgressView

-(void)setFillColor:(NSColor *)fillColor{
    
}

-(CALayer *)getFillLayer:(NSRect)layerRect{
    CAGradientLayer * fillLayer = [CAGradientLayer layer];
    fillLayer.frame = layerRect;
    [fillLayer setColors:@[(id)[NSColor colorWithHex:0x00E1A2].CGColor, (id)[NSColor colorWithHex:0x00DC948].CGColor]];
    //    [fillLayer setLocations:@[@0.01, @1]];
    [fillLayer setStartPoint:CGPointMake(0, 0)];
    [fillLayer setEndPoint:CGPointMake(1, 1)];
    fillLayer.cornerRadius = layerRect.size.height / 2;
    return fillLayer;
}



@end
