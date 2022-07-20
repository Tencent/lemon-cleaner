//
//  McFlyWindow.m
//  McUICommon
//
//  Created by developer on 8/31/12.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import "McFlyWindow.h"

@interface McFlyWindow()<NSAnimationDelegate>
@property (nonatomic, copy) void (^completionHandler)(void);
@end

@implementation McFlyWindow
@synthesize image;
@synthesize flyDuration;
@synthesize flyEffect;
@synthesize completionHandler;

- (id)init
{
    self = [super initWithContentRect:NSMakeRect(0, 0, 64, 64) 
                            styleMask:NSBorderlessWindowMask 
                              backing:NSBackingStoreBuffered 
                                defer:NO];
    
    [self setReleasedWhenClosed:NO];
	[self setMovableByWindowBackground:NO];
	[self setBackgroundColor:[NSColor clearColor]];
	[self setLevel:(NSFloatingWindowLevel + 3000)];
	[self setOpaque:NO];
	[self setHasShadow:NO];
	[[self contentView] setWantsLayer:YES];
    
    return self;
}

- (NSImage *)image
{
    return image;
}
- (void)setImage:(NSImage *)aImage
{
    image = aImage;
    NSRect changeFrame = self.frame;
    changeFrame.size = aImage.size;
    [self setFrame:NSIntegralRect(changeFrame) display:NO];
    if (!imgView)
    {
        imgView = [[NSImageView alloc] initWithFrame:[self.contentView bounds]];
        [imgView setAutoresizingMask:NSViewMinXMargin|NSViewMaxXMargin|NSViewMinYMargin|NSViewMaxYMargin|NSViewWidthSizable|NSViewHeightSizable];
        [imgView setImageScaling:NSScaleToFit];
        [self.contentView addSubview:imgView];
    }
    [imgView setFrameSize:image.size];
    [imgView setImage:image];
}

- (void)flyWithFrom:(NSPoint)fromPoint to:(NSPoint)toPoint completionHandler:(void (^)(void))aCompletionHandler
{
    self.completionHandler = aCompletionHandler;
    if (flyEffect == McFlyEffectFadeOut)
    {
        [self setAlphaValue:1.0];
    }else 
    {
        [self setAlphaValue:0.0];
    }
	[self orderFront:self];
    
    NSRect fromFrame = self.frame;
    fromFrame.origin = NSMakePoint(fromPoint.x-NSWidth(self.frame)/2, fromPoint.y-NSHeight(self.frame)/2);
    [self setFrame:fromFrame display:YES];
    
    NSRect toFrame = self.frame;
    toFrame.origin = NSMakePoint(toPoint.x-NSWidth(self.frame)/2, toPoint.y-NSHeight(self.frame)/2);
    
    NSString *animationEffect = NSViewAnimationFadeOutEffect;
    if (flyEffect == McFlyEffectFadeIn)
    {
        animationEffect = NSViewAnimationFadeInEffect;
    }
    
    NSArray *animations = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    self,NSViewAnimationTargetKey,
                                                    [NSValue valueWithRect:fromFrame],NSViewAnimationStartFrameKey,
                                                    [NSValue valueWithRect:toFrame],NSViewAnimationEndFrameKey,
                                                    animationEffect,NSViewAnimationEffectKey,nil]];
    
    NSViewAnimation *viewAnimation = [[NSViewAnimation alloc] initWithViewAnimations:animations];
    [viewAnimation setAnimationBlockingMode:NSAnimationNonblockingThreaded];
    [viewAnimation setDuration:flyDuration];
    [viewAnimation setDelegate:self];
    [viewAnimation startAnimation];
}

- (void)animationCompleted
{
    [self orderOut:nil];
    if (completionHandler)
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.completionHandler();
            self.completionHandler = nil;
        });
    }
}

- (void)animationDidStop:(NSAnimation*)animation
{
    [self animationCompleted];
}

- (void)animationDidEnd:(NSAnimation*)animation
{
    [self animationCompleted];
}

@end
