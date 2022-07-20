//
//  LMCheckboxButton.m
//  LemonClener
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMCheckboxButton.h"
#import "NSEvent+Extension.h"

static NSImage *onImage_normal_new = nil;
static NSImage *onImage_disable_new = nil;
static NSImage *onImage_hover_new = nil;
static NSImage *onImage_pressed_new = nil;

static NSImage *offImage_normal_new = nil;
static NSImage *offImage_disable_new = nil;
static NSImage *offImage_hover_new = nil;
static NSImage *offImage_pressed_new = nil;

static NSImage *mixedImage_normal_new = nil;
static NSImage *mixedImage_disable_new = nil;
static NSImage *mixedImage_hover_new = nil;
static NSImage *mixedImage_pressed_new = nil;

@interface LMCheckboxButton ()
{
    BOOL mouseEnter;
    BOOL mouseDown;
    
    id eventMonitor;
}
@end

@implementation LMCheckboxButton

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setUp];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setUp];
    }
    return self;
}

//通过这种方式加载的NSImage，可防止当程序删除后图片无法的问题
- (NSImage *)strongImageByName:(NSString *)imageName
{
//    NSBundle *selfBundle = [NSBundle bundleForClass:self.class];
//    NSString *imagePath = [selfBundle pathForImageResource:imageName];
//    NSData *imageData = [[NSData alloc] initWithContentsOfFile:imagePath];
//    if (!imageData)
//        return nil;
//
//    NSImage *image = [[NSImage alloc] initWithData:imageData];
//    return image;
    NSBundle *selfBundle = [NSBundle bundleForClass:self.class];
    return [selfBundle imageForResource:imageName];
}

- (void)setUp
{
    self.imageScaling = NSImageScaleProportionallyDown;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        onImage_normal_new = [self strongImageByName:@"check_btn_on_normal"];
        onImage_disable_new = [self strongImageByName:@"check_btn_off_disable"];
        onImage_hover_new = [self strongImageByName:@"check_btn_on_normal"];
        onImage_pressed_new = [self strongImageByName:@"check_btn_on_normal"];
        
        offImage_normal_new = [self strongImageByName:@"check_btn_off_normal"];
        offImage_disable_new = [self strongImageByName:@"check_btn_off_disable"];
        offImage_hover_new = [self strongImageByName:@"check_btn_off_normal"];
        offImage_pressed_new = [self strongImageByName:@"check_btn_off_normal"];
        
        mixedImage_normal_new = [self strongImageByName:@"check_btn_mix_normal"];
        mixedImage_disable_new = [self strongImageByName:@"check_btn_off_disable"];
        mixedImage_hover_new = [self strongImageByName:@"check_btn_mix_normal"];
        mixedImage_pressed_new = [self strongImageByName:@"check_btn_mix_normal"];
    });
    
    [self setNeedsDisplay];
}

- (void)setNeedsDisplay
{
    [super setNeedsDisplay];
    
    NSImage *drawImage = nil;
    
    if (self.state == NSOnState)
    {
        if (!self.isEnabled)
            drawImage = onImage_disable_new;
        
        else if ([self isMouseDown])
            drawImage = onImage_pressed_new;
        
        else if ([self isMouseEnter])
            drawImage = onImage_hover_new;
        
        else
            drawImage = onImage_normal_new;
    }
    else if (self.state == NSOffState)
    {
        if (!self.isEnabled)
            drawImage = offImage_disable_new;
        
        else if ([self isMouseDown])
            drawImage = offImage_pressed_new;
        
        else if ([self isMouseEnter])
            drawImage = offImage_hover_new;
        
        else
            drawImage = offImage_normal_new;
    }
    else if (self.state == NSMixedState)
    {
        if (!self.isEnabled)
            drawImage = mixedImage_disable_new;
        
        else if ([self isMouseDown])
            drawImage = mixedImage_pressed_new;
        
        else if ([self isMouseEnter])
            drawImage = mixedImage_hover_new;
        
        else
            drawImage = mixedImage_normal_new;
    }
    
    [self setAlternateImage:drawImage];
    [self setImage:drawImage];
}

- (void)setEnabled:(BOOL)flag
{
    [super setEnabled:flag];
    [self setNeedsDisplay];
}

- (void)setState:(NSInteger)value
{
    [super setState:value];
    [self setNeedsDisplay];
}

- (void)viewDidMoveToSuperview
{
    if (!self.superview && mouseEnter)
    {
        [self mouseExited:nil];
    }
}

- (BOOL)isMouseDown
{
    return mouseDown;
}

- (BOOL)isMouseEnter
{
    return mouseEnter && [NSEvent mouseInView:self];
}

- (void)updateTrackingAreas
{
    NSArray *areaArray = [self trackingAreas];
    for (NSTrackingArea *area in areaArray)
    {
        [self removeTrackingArea:area];
    }
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                                options:NSTrackingMouseMoved|NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways
                                                                  owner:self
                                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)mouseEntered:(NSEvent *)event
{
    if (!self.isEnabled)
    {
        return;
    }
    
    mouseEnter = YES;
    [self setNeedsDisplay];
    
    //因为鼠标滚动时,会收不到mouseExited的消息,所以此处通过注册全局的监控来实现
    if (!eventMonitor)
    {
        eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSScrollWheelMask|NSMouseMovedMask handler:^NSEvent *(NSEvent *event) {
            if (![NSEvent mouseInView:self])
                [self mouseExited:nil];
            return event;
        }];
    }
}

- (void)mouseExited:(NSEvent *)event
{
    if (!self.isEnabled)
    {
        return;
    }
    
    mouseEnter = NO;
    [self setNeedsDisplay];
    
    if (eventMonitor)
    {
        [NSEvent removeMonitor:eventMonitor];
        eventMonitor = nil;
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (!self.isEnabled)
    {
        return;
    }
    
    mouseDown = YES;
    [self setNeedsDisplay];
    
    
    NSEvent *nextEvent = nil;
    while ((nextEvent=[self.window nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask]) && nextEvent.type != NSLeftMouseUp)
    {
        //
    }
    
    if ([NSEvent mouseInView:self])
    {
        if(_changeToMixStateNotOnStateWhenClick){
            self.state = (self.state == NSOffState) ? NSMixedState : NSOffState;
            [self sendAction:self.action to:self.target];
        }else{
            self.state = (self.state == NSOffState) ? NSOnState : NSOffState;
            [self sendAction:self.action to:self.target];
        }
        
    }
    mouseDown = NO;
    
    [self setNeedsDisplay];
}

@end
