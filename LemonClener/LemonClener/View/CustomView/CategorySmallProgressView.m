//
//  CategorySmallProgressView.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "CategorySmallProgressView.h"

@implementation CategorySmallProgressView

-(id)initWithCoder:(NSCoder *)decoder{
    self = [super initWithCoder:decoder];
    if (self) {
        [self setWantsLayer:YES];
        [self.layer setBackgroundColor:[NSColor clearColor].CGColor];
    }
    
    return self;
}

-(NSImage *)getAnimateImage{
    return [NSImage imageNamed:@"small_round_circle" withClass:[self class]];
}

-(void)setPicEnAble:(BOOL)isEnable{
    
}

- (NSInteger)getLineWidth{
    return 1;
}

@end
