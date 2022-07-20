//
//  CircleCleanImageView.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "CircleCleanImageView.h"
#import <QMCoreFunction/NSImage+Extension.h>

@interface CircleCleanImageView()

@property (strong, nonatomic) NSTrackingArea *trackingArea;
@property (strong, nonatomic) NSTimer *enterAniTimer;
@property (strong, nonatomic) NSTimer *exitAniTimer;
@property (strong, nonatomic) NSMutableArray *enterArr;
@property (strong, nonatomic) NSMutableArray *exitArr;
@property (assign, nonatomic) NSInteger currentCount;

@end

@implementation CircleCleanImageView

-(void)updateTrackingAreas{
    [super updateTrackingAreas];
    if (self.trackingArea) {
        [self removeTrackingArea:self.trackingArea];
    }
    self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                     options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                                     owner:self
                                                     userInfo:nil];

    [self addTrackingArea:self.trackingArea];
    [self becomeFirstResponder];
}

//- (void)drawRect:(NSRect)dirtyRect {
//    [super drawRect:dirtyRect];
//    
//    // Drawing code here.
//    NSLog(@"frame：%@ , dirtyRect ： %@",NSStringFromRect([self frame]),NSStringFromRect(dirtyRect));
//    //frame：{{100, 100}, {300, 300}} , dirtyRect ： {{0, 0}, {300, 300}}
//    
//    
//}

//鼠标进入追踪区域
- (void)mouseEntered:(NSEvent *)event{
//        NSLog(@"mouseEntered ========== ");
    [self stopExitAni];
    //播放动画
    NSMutableArray *imageArr = [NSMutableArray array];
    for (NSInteger i=1; i<=10; i++) {
        // 获取图片的名称
        NSString *imageName = [NSString stringWithFormat:@"clean_main_ani_%ld", i];
        // 创建UIImage对象
        NSImage *image = [NSImage imageNamed:imageName withClass:self.class];
        // 加入数组
        [imageArr addObject:image];
    }
    self.enterArr = imageArr;
    self.currentCount = 0;
    [self startEnterAni];
}

//鼠标退出追踪区域
- (void)mouseExited:(NSEvent *)event{
//    NSLog(@"mouseExited ---------- ");
    [self stopEnterAni];
    //结束动画
    NSMutableArray *imageArr = [NSMutableArray array];
    for (NSInteger i=10; i>0; i--) {
        // 获取图片的名称
        NSString *imageName = [NSString stringWithFormat:@"clean_main_ani_%ld", i];
        // 创建UIImage对象
        NSImage *image = [NSImage imageNamed:imageName withClass:self.class];
        // 加入数组
        [imageArr addObject:image];
    }
    self.exitArr = imageArr;
    self.currentCount = 0;
    [self startExitAni];
}

-(void)startEnterAni{
    if (self.enterAniTimer == nil) {
        self.enterAniTimer = [NSTimer scheduledTimerWithTimeInterval:0.041 target:self selector:@selector(enterAnimate) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.enterAniTimer forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:self.enterAniTimer forMode:NSRunLoopCommonModes];
    }
}

-(void)enterAnimate{
    NSImage *image = [self.enterArr objectAtIndex:self.currentCount];
    [self setImage:image];
    self.currentCount++;
    if (self.currentCount == 10) {
        [self stopEnterAni];
    }
}

-(void)stopEnterAni{
    if (self.enterAniTimer != nil) {
        [self.enterAniTimer invalidate];
        self.enterAniTimer = nil;
        self.enterArr = nil;
    }
}

-(void)startExitAni{
    if (self.exitAniTimer == nil) {
        self.exitAniTimer = [NSTimer scheduledTimerWithTimeInterval:0.041 target:self selector:@selector(exitAnimate) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.exitAniTimer forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:self.exitAniTimer forMode:NSRunLoopCommonModes];
    }
}

-(void)exitAnimate{
    NSImage *image = [self.exitArr objectAtIndex:self.currentCount];
    [self setImage:image];
    self.currentCount++;
    if (self.currentCount == 10) {
        [self stopExitAni];
    }
}

-(void)stopExitAni{
    if (self.exitAniTimer != nil) {
        [self.exitAniTimer invalidate];
        self.exitAniTimer = nil;
        self.exitArr = nil;
    }
}


////鼠标左键按下
//- (void)mouseDown:(NSEvent *)event{
//
//    //event.clickCount 不是累计数。双击时调用mouseDown 两次，clickCount 第一次=1，第二次 = 2。
//    if ([event clickCount] > 1) {
//        //双击相关处理
//    }
//
//    NSLog(@"mouseDown ========== clickCount：%ld buttonNumber：%ld",event.clickCount,event.buttonNumber);
//
//    self.layer.backgroundColor = [NSColor redColor].CGColor;
//
//    //获取鼠标点击位置坐标：先获取event发生的window中的坐标，在转换成view视图坐标系的坐标。
//    NSPoint eventLocation = [event locationInWindow];
//    NSPoint center = [self convertPoint:eventLocation fromView:nil];
//
//    //与上面等价
//    NSPoint clickLocation = [self convertPoint:[event locationInWindow]
//                                      fromView:nil];
//
//    NSLog(@"center：%@ , clickLocation：%@",NSStringFromPoint(center),NSStringFromPoint(clickLocation));
//
//    //判断是否按下了Command键
//    if ([event modifierFlags] & NSCommandKeyMask) {
//        [self setFrameRotation:[self frameRotation]+90.0];
//        [self setNeedsDisplay:YES];
//
//        NSLog(@"按下了Command键 ------ ");
//    }
//}
//
////鼠标左键起来
//- (void)mouseUp:(NSEvent *)event{
//    NSLog(@"mouseUp ========== ");
//
//    self.layer.backgroundColor = [NSColor greenColor].CGColor;
//
//}
//
////鼠标右键按下
//- (void)rightMouseDown:(NSEvent *)event{
//    NSLog(@"rightMouseDown ========== ");
//}
//
////鼠标右键起来
//- (void)rightMouseUp:(NSEvent *)event{
//    NSLog(@"rightMouseUp ========== ");
//}
//
////鼠标移动
//- (void)mouseMoved:(NSEvent *)event{
//    //    NSLog(@"mouseMoved ========== ");
//}
//
////鼠标按住左键进行拖拽
//- (void)mouseDragged:(NSEvent *)event{
//    NSLog(@"mouseDragged ========== ");
//}
//
////鼠标按住右键进行拖拽
//- (void)rightMouseDragged:(NSEvent *)event{
//    NSLog(@"rightMouseDragged ========== ");
//}

@end
