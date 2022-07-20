//
//  LemonMainWndController.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#define kMinWindowWidth 383
#define kMaxWindowWidth 1000

#import "LemonMainWndController.h"
#import "LMMainViewController.h"
#import "LMToolViewController.h"
#import <LemonClener/CleanerCantant.h>
#import <LemonClener/LMCleanBigViewController.h>
#import <LemonClener/LMCleanResultViewController.h>
#import <LemonClener/MacDeviceHelper.h>
#import <LemonClener/LMCleanerDataCenter.h>
#import <QMCoreFunction/NSView+Extension.h>
#import <QMUICommon/SharedPrefrenceManager.h>
#import <QMCoreFunction/NSBundle+LMLanguage.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMUICommon/RatingUtils.h>
#import <QMCoreFunction/LMBookMark.h>
#import <QMCoreFunction/NSString+Extension.h>
#import <LemonSpaceAnalyse/McSpaceAnalyseWndController.h>

#define DOCK_ON_OFF_STATE         @"dock_on_off_state"
#define MAS_MONITOR_BUNDLE_ID     @"88L2Q4487U.com.tencent.LemonASMonitor"
#define MAS_SHOW_STATUS_BAR_GUIDE @"mas_show_status_bar_guide"
#define IS_APPSTORE_NEW_USER_14   @"is_appstore_new_user_14"
#define IS_GUIDE_THE_OLD_USER     @"is_guide_the_old_user"


@interface LemonMainWndController ()<NSWindowDelegate>

@property (weak) IBOutlet NSView *mainView;
@property (weak) IBOutlet NSView *toolView;
@property (weak) IBOutlet NSImageView *shadowView;
@property (weak) IBOutlet NSView *bigCleanView;
@property (strong, nonatomic) LMMainViewController *mainViewController;
@property (strong, nonatomic) LMToolViewController *toolViewController;
@property (strong, nonatomic) LMCleanBigViewController *bigCleanViewController;
@property (strong, nonatomic) LMCleanResultViewController *resultViewController;
@property (strong, nonatomic) NSTimer *animateTimer;

///保存收到通知中的flag，判断是展示大界面还是小界面
@property NSString * viewShowFlag;

@end

@implementation LemonMainWndController

- (id)init
{
    static dispatch_once_t onceToken;
    static LemonMainWndController *mainWindow;
    dispatch_once(&onceToken, ^{
        mainWindow = [super initWithWindowNibName:NSStringFromClass(self.class)];
    });
    return mainWindow;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    self.window.delegate = self;
    [self.window setStyleMask:NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskTitled | NSFullSizeContentViewWindowMask];
    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    NSArray *screens = [NSScreen screens];
    for (NSScreen *screen in screens) {
        NSLog(@"screen = %@", NSStringFromRect(screen.frame));
    }
    
    [self addNotification];
    [self initData];
    [self initView];
    if([SharedPrefrenceManager getBool:IS_SHOW_BIG_VIEW]){
        [self showToolView];
    }
}

-(void)addNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showOrCloseToolView:) name:SHOW_OR_CLOSE_TOOL_VIEW object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showOrCloseBigCleanView:) name:SHOW_OR_CLOSE_BIG_CLEAN_VIEW object:nil];
#ifdef APPSTORE_VERSION
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCleanTrasbFinished) name:MAS_CLEAN_TRASH_FINISH object:nil];
#endif
}

-(void)initData{
    NSString *language = [LanguageHelper getCurrentUserLanguage];
    if(language != nil){
        //hook 主清理多语言
        [NSBundle setLanguage:language bundle:[NSBundle bundleForClass:[LMCleanBigViewController class]]];
        [NSBundle setLanguage:language bundle:[NSBundle bundleForClass:[McSpaceAnalyseWndController class]]];
        //hook qmuicommon多语言
        [NSBundle setLanguage:language bundle:[NSBundle bundleForClass:[SharedPrefrenceManager class]]];
    }
    
    self.mainViewController = [[LMMainViewController alloc] init];
    self.toolViewController = [[LMToolViewController alloc] init];
    self.bigCleanViewController = [[LMCleanBigViewController alloc] init];
    self.resultViewController = [[LMCleanResultViewController alloc] init];
}

-(void)initView{
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    
    CGSize windowSize = self.window.frame.size;
    CGFloat screenWidth = [MacDeviceHelper getScreenWidth];
    CGFloat screenHeight = [MacDeviceHelper getScreenHeight];
    CGFloat menuBarHeight = [[[NSApplication sharedApplication] mainMenu] menuBarHeight];
    CGPoint newPoint = CGPointMake((screenWidth - windowSize.width) / 2, (screenHeight - windowSize.height - menuBarHeight) / 2);
    [self.window setFrame:NSMakeRect(newPoint.x, newPoint.y, 383, 618) display:YES];
    
    [self.bigCleanView addSubview:self.bigCleanViewController.view];
    [self.bigCleanView addSubview:self.resultViewController.view];
    [self.bigCleanView setHidden:YES];
    [self.mainView addSubview:self.mainViewController.view];
    [self.toolView addSubview:self.toolViewController.view];
    [self.toolView setHidden:YES];
    [self.toolView insertVibrancyViewBlendingMode:NSVisualEffectBlendingModeBehindWindow];
    NSLog(@"mainview = %@, conVIew = %@", NSStringFromRect(self.mainView.frame), NSStringFromRect(self.mainViewController.view.frame));
    [self.shadowView setAlphaValue:0.7];
}

-(void)hiddenMainViewAndToolView:(BOOL) isHidden{
    [self.mainView setHidden:isHidden];
    [self.toolView setHidden:isHidden];
}

#ifdef APPSTORE_VERSION
-(void)onCleanTrasbFinished{
    
    // 1.如果没有 show guide,优先 show guide
//    BOOL hasShowGuide = [SharedPrefrenceManager getBool:MAS_SHOW_STATUS_BAR_GUIDE];
//    NSLog(@"hasShowGuide ------- %hhd", hasShowGuide);

//    if(hasShowGuide)
//    {
//        LemonAsMonitorGuideViewController *controller = [[LemonAsMonitorGuideViewController alloc] initWithShowType:ShowTypeNew];
//        if(_mainViewController){
//            controller.parentViewController = _mainViewController;
//            [_mainViewController presentViewControllerAsModalWindow:controller];
//            [SharedPrefrenceManager putBool:YES withKey:MAS_SHOW_STATUS_BAR_GUIDE];
//        }
//
//        return;
//    }
//
    // 2.多次评分完成时,如果还没有显示过评分引导, 显示评分引导.
    
//    [RatingUtils showRatingViewControllerIfNeededAt:_mainViewController];
}

#endif

-(void)showOrCloseToolView:(NSNotification *)noti {
    [self setSelfWindowToolFrameSize:YES];
}

-(void)showOrCloseBigCleanView:(NSNotification *)noti{
    if (noti != nil) {
        NSDictionary *userInfo = noti.userInfo;
        NSString *flag = userInfo[@"flag"];
        self.viewShowFlag = flag;
        if ([flag isEqualToString:CLOSE_BIG_CLEAN_VIEW] || [flag isEqualToString:CLOSE_BIG_RESULT_VIEW]) {
            [self setSelfWindowToolFrameSize:NO];
            return;
        }else if([flag isEqualToString:OPEN_BIG_CLEAN_VIEW]){
            NSString *cleanViewType = userInfo[BIG_CLEAN_VIEW_TYPE];
            if ([cleanViewType isEqualToString:CLEAN_VIEW_TYPE_RESULT] || [cleanViewType isEqualToString:CLEAN_VIEW_TYPE_SCANNING]) {
                self.bigCleanViewController.fileMoveTotalNum = self.mainViewController.scanViewContoller.fileMoveTotalNum;
                [self.bigCleanViewController showScanBigView];
                self.mainViewController.scanViewContoller.fileMoveTotalNum = 0;
            }else if ([cleanViewType isEqualToString:CLEAN_VIEW_TYPE_NORESULT]){
                NSUInteger cleanFileNums = [userInfo[BIG_CLEAN_VIEW_FILE_NUMS] unsignedIntegerValue];
                NSUInteger cleanTime = [userInfo[BIG_CLEAN_VIEW_TIME] unsignedIntegerValue];
                [self.bigCleanViewController setNoResultViewWithScanFileNum:cleanFileNums scanTime:cleanTime];
            }else if ([cleanViewType isEqualToString:CLEAN_VIEW_TYPE_CLEANNING]){
                [self.bigCleanViewController showCleanBigView];
            }
            [self.bigCleanViewController.view setHidden:NO];
            [self.resultViewController.view setHidden:YES];
            
            //通知BigCleanViewController展示切换动画
            [self.bigCleanViewController showAnimate];
        }else if ([flag isEqualToString:OPEN_BIG_RESULT_VIEW]){
            NSUInteger cleanSize = [userInfo[BIG_RESULT_VIEW_FILE_SIZE] unsignedIntegerValue];
            NSUInteger cleanFileNums = [userInfo[BIG_RESULT_VIEW_FILE_NUMS] unsignedIntegerValue];
            NSUInteger cleanTime = [userInfo[BIG_RESULT_VIEW_TIME] unsignedIntegerValue];
            [self.resultViewController setResultViewWithCleanFileSize:cleanSize fileNum:cleanFileNums cleanTime:cleanTime];
            [self.bigCleanViewController.view setHidden:YES];
            [self.resultViewController.view setHidden:NO];
            
            //通知ResultViewController展示切换动画(added by levey)
            [self.resultViewController showAnimate];
        }
        [self setSelfWindowToolFrameSize:NO];
        [self.bigCleanView setHidden:NO];
        [self hiddenMainViewAndToolView:YES];
    }
}

-(CGPoint)getNewWindowPoint{
//    CGSize windowSize = self.window.frame.size;
    CGFloat windowWidth = 1000;
    CGFloat windowHeight = 618;
    CGFloat screenWidth = [MacDeviceHelper getScreenWidth];
    CGFloat screenHeight = [MacDeviceHelper getScreenHeight];
    CGFloat menuBarHeight = [[[NSApplication sharedApplication] mainMenu] menuBarHeight];
    CGPoint newPoint = CGPointMake((screenWidth - windowWidth) / 2, (screenHeight - windowHeight - menuBarHeight) / 2);
    return newPoint;
}

///展示大界面
-(void)showToolView{
    [self.toolView setHidden:NO];
    [self.shadowView setHidden:NO];
    CGPoint newPoint = [self getNewWindowPoint];
    [self.window setFrame:NSMakeRect(newPoint.x, newPoint.y, 1000, 618) display:YES];
    [self.toolView setFrameOrigin:NSMakePoint(383, 0)];
}

-(void)setSelfWindowToolFrameSize:(BOOL)isToolAnimate{
    CGPoint origin = self.window.frame.origin;
    CGSize size = self.window.frame.size;
    __weak LemonMainWndController* weakSelf = self;
    if (size.width <= 500) {
        [self.toolView setHidden:NO];
        [self.shadowView setHidden:NO];
        CGPoint newPoint = [self getBigNowOriginFormOldOrigin:origin];
//
        if (isToolAnimate) {
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                [context setDuration:0.5];
                context.allowsImplicitAnimation=YES;
                [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
                [[weakSelf.window animator] setFrame:NSMakeRect(newPoint.x, newPoint.y, 1000, 618) display:YES];
                [[weakSelf.toolView animator] setFrameOrigin:NSMakePoint(383, 0)];
            } completionHandler:^{
//                NSLog(@"All done!");
            }];
        }else{
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                [context setDuration:0.3];
                context.allowsImplicitAnimation=YES;
                [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
                if ([[LMCleanerDataCenter shareInstance] isBigPage]) {
                    [[weakSelf.window animator] setFrame:NSMakeRect(origin.x, origin.y, 1000, 618) display:YES];
                }else{
                    [[weakSelf.window animator] setFrame:NSMakeRect(origin.x, origin.y, 383, 618) display:YES];
                }
            } completionHandler:^{
//                NSLog(@"All done!");
            }];
        }
        
    }else if (size.width > 500){
        CGPoint newPoint = [self getSmallNowOriginFormOldOrigin:origin];
        if (isToolAnimate) {
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                [context setDuration:0.5];
                context.allowsImplicitAnimation=YES;
                [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
                [[weakSelf.window animator] setFrame:NSMakeRect(newPoint.x, newPoint.y, 383, 618) display:YES];
                [[weakSelf.toolView animator] setFrameOrigin:NSMakePoint(-234, 0)];
            } completionHandler:^{
//                NSLog(@"All done!");
                [self.toolView setHidden:YES];
                [self.shadowView setHidden:YES];
            }];
        }else{
            //在清理详情界面点击完成后，展示大界面（tool view）
            if([self.viewShowFlag isEqualToString:CLOSE_BIG_RESULT_VIEW]){
                [self showToolViewAfterCompeleteClean];
                self.viewShowFlag = @"";
                return;
            }
            //在清理详情界面点击返回后，展示小界面
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                [context setDuration:0.3];
                context.allowsImplicitAnimation=YES;
                [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
                if ([[LMCleanerDataCenter shareInstance] isBigPage]) {
                    [[weakSelf.window animator] setFrame:NSMakeRect(origin.x, origin.y, 1000, 618) display:YES];
                }else{
                    [[weakSelf.window animator] setFrame:NSMakeRect(origin.x, origin.y, 383, 618) display:YES];
                }
            } completionHandler:^{
//                NSLog(@"All done!");
                //大界面切换大界面时不执行，大界面切换小界面才执行(added by levey)
                if (weakSelf.window.frame.size.width < 500) {
                    //窗口变化结束再展示小界面（added by levey）
                    [self.bigCleanView setHidden:YES];
                    [self hiddenMainViewAndToolView:NO];
                    [self.toolView setHidden:YES];
                    [self.shadowView setHidden:YES];
                    
                    //通知ScanViewController展示切换动画(added by levey)
                    //在清理详情界面点击返回后，展示小界面，需要将toolViewBtn设置为非展开状态
                    NSDictionary *dict = @{K_SHOW_TOOL_VIEW_BTN_STATE:@(NO)};
                    [[NSNotificationCenter defaultCenter]postNotificationName:UPDATE_SHOW_TOOL_VIEW_BTN_STATE object:nil userInfo:dict];
                    [self.mainViewController showAnimate];
                }
            }];
        }
    }
}

///在清理详情界面点击完成后，展示大界面（tool view）
-(void)showToolViewAfterCompeleteClean{
    CGPoint origin = self.window.frame.origin;
    [self.window setFrame:NSMakeRect(origin.x, origin.y, 1000, 618) display:YES];
    [self.toolView setFrameOrigin:NSMakePoint(383, 0)];
    [self.bigCleanView setHidden:YES];
    [self hiddenMainViewAndToolView:NO];
    [self.toolView setHidden:NO];
    [self.shadowView setHidden:NO];
    NSDictionary *dict = @{K_SHOW_TOOL_VIEW_BTN_STATE:@(YES)};
    [[NSNotificationCenter defaultCenter]postNotificationName:UPDATE_SHOW_TOOL_VIEW_BTN_STATE object:nil userInfo:dict];
}

//展开工具界面抽屉动画时
-(CGPoint)getBigNowOriginFormOldOrigin:(CGPoint) oldOrigin{
    return [MacDeviceHelper getScreenOriginBig:oldOrigin];
}

//收缩工具界面抽屉动画
-(CGPoint)getSmallNowOriginFormOldOrigin:(CGPoint) oldOrigin{
    return [MacDeviceHelper getScreenOriginSmall:oldOrigin];
}

-(void)windowWillClose:(NSNotification *)notification{
#ifndef APPSTORE_VERSION
    BOOL isDockOn = [SharedPrefrenceManager getBool:DOCK_ON_OFF_STATE];
    if (!isDockOn) {
        [[NSApplication sharedApplication] terminate:self];
    }
#else
//    [[NSApplication sharedApplication] terminate:self];
#endif
}




@end




