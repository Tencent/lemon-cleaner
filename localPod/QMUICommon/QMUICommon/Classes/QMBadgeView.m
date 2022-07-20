//
//  QMBadgeView.m
//  QMUICommon
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "QMBadgeView.h"

@implementation QMBadgeView
@synthesize textColor,borderColor,backgroundColor,text;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setUp];
    }
    return self;
}

- (void)setUp
{
    textColor = [NSColor whiteColor];
    borderColor = [NSColor whiteColor];
    backgroundColor = [NSColor colorWithHex:0xff0707];
}

- (NSColor *)textColor
{
    return textColor;
}

- (void)setTextColor:(NSColor *)value
{
    textColor = value;
    [self setNeedsDisplay:YES];
}

- (NSColor *)borderColor
{
    return borderColor;
}

- (void)setBorderColor:(NSColor *)value
{
    borderColor = value;
    [self setNeedsDisplay:YES];
}

- (NSColor *)backgroundColor
{
    return backgroundColor;
}

- (void)setBackgroundColor:(NSColor *)value
{
    backgroundColor = value;
    [self setNeedsDisplay:YES];
}

- (NSString *)text
{
    return text;
}

- (void)setText:(NSString *)value
{
    text = value;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	if (!text || !textColor || !backgroundColor)
        return;

    NSDictionary *attributes = @{NSForegroundColorAttributeName: textColor,
                                 NSFontAttributeName:[NSFont systemFontOfSize:10.0]};
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text attributes:attributes];
    NSSize size = [attributedString size];
    
    NSRect textRect = NSMakeRect(NSMidX(self.bounds)-size.width/2, NSMidY(self.bounds)-size.height/2, size.width, size.height);
    NSRect bgRect = NSInsetRect(textRect, -2, -2);
    if (bgRect.size.width < bgRect.size.height)
    {
        bgRect.origin.x = NSMidX(self.bounds)-NSHeight(bgRect)/2;
        bgRect.size.width = bgRect.size.height;
    }
    NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:bgRect xRadius:NSHeight(bgRect)/2 yRadius:NSHeight(bgRect)/2];
    
    //[bezierPath setLineWidth:3.0];
    //[borderColor set];
    //[bezierPath stroke];
    
    NSShadow *bgShadow = [[NSShadow alloc] init];
    bgShadow.shadowOffset = CGSizeMake(0, -2);
    bgShadow.shadowColor = [NSColor colorWithHex:0x000000 alpha:0.1];
    [bgShadow set];
    [backgroundColor set];
    [bezierPath fill];
    
    NSShadow *textShadow = [[NSShadow alloc] init];
    textShadow.shadowOffset = CGSizeMake(0, -1);
    textShadow.shadowColor = [NSColor colorWithHex:0x000000 alpha:0.45];
    [textShadow set];
    [attributedString drawInRect:textRect];
}

@end
