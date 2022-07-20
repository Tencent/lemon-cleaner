//
//  LMBigLoadingView.m
//  QMUICommon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMBigLoadingView.h"
#import <QMCoreFunction/NSImage+Extension.h>
#define MAX_FRAME_COUNT     40

@interface LMBigLoadingView(){
    NSTimer *_aniTimer;
    NSArray<NSImage *> * _aniArray;
    NSInteger _curAniIndex;
}
@end

@implementation LMBigLoadingView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initView];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initView];
    }
    return self;
}

// 总共40帧，0~39， 13-18相同，34-0相同
- (void)initAniArray {
    NSMutableArray *imageArray = [NSMutableArray array];
    NSUInteger i = 0;
    for (i = 0; i < 13; i++) {
        NSString *imageName = [self getImageNameByIndxe:i];
        NSImage *image = [NSImage imageNamed:imageName withClass:self.class];
        [imageArray addObject:image];
    }
    NSImage *image13 = [NSImage imageNamed:[self getImageNameByIndxe:13] withClass:self.class];
    for (i = 13; i < 19; i++) {
        [imageArray addObject:image13];
    }
    
    for (i = 19; i < 34; i++) {
        NSString *imageName = [self getImageNameByIndxe:i];
        NSImage *image = [NSImage imageNamed:imageName withClass:self.class];
        [imageArray addObject:image];
    }
    
    NSImage *image0 = imageArray[0];
    for (i = 34; i < 40; i++) {
        [imageArray addObject:image0];
    }
    _aniArray = [imageArray copy];
}

- (void)initView {
    //    _aniTimer = [NSTimer scheduledTimerWithTimeInterval:0.052 target:self selector:@selector(changeFrame) userInfo:nil repeats:YES];
    _curAniIndex = 0;
    [self initAniArray];
    _aniTimer = [NSTimer timerWithTimeInterval:0.04 target:self selector:@selector(changeFrame) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_aniTimer forMode:NSRunLoopCommonModes];
}

- (void)changeFrame {
    NSImage *curImg = _aniArray[_curAniIndex];
    [self setImage:curImg];
    _curAniIndex++;
    if (_curAniIndex >= MAX_FRAME_COUNT) {
        _curAniIndex = 0;
    }
}

- (NSString *)getImageNameByIndxe:(NSInteger)index {
    return [NSString stringWithFormat:@"loading_%ld", index];
}

- (void)invalidate {
    [_aniTimer invalidate];
    _aniTimer = nil;
}

@end
