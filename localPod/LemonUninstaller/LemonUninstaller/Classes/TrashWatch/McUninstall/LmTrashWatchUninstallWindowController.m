//
//  McUninstallWindowController.m
//  QQMacMgrAgent
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "LmTrashWatchUninstallWindowController.h"
#import <QMCoreFunction/QMExtension.h>
#import <QMCoreFunction/QMStatusItem.h>
#import "McUninstallSelectedViewController.h"
#import <QMCoreFunction/NSBundle+LMLanguage.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/LMCommonHelper.h>
#import <QMUICommon/GetFullAccessWndController.h>
#import <QMCoreFunction/QMFullDiskAccessManager.h>

#pragma mark -
#pragma mark 蓝色背景的进度条

@interface McUninstallProgressView : NSView
@property (nonatomic, assign) double doubleValue;
@end

@implementation McUninstallProgressView
@synthesize doubleValue;

- (double)doubleValue
{
    return doubleValue;
}

- (void)setDoubleValue:(double)value
{
    doubleValue = value;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:NSHeight(self.bounds)/2 yRadius:NSHeight(self.bounds)/2];
    
    [[NSColor intlGrayColor] set];
    [bezierPath fill];
    
    [[NSColor intlGreenColor] set];
    NSRect rect = self.bounds;
    rect.size.width *= doubleValue;
    NSRectClip(rect);
    [bezierPath fill];
}

@end

#pragma mark -
#pragma mark McUninstallWindowController

@interface LmTrashWatchUninstallWindowController ()<McUninstallSelectedDelegate>
{
    McUninstallSelectedViewController *selectedVC;
    NSTimer *closeTimer;
    NSSize initSize;
    size_t _totalSize;
    NSUInteger _selectedCount;
}

@property (strong,nonatomic) GetFullAccessWndController *getFullAccessWndController;

@end

@implementation LmTrashWatchUninstallWindowController
@synthesize delegate;

- (id)init
{
    //hook 多语言
    NSString *languageString = [LanguageHelper getCurrentUserLanguageByReadFile];
    if(languageString != nil){
        [NSBundle setLanguage:languageString bundle:[NSBundle bundleForClass:[LmTrashWatchUninstallWindowController class]]];
    }
    
    self = [super initWithWindowNibName:@"LmTrashWatchUninstallWindowController"];
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self.window setMovableByWindowBackground:YES];
    [self.window setLevel:kCGDockWindowLevel];
    NSView *view = self.window.contentView.superview;
    view.wantsLayer = YES;
    if ([LMCommonHelper isMacOS11]) {
        view.layer.cornerRadius = 10;
    } else {
        view.layer.cornerRadius = 5;
    }
    
    //TODO:没有考虑在窗口打开时切换主题样式的情况，此时切换主题，窗口样式不会变化
    [self.window setBackgroundColor:[LMAppThemeHelper getMainBgColor]];

    [self.window setOpaque:NO];
    initSize = [alertView frame].size;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppDelectProgress:)
                                                 name:LMNotificationDelectProgress
                                               object:nil];
    
    [self setupI18nView];
}


// 多语言
- (void)setupI18nView
{

    [alertCancelButton setTitle:NSLocalizedStringFromTableInBundle(@"ButtonCancel", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alertCancelButton setFocusRingType:NSFocusRingTypeNone];
    [alertOKButton setTitle:NSLocalizedStringFromTableInBundle(@"ButtonUninstall", nil, [NSBundle bundleForClass:[self class]], @"")];
    [sucessButton setTitle:NSLocalizedStringFromTableInBundle(@"ButtonOK", nil, [NSBundle bundleForClass:[self class]], @"")];

}


- (void)show
{
    [alertCancelButton mouseExited:nil];
    [alertOKButton mouseExited:nil];
    [sucessButton mouseExited:nil];
    
    [self window];//防止Window还未初使化
    [self alertSetup];
}

- (void)closeAll
{
    selectedVC = nil;
    [alertIconView setImage:nil];
    [progressIconView setImage:nil];
    [self.window orderOut:nil];
    if (closeTimer)
    {
        [closeTimer invalidate];
        closeTimer = nil;
    }
    if ([delegate respondsToSelector:@selector(uninstallFinished:)])
    {
        [delegate performSelector:@selector(uninstallFinished:) withObject:self];
    }
}

//指定显示View,并展示切换动画
- (void)changeView:(NSView *)aView
{
    NSRect currentFrame = self.window.frame;
    NSRect changeFrame = NSZeroRect;
    changeFrame.origin.x = NSMinX(currentFrame)-(NSWidth(aView.frame)-NSWidth(currentFrame))/2;
    changeFrame.origin.y = NSMinY(currentFrame)-(NSHeight(aView.frame)-NSHeight(currentFrame))/2;
    changeFrame.size = aView.frame.size;
    
    //保证让视图不超出屏幕
    NSRect visibleFrame = [[NSScreen mainScreen] visibleFrame];
    if (NSMinX(changeFrame)<NSMinX(visibleFrame)) changeFrame.origin.x = NSMinX(visibleFrame);
    if (NSMinY(changeFrame)<NSMinY(visibleFrame)) changeFrame.origin.y = NSMinY(visibleFrame);
    if (NSMaxX(changeFrame)>NSMaxX(visibleFrame)) changeFrame.origin.x = NSMaxX(visibleFrame)-NSWidth(changeFrame);
    if (NSMaxY(changeFrame)>NSMaxY(visibleFrame)) changeFrame.origin.y = NSMaxY(visibleFrame)-NSHeight(changeFrame);
    [self showView:aView frame:changeFrame];
    [LMAppThemeHelper setDivideLineColorFor:successLineView];
}

- (void)showView:(NSView *)aView frame:(NSRect)frame
{
    [self.window setFrame:frame display:YES];
    [[self.window animator] setContentView:aView];
}

- (NSAttributedString *)attributedWithString:(NSString *)string keywordsRange:(NSRange)range
{
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:string
                                                                                      attributes:@{NSForegroundColorAttributeName: [LMAppThemeHelper getTitleColor],
                                                                                                   NSFontAttributeName: [NSFont systemFontOfSize:13.0]}];
    [attributedStr addAttribute:NSForegroundColorAttributeName value:[NSColor intlBlueColor] range:range];
    return attributedStr;
}

#pragma mark -
#pragma mark 弹出有残留文件的界面

- (void)alertSetup
{
    [alertTitleView setStringValue:NSLocalizedStringFromTableInBundle(@"McUninstallWindowController_alertSetup_alertTitleView_1", nil, [NSBundle bundleForClass:[self class]], @"")];

    NSString *sizeString = [NSString stringFromDiskSize:_soft.totalSize];
    NSString *alertString = [NSString stringWithFormat:
                             NSLocalizedStringFromTableInBundle(@"McUninstallWindowController_alertSetup_1553842683_2", nil, [NSBundle bundleForClass:[self class]], @""),
                             [_soft.showName truncatesString:QMTruncatingTail length:16],
                             sizeString];
    NSAttributedString *attString = [self attributedWithString:alertString keywordsRange:[alertString rangeOfString:sizeString]];
    
    [alertMessageView setAttributedStringValue:attString];
    [alertIconView setImage:_soft.icon];
    
    
    [alertView setFrameSize:initSize];
    [LMAppThemeHelper setDivideLineColorFor:alertLineView];
    
    NSRect frame;
    frame.size = alertView.frame.size;
    frame.origin.x = NSMaxX([[NSScreen mainScreen] visibleFrame])-NSWidth(frame)-20;
    frame.origin.y = NSMaxY([[NSScreen mainScreen] visibleFrame])-NSHeight(frame)-20;
    
    [self.window setAlphaValue:0];
    [self.window setContentView:alertView];
    [self.window setFrame:frame display:YES];
    [self.window makeKeyAndOrderFront:nil];
    [[self.window animator] setAlphaValue:1.0];
}

- (IBAction)alertCancelClick:(id)sender
{
    [self closeAll];
}

- (IBAction)alertOKClick:(id)sender
{
    if ([QMFullDiskAccessManager getFullDiskAuthorationStatus] != QMFullDiskAuthorationStatusAuthorized) {
        [self openFullDiskAccessSettingGuidePage];
        return;
    };
    
    [self selectSetup];
}

#pragma mark -
#pragma mark 用户选择卸载残留文件

- (void)selectSetup
{
    if (!selectedVC) {
        selectedVC = [[McUninstallSelectedViewController alloc] init];
        selectedVC.delegate = self;
    }
    selectedVC.soft = _soft;
    
    /*
    NSRect visibleFrame = [[NSScreen mainScreen] visibleFrame];
    NSRect frame = NSMakeRect(NSMidX(visibleFrame)-NSWidth(selectedVC.view.frame)/2,
                              NSMidY(visibleFrame)-NSHeight(selectedVC.view.frame)/2,
                              NSWidth(selectedVC.view.frame),
                              NSHeight(selectedVC.view.frame));
    [self showView:selectedVC.view frame:frame];
    */
    [self changeView:selectedVC.view];
}

#pragma mark -
#pragma mark 开始删除残留文件的进度界面

//- (void)progressSetup:(NSArray *)selectedArray
//{
//    [progressTitleView setTextColor:[NSColor intlTextColor]];
//    [progressTitleView setStringValue:@"正在卸载,请稍候..."];
//
//    [progressIconView setImage:soft.icon];
//    [self changeView:progressView];
//
//    //计算卸载的总大小
//    size_t totalSize = 0;
//    for (McSoftwareFileItem *item in selectedArray)
//        totalSize += item.fileSize;
//
//    //提前将结束界面的文字更新
//    NSString *sizeString = [NSString stringFromDiskSize:totalSize];
//    NSString *sucessTitle = [NSString stringWithFormat:@"清除卸载残留文件完成,帮您腾出%@磁盘空间.",
//                             sizeString];
//    NSAttributedString *attString = [self attributedWithString:sucessTitle keywordsRange:[sucessTitle rangeOfString:sizeString]];
//    [sucessTitleView setAttributedStringValue:attString];
//
//    //执行卸载任务
//    __unsafe_unretained McUninstallSoft *softwarePr = soft;
//    [soft removeItems:selectedArray :^(double progress) {
//        [progressLoadingView setDoubleValue:progress];
//    } :^(BOOL removeAll) {
//
//        //显示完成界面
//        [self sucessSetup];
//    }];
//}


- (void)beginDelProgress
{
//    [progressTitleView setTextColor:[NSColor intlTextColor]];
    [progressTitleView setStringValue:NSLocalizedStringFromTableInBundle(@"McUninstallWindowController_beginDelProgress_progressTitleView_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    
    [progressIconView setImage:_soft.icon];
    [self changeView:progressView];
    
    //计算卸载的总大小
    _totalSize = _soft.selectedSize;
    _selectedCount = _soft.selectedCount;

    //提前将结束界面的文字更新
    NSString *sizeString = [NSString stringFromDiskSize:_totalSize];
    NSString *sucessTitle = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"McUninstallWindowController_beginDelProgress_sucessTitle _2", nil, [NSBundle bundleForClass:[self class]], @""),
                             sizeString];
    NSAttributedString *attString = [self attributedWithString:sucessTitle keywordsRange:[sucessTitle rangeOfString:sizeString]];
    [sucessTitleView setAttributedStringValue:attString];
    
    NSLog(@"[TrashDel] %s %@", __FUNCTION__, _soft.bundleID );
    [_soft delSelectedItem];
    
}

- (void)onAppDelectProgress:(NSNotification *)notify
{
    if (!self.window || !progressLoadingView)
        return;
    
    if (self.soft != notify.object)
        return;
    
    double progress = [[notify.userInfo objectForKey:LMNotificationKeyDelProgress] doubleValue];
    BOOL isFinish = [[notify.userInfo objectForKey:LMNotificationKeyIsDelFinished] boolValue];
    NSLog(@"%s, uninstall progress %f", __FUNCTION__, progress);
    [progressLoadingView setDoubleValue:progress];
    LMLocalApp *app = notify.object;
    //卸载时如果没有移选择xxx.app，这时把progressView隐藏，btnRemove显示出来
//    if (isFinish && ![app isBundleItemDelected]) {
//        NSLog(@"uninstall end, soft:%@", app.showName);
//        [self.progressView setHidden:YES];
//        [self.btnRemove setHidden:NO];
//    }
    if (isFinish) {
        [self sucessSetup];
    }
}
#pragma mark -
#pragma mark 残留文件删除结果界面

- (void)sucessSetup
{
    [self changeView:sucessView];
    closeTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(closeAll) userInfo:nil repeats:NO];
}

- (IBAction)sucessOKClick:(id)sender
{
    [self closeAll];
}

#pragma mark -
#pragma mark McUninstallSelectedDelegate

- (void)selectedDidCancel:(McUninstallSelectedViewController*)viewController
{
    [self closeAll];
}

- (void)selectedDidDone:(McUninstallSelectedViewController*)viewController withSoft:(LMLocalApp *)soft
{
    [self beginDelProgress];
}

- (void)openFullDiskAccessSettingGuidePage {
    if (!self.getFullAccessWndController) {
        self.getFullAccessWndController = [GetFullAccessWndController shareInstance];
        if (@available(macOS 13.0, *)) {
            self.getFullAccessWndController.style = GetFullDiskPopVCStyleDefault;
        } else {
            self.getFullAccessWndController.style = GetFullDiskPopVCStyleMonitor;
        }
        [self.getFullAccessWndController setParaentCenterPos:[self getCenterPoint] suceessSeting:nil];
    }
    
    [self.getFullAccessWndController.window makeKeyAndOrderFront:nil];
}

- (CGPoint)getCenterPoint {
    CGPoint origin = [NSScreen mainScreen].frame.origin;
    CGSize size = [NSScreen mainScreen].frame.size;
    return CGPointMake(origin.x + size.width / 2, origin.y + size.height / 2);
}

@end
