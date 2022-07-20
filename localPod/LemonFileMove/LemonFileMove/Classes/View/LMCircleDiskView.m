//
//  LMCircleDiskView.m
//  LemonFileMove
//
//  
//

#import "LMCircleDiskView.h"
#import <QMCoreFunction/NSColor+Extension.h>

@interface LMCircleDiskView() {
    NSUInteger _usedFullSize;
    NSUInteger _totalFullSize;
    CGFloat usedStartAngle;
    CGFloat usedEndAngle;
}
@property (nonatomic, strong) NSColor *color;

@end

@implementation LMCircleDiskView

-(instancetype)initWithCoder:(NSCoder *)decoder{
    self = [super initWithCoder:decoder];
    if (self) {
        
    }
    return self;
}

- (BOOL)isFlipped{
    return true;
}

- (void)setSysFullSize:(NSUInteger)sysFullSize alreadySize:(NSUInteger)alreadySize {
    _usedFullSize = alreadySize;
    _totalFullSize = sysFullSize;
    _color = [NSColor colorWithHex:0x9A9A9A alpha:0.2];
    [self setNeedsDisplay:YES];
}

- (void)setCircleColor:(NSColor *)color {
    self.color = color;
    [self setNeedsDisplay:YES];
}

//93F555绿色  F9EA0F黄色 21DB8A蓝色 18 36
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSUInteger totalSize = _totalFullSize;
    if(totalSize == 0)
        return;
    
    CGFloat usedProgress = ((CGFloat)_usedFullSize)/totalSize;
    CGFloat circleDegree = 360;
    
    // Drawing code here.
    CGFloat width = self.bounds.size.width - 8;
    CGFloat radius = (width) / 2;
    NSPoint centerPoint = NSMakePoint(self.bounds.size.width / 2, self.bounds.size.width / 2);
    
    CGFloat startAngle = 0;
    CGFloat endAngle = -90;
    if (usedProgress > 0) {
        startAngle = -90;
        endAngle = usedProgress * circleDegree - 90;
        usedStartAngle = startAngle;
        usedEndAngle = endAngle;
        NSBezierPath *usedPathArch = [NSBezierPath bezierPath];
        NSColor *color = nil;
        usedPathArch.lineWidth = 5.0;
        color = self.color;
        [usedPathArch appendBezierPathWithArcWithCenter:centerPoint radius:radius startAngle:startAngle endAngle:endAngle clockwise:NO];
        [color setStroke];
        [usedPathArch stroke];
        [usedPathArch closePath];
    }else{
        usedStartAngle = 0;
        usedEndAngle = 0;
    }
}


@end

