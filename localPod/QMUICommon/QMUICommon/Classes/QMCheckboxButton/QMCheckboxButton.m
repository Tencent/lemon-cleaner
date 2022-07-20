//
//  QMCheckboxButton.m
//  QMUICommon
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMCheckboxButton.h"
#import "NSEvent+Extension.h"

static NSImage *onImage_normal = nil;
static NSImage *onImage_disable = nil;
static NSImage *onImage_hover = nil;
static NSImage *onImage_pressed = nil;

static NSImage *offImage_normal = nil;
static NSImage *offImage_disable = nil;
static NSImage *offImage_hover = nil;
static NSImage *offImage_pressed = nil;

static NSImage *mixedImage_normal = nil;
static NSImage *mixedImage_disable = nil;
static NSImage *mixedImage_hover = nil;
static NSImage *mixedImage_pressed = nil;

@interface QMCheckboxButton ()
{
    BOOL mouseEnter;
    BOOL mouseDown;
    
    id eventMonitor;
}
@end

@implementation QMCheckboxButton

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
    NSBundle *selfBundle = [NSBundle bundleForClass:self.class];
    NSString *imagePath = [selfBundle pathForImageResource:imageName];
    NSData *imageData = [[NSData alloc] initWithContentsOfFile:imagePath];
    if (!imageData)
        return nil;
    
    NSImage *image = [[NSImage alloc] initWithData:imageData];
    return image;
}

- (void)setUp
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        onImage_normal = [self strongImageByName:@"selected_normal"];
        onImage_disable = [self strongImageByName:@"selected_disable"];
        onImage_hover = [self strongImageByName:@"selected_hover"];
        onImage_pressed = [self strongImageByName:@"selected_press"];
        
        offImage_normal = [self strongImageByName:@"unselected_normal"];
        offImage_disable = [self strongImageByName:@"unselected_disable"];
        offImage_hover = [self strongImageByName:@"unselected_hover"];
        offImage_pressed = [self strongImageByName:@"unselected_press"];
        
        mixedImage_normal = [self strongImageByName:@"mix_select_normal"];
        mixedImage_disable = [self strongImageByName:@"mix_select_disable"];
        mixedImage_hover = [self strongImageByName:@"mix_select_hover"];
        mixedImage_pressed = [self strongImageByName:@"mix_select_press"];
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
            drawImage = onImage_disable;
        
        else if ([self isMouseDown])
            drawImage = onImage_pressed;
        
        else if ([self isMouseEnter])
            drawImage = onImage_hover;
        
        else
            drawImage = onImage_normal;
    }
    else if (self.state == NSOffState)
    {
        if (!self.isEnabled)
            drawImage = offImage_disable;
        
        else if ([self isMouseDown])
            drawImage = offImage_pressed;
        
        else if ([self isMouseEnter])
            drawImage = offImage_hover;
        
        else
            drawImage = offImage_normal;
    }
    else if (self.state == NSMixedState)
    {
        if (!self.isEnabled)
            drawImage = mixedImage_disable;
        
        else if ([self isMouseDown])
            drawImage = mixedImage_pressed;
        
        else if ([self isMouseEnter])
            drawImage = mixedImage_hover;
        
        else
            drawImage = mixedImage_normal;
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
        self.state = (self.state == NSOffState) ? NSOnState : NSOffState;
        [self sendAction:self.action to:self.target];
    }
    mouseDown = NO;
    
    [self setNeedsDisplay];
}

@end
