//
//  LMMemoryCellView.m
//  LemonMonitor
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "LMMemoryCellView.h"
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/ClickableView.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/AcceptsFirstMouseView.h>
#import <QMUICommon/LMAppThemeHelper.h>


@interface MessageViewController : NSViewController

@property (strong)  NSTextField *messageLabel;

@property (nonatomic)  NSString *message;

@end





@interface LMMemoryCellView ()
{
    NSTrackingArea *trackingArea;
}

@property (nonatomic ,strong)QMBubble *bubble;

@end

@implementation LMMemoryCellView




- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        bundle = [NSBundle bundleForClass:self.class];
        [self setupViews];
    }
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onKillProcess:) name:KILL_PROCESS_AT_MONITOR object:nil];
    return self;
}

- (void)setupViews{
    [self setupMemoryViews];
    [self setupCloseInfoViews];

}

-(void)setGradient{
    NSColor *grayColor = [LMAppThemeHelper getMonitorMemoryViewFillColor];
    gradient = [[NSGradient alloc] initWithColors:@[grayColor,grayColor]];
}

- (void)setupMemoryViews {
    [self setGradient];
    NSImageView *procImageView = [LMViewHelper createNormalImageView];
    self.procImageView = procImageView;
    [self addSubview:procImageView];

    NSTextField *procLabel = [LMViewHelper createNormalLabel:12 fontColor:[LMAppThemeHelper getTitleColor]];
    self.procField = procLabel;
    [procLabel setLineBreakMode:NSLineBreakByTruncatingTail];
    procLabel.preferredMaxLayoutWidth = 188;
    [self addSubview:procLabel];
    
    
    NSTextField *memoryLabel = [LMViewHelper createNormalLabel:12 fontColor:[LMAppThemeHelper getTitleColor]];
    self.memoryField = memoryLabel;
    [self addSubview:memoryLabel];
    
    [procImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@16);
        make.left.equalTo(self).offset(8);
        make.centerY.equalTo(self);
    }];
    
    [procLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.left.equalTo(procImageView.mas_right).offset(9);
    }];
    
    [memoryLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.right.equalTo(self).offset(-20);
    }];
    
}


-(void)setupCloseInfoViews
{
    NSView *closeContainer = [[NSView alloc] init];
    [self addSubview:closeContainer];
    self.closeContainer = closeContainer;
    [closeContainer setHidden:YES];
    

    NSButton *closeButton = [LMViewHelper createNormalTextButton:12 title:NSLocalizedStringFromTableInBundle(@"LMMemoryCellView_setupCloseInfoViews_closeButton _1", nil, [NSBundle bundleForClass:[self class]], @"") textColor:[NSColor colorWithHex:0x1A83F7]];
    [closeContainer addSubview:closeButton];
    closeButton.target = self;
    closeButton.action = @selector(closeProcess:);
    
    NSImageView *closeImageView = [LMViewHelper createNormalImageView];
    closeImageView.image = [[NSBundle bundleForClass:self.class]imageForResource: @"process_close_alert"];
    [closeContainer addSubview:closeImageView];
    self.closeImageView = closeImageView;
    
    [closeContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@16);
        make.centerY.equalTo(self);
        make.right.equalTo(self).offset(-20);
        make.left.equalTo(closeButton);
    }];
    [closeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@16);
        make.centerY.equalTo(closeButton);
        make.right.equalTo(closeContainer);
    }];
    [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.right.equalTo(closeImageView.mas_left).offset(-7);
    }];
}


- (BOOL)acceptsFirstMouse:(NSEvent *)event{
    return YES;
}

- (void)updateView:(LMMemoryItem *)memoryItem
{
    [self showCloseInfo:NO event:nil];
}
- (void)closeProcess:(NSButton *)button
{
    NSLog(@"closeProcess ....");
    if(self.killDelegate){
        [self.killDelegate killProcess:button];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect rect = NSInsetRect(self.bounds, 0, 6);
    double drawProcess = _progress * 0.7;
    rect.size.width *= drawProcess;
//    NSLog(@"drawRect ... rect  is %@, bound is %@, _progress is %f", NSStringFromRect(rect),NSStringFromRect(self.bounds) ,_progress);
    [self setGradient];
    [gradient drawInRect:rect angle:0];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:trackingArea]) {
        [self addTrackingArea:trackingArea];
    }
}

- (void)ensureTrackingArea {
    if (trackingArea == nil) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved
                                                    owner:self userInfo:nil];
    }
}

- (void)mouseEntered:(NSEvent *)event {
    [self showCloseInfo:YES event:event];
}

- (void)mouseExited:(NSEvent *)event {
    
//    NSPoint event_location = [event locationInWindow];
//    NSPoint local_point = [self convertPoint:event_location fromView:nil];
//    NSLog(@"mouseExited : %@" , NSStringFromPoint(local_point));
    //    // note: mouseExited 会调用多次, 这里在 移出closeButton 区域时是也会触发.原因:底部的 closeButton 也注册了 NSTrackingArea.
//    if(local_point.x <= 0 ||  local_point.y <= 0
//       || local_point.y > self.bounds.size.height ||  local_point.x > self.bounds.size.width){
//        [self showCloseInfo:NO event:event];
//    }
//
    [self showCloseInfo:NO event:event];
    
//    NSLog(@"mouseExited ....event:%@", event);

}

- (void)mouseMoved:(NSEvent *)event{
    [self showCloseInfo:YES event:event];
//    NSLog(@"mouseMoved ....event:%@", event);
}

- (void)showCloseInfo:(BOOL)show event:(NSEvent *)event{

    if(show && event){
        NSPoint event_location = [event locationInWindow];
        NSPoint local_point = [self convertPoint:event_location fromView:nil];
        if(local_point.y > 11 && local_point.y < self.frame.size.height - 11){
            [_closeContainer setHidden:NO];
            [_memoryField setHidden:YES];

            CGFloat closeContainerRightOffset = 20;
            CGFloat offset = closeContainerRightOffset + 10; // 10为增大响应范围.
            if(local_point.x > self.bounds.size.width - self.closeContainer.bounds.size.width  - offset){
                [self showBubble];
            }else{
                [self dismissCloseProcessBubble:show];
            }

        }
    }else{
        [_closeContainer setHidden:YES];
        [_memoryField setHidden:NO];
        [self dismissCloseProcessBubble:show];
    }
}

- (void)dismissCloseProcessBubble:(BOOL)show
{
    if(self.bubble){
        [self.bubble dismiss];
        if (!show) {
            self.bubble = nil;
        }
    }
}

- (void)showBubble
{
    if(self.bubble && [self.bubble isVisible]){
        return;
    }
    
    QMBubble *bubble = [self setupBubble];
    bubble.distance = 30;
    if (bubble.isVisible && !bubble.attachedToParentWindow) return;
    
    NSPoint centerXPosition = NSMakePoint(self.closeImageView.frame.origin.x + self.closeImageView.frame.size.width / 2, self.closeImageView.frame.origin.y);
    NSPoint pointInWindow = [self.closeImageView.window.contentView convertPoint:centerXPosition fromView:self.closeContainer];

    [bubble showToPoint:pointInWindow ofWindow:[self.closeImageView window]];
}

- (QMBubble *)setupBubble
{
    if (!_bubble) {
        _bubble = [[QMBubble alloc] init];
        _bubble.distance = 30;
        _bubble.keyWindow = YES;
        _bubble.draggable = NO;
        [_bubble setCornerRadius:4.0];
        [_bubble setArrowHeight:6.0];
        [_bubble setArrowWidth:10.0];
        [_bubble setBorderColor:[NSColor clearColor]];
        [_bubble setBackgroudColor:[LMAppThemeHelper getTipsViewBgColor]];
        QMArrowDirection direction = QMArrowTopRight;
        _bubble.arrowDistance = 20;
        _bubble.direction = direction;
        _bubble.animation = NO;

        MessageViewController *controller = [[MessageViewController alloc] init];
        [_bubble setContentView:controller.view];
    }
    return _bubble;
}

// 触发杀进程时(不一定是当前 cell 对于的进程被杀), 必须取消 提示窗口 的显示(防止如果进程被杀,响应的cell 对应的提示窗口要取消显示,否则会出现进程列表中 cell不满五个时,同时有多个提示窗口的问题).
-(void)onKillProcess:(NSNotification*)notificer{
    [self showCloseInfo:NO event:nil];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end


@implementation MessageViewController


- (instancetype)initWithMessage:(NSString *)message andPadding:(CGFloat)padding
{
    self = [super init];
    if( self )
    {
        [self loadView];
        self.message = message;
    }
    return self;
}

- (void)loadView
{
    NSRect rect = NSMakeRect(0, 0, 250, 27);
    NSView *view = [[NSView alloc] initWithFrame:rect];
    self.view = view;
    [self viewDidLoad];
}

-(void)viewDidLoad
{
    NSTextField *messageLabel = [LMViewHelper createNormalLabel:12 fontColor:[LMAppThemeHelper getTipsTextColor]];
    [self.view addSubview:messageLabel];
    self.messageLabel = messageLabel;
    self.messageLabel.stringValue =  NSLocalizedStringFromTableInBundle(@"LMMemoryCellView_viewDidLoad_messageLabel_1", nil, [NSBundle bundleForClass:[self class]], @"");
    
    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.centerX.equalTo(self.view);
    }];
  
}

- (void)setMessage:(NSString *)message
{
    _message = message;
    self.messageLabel.stringValue = message;
    
    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.centerX.equalTo(self.view);
    }];
}

@end
