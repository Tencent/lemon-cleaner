//
//  OwlViewController.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlViewController.h"
#import <QMUICommon/COSwitch.h>
#import "OwlWindowController.h"
#import "OwlLogViewController.h"
#import "OwlWhiteListViewController.h"
#import "OwlManager.h"
#import "OwlConstant.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/NSFontHelper.h>
#import "QMUserNotificationCenter.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import "LemonDaemonConst.h"

@interface OwlBorderView : NSView

@end

@implementation OwlBorderView
- (void)drawRect:(NSRect)dirtyRect{
    [super drawRect:dirtyRect];
}
@end

@interface OwlContentView : NSVisualEffectView

@end

@implementation OwlContentView
- (void)drawRect:(NSRect)dirtyRect{
    [super drawRect:dirtyRect];
}
@end


@interface OwlViewController () <NSUserNotificationCenterDelegate>
@property (nonatomic, strong) NSView *loadingView;
@property (nonatomic, strong) NSView *ccView;
@property (nonatomic, strong) NSButton *wlistBtn;
@property (nonatomic, strong) OwlContentView *bottomBgView;
@property(weak) COSwitch *vedioSwitch;
@property(weak) COSwitch *audioSwitch;
@end

@implementation OwlViewController

- (NSView*)buildBoxView{
    NSView *view = [[NSView alloc] init];
    CALayer *borderLayer = [[CALayer alloc] init];
    borderLayer.borderColor = [NSColor colorWithWhite:0.94 alpha:1].CGColor;
    borderLayer.borderWidth = 0;
    borderLayer.cornerRadius = 4;
    view.layer = borderLayer;
    return view;
}
- (NSTextField*)buildLabel:(NSString*)title font:(NSFont*)font color:(NSColor*)color{
    NSTextField *labelTitle = [[NSTextField alloc] init];
    labelTitle.stringValue = title;
    labelTitle.font = font;
    labelTitle.alignment = NSTextAlignmentCenter;
    labelTitle.bordered = NO;
    labelTitle.editable = NO;
    labelTitle.textColor = color;
    return labelTitle;
}
- (NSView*)buildCircleView{
    NSView *view = [[NSView alloc] init];
    CALayer *layer = [[CALayer alloc] init];
    layer.backgroundColor = [NSColor lightGrayColor].CGColor;
    layer.cornerRadius = 50;
    view.layer = layer;
    view.alphaValue = 0.2;
    return view;
}

- (instancetype)initWithFrame:(NSRect)frame{
    self = [super init];
    if (self) {
        OwlContentView *containView = [[OwlContentView alloc] initWithFrame:frame];
        _loadingView = [[NSView alloc] initWithFrame:frame];
        _ccView = [[NSView alloc] initWithFrame:frame];
        CALayer *layer = [[CALayer alloc] init];
        layer.backgroundColor = [NSColor whiteColor].CGColor;
        _ccView.layer = layer;
        self.view = containView;
        if ([OwlManager shareInstance].isFetchDataFinish) {
            [self setFinishUI:frame];
        } else {
            [self setLoadingUI:frame];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(whiteListChange:) name:OwlWhiteListChangeNotication object:nil];
        [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                       forKey:@"OwlVideoCheckOnceNotification"];
        [[QMUserNotificationCenter defaultUserNotificationCenter] addDelegate:(id<NSUserNotificationCenterDelegate>)self
                                                                       forKey:@"OwlAudioCheckOnceNotification"];
        
        //NSTableView
    }
    return self;
}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.ccView];
    self.vedioSwitch.offFillColor = [LMAppThemeHelper getFixedMainBgColor];
    self.audioSwitch.offFillColor = [LMAppThemeHelper getFixedMainBgColor];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.wlWindowController) {
        [self.wlWindowController close];
        self.wlWindowController = nil;
    }
    if (self.logWindowController) {
        [self.logWindowController close];
        self.logWindowController = nil;
    }
}
- (void)removeNotifyDelegate{
    [[QMUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotificationWithKey:@"OwlVideoCheckOnceNotification" flagsBlock:nil];
    [[QMUserNotificationCenter defaultUserNotificationCenter] removeScheduledNotificationWithKey:@"OwlAudioCheckOnceNotification" flagsBlock:nil];
}
- (void)whiteListChange:(NSNotification*)no{
    _wlistBtn.title = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"OwlViewController_whiteListChange_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""), (unsigned long)[OwlManager shareInstance].wlArray.count];
}

- (void)setLoadingUI:(NSRect)frame{
    NSLog(@"owl setLoadingUI");
    [self.ccView removeFromSuperview];
    [self.view addSubview:self.loadingView];
    NSProgressIndicator *indicator = [[NSProgressIndicator alloc] init];
    indicator.style = NSProgressIndicatorStyleSpinning;
    [_loadingView addSubview:indicator];
    NSTextField *loadingLabelSpec = [self buildLabel:NSLocalizedStringFromTableInBundle(@"OwlViewController_setLoadingUI_loadingLabelSpec _1", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFont systemFontOfSize:18]color:[NSColor lightGrayColor]];
    loadingLabelSpec.backgroundColor = [NSColor clearColor];
    [_loadingView addSubview:loadingLabelSpec];
    [indicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.loadingView);
        make.centerY.equalTo(self.loadingView).offset(-20);
        make.width.height.equalTo(@48);
    }];
    [loadingLabelSpec mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.loadingView);
        make.centerY.equalTo(self.loadingView).offset(20);
    }];
    
    [indicator startAnimation:nil];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (![OwlManager shareInstance].isFetchDataFinish)
        {
            sleep(1);
            [[OwlManager shareInstance] loadOwlDataFromMonitor];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf setFinishUI:frame];
            [indicator stopAnimation:nil];
        });
    });
}
- (void)setFinishUI:(NSRect)frame{
    NSLog(@"owl setFinishUI");
    [self.loadingView removeFromSuperview];
    [self.view addSubview:self.ccView];
    
    NSTextField *labelTitle = [self buildLabel:NSLocalizedStringFromTableInBundle(@"OwlViewController_setFinishUI_labelTitle _1", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFont systemFontOfSize:32]color:[LMAppThemeHelper getTitleColor]];
    labelTitle.backgroundColor = [NSColor clearColor];
    [self.ccView addSubview:labelTitle];
    //    NSTextField *labelSpec = [self buildLabel:@"保护你的摄像头和麦克风安全" font:[NSFont systemFontOfSize:12]color:[NSColor darkGrayColor]];
    //    [contentView addSubview:labelSpec];
    
    //NSLog(@"NSFontWeightMedium: %f", NSFontWeightMedium); //NSFontWeightMedium = 0.23。// -1 1。0
    NSFont *origFont = [NSFont systemFontOfSize:32];
    NSFontDescriptor* origDescriptor = origFont.fontDescriptor;
    NSFontDescriptor* newDescriptor = [origDescriptor fontDescriptorByAddingAttributes:@{ NSFontTraitsAttribute: @{ NSFontWeightTrait: @(0.0) } }];
    NSFont* newFont = [NSFont fontWithDescriptor:newDescriptor size:origFont.pointSize];
    [labelTitle setFont:newFont];
    
    NSView *vedioView = [self buildBoxView];
    [self.ccView addSubview:vedioView];
    NSView *audioView = [self buildBoxView];
    [self.ccView addSubview:audioView];
    
    //    NSView *bgCircleVedioView = [self buildCircleView];
    //    [vedioView addSubview:bgCircleVedioView];
    //    NSView *bgCircleAudioView = [self buildCircleView];
    //    [audioView addSubview:bgCircleAudioView];
    
    NSImageView *vedioImageView = [[NSImageView alloc] init];
    [vedioView addSubview:vedioImageView];
    NSImageView *audioImageView = [[NSImageView alloc] init];
    [audioView addSubview:audioImageView];
    
    NSTextField *vedioLabelTitle = [self buildLabel:NSLocalizedStringFromTableInBundle(@"OwlViewController_setFinishUI_vedioLabelTitle _2", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFont systemFontOfSize:20]color:[LMAppThemeHelper getTitleColor]];
    vedioLabelTitle.backgroundColor = [NSColor clearColor];
    [vedioView addSubview:vedioLabelTitle];
    NSTextField *vedioLabelSpec = [self buildLabel:NSLocalizedStringFromTableInBundle(@"OwlViewController_setFinishUI_vedioLabelSpec _3", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x94979B]];
    vedioLabelSpec.backgroundColor = [NSColor clearColor];
    [vedioView addSubview:vedioLabelSpec];
    
    NSTextField *audioLabelTitle = [self buildLabel:NSLocalizedStringFromTableInBundle(@"OwlViewController_setFinishUI_audioLabelTitle _4", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFont systemFontOfSize:20]color:[LMAppThemeHelper getTitleColor]];
    audioLabelTitle.backgroundColor = [NSColor clearColor];
    [audioView addSubview:audioLabelTitle];
    
    NSTextField *audioLabelSpec = [self buildLabel:NSLocalizedStringFromTableInBundle(@"OwlViewController_setFinishUI_audioLabelSpec _5", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12]color:[NSColor colorWithHex:0x94979B]];
    audioLabelSpec.backgroundColor = [NSColor clearColor];
    [audioView addSubview:audioLabelSpec];
    
    COSwitch *vedioSwitch = [[COSwitch alloc] init];
    self.vedioSwitch = vedioSwitch;
    __weak typeof(self) weakSelf = self;
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    [vedioSwitch setOnValueChanged:^(COSwitch *button) {
        [[OwlManager shareInstance] setWatchVedio:button.on toDb:YES];
        if (button.on) {
            vedioImageView.image = [bundle imageForResource:@"owl_vedio_nomal"];
            [weakSelf showToastForFirst:YES];
        } else {
            vedioImageView.image = [bundle imageForResource:@"owl_vedio_disable"];
        }
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:OwlWatchVedioStateChange
                                                                       object:nil
                                                                     userInfo:@{@"state":[NSNumber numberWithBool:button.on]}
                                                           deliverImmediately:YES];
        [[NSUserDefaults standardUserDefaults] setBool:button.on forKey:K_IS_WATCHING_VEDIO];
    }];
    vedioSwitch.on = [[OwlManager shareInstance] isWatchVedio];
    if (vedioSwitch.on) {
        vedioImageView.image = [bundle imageForResource:@"owl_vedio_nomal"];
    } else {
        vedioImageView.image = [bundle imageForResource:@"owl_vedio_disable"];
    }
    [vedioView addSubview:vedioSwitch];
    COSwitch *audioSwitch = [[COSwitch alloc] init];
    self.audioSwitch = audioSwitch;
    [audioSwitch setOnValueChanged:^(COSwitch *button) {
        [[OwlManager shareInstance] setWatchAudio:button.on toDb:YES];
        if (button.on) {
            audioImageView.image = [bundle imageForResource:@"owl_audio_nomal"];
            [weakSelf showToastForFirst:NO];
        } else {
            audioImageView.image = [bundle imageForResource:@"owl_audio_disable"];
        }
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:OwlWatchAudioStateChange
                                                                       object:nil
                                                                     userInfo:@{@"state":[NSNumber numberWithBool:button.on]}
                                                           deliverImmediately:YES];
        [[NSUserDefaults standardUserDefaults] setBool:button.on forKey:K_IS_WATCHING_AUDIO];
    }];
    audioSwitch.on = [[OwlManager shareInstance] isWatchAudio];
    if (audioSwitch.on) {
        audioImageView.image = [bundle imageForResource:@"owl_audio_nomal"];
    } else {
        audioImageView.image = [bundle imageForResource:@"owl_audio_disable"];
    }
    [audioView addSubview:audioSwitch];
    
    self.bottomBgView = [[OwlContentView alloc] init];
    //    CALayer *bgLayer = [[CALayer alloc] init];
    //    bgLayer.backgroundColor = [NSColor colorWithWhite:0.95 alpha:1].CGColor;
    //    bottomBgView.layer = bgLayer;
    [self.ccView addSubview:self.bottomBgView];
    
    
    NSView *bLineview = [[NSView alloc] init];
    CALayer *lineLayer = [[CALayer alloc] init];
    lineLayer.backgroundColor = [NSColor colorWithWhite:0.87 alpha:1].CGColor;
    bLineview.layer = lineLayer;
    [self.bottomBgView addSubview:bLineview];
    
    NSButton *logBtn = [[NSButton alloc] init];
    logBtn.title = NSLocalizedStringFromTableInBundle(@"OwlViewController_setFinishUI_logBtn_6", nil, [NSBundle bundleForClass:[self class]], @"");
    [logBtn setButtonType:NSButtonTypeMomentaryChange];
    logBtn.target = self;
    logBtn.action = @selector(clickLogBtn:);
    logBtn.bordered = NO;
    logBtn.font = [NSFont systemFontOfSize:12];
    [self.bottomBgView addSubview:logBtn];
    
    _wlistBtn = [[NSButton alloc] init];
    _wlistBtn.title = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"OwlViewController_setFinishUI_NSString_7", nil, [NSBundle bundleForClass:[self class]], @""), (unsigned long)[OwlManager shareInstance].wlArray.count];
    [_wlistBtn setButtonType:NSButtonTypeMomentaryChange];
    _wlistBtn.target = self;
    _wlistBtn.action = @selector(clickWlistBtn:);
    _wlistBtn.bordered = NO;
    _wlistBtn.font = [NSFont systemFontOfSize:12];
    [self.bottomBgView addSubview:_wlistBtn];
    
    int space = 10;
    int width = 268;
    int height = 250;
    [labelTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.ccView.mas_top).offset(OwlWindowTitleHeight + 6);
        make.left.right.mas_equalTo(self.ccView);
    }];
    //    [labelSpec mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.top.equalTo(labelTitle.mas_bottom).offset(10);
    //        make.left.right.equalTo(contentView);
    //    }];
    [vedioView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(labelTitle.mas_bottom).offset(space*3);
        make.right.equalTo(self.ccView.mas_centerX).offset(-20);
        make.width.equalTo(@(width));
        make.height.equalTo(@(height));
    }];
    [audioView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(labelTitle.mas_bottom).offset(space*3);
        make.left.equalTo(self.ccView.mas_centerX).offset(20);
        make.width.equalTo(@(width));
        make.height.equalTo(@(height));
    }];
    //    [bgCircleVedioView mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.top.equalTo(@0).offset(space);
    //        make.centerX.equalTo(vedioView);
    //        make.width.height.equalTo(@100);
    //    }];
    //    [bgCircleAudioView mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.top.equalTo(@0).offset(space);
    //        make.centerX.equalTo(audioView);
    //        make.width.height.equalTo(@100);
    //    }];
    [vedioImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0).offset(34);
        make.centerX.equalTo(vedioView);
        make.width.height.equalTo(@86);
    }];
    [audioImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0).offset(34);
        make.centerX.equalTo(audioView);
        make.width.height.equalTo(@86);
    }];
    [vedioLabelTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(vedioImageView.mas_bottom).offset(space);
        make.left.right.equalTo(vedioView);
    }];
    [vedioLabelSpec mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(vedioLabelTitle.mas_bottom).offset(space/2);
        make.left.right.equalTo(vedioView);
    }];
    [audioLabelTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(audioImageView.mas_bottom).offset(space);
        make.left.right.equalTo(audioView);
    }];
    [audioLabelSpec mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(audioLabelTitle.mas_bottom).offset(space/2);
        make.left.right.equalTo(audioView);
    }];
    [vedioSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(vedioLabelSpec.mas_bottom).offset(27);
        make.centerX.equalTo(vedioView);
        make.width.equalTo(@(60));
        make.height.equalTo(@(28));
    }];
    [audioSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(audioLabelSpec.mas_bottom).offset(27);
        make.centerX.equalTo(audioView);
        make.width.equalTo(@(60));
        make.height.equalTo(@(28));
    }];
    [self.bottomBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(vedioView.mas_bottom).offset(60);
        make.bottom.equalTo(self.ccView);
        make.left.right.equalTo(self.ccView);
    }];
    [logBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomBgView);
        make.left.equalTo(self.ccView.mas_left).offset(space*3);
    }];
    [bLineview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomBgView);
        make.left.equalTo(logBtn.mas_right).offset(space/2);
        make.height.equalTo(@10);
        make.width.equalTo(@1);
    }];
    [_wlistBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.bottomBgView);
        make.left.equalTo(logBtn.mas_right).offset(space+1);
    }];
    NSLog(@"owl setFinishUI end");
}
- (void)showToastForFirst:(BOOL)isVedio{
    BOOL isShow = NO;
    if (isVedio) {
        NSString *strFirst = [[NSUserDefaults standardUserDefaults] objectForKey:@"kLemonVedioFirstUsing"];
        if (!strFirst) {
            isShow = YES;
            [[NSUserDefaults standardUserDefaults] setObject:@"strFirst" forKey:@"kLemonVedioFirstUsing"];
        }
    } else {
        NSString *strFirst = [[NSUserDefaults standardUserDefaults] objectForKey:@"kLemonAudioFirstUsing"];
        if (!strFirst) {
            isShow = YES;
            [[NSUserDefaults standardUserDefaults] setObject:@"strFirst" forKey:@"kLemonAudioFirstUsing"];
        }
    }
    if (isShow) {
        NSLog(@"showToastForFirst");
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title =  isVedio ? NSLocalizedStringFromTableInBundle(@"OwlViewController_showToastForFirst_notification_4", nil, [NSBundle bundleForClass:[self class]], @"") :
        NSLocalizedStringFromTableInBundle(@"OwlViewController_showToastForFirst_notification_1", nil, [NSBundle bundleForClass:[self class]], @"");
        notification.informativeText = isVedio ? NSLocalizedStringFromTableInBundle(@"OwlViewController_showToastForFirst_notification_5", nil, [NSBundle bundleForClass:[self class]], @"") :
        NSLocalizedStringFromTableInBundle(@"OwlViewController_showToastForFirst_notification_2", nil, [NSBundle bundleForClass:[self class]], @"");
        notification.hasActionButton = NO;
        notification.otherButtonTitle = NSLocalizedStringFromTableInBundle(@"OwlViewController_showToastForFirst_1553136870_3", nil, [NSBundle bundleForClass:[self class]], @"");
        notification.identifier = [NSString stringWithFormat:@"%@.TimeUpNotification type:%d time:%@", [[NSBundle mainBundle] bundleIdentifier], isVedio, [[NSDate date] description]];
        //[notification setDeliveryDate: [NSDate dateWithTimeIntervalSinceNow: 3]];
        //[[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
        if (isVedio) {
            [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification
                                                                                       key:@"OwlVideoCheckOnceNotification"];
        } else {
            [[QMUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification
                                                                                       key:@"OwlAudioCheckOnceNotification"];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSUserNotificationCenter * center = [NSUserNotificationCenter defaultUserNotificationCenter];
            [center removeDeliveredNotification:notification];
        });
    }
}
#pragma mark NSUserNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    [center removeDeliveredNotification:notification];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    [center removeDeliveredNotification:notification];
}
- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDismissAlert:(NSUserNotification *)notification{
    [center removeDeliveredNotification:notification];
}
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}
- (void)clickLogBtn:(id)sender{
    if (!self.logWindowController) {
        NSRect prect = self.view.window.frame;
        NSRect srect = NSMakeRect(prect.origin.x + (prect.size.width - OwlWindowWidth) / 2, prect.origin.y + (prect.size.height - OwlWindowHeight) / 2, OwlWindowWidth, OwlWindowHeight);
        NSViewController *viewController = [[OwlLogViewController alloc] initWithFrame:srect];
        self.logWindowController = [[OwlWindowController alloc] initViewController:viewController];
        [self.view.window addChildWindow:self.logWindowController.window ordered:NSWindowAbove];
        [self.logWindowController showWindow:nil];
        [self.logWindowController.window setFrame:srect display:NO];
    } else {
        [self.logWindowController showWindow:nil];
    }
}
- (void)clickWlistBtn:(id)sender{
    if (!self.wlWindowController) {
        NSRect prect = self.view.window.frame;
        NSRect srect = NSMakeRect(prect.origin.x + (prect.size.width - OwlWindowWidth) / 2, prect.origin.y + (prect.size.height - OwlWindowHeight) / 2, OwlWindowWidth, OwlWindowHeight);
        NSViewController *viewController = [[OwlWhiteListViewController alloc] initWithFrame:srect];
        self.wlWindowController = [[OwlWindowController alloc] initViewController:viewController];
        [self.view.window addChildWindow:self.wlWindowController.window ordered:NSWindowAbove];
        [self.wlWindowController showWindow:nil];
        [self.wlWindowController.window setFrame:srect display:NO];
    } else {
        [self.wlWindowController showWindow:nil];
    }
}

@end
