//
//  CategoryProgressView.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//



#import "CategoryProgressView.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSImage+Extension.h>

@interface CategoryProgressView ()

@property (assign, nonatomic) ProgressViewType type;
@property (strong, nonatomic) NSImageView *iconImageView;

@end

@implementation CategoryProgressView
{
//    NSTrackingArea *trackingArea;
}

-(instancetype)initWithCoder:(NSCoder *)decoder{
    self = [super initWithCoder:decoder];
    if (self) {
        self.circleColor = [NSColor clearColor];
        self.radianColor = [NSColor clearColor];
        [self getIconImageView];
        [self.iconImageView setImageScaling:NSImageScaleNone];
        [self.animateImageView setWantsLayer:YES];
        [self.animateImageView setImageScaling:NSImageScaleNone];
    }
    
    return self;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    
}

- (BOOL)isFlipped{
    return YES;
}

-(void)setProgressType:(ProgressViewType) type{
    self.type = type;
}

-(void)processAnimate{
    self.offset += 10;
    [self.animateImageView.layer setAnchorPoint:NSMakePoint(0.5, 0.5)];
    CGPoint center = CGPointMake(CGRectGetMidX(self.animateImageView.frame), CGRectGetMidY(self.animateImageView.frame));
    self.animateImageView.layer.position = center;
    CGAffineTransform ourTransform= CGAffineTransformMakeRotation( ( self.offset * M_PI ) / 180 );
    [self.animateImageView.layer setAffineTransform: ourTransform];
//    NSLog(@"acchor point = %@", NSStringFromRect(self.layer.frame));
//    [self setNeedsDisplay:YES];
}

-(void)startAni{
    
    if (self.timer == nil) {
//        self.circleColor = [NSColor colorWithHex:0xEBECEE];
//        self.radianColor = [NSColor colorWithHex:0x97FA97];
        [self.animateImageView setImage:[self getAnimateImage]];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(processAnimate) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        
        [self setPicEnAble:YES];
    }
    
    
}

-(NSImage *)getAnimateImage{
    return [NSImage imageNamed:@"big_round_circle" withClass:[self class]];
}

-(void)stopAni{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
        [self.animateImageView setImage:nil];
//        self.circleColor = [NSColor clearColor];
//        self.radianColor = [NSColor clearColor];
//        [self setNeedsDisplay:YES];
        CGAffineTransform ourTransform= CGAffineTransformMakeRotation(0);
        [self.animateImageView.layer setAffineTransform: ourTransform];
        [self setPicEnAble:NO];
    }
}

-(void)setPicEnAble:(BOOL) isEnable{
    if (isEnable) {
        if (self.type == ProgressViewTypeSys) {
            [self.iconImageView setImage:[NSImage imageNamed:@"sys_enable" withClass:[self class]]];
        }else if (self.type == ProgressViewTypeApp){
            [self.iconImageView setImage:[NSImage imageNamed:@"app_enable" withClass:[self class]]];
        }else if (self.type == ProgressViewTypeInt){
            [self.iconImageView setImage:[NSImage imageNamed:@"int_enable" withClass:[self class]]];
        }
    }else{
        if (self.type == ProgressViewTypeSys) {
            [self.iconImageView setImage:[NSImage imageNamed:@"sys_disable" withClass:[self class]]];
        }else if (self.type == ProgressViewTypeApp){
            [self.iconImageView setImage:[NSImage imageNamed:@"app_disable" withClass:[self class]]];
        }else if (self.type == ProgressViewTypeInt){
            [self.iconImageView setImage:[NSImage imageNamed:@"int_disable" withClass:[self class]]];
        }
    }
}

-(void)getIconImageView{
    for (NSView *view in self.subviews) {
        if ([view isKindOfClass:[NSImageView class]]) {
            if (view.tag == 1) {
                self.animateImageView = (NSImageView *)view;
            }else{
                self.iconImageView = (NSImageView *)view;
            }
        }
    }
}

//- (void)drawRect:(NSRect)dirtyRect {
//    [super drawRect:dirtyRect];
//
//    // Drawing code here.
//    CGPoint centerPoint = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
//    CGFloat radius = self.frame.size.width / 2 - 5;
//
////    NSBezierPath *circlePath = [NSBezierPath bezierPath];
////    circlePath.lineWidth = 2.0;
////    [self.circleColor set];
////    [circlePath appendBezierPathWithArcWithCenter:centerPoint radius:radius startAngle:0 endAngle:360];
////    [circlePath stroke];
////    [circlePath closePath];
//
//    NSInteger lineWidth = [self getLineWidth];
//    NSBezierPath *topRadianPath = [NSBezierPath bezierPath];
//    topRadianPath.lineWidth = lineWidth;
//    [self.radianColor set];
//    [topRadianPath appendBezierPathWithArcWithCenter:centerPoint radius:radius startAngle:-120 + self.offset endAngle:-60 + self.offset];
//    [topRadianPath stroke];
//    [topRadianPath closePath];
//
//    NSBezierPath *bottomRadianPath = [NSBezierPath bezierPath];
//    bottomRadianPath.lineWidth = lineWidth;
//    [bottomRadianPath appendBezierPathWithArcWithCenter:centerPoint radius:radius startAngle:60 + self.offset endAngle:120 + self.offset];
//    [bottomRadianPath stroke];
//    [bottomRadianPath closePath];
//
//}

-(NSInteger)getLineWidth{
    return 2;
}

//- (void)updateTrackingAreas {
//    [super updateTrackingAreas];
//    [self ensureTrackingArea];
//    if (![[self trackingAreas] containsObject:trackingArea]) {
//        [self addTrackingArea:trackingArea];
//    }
//}
//
//- (void)ensureTrackingArea {
//    if (trackingArea == nil) {
//        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
//                                                    options:NSTrackingInVisibleRect | NSTrackingActiveAlways |
//                        NSTrackingMouseEnteredAndExited
//                                                      owner:self userInfo:nil];
//    }
//}
//
//- (void)mouseEntered:(NSEvent *)event {
//    [self.delegate onProgressViewMouseEnter:self];
//}
//
//- (void)mouseExited:(NSEvent *)event {
//    [self.delegate onProgressViewMouseExit:self];
//}

@end
