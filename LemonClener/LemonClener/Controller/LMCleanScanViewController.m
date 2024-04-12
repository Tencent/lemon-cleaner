//
//  LMCleanScanViewController.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMCleanScanViewController.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import "QMCleanManager.h"
#import "CleanerCantant.h"
#import "LMCleanerDataCenter.h"
#import "CircleProportionView.h"
#import "CircleCleanImageView.h"
#import <QMUICommon/LMButton.h>
#import <QMCoreFunction/NSString+Extension.h>
#import "CategoryProgressView.h"
#import <QMUICommon/LMBorderButton.h>
#import "LMBackImageButton.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/QMProgressView.h>
#import <QMUICommon/SharedPrefrenceManager.h>
#import "CleanerCantant.h"
#import <QMUICommon/NSFontHelper.h>
#import "MacDeviceHelper.h"
#import "LMCategoryStateImageView.h"
#import <QMCoreFunction/LMBookMark.h>
#import <QMCoreFunction/NSString+Extension.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <QMCoreFunction/LanguageHelper.h>
#import "LMAppSandboxHelper.h"
#import <QMUICommon/RatingUtils.h>
#import <QMUICommon/LemonSuiteUserDefaults.h>
#import <QMUICommon/FullDiskAccessPermissionViewController.h>
#import "LMWebWindowController.h"
#import "LemonVCModel.h"
#import <QMUICommon/QMButton.h>
#import "LMMaskView.h"
#import "LMActivityCard.h"
#import "LMGSView.h"
#import "LMFileMoveIntroduceVC.h"
#import <LemonFileMove/LMFileMoveDefines.h>
#import <QMUICommon/GetFullAccessWndController.h>
#import <LemonStat/McSystemInfo.h>

#define kQMNetworkFileChangedNotificaton    @"QMNetworkFileChangedNotificaton"    //数据文件更新的通知
#define kCategoryNil    @"0"    //空占位
#define kCategorySys    @"1"    //系统垃圾
#define kCategoryApp    @"2"    //应用垃圾
#define kCategoryInt    @"3"    //上网垃圾

#define kGuideAnimateCount  60              //引导动画最大计数
#define kGuideBubbleCount   60              //引导气泡动画帧数
#define kGuideArrowCount    30              //引导箭头动画帧数
#define kGuideBubbleString  @"bubble_%05d"  //引导气泡动画文件名
#define kGuideArrowString   @"arrow_%05d"   //引导箭头动画文件名

#define kUpAnimatePointX        59          //动画上面部分的最终位置，跟BigView中Icon保持一致
#define kUpAnimatePointY        473         //动画上面部分的最终位置，跟BigView中Icon保持一致
#define kUpAnimateSizeW         88          //动画上面部分的最终大小，跟BigView中Icon保持一致
#define kAnimateDuration        0.15        //动画默认时长
#define kAnimateBottomTransY    -200        //动画下半部分的默认位移大小

#define MAS_SHOW_STATUS_BAR_GUIDE @"mas_show_status_bar_guide" //发送app store的通知
#define MAIN_APP_GET_DIR_PRIVACY @"main_app_get_dir_privacy"
#define UPDATE_APP_NAME         @"LemonUpdate.app"
#define CLOSE_TIP_505_ACTIVITY         @"CLOSE_TIP_505_ACTIVITY" // 关闭505新春活动
//设置各种Label在清理状态下的颜色
#define CLEAN_LABEL_TAEXT_COLOR_10_13 [NSColor colorNamed:@"title_color" bundle:[NSBundle mainBundle]] : [NSColor colorWithHex:0x94979B]
#define CLEAN_LABEL_TAEXT_COLOR_10_11 [NSColor colorWithHex:0x515151] : [NSColor colorWithHex:0x94979B]



#define K_CELAN_SELECTED_SIZE   totalSelectedSize     //实际清理的大小
#define K_TOTLE_SIZE            totalSize             //扫描出的垃圾大小

#define DEFAULT_APP_PATH        @"/Applications/Tencent Lemon.app"

#define kLemonUserDidEnterWeb_505 @"kLemonUserDidEnterWeb_505"              // 用户进入过web活动页


#define kLMFullAccessDisplayAfterInstallation_Count @"kLMFullAccessDisplayAfterInstallation_Count"
#define kLMFullAccessDisplayAfterInstallation_LastBootTime @"kLMFullAccessDisplayAfterInstallation_LastBootTime"
#define LemonFullAccessMaxDisplayAfterInstallation 2 // 最多展示2次

@interface LMCleanScanViewController ()<QMCleanManagerDelegate, CategoryProgressViewDelegate, ChooseCategoryDelegate, CAAnimationDelegate, NSOpenSavePanelDelegate, QMWindowDelegate, LMMaskViewDelegete, LMGSViewDelegete, LMFileMoveIntroduceVCDelegate>
{
    BOOL isDidAppear;
    UInt64 _totalSize;
    NSUInteger _nowCategoryId;
    UInt64 _itemRemoveSize;
    UInt64 _removeSize;
    NSUInteger _scanFileNums;
    NSUInteger _cleanFileNums;
    NSUInteger _startTimeInterval;
    NSUInteger _scanTime;
    NSUInteger _cleanTime;
    // selected
    UInt64 _totalSelectedSize;
    BOOL _isCloseToolView;
    
    NSString* _floatViewIdx;
    
    UInt64 _sysSelectSize;
    UInt64 _appSelectSize;
    UInt64 _intSelectSize;
    BOOL _canClickShowToolViewBtn;
    BOOL _isCleanOrChooseRubbish;
    
    BOOL _isShowGuide;
    NSTimer * _guideTimer;
    int _guideCount;
    BOOL _isBubbleShown;
    
    //扫描转圈动画
    NSTimer *_scanAniTimer;
    NSArray *_scanAniArray;
    //清理转圈动画
    NSTimer *_cleanAniTimer;
    NSArray *_cleanAniArray;
    NSInteger _currentCount;//当前扫描或者清理当前图片计数
    
    //将正常调用放到动画结束后（added by levey）
    NSInteger _isAnimateToShowScanView;         //动画计数，当减为0时继续正常调用
    NSInteger _isAnimateToShowBigCleanView;     //动画计数，当减为0时继续正常调用
    NSInteger _isAnimating;                     //动画计数，用于屏蔽动画中点击事件和跳转逻辑（切换动画同一时间只有一套，可以用一个计数简单处理）
    NSInteger _isAnimateToShowMainView;         //动画计数，当减为0时继续正常调用
    NSInteger _isAnimateToShowScanResView;      //动画计数，当减为0时继续正常调用
    NSInteger _isAnimateToShowCleanView;        //动画计数，当减为0时继续正常调用
    NSInteger _isAnimateToShowCleanResView;     //动画计数，当减为0时继续正常调用
    
    NSBundle *bundle;
    BOOL isUserGiveHomePathPermission;
    
    //动画计数，用于屏蔽动画中点击事件或跳转逻辑（切换动画同一时间只有一套，可以用一个计数简单处理）
    GetFullAccessWndController *_getFullAccessController;
    // 用于标记本次启动是否展示过首次安装的权限弹窗
    BOOL _isShowedFullAccessWhenFirstInstallation;
}
@property (assign, nonatomic) CleanStatus cleanStatus;
// 扫描的类别
@property (strong, nonatomic) NSArray *categoryArray;
// 记录扫描到各个类别的尺寸
@property (strong, nonatomic) NSMutableDictionary *currentResultSizeInfo;
//扫描剩余各个类别的尺寸
@property (strong, nonatomic) NSMutableDictionary *currentCleanSizeInfo;
// 扫描过程限制刷新频率
@property (strong, nonatomic) NSTimer *scantimer;
@property (assign, nonatomic) BOOL currentScanStop;
//清理过程timer
@property (strong, nonatomic) NSTimer *cleantimer;
@property (assign, nonatomic) BOOL currentCleanStop;
@property (assign, nonatomic) CGFloat cleanProgress;
//刷新路径timer
@property (strong, nonatomic) NSTimer *updatePathTimer;
@property (strong, nonatomic) NSString *curPath;

@property (assign, nonatomic) NSUInteger nowCleanCategory;//当前正在扫描的Category
@property (weak) IBOutlet LMButton *startScanBtn;

@property (weak) IBOutlet NSImageView *backImageView;


//main view

@property (strong) IBOutlet NSView *mainView;
@property (weak) IBOutlet LMButton *showToolBtn;
@property (weak) IBOutlet CircleCleanImageView *mainCircleImageView;
@property (weak) IBOutlet NSTextField *mainViewTitleLabel;
@property (weak) IBOutlet NSTextField *mainViewDescLabel;

//process view
@property (strong) IBOutlet NSView *processView;
@property (strong) IBOutlet NSView *processAnimateUpView;           //大小界面切换动画，上半部分
@property (strong) IBOutlet NSView *processAnimateBottomView;       //大小界面切换动画，下半部分
@property (strong) IBOutlet NSView *processAnimateScanUpView;       //开始扫描切换动画，上半部分
@property (strong) IBOutlet NSView *processAnimateScanBottomView;   //开始扫描切换动画，下半部分
@property (weak) IBOutlet NSImageView *circleImageView;
@property (weak) IBOutlet NSTextField *sizeLabel;
@property (weak) IBOutlet NSTextField *unitLabel;
@property (weak) IBOutlet NSTextField *scanTipLabel;
@property (weak) IBOutlet NSButton *scanCancelBtn;
@property (weak) IBOutlet LMBorderButton *scanDetailBtn;
@property (strong, nonatomic) QMProgressView *scanProgressView;
@property (weak) IBOutlet NSTextField *scanPathLabel;
@property (weak) IBOutlet LMCategoryStateImageView *systemRubbishImageView;
@property (weak) IBOutlet NSTextField *systemRubbishLabel;
@property (weak) IBOutlet NSTextField *systemRubbishSizeLabel;
@property (weak) IBOutlet LMCategoryStateImageView *appRubbishImageView;
@property (weak) IBOutlet NSTextField *appRubbishLabel;
@property (weak) IBOutlet NSTextField *appRubishSizeLabel;
@property (weak) IBOutlet LMCategoryStateImageView *internetRubbishImageView;
@property (weak) IBOutlet NSTextField *internetRubbishLabel;
@property (weak) IBOutlet NSTextField *internetRubbishSizeLabel;
//hover态时显示详细信息
@property (weak) IBOutlet NSView      *floatViewFrame;
@property (weak) IBOutlet NSImageView *floatViewBg;
@property (weak) IBOutlet NSImageView *floatViewIcon;
@property (weak) IBOutlet NSTextField *floatViewTitle;
@property (weak) IBOutlet NSTextField *floatViewScanning;
@property (weak) IBOutlet NSTextField *floatViewDesc;
@property (weak) IBOutlet NSTextField *floatViewSize;

//resultView
@property (strong) IBOutlet NSView *resultView;
@property (strong) IBOutlet NSView *resultAnimateUpView;            //大小界面切换动画，上半部分
@property (strong) IBOutlet NSView *resultAnimateBottomView;        //大小界面切换动画，下半部分
@property (strong) IBOutlet NSView *resultAnimateBottomUView;        //大小界面切换动画，下半部分的上半部分
@property (strong) IBOutlet NSView *resultAnimateBottomBView;        //大小界面切换动画，下半部分的下半部分
@property (weak) IBOutlet LMBackImageButton *backToMainBtn;
@property (weak) IBOutlet CircleProportionView *resultCircleImageView;
@property (weak) IBOutlet NSImageView *noResultImageView;
@property (weak) IBOutlet NSTextField *resultSizeLabel;
@property (weak) IBOutlet NSImageView *resultTipImageView;
@property (weak) IBOutlet NSTextField *resultTipLabel;
@property (weak) IBOutlet NSTextField *noResultTipLabel;
@property (weak) IBOutlet LMBorderButton *showBIgBtn;
@property (weak) IBOutlet NSTextField *resultTitleLabel;
@property (weak) IBOutlet LMButton *resultBtn;

//guideView
@property (weak) IBOutlet NSView *guideView;
@property (weak) IBOutlet NSImageView *bubbleImageView;
@property (weak) IBOutlet NSImageView *arrowImageView;
@property (weak) IBOutlet NSTextField *guideDescLabel1;
@property (weak) IBOutlet NSTextField *guideDescLabel2;
@property (assign, nonatomic) BOOL isParseEnd;

//@property (assign) NSTimeInterval timeInterval;
@property(nonatomic, assign) long timerNum;
@property(nonatomic, strong) NSTimer *happyBirTimer; // 三周年动画定时器
@property(nonatomic, strong) QMButton *happyBirthBtn; // 三周年入口按钮
@property(nonatomic, strong) NSTextField *happyBirText; // 三周年文案
@property(nonatomic, strong) NSImageView *finishImageView;  //活动完成提示点
@property (nonatomic, assign) NSInteger networkType;
@property(nonatomic, strong) NSButton *activityCard;
@property(nonatomic, strong) NSView *blurView;
@property(nonatomic, strong) NSImageView *iconBackImageView;
@property(nonatomic, strong) LMMaskView *activityMask;
@property(nonatomic, strong) QMButton *activityButton;
@property(nonatomic, strong) LMGSView *maskBlurView;
@end

@implementation LMCleanScanViewController

-(id)init{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        
    }
    
    return self;
}

- (void)viewDidLoad {
    // 设置: 关闭文案动画
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:CLOSE_TIP_505_ACTIVITY];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kLemonUserDidEnterWeb_505];
    [super viewDidLoad];
    // Do view setup here.
    [LMAppSandboxHelper shareInstance];
    bundle = [NSBundle bundleForClass:self.class];
    [self initData];
    [self initView];
    [self setShowToolBtnWithOpenState:[SharedPrefrenceManager getBool:IS_SHOW_BIG_VIEW]];
    if([FullDiskAccessPermissionViewController needShowRequestFullDiskAccessPermissionAlert]){
        [FullDiskAccessPermissionViewController showFullDiskAccessRequestIfNeededWithParentController:self sourceType:MAIN_CLEANER_SMALL_VIEW];
        _isShowedFullAccessWhenFirstInstallation = YES;
    }
    
    // 如果进入过活动 则不显示文案动画
    BOOL didEnterWeb = [[NSUserDefaults standardUserDefaults] boolForKey:kLemonUserDidEnterWeb_505];
    if (!didEnterWeb) {
        NSMutableDictionary *firstViewDict = [NSMutableDictionary dictionary];
        NSViewAnimation *theAnim;
        NSRect firstViewFrame;
        NSRect newViewFrame;
        firstViewFrame = [self.happyBirText frame];
        [firstViewDict setObject:self.happyBirText forKey:NSViewAnimationTargetKey];
        [firstViewDict setObject:[NSValue valueWithRect:firstViewFrame]
                          forKey:NSViewAnimationStartFrameKey];
        newViewFrame = firstViewFrame;
        newViewFrame.size.width += 80;
        [firstViewDict setObject:[NSValue valueWithRect:newViewFrame]
                                  forKey:NSViewAnimationEndFrameKey];
        theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:firstViewDict, nil]];
        // 设置动画的一些属性.比如持续时间0.5秒
        [theAnim setDuration:1.0];
        // 启动动画
        [theAnim setAnimationCurve:NSAnimationLinear];
        [theAnim setAnimationBlockingMode:NSAnimationNonblocking];
        [theAnim startAnimation];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kLemonUserDidEnterWeb_505];
    }
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark-
#pragma mark init view and data

-(void)initData{
    self.cleanStatus = CleanStatusMainPage;
    self.nowCleanCategory = CleanCategoryStart;
    _isCleanOrChooseRubbish = YES;
    _canClickShowToolViewBtn = YES;
    _isAnimateToShowScanView = 0;
    _isAnimateToShowBigCleanView = 0;
    _isAnimateToShowMainView = 0;
    _isAnimating = 0;
    self.isParseEnd = NO;
    self.networkType = 1;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cleanItemParseEnd:)
                                                 name:kQMCleanXMLItemParseEnd
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(knowledgeUpdateNotification:)
                                                 name:kQMNetworkFileChangedNotificaton
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshSelectSize:)
                                                 name:REFRESH_SELECT_SIZE
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startSmallClean:)
                                                 name:START_SMALL_CLEAN
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(junpToMainPage:)
                                                 name:START_JUMP_MAINPAGE
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reParseTheXml)
                                                 name:REPARSE_CLEAN_XML
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showGetDirAccess)
                                                 name:SHOW_GET_DIR_ACCESS
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateShowToolBtnState:)
                                                 name:UPDATE_SHOW_TOOL_VIEW_BTN_STATE
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backAction)
                                                 name:LM_FILE_MOVE_DID_START_NOTIFICATION
                                               object:nil];

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(removeTipIcon)
                                                            name:@"kLEMON_MONITOR_CLICK_HAPPY_BIR"
                                                          object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkChange:)
                                                 name:@"K_Curent_NetWork"
                                               object:nil];
    
    //    [self.startScanBtn setEnabled:NO];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // 解析XML
        [QMCleanManager sharedManger];
    });
    
    [[LMCleanerDataCenter shareInstance] getCleanShowModelByTimeInterval:[[NSDate date] timeIntervalSince1970]];
}

- (void)removeTipIcon {
    if (self.finishImageView) {
        [self.finishImageView removeFromSuperview];
    }
}

-(void)viewWillAppear{
    [super viewWillAppear];
    NSLog(@"viewWillAppear");
    if (self.cleanStatus == CleanStatusScanResult) {
        NSLog(@"CleanStatusScanResult reSetCurrentResultSizeInfo");
        if ([[LMCleanerDataCenter shareInstance] isCleanning]) {
            return;
        }
        [self setResultCircleImageViewProgress];
    }
}

-(void)viewDidAppear{
    isDidAppear = YES;
}

-(void)initView{
    [self initViewText];
    
    //    [self.mainView setWantsLayer:YES];
    //    [self.mainView.layer setBackgroundColor:[NSColor whiteColor].CGColor];
    [self.view addSubview:self.mainView];
    //    [self.processView setWantsLayer:YES];
    //    [self.processView.layer setBackgroundColor:[NSColor whiteColor].CGColor];
    [self.processView setHidden:YES];
    [self.view addSubview:self.processView];
    //    [self.resultView setWantsLayer:YES];
    //    [self.resultView.layer setBackgroundColor:[NSColor whiteColor].CGColor];
    [self.resultView setHidden:YES];
    [self.view addSubview:self.resultView];
    [self setProgressViewStyle];
    [self.scanPathLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [self.scanPathLabel setStringValue:@""];
    if ([McCoreFunction isAppStoreVersion]){
        //查看用户是否给予了用户主目录的权限
        NSString *userPath = [NSString getUserHomePath];
        isUserGiveHomePathPermission = [[LMBookMark defaultShareBookmark] accessingSecurityScopedResourceWithFilePath:userPath];
        if (!isUserGiveHomePathPermission) {
            [self.startScanBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_initView_startScanBtn_1", nil, [NSBundle bundleForClass:[self class]], @"") withColor:[NSColor whiteColor]];
            [self.showToolBtn setHidden:YES];
        }else{
            if ([McCoreFunction isAppStoreVersion]) {//老用户升级 托盘权限的问题
                NSString *userPath = [NSString getUserHomePath];
                NSURL *fileURL = [NSURL fileURLWithPath:userPath];
                
                NSError *error;
                NSData *bookmarkData = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess
                                         includingResourceValuesForKeys:nil
                                                          relativeToURL:nil
                                                                  error:&error];
                if (bookmarkData != nil) {
                    [LemonSuiteUserDefaults putData:bookmarkData withKey:userPath];
                }
            }
        }
        [self.mainViewDescLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_initView_mainViewDescLabel_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    }else{
        [self.mainViewDescLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_initView_mainViewDescLabel_3", nil, [NSBundle bundleForClass:[self class]], @"")];
    }
    
    //main imageview add gesture
    [(NSButtonCell *)self.showToolBtn.cell setHighlightsBy:NSNoCellMask];
    [self setTitleColorForTextField:self.mainViewTitleLabel];
    [self.mainViewDescLabel setTextColor:[NSColor colorWithHex:0x94979B]];
    NSClickGestureRecognizer *clickGes = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(clickMainPic)];
    [self.mainCircleImageView addGestureRecognizer:clickGes];
    //scan imageView
    //    [self.scanTipLabel setTextColor:[NSColor colorWithHex:0x515151]];
    [self setTitleColorForTextField:self.scanTipLabel];
    [self.scanPathLabel setTextColor:[NSColor colorWithHex:0x94979B]];
    //    [self.circleImageView setWantsLayer:YES];
    //    [self.circleImageView.layer setBackgroundColor:[NSColor whiteColor].CGColor];
    //    self.circleImageView.layer.cornerRadius = 145;
    
    [self.floatViewTitle mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.floatViewIcon.mas_right).offset(2);
        make.centerY.equalTo(self.floatViewIcon);
    }];
    
    [self.floatViewScanning mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.floatViewTitle.mas_right).offset(6);
        make.centerY.equalTo(self.floatViewTitle);
    }];
    
    [self.systemRubbishImageView setDelegate:self];
    [self.appRubbishImageView setDelegate:self];
    [self.internetRubbishImageView setDelegate:self];
    [self.floatViewFrame setHidden:YES];
    //    [self.processView addSubview:self.sizeLabel positioned:NSWindowAbove relativeTo:self.circleImageView];
    [self setScanCategorySizeLabelColor:CleanCategoryStart];
    //result view
    [self setScanSizeLabelHiddenStatus];
    self.resultCircleImageView.delegate = self;
    [self setTitleColorForTextField:self.resultSizeLabel];
    [self.resultTipLabel setTextColor:[NSColor colorWithHex:0x94979b]];
    [self.noResultTipLabel setTextColor:[NSColor colorWithHex:0x94979b]];
    [self setTitleColorForTextField:self.resultTitleLabel];
    //    NSClickGestureRecognizer *ges = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(back:)];
    //    ges.numberOfClicksRequired = 1;
    //    [_backToMainBtn addGestureRecognizer:ges];
    
    self.guideView.hidden = YES;
    
    [self setLightLabelFont];
    
    

    BOOL appearTip = [[NSUserDefaults standardUserDefaults] boolForKey:CLOSE_TIP_505_ACTIVITY];
    if (appearTip == YES) {
        return;
    }

    // 如果进入过活动 则不显示文案
    BOOL didEnterWeb = [[NSUserDefaults standardUserDefaults] boolForKey:kLemonUserDidEnterWeb_505];
    int width = 20;
    if(didEnterWeb) {
        width = 0;
    }
    // 三周年活动入口
    NSTextField *happyBirText = [[NSTextField alloc] initWithFrame:NSMakeRect(31, 13, width, 18)];
    happyBirText.stringValue = @"   一封新春简信";
    happyBirText.wantsLayer = YES;
    happyBirText.editable = NO;
    happyBirText.alignment = NSTextAlignmentCenter;
    happyBirText.lineBreakMode = NSLineBreakByTruncatingHead;
    happyBirText.font = [NSFont systemFontOfSize:12];
//    [happyBirText setTextColor:[NSColor colorWithHex:0x28283C]];
    happyBirText.backgroundColor = [NSColor colorWithRed:0.783 green:0.794 blue:0.817 alpha:0.2];
    //[NSColor colorWithHex:0xCAC8D6];
    happyBirText.layer.cornerRadius = 9.0;
    happyBirText.bordered = NO;
    self.happyBirText = happyBirText;
    [self.mainView addSubview:happyBirText];
    
    NSImageView *backImageView = [[NSImageView alloc] init];
    NSImage *image = [NSImage imageNamed:@"bg_circle" withClass:self.class];
    backImageView.image = image;
    self.iconBackImageView = backImageView;
    [self.mainView addSubview:self.iconBackImageView];
    [self.iconBackImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.width.mas_equalTo(40);
        make.left.equalTo(self.mainView).offset(11);
        make.bottom.equalTo(self.mainView).offset(-10);
    }];
    
    QMButton *happyBirthBtn = [[QMButton alloc]init];
    happyBirthBtn.handCursor = YES;
    [happyBirthBtn setButtonType:NSMomentaryLightButton];
    [happyBirthBtn.cell setImageScaling:NSImageScaleAxesIndependently];
    happyBirthBtn.image = [NSImage imageNamed:@"happyNewYear" withClass:self.class];
    
    [(NSButtonCell *)happyBirthBtn.cell setHighlightsBy:NSContentsCellMask];
    happyBirthBtn.alternateImage = [NSImage imageNamed:@"happyNewYear"];
    happyBirthBtn.frame = NSMakeRect(0, 0, 40, 40);
    happyBirthBtn.wantsLayer = YES;
    [happyBirthBtn setBordered:NO];
    happyBirthBtn.layer.backgroundColor = [NSColor clearColor].CGColor;
    happyBirthBtn.state = NSControlStateValueOff;
    self.happyBirthBtn = happyBirthBtn;
    [self.mainView addSubview:happyBirthBtn];
    [happyBirthBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.width.mas_equalTo(40);
        make.left.equalTo(self.mainView).offset(11);
        make.bottom.equalTo(self.mainView).offset(-10);
    }];
    
    LMMaskView *activityMask = [[LMMaskView alloc] initWithFrame:NSMakeRect(0, 0, 40, 40)];
    activityMask.wantsLayer = YES;
    activityMask.layer.backgroundColor = [NSColor clearColor].CGColor;
    activityMask.mouseDelegate = self;
    self.activityMask = activityMask;
    [self.mainView addSubview:self.activityMask];
    [self.activityMask mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(happyBirthBtn);
    }];
    
}
- (void)viewWillLayout {
    [super viewWillLayout];
    if([self isDarkMode]) {
        self.maskBlurView.layer.backgroundColor = [[NSColor colorWithHex:0x2C2E41] colorWithAlphaComponent:1].CGColor;
    } else {
        self.maskBlurView.layer.backgroundColor = [[NSColor whiteColor] colorWithAlphaComponent:1].CGColor;
    }
}

- (Boolean)isDarkMode {
    if (@available(macOS 10.14, *)) {
        NSAppearance *apperance = NSApp.effectiveAppearance; // only 10.14
        return  [apperance bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua,NSAppearanceNameAqua]] == NSAppearanceNameDarkAqua;
    } else {
        return false;
    }
    return false;
}

- (void)maskViewDidMoveIn {
    [self.startScanBtn setEnabled:NO];
    [self viewNeedHidden:YES];
    if(self.activityCard) {
        [self.activityCard removeFromSuperview];
    }
    if(self.blurView) {
        [self.blurView removeFromSuperview];
    }
    
    LMGSView *maskBlurView =  [[LMGSView alloc] init];
    maskBlurView.wantsLayer = YES;
    maskBlurView.layer.cornerRadius = 14;
    maskBlurView.layer.masksToBounds = YES;
    maskBlurView.alphaValue = 0.1;
    maskBlurView.mouseDelegate = self;
    if([self isDarkMode]) {
        maskBlurView.layer.backgroundColor = [[NSColor colorWithHex:0x2C2E41] colorWithAlphaComponent:1].CGColor;
    } else {
        maskBlurView.layer.backgroundColor = [[NSColor whiteColor] colorWithAlphaComponent:1].CGColor;
    }

    self.maskBlurView = maskBlurView;
    [self.mainView addSubview:maskBlurView];
    [maskBlurView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(145);
        make.width.mas_equalTo(260);
        make.left.equalTo(self.mainView).offset(11);
        make.bottom.equalTo(self.mainView).offset(-10);
    }];
    
    LMActivityCard *blurView =  [[LMActivityCard alloc] init];
    blurView.wantsLayer = YES;
    blurView.layer.cornerRadius = 14;
    blurView.layer.masksToBounds = YES;
    blurView.alphaValue = 0.1;
    blurView.layer.backgroundColor = [NSColor clearColor].CGColor;
    self.blurView = blurView;
    [self.mainView addSubview:self.blurView];
    [self.blurView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(145);
        make.width.mas_equalTo(260);
        make.left.equalTo(self.mainView).offset(11);
        make.bottom.equalTo(self.mainView).offset(-10);
    }];
    
    NSButton *activityCard = [[NSButton alloc] init];
    [activityCard setImage:[NSImage imageNamed:@"activityCard" withClass:self.class]];
    activityCard.wantsLayer = YES;
    [(NSButtonCell*)activityCard.cell setHighlightsBy:NSNoCellMask];
    [activityCard setBordered:NO];
    activityCard.layer.cornerRadius = 14;
    activityCard.layer.masksToBounds = YES;
    self.activityCard = activityCard;
    [self.blurView addSubview:self.activityCard];
    [self.activityCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(145);
        make.width.mas_equalTo(260);
        make.left.equalTo(self.mainView).offset(11);
        make.bottom.equalTo(self.mainView).offset(-10);
    }];
    
    QMButton *tipButton = [[QMButton alloc] init];
    tipButton.handCursor = YES;
    [tipButton setTitle:@"不再提示" withColor:[NSColor colorWithHex:0x989A9E]];
    [(NSButtonCell*)tipButton.cell setHighlightsBy:NSNoCellMask];
    [tipButton setFont:[NSFont systemFontOfSize:10.0]];
    [tipButton setBordered:NO];
    tipButton.wantsLayer = YES;
    tipButton.layer.backgroundColor = [NSColor clearColor].CGColor;
    [tipButton setTarget:self];
    [tipButton setAction:@selector(tipBtn)];
    [self.blurView addSubview:tipButton];
    [tipButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(12);
        make.width.mas_equalTo(50);
        make.right.equalTo(self.blurView).offset(-10);
        make.top.equalTo(self.blurView).offset(10);
    }];

    //
    QMButton *activityButton = [[QMButton alloc] init];
    activityButton.handCursor = YES;
    [activityButton setImage:[NSImage imageNamed:@"activityButton" withClass:self.class]];
    activityButton.wantsLayer = YES;
    [(NSButtonCell*)activityButton.cell setHighlightsBy:NSNoCellMask];
    [activityButton setBordered:NO];
    activityButton.layer.cornerRadius = 4;
    activityButton.layer.masksToBounds = YES;
    [activityButton setTarget:self];
    [activityButton setAction:@selector(activityBtn)];
    self.activityButton = activityButton;
    [self.blurView addSubview:self.activityButton];
    [self.activityButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(25);
        make.width.mas_equalTo(52);
        make.left.equalTo(self.blurView).offset(20);
        make.bottom.equalTo(self.blurView).offset(-16);
    }];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            context.duration = 1.0;
            context.allowsImplicitAnimation = YES;
            maskBlurView.animator.alphaValue = 1;
            blurView.animator.alphaValue = 1;
        } completionHandler:^{
            
        }];
//    });
    
}

- (void)activityBtn {
    NSURL *url = [NSURL URLWithString:@"https://mp.weixin.qq.com/s?__biz=MzI5ODU3NjMzNA==&mid=2247483760&idx=1&sn=1da64b403075f9ba84cb6b349e0951dc&chksm=eca2f1d1dbd578c7badd2e68b9325a329ccf70cd28137c11b475bca5da7c17c90bb89166df7c#rd"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)tipBtn {
    [self.startScanBtn setEnabled:YES];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:CLOSE_TIP_505_ACTIVITY];
    [self viewNeedHidden:YES];
    if(self.activityCard) {
        [self.activityCard removeFromSuperview];
    }
    if(self.blurView) {
        [self.blurView removeFromSuperview];
    }
    if(self.maskBlurView) {
        [self.maskBlurView removeFromSuperview];
    }
}

- (void)maskViewDidMoveOut {
   
}

- (void)GSViewDidMoveIn {
    
}

- (void)GSViewDidMoveOut {
    [self.startScanBtn setEnabled:YES];
    if(![[NSUserDefaults standardUserDefaults] boolForKey:CLOSE_TIP_505_ACTIVITY]) {
        [self viewNeedHidden:NO];
    }
}

- (void)viewNeedHidden:(BOOL)hidden {
    self.happyBirText.hidden = hidden;
    self.iconBackImageView.hidden = hidden;
    self.happyBirthBtn.hidden = hidden;
    self.activityMask.hidden = hidden;
    self.maskBlurView.hidden = hidden;
}

#pragma mark -- 控件初始化
-(void)initViewText{
    [self.startScanBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_initViewText_startScanBtn_1", nil, [NSBundle bundleForClass:[self class]], @"") withColor:[NSColor whiteColor]];
    [self.mainViewTitleLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_initViewText_mainViewTitleLabel_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.noResultTipLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_initViewText_noResultTipLabel_3", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.showBIgBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_initViewText_showBIgBtn_4", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.guideDescLabel1 setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_initViewText_guideDescLabel1_5", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.guideDescLabel2 setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_initViewText_guideDescLabel2_6", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.scanDetailBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_initViewText_scanDetailBtn_7", nil, [NSBundle bundleForClass:[self class]], @"")];
}

-(void)setLightLabelFont{
    [_startScanBtn setFont:[NSFontHelper getLightSystemFont:28]];
    [_resultBtn setFont:[NSFontHelper getLightSystemFont:28]];
    [_mainViewDescLabel setFont:[NSFontHelper getLightSystemFont:16]];
    [_scanPathLabel setFont:[NSFontHelper getLightSystemFont:14]];
    [_scanDetailBtn setFont:[NSFontHelper getLightSystemFont:12]];
    [_systemRubbishLabel setFont:[NSFontHelper getLightSystemFont:14]];
    [_systemRubbishLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_setLightLabelFont_systemRubbishLabel_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    //    [_systemRubbishSizeLabel setFont:[NSFontHelper getLightSystemFont:14]];
    [_appRubbishLabel setFont:[NSFontHelper getLightSystemFont:14]];
    [_appRubbishLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_setLightLabelFont_appRubbishLabel_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    //    [_appRubishSizeLabel setFont:[NSFontHelper getLightSystemFont:14]];
    [_internetRubbishLabel setFont:[NSFontHelper getLightSystemFont:14]];
    [_internetRubbishLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_setLightLabelFont_internetRubbishLabel_3", nil, [NSBundle bundleForClass:[self class]], @"")];
    //    [_internetRubbishSizeLabel setFont:[NSFontHelper getLightSystemFont:14]];
    [_floatViewScanning setFont:[NSFontHelper getLightSystemFont:14]];
    [_floatViewSize setFont:[NSFontHelper getLightSystemFont:14]];
    [_floatViewDesc setFont:[NSFontHelper getLightSystemFont:12]];
    [_resultTipLabel setFont:[NSFontHelper getLightSystemFont:14]];
    [_noResultTipLabel setFont:[NSFontHelper getLightSystemFont:16]];
    [_showBIgBtn setFont:[NSFontHelper getLightSystemFont:12]];
    [_guideDescLabel1 setFont:[NSFontHelper getLightSystemFont:14]];
    [_guideDescLabel2 setFont:[NSFontHelper getLightSystemFont:14]];
}

#pragma mark -- view update

-(void)setResultCircleImageViewProgress{
    UInt64 sysFullSize = 0;
    UInt64 appFullSize = 0;
    UInt64 intFullSize = 0;
    for (QMCategoryItem *categoryItem in _categoryArray) {
        if([categoryItem.categoryID isEqualToString:@"1"]){
            sysFullSize = categoryItem.resultFileSize;
            _sysSelectSize = categoryItem.resultSelectedFileSize;
            [[LMCleanerDataCenter shareInstance] setSysSelectSize:_sysSelectSize];
        }else if ([categoryItem.categoryID isEqualToString:@"2"]){
            appFullSize = categoryItem.resultFileSize;
            _appSelectSize = categoryItem.resultSelectedFileSize;
            [[LMCleanerDataCenter shareInstance] setAppSelectSize:_appSelectSize];
        }else if ([categoryItem.categoryID isEqualToString:@"3"]){
            intFullSize = categoryItem.resultFileSize;
            _intSelectSize = categoryItem.resultSelectedFileSize;
            [[LMCleanerDataCenter shareInstance] setIntSelectSize:_intSelectSize];
        }
    }
    [self.resultCircleImageView setSysFullSize:sysFullSize appFullSize:appFullSize intFullSize:intFullSize];
    _totalSize = sysFullSize + appFullSize + intFullSize;
    _totalSelectedSize = _sysSelectSize + _appSelectSize + _intSelectSize;
    
    //    if((_sysSelectSize != 0) && ((_appSelectSize + _intSelectSize) == 0)){
    //        [self.resultTipImageView setImage:[NSImage imageNamed:@"cate_sys" withClass:[self class]]];
    //        [self.resultTipLabel setStringValue:@"系统垃圾"];
    //    }else if((_appSelectSize != 0) && ((_sysSelectSize + _intSelectSize) == 0)){
    //        [self.resultTipImageView setImage:[NSImage imageNamed:@"cate_sys" withClass:[self class]]];
    //        [self.resultTipLabel setStringValue:@"应用垃圾"];
    //    }else if((_intSelectSize != 0) && ((_appSelectSize + _sysSelectSize) == 0)){
    //        [self.resultTipImageView setImage:[NSImage imageNamed:@"cate_sys" withClass:[self class]]];
    //        [self.resultTipLabel setStringValue:@"上网垃圾"];
    //    }else{
    [self.resultTipImageView setHidden:YES];
    [self.resultTipLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_setResultCircleImageViewProgress_resultTipLabel_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    //    }
    
    //重新设置已选择大小以及刷新图标
    NSString *totalSizeString = [NSString stringFromDiskSize:_totalSize];
    NSString *nowSelectSizeString = [NSString stringFromDiskSize:_totalSelectedSize];
    [self.resultSizeLabel setStringValue:totalSizeString];
    NSString *sizeString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_setResultCircleImageViewProgress_sizeString _2", nil, [NSBundle bundleForClass:[self class]], @""), nowSelectSizeString];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:sizeString];
    NSRange range = [sizeString rangeOfString:nowSelectSizeString];
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0xFFAA09] range:range];
    //    if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
    //        [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0xFFAA09] range:NSMakeRange(3, sizeString.length - 6)];
    //    }else{//其他语言目前按照英语来
    //        [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0xFFAA09] range:NSMakeRange(0, sizeString.length - 8)];
    //    }
    
    //段落样式
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc]init];
    //对齐方式
    paragraph.alignment = NSTextAlignmentCenter;
    [attrString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, sizeString.length)];
    [self.resultTitleLabel setAttributedStringValue:attrString];
    
    //设置清理按钮状态
    if ((_totalSize > 0) && (_totalSelectedSize == 0)) {
        _isCleanOrChooseRubbish = NO;
        [self.resultBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_setResultCircleImageViewProgress_resultBtn_3", nil, [NSBundle bundleForClass:[self class]], @"") withColor:[NSColor whiteColor]];
    }else{
        _isCleanOrChooseRubbish = YES;
        [self.resultBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_setResultCircleImageViewProgress_resultBtn_4", nil, [NSBundle bundleForClass:[self class]], @"") withColor:[NSColor whiteColor]];
    }
}

-(void)setScanSizeLabelHiddenStatus{
    BOOL isHidden = !(self.cleanStatus == CleanStatusScanResult);
    [self.noResultImageView setHidden:!isHidden];
    [self.resultCircleImageView setHidden:isHidden];
    [self.resultSizeLabel setHidden:isHidden];
    [self.resultTipLabel setHidden:isHidden];
    [self.noResultTipLabel setHidden:!isHidden];
    [self.resultTipImageView setHidden:isHidden];
    [self.showBIgBtn setHidden:isHidden];
}

-(void)setScanCategorySizeLabelColor:(NSInteger) nowCleanCategory{
    
    if (@available(macOS 10.13, *)) {
        [self.systemRubbishLabel setTextColor:nowCleanCategory == CleanCategorySystem ? CLEAN_LABEL_TAEXT_COLOR_10_13];
        [self.systemRubbishSizeLabel setTextColor:nowCleanCategory == CleanCategorySystem ? CLEAN_LABEL_TAEXT_COLOR_10_13];
        [self.appRubbishLabel setTextColor:nowCleanCategory == CleanCategoryApp ? CLEAN_LABEL_TAEXT_COLOR_10_13];
        [self.appRubishSizeLabel setTextColor:nowCleanCategory == CleanCategoryApp ? CLEAN_LABEL_TAEXT_COLOR_10_13];
        [self.internetRubbishLabel setTextColor:nowCleanCategory == CleanCategoryInternet ? CLEAN_LABEL_TAEXT_COLOR_10_13];
        [self.internetRubbishSizeLabel setTextColor:nowCleanCategory == CleanCategoryInternet ? CLEAN_LABEL_TAEXT_COLOR_10_13];
    } else {
        [self.systemRubbishLabel setTextColor:nowCleanCategory == CleanCategorySystem ? CLEAN_LABEL_TAEXT_COLOR_10_11];
        [self.systemRubbishSizeLabel setTextColor:nowCleanCategory == CleanCategorySystem ? CLEAN_LABEL_TAEXT_COLOR_10_11];
        [self.appRubbishLabel setTextColor:nowCleanCategory == CleanCategoryApp ? CLEAN_LABEL_TAEXT_COLOR_10_11];
        [self.appRubishSizeLabel setTextColor:nowCleanCategory == CleanCategoryApp ? CLEAN_LABEL_TAEXT_COLOR_10_11];
        [self.internetRubbishLabel setTextColor:nowCleanCategory == CleanCategoryInternet ? CLEAN_LABEL_TAEXT_COLOR_10_11];
        [self.internetRubbishSizeLabel setTextColor:nowCleanCategory == CleanCategoryInternet ? CLEAN_LABEL_TAEXT_COLOR_10_11];
    }
    
}


-(void)setScanCategorySizeLabelSize:(NSInteger) cleanCateroy inDic:(NSDictionary *)dic{
    QMCategoryItem *item = [self getCategoryItemById:[NSString stringWithFormat:@"%ld", cleanCateroy]];
    NSString *nowScanSizeString = [NSString stringFromDiskSize:item.resultFileSize];
    if (cleanCateroy == 1){
        [self.systemRubbishSizeLabel setStringValue:nowScanSizeString];
    }else if (cleanCateroy == 2){
        [self.appRubishSizeLabel setStringValue:nowScanSizeString];
    }else if (cleanCateroy == 3){
        [self.internetRubbishSizeLabel setStringValue:nowScanSizeString];
    }
}

-(void)setCleanCategoryLabel{
    for (NSInteger i = 1; i <= 3; i++) {
        NSString *cleanSizeString = @"0 B";
        if(self.cleanStatus == CleanStatusCleanProgress) {
            QMCategoryItem* item = self.categoryArray[i-1];
            if([self isCategoryNoSelect:item])
                cleanSizeString = NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_setCleanCategoryLabel_1553048057_1", nil, [NSBundle bundleForClass:[self class]], @"");
            else if(!item.isCleanning)
                cleanSizeString = NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_setCleanCategoryLabel_1553048057_2", nil, [NSBundle bundleForClass:[self class]], @"");
        }
        if (i == 1) {
            if (_sysSelectSize > 0) {
                cleanSizeString = [NSString stringFromDiskSize:_sysSelectSize];
            }
            [self.systemRubbishSizeLabel setStringValue:cleanSizeString];
        }else if (i == 2){
            if (_appSelectSize > 0) {
                cleanSizeString = [NSString stringFromDiskSize:_appSelectSize];
            }
            [self.appRubishSizeLabel setStringValue:cleanSizeString];
        }else if (i == 3){
            if (_intSelectSize > 0) {
                cleanSizeString = [NSString stringFromDiskSize:_intSelectSize];
            }
            [self.internetRubbishSizeLabel setStringValue:cleanSizeString];
        }
    }
}

-(void)setProgressSizeLabel{
    UInt64 totalSelectSize = [[LMCleanerDataCenter shareInstance] totalSelectSize];
    UInt64 leftCleanSize = totalSelectSize - _removeSize;
    [[LMCleanerDataCenter shareInstance] setCleanLeftSize:leftCleanSize];
    NSString *leftSizeString = [NSString sizeStringFromSize:(leftCleanSize) diskMode:YES];
    NSString *leftUnitString = [NSString unitStringFromSize:(leftCleanSize) diskMode:YES];
    [self.sizeLabel setStringValue:leftSizeString];
    [self.unitLabel setStringValue:leftUnitString];
}

-(void)setProgressViewStyle{
    //    if (self.scanProgressView) {
    //        [self.scanProgressView removeFromSuperview];
    //    }
    self.scanProgressView = [[QMProgressView alloc] initWithFrame:NSMakeRect(46, 237, 292, 5)];
    //    [self.processView addSubview:self.scanProgressView];
    [self.processAnimateBottomView addSubview:self.scanProgressView];
    self.scanProgressView.borderColor = [NSColor clearColor];
    self.scanProgressView.minValue = 0.0;
    self.scanProgressView.maxValue = 1.0;
    self.scanProgressView.value = 0.0;
    [self.scanProgressView setWantsLayer:YES];
}

-(void)setCleanStatus:(CleanStatus)cleanStatus{
    [[LMCleanerDataCenter shareInstance] setCurrentCleanerStatus:cleanStatus];
    _cleanStatus = cleanStatus;
}

-(void)refreshSelectSize:(id)noti{
    _startTimeInterval = [[NSDate date] timeIntervalSince1970];
    for (QMCategoryItem *categoryItem in _categoryArray) {
        if([categoryItem.categoryID isEqualToString:@"1"]){
            _sysSelectSize = categoryItem.resultSelectedFileSize;
            [[LMCleanerDataCenter shareInstance] setSysSelectSize:_sysSelectSize];
        }else if ([categoryItem.categoryID isEqualToString:@"2"]){
            _appSelectSize = categoryItem.resultSelectedFileSize;
            [[LMCleanerDataCenter shareInstance] setAppSelectSize:_appSelectSize];
        }else if ([categoryItem.categoryID isEqualToString:@"3"]){
            _intSelectSize = categoryItem.resultSelectedFileSize;
            [[LMCleanerDataCenter shareInstance] setIntSelectSize:_intSelectSize];
        }
    }
}

-(void)startSmallClean:(id)noti{
    NSString *totalSizeString = [NSString stringFromDiskSize:_totalSize];
    NSString *nowSelectSizeString = [NSString stringFromDiskSize:_totalSelectedSize];
    if ([[LMCleanerDataCenter shareInstance] needTipUserSaveSubcateStatus]) {
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert.accessoryView setFrameOrigin:NSMakePoint(0, 0)];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_startSmallClean_alert_1", nil, [NSBundle bundleForClass:[self class]], @"");
        alert.informativeText = NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_startSmallClean_alert_2", nil, [NSBundle bundleForClass:[self class]], @"");
        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_startSmallClean_alert_3", nil, [NSBundle bundleForClass:[self class]], @"")];
        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_startSmallClean_alert_4", nil, [NSBundle bundleForClass:[self class]], @"")];
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertSecondButtonReturn) {
                [[LMCleanerDataCenter shareInstance] storeSubcateArrToDb];
            }
            if ([[LMCleanerDataCenter shareInstance] isBigPage]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:NEED_DISPLAY_BIG_VIEW_CLEANING object:nil];
            }
            [self startCleanFunction];
        }];
        
    }else{
        if ([[LMCleanerDataCenter shareInstance] isBigPage]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NEED_DISPLAY_BIG_VIEW_CLEANING object:nil];
        }
        [self startCleanFunction];
    }
}

-(void)startCleanFunction{
    [self setCleanCategoryLabel];
    self.currentCleanSizeInfo = [[NSMutableDictionary alloc] initWithDictionary:self.currentResultSizeInfo];
    
    //    CleanStatus cleanStatus = self.cleanStatus;
    //    self.cleanStatus = CleanStatusCleanProgress;
    //    [self reArrangeContentView:cleanStatus];
    //    [[QMCleanManager sharedManger] startCleaner];
    [self showAnimateReverse:NO viewToShow:&_isAnimateToShowCleanView isInSamll:YES];
}

//重置小界面 几个扫描view图片状态为初始状态
-(void)setCategoryStateImageViewPic{
    [self setCircleImageViewAniWithCategoryId:@"1" isStart:NO];
    [self setCircleImageViewAniWithCategoryId:@"2" isStart:NO];
    [self setCircleImageViewAniWithCategoryId:@"3" isStart:NO];
}

-(void)setCircleImageViewAniWithCategoryId:(NSString *)categoryId isStart:(BOOL)isStart{
    if ([categoryId isEqualToString:@"1"]) {
        if (isStart) {
            [_systemRubbishImageView setImage:[NSImage imageNamed:@"sys_enable" withClass:self.class]];
        }else{
            [_systemRubbishImageView setImage:[NSImage imageNamed:@"sys_disable" withClass:self.class]];
        }
        
    }else if([categoryId isEqualToString:@"2"]){
        if (isStart) {
            [_appRubbishImageView setImage:[NSImage imageNamed:@"app_enable" withClass:self.class]];
        }else{
            [_appRubbishImageView setImage:[NSImage imageNamed:@"app_disable" withClass:self.class]];
        }
        
    }else if ([categoryId isEqualToString:@"3"]){
        if (isStart) {
            [_internetRubbishImageView setImage:[NSImage imageNamed:@"int_enable" withClass:self.class]];
        }else{
            [_internetRubbishImageView setImage:[NSImage imageNamed:@"int_disable" withClass:self.class]];
        }
        
    }
}

-(void)junpToMainPage:(id)noti{
    //返回时需要清除主页的动画效果，否则不显示（added by levey）
    [self removeMainPageAnimate];
    
    CleanStatus cleanStatus = self.cleanStatus;
    self.cleanStatus = CleanStatusMainPage;
    [self reArrangeContentView:cleanStatus];
}

-(void)reArrangeContentView:(CleanStatus) lastCleanStatus{
    switch (self.cleanStatus) {
        case CleanStatusMainPage://主页
        {
            if (lastCleanStatus == CleanStatusFirst) {
                
            }else if (lastCleanStatus == CleanStatusCleanResult){
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [RatingUtils recordCleanTrashFinishAction];
                    [[NSNotificationCenter defaultCenter] postNotificationName:MAS_CLEAN_TRASH_FINISH object:nil];
                    
                });
            }else if (lastCleanStatus == CleanStatusScanNoResult){
                
            }
            [self.mainView setHidden:NO];
            [self.resultView setHidden:YES];
            [self.scanProgressView setValue:0];
            //            [self.startScanBtn setEnabled:YES];
            //数据层读取数据判断首页应该展示的样式
            _totalSize = 0;
            _totalSelectedSize = 0;
            _removeSize = 0;
            break;
        }
        case CleanStatusScanProgress://扫描过程页
        {
            [self.mainView setHidden:YES];
            [self.sizeLabel setStringValue:@"0"];
            [self.unitLabel setStringValue:@"B"];
            [self.scanTipLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_reArrangeContentView_scanTipLabel_1", nil, [NSBundle bundleForClass:[self class]], @"")];
            [self.systemRubbishSizeLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_reArrangeContentView_systemRubbishSizeLabel_2", nil, [NSBundle bundleForClass:[self class]], @"")];
            [self.appRubishSizeLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_reArrangeContentView_appRubishSizeLabel_3", nil, [NSBundle bundleForClass:[self class]], @"")];
            [self.internetRubbishSizeLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_reArrangeContentView_internetRubbishSizeLabel_4", nil, [NSBundle bundleForClass:[self class]], @"")];
            [self startScanAniTimer];
            self.scanCancelBtn.alphaValue = 1.0f;
            [self.unitLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(self.scanCancelBtn.mas_left);
                make.centerY.equalTo(self.sizeLabel);
                make.width.equalTo(@50);
                make.height.equalTo(@39);
            }];
            [self.processView setHidden:NO];
            break;
        }
            
        case CleanStatusScanResult:
        case CleanStatusScanNoResult://扫描结果页
        {
            [self stopScanAniTimer];
            [self setScanSizeLabelHiddenStatus];
            [self.processView setHidden:YES];
            [self.scanProgressView setValue:0];
            [self.resultView setHidden:NO];
            [self setCategoryStateImageViewPic];
            if (self.cleanStatus == CleanStatusScanResult) {
                [self.resultTipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.centerX.equalTo(self.resultView);
                    make.centerY.equalTo(self.resultTipImageView);
                }];
                [self.resultTipImageView setHidden:YES];
                
                [self setResultCircleImageViewProgress];
                [self.backToMainBtn setHidden:NO];
                
                //是否展示引导动画
                BOOL guideHasShown = [SharedPrefrenceManager getBool:GUIDE_HAS_SHOWN];
                if(!guideHasShown) {
                    [SharedPrefrenceManager putBool:YES withKey:GUIDE_HAS_SHOWN];
                    _isShowGuide = YES;
                    self.resultBtn.enabled = NO;
                    if(!_guideTimer) {
                        _isBubbleShown = NO;
                        _guideCount = 0;
                        self.guideView.hidden = NO;
                        _guideTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30
                                                                       target:self
                                                                     selector:@selector(_refreshGuide)
                                                                     userInfo:nil
                                                                      repeats:YES];
                    }
                }
            }else if (self.cleanStatus == CleanStatusScanNoResult){
                [self.resultBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_reArrangeContentView_resultBtn_5", nil, [NSBundle bundleForClass:[self class]], @"") withColor:[NSColor whiteColor]];
                //                [self.resultTitleLabel setTextColor:[NSColor colorWithHex:0x00DB99]];
                [self.resultTitleLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_reArrangeContentView_resultTitleLabel_6", nil, [NSBundle bundleForClass:[self class]], @"")];
                [self.backToMainBtn setHidden:YES];
            }
            break;
        }
        case CleanStatusCleanProgress://清理过程页
        {
            [self startCleanAniTimer];
            [self.resultCircleImageView setSysFullSize:_sysSelectSize appFullSize:_appSelectSize intFullSize:_intSelectSize];
            [self.resultView setHidden:YES];
            self.scanCancelBtn.alphaValue = 0.0f;
            [self.scanTipLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_reArrangeContentView_scanTipLabel_7", nil, [NSBundle bundleForClass:[self class]], @"")];
            [self.unitLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(self.scanCancelBtn.mas_right);
                make.centerY.equalTo(self.sizeLabel);
                make.width.equalTo(@50);
                make.height.equalTo(@39);
            }];
            [self.processView setHidden:NO];
            break;
        }
            
        case CleanStatusCleanResult://清理结果页
        {
            [self stopCleanTimer];
            [self.processView setHidden:YES];
            [self.resultView setHidden:NO];
            [self.resultTipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.resultTipImageView.mas_right).offset(10);
                make.centerY.equalTo(self.resultTipImageView);
            }];
            [self setCategoryStateImageViewPic];
            [self.resultTipLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_reArrangeContentView_resultTipLabel_8", nil, [NSBundle bundleForClass:[self class]], @"")];
            [self.resultTipImageView setHidden:NO];
            [self.resultBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_reArrangeContentView_resultBtn_9", nil, [NSBundle bundleForClass:[self class]], @"") withColor:[NSColor whiteColor]];
            UInt64 totalSelectSize = [[LMCleanerDataCenter shareInstance] totalSelectSize];
            NSString *sizeRemoveSizeString = [NSString stringFromDiskSize:totalSelectSize];
            [self.resultSizeLabel setStringValue:sizeRemoveSizeString];
            NSString *numString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_reArrangeContentView_numString _10", nil, [NSBundle bundleForClass:[self class]], @""), _cleanFileNums];
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:numString];
            NSString *cleanFileNumsString = [NSString stringWithFormat:@"%ld",_cleanFileNums];
            NSRange cleanNumRange = [numString rangeOfString:cleanFileNumsString];
            [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x04D999] range:cleanNumRange];
            //            if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
            //                if (numString.length > 6) {
            //                    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x04D999] range:NSMakeRange(3, numString.length - 6)];
            //                }
            //            }else{
            //                if (numString.length > 13) {
            //                    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x04D999] range:NSMakeRange(0, numString.length - 13)];
            //                }
            //            }
            //段落样式
            NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc]init];
            //对齐方式
            paragraph.alignment = NSTextAlignmentCenter;
            [attrString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, numString.length)];
            [self.resultTitleLabel setAttributedStringValue:attrString];
            [self.backToMainBtn setHidden:YES];
            break;
        }
        default:
            break;
    }
}

- (void)_refreshGuide {
    int arrowIdx = _guideCount % kGuideArrowCount;
    NSString* arrowName = [NSString stringWithFormat:kGuideArrowString,arrowIdx];
    [self.arrowImageView setImage:[bundle imageForResource:arrowName]];
    
    if(!_isBubbleShown) {
        int bubbleIdx = _guideCount % kGuideBubbleCount;
        NSString* bubbleName = [NSString stringWithFormat:kGuideBubbleString,bubbleIdx];
        [self.bubbleImageView setImage:[bundle imageForResource:bubbleName]];
        if(bubbleIdx == kGuideBubbleCount - 1)
            _isBubbleShown = YES;
    }
    
    _guideCount++;
    if(_guideCount >= kGuideAnimateCount)
        _guideCount = 0;
}

- (void)_closeGuideIfNeeded {
    if(!_isShowGuide)
        return;
    _isShowGuide = NO;
    self.resultBtn.enabled = YES;
    self.guideView.hidden = YES;
    [_guideTimer invalidate];
    _guideTimer = nil;
}

-(QMCategoryItem *)getCategoryItemById:(NSString *)cateId{
    for(QMCategoryItem* item in self.categoryArray) {
        if([item.categoryID isEqualToString:cateId]) {
            return item;
        }
    }
    
    return nil;
}

#pragma mark-
#pragma mark animations

//扫描过程替换图片相关
-(void)startScanAniTimer{
    NSMutableArray *imageArr = [NSMutableArray array];
    for (NSInteger i=1; i<=10; i++) {
        NSString *imageName = [NSString stringWithFormat:@"clean_main_ani_%ld", i];
        NSImage *image = [NSImage imageNamed:imageName withClass:self.class];
        [imageArr addObject:image];
    }
    for (NSInteger i=1; i<=25; i++) {
        // 获取图片的名称
        NSString *imageName = [NSString stringWithFormat:@"clean_scan_ani_%ld", i];
        // 创建UIImage对象
        NSImage *image = [NSImage imageNamed:imageName withClass:self.class];
        // 加入数组
        [imageArr addObject:image];
    }
    _scanAniArray = imageArr;
    _currentCount = 0;
    _scanAniTimer = [NSTimer scheduledTimerWithTimeInterval:0.052 target:self selector:@selector(changeScanAniPic) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_scanAniTimer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:_scanAniTimer forMode:NSRunLoopCommonModes];
}

-(void)changeScanAniPic{
    NSImage *image = [_scanAniArray objectAtIndex:_currentCount];
    [self.circleImageView setImage:image];
    _currentCount++;
    //    if (_currentCount == 25) {
    //        _currentCount = 0;
    //    }
    if (_currentCount == 35) {
        _currentCount = 10;
    }
}

-(void)stopScanAniTimer{
    NSImage *image = [_scanAniArray objectAtIndex:0];
    [self.circleImageView setImage:image];
    [_scanAniTimer invalidate];
    _scanAniTimer = nil;
    _scanAniArray = nil;
}

//清理过程替换图片相关
-(void)startCleanAniTimer{
    NSMutableArray *imageArr = [NSMutableArray array];
    for (NSInteger i=1; i<=20; i++) {
        // 获取图片的名称
        NSString *imageName = [NSString stringWithFormat:@"clean_clean_ani-%ld", i];
        // 创建UIImage对象
        NSImage *image = [NSImage imageNamed:imageName withClass:self.class];
        // 加入数组
        [imageArr addObject:image];
    }
    _cleanAniArray = imageArr;
    _currentCount = 0;
    _cleanAniTimer = [NSTimer scheduledTimerWithTimeInterval:0.052 target:self selector:@selector(changeCleanAniPic) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_cleanAniTimer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:_cleanAniTimer forMode:NSRunLoopCommonModes];
}

-(void)changeCleanAniPic{
    NSImage *image = [_cleanAniArray objectAtIndex:_currentCount];
    [self.circleImageView setImage:image];
    _currentCount++;
    if (_currentCount == 20) {
        _currentCount = 0;
    }
}

-(void)stopCleanTimer{
    [_cleanAniTimer invalidate];
    _cleanAniTimer = nil;
    _cleanAniArray = nil;
}

//窗口调用切换动画（added by levey）
- (void)showAnimate {
    //show animate
    [self showAnimateReverse:YES viewToShow:nil isInSamll:NO];
}

//移除动画效果（added by levey）
- (void)removeAllAnimate {
    [self removeMainPageAnimate];
    [self removeProgressPageAnimate];
    [self removeResultPageAnimate];
}
- (void)removeMainPageAnimate {
    [self.mainCircleImageView.layer removeAllAnimations];
    [self.mainViewTitleLabel.layer removeAllAnimations];
    [self.mainViewDescLabel.layer removeAllAnimations];
    [self.startScanBtn.layer removeAllAnimations];
}
- (void)removeProgressPageAnimate {
    [self.processAnimateUpView.layer removeAllAnimations];
    [self.processAnimateScanUpView.layer removeAllAnimations];
    [self.processAnimateScanBottomView.layer removeAllAnimations];
    [self.scanPathLabel.layer removeAllAnimations];
    [self.scanDetailBtn.layer removeAllAnimations];
    [self.scanProgressView.layer removeAllAnimations];
}
- (void)removeResultPageAnimate {
    [self.backToMainBtn.layer removeAllAnimations];
    [self.resultAnimateUpView.layer removeAllAnimations];
    [self.resultAnimateBottomView.layer removeAllAnimations];
    [self.resultTitleLabel.layer removeAllAnimations];
    [self.resultAnimateBottomUView.layer removeAllAnimations];
    [self.resultAnimateBottomBView.layer removeAllAnimations];
}


- (void)showAnimateReverse:(BOOL)isReverse viewToShow:(NSInteger*)viewToShow isInSamll:(BOOL)isInSamll {
    //reset animate view state
    [self removeAllAnimate];
    
    CGPoint oldOrigin = self.view.window.frame.origin;
    CGPoint newOrigin = (viewToShow != &_isAnimateToShowBigCleanView) ? [MacDeviceHelper getScreenOriginSmall:oldOrigin] : [MacDeviceHelper getScreenOriginBig:oldOrigin];
    CGSize size = self.view.window.frame.size;
    if(!isReverse && oldOrigin.x != newOrigin.x) {
        __weak __typeof(self) weakSelf = self;
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [context setDuration:0.3];
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if(strongSelf) {
                //窗口移动动画，也需要设置_isAnimating
                strongSelf->_isAnimating = 1;
                [[strongSelf.view.window animator] setFrame:NSMakeRect(newOrigin.x, newOrigin.y, size.width, size.height) display:YES];
            }
        } completionHandler:^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if(strongSelf) {
                strongSelf->_isAnimating = 0;
                if(isInSamll)
                    [strongSelf showAnimateInSmallReverseLogic:isReverse viewToShow:viewToShow];
                else
                    [strongSelf showAnimateReverseLogic:isReverse viewToShow:viewToShow];
            }
        }];
    } else {
        if(isInSamll)
            [self showAnimateInSmallReverseLogic:isReverse viewToShow:viewToShow];
        else
            [self showAnimateReverseLogic:isReverse viewToShow:viewToShow];
    }
}
//showAnimateReverse原本逻辑，等窗口移动后再执行（added by levey）
//大小界面切换
- (void)showAnimateReverseLogic:(BOOL)isReverse viewToShow:(NSInteger*)viewToShow {
    if(self.cleanStatus == CleanStatusFirst|| self.cleanStatus == CleanStatusMainPage) {
        if(!isReverse) {
            *viewToShow = 4;
        }
        _isAnimating = 4;
        [self ScaleTransOpacityAnimate:self.mainCircleImageView reverse:isReverse isCenter:NO type:kCAMediaTimingFunctionEaseIn];
        [self TransOpacityAnimate:self.startScanBtn reverse:isReverse offsetY:-27 opacity:0 durationT:0.24 durationO:0.2 delay:0 type:kCAMediaTimingFunctionEaseIn];
        [self TransOpacityAnimate:self.mainViewTitleLabel reverse:isReverse offsetY:-27 opacity:0 durationT:0.24 durationO:0.2 delay:0.04 type:kCAMediaTimingFunctionEaseIn];
        [self TransOpacityAnimate:self.mainViewDescLabel reverse:isReverse offsetY:-27 opacity:0 durationT:0.24 durationO:0.2 delay:0.04 type:kCAMediaTimingFunctionEaseIn];
    } else if(self.cleanStatus == CleanStatusScanProgress || self.cleanStatus == CleanStatusCleanProgress) {
        if(!isReverse) {
            *viewToShow = 6;
        }
        _isAnimating = 6;
        [self ScaleTransOpacityAnimate:self.processAnimateUpView reverse:isReverse isCenter:NO type:kCAMediaTimingFunctionEaseIn];
        [self TransOpacityAnimate:self.processAnimateScanBottomView reverse:isReverse offsetY:-27 opacity:0 durationT:0.24 durationO:0.2 delay:0 type:kCAMediaTimingFunctionEaseIn];
        [self TransOpacityAnimate:self.processAnimateScanUpView reverse:isReverse offsetY:-27 opacity:0 durationT:0.24 durationO:0.2 delay:0.04 type:kCAMediaTimingFunctionEaseIn];
        [self TransOpacityAnimate:self.scanPathLabel reverse:isReverse offsetY:-27 opacity:0 durationT:0.24 durationO:0.2 delay:0.04 type:kCAMediaTimingFunctionEaseIn];
        [self TransOpacityAnimate:self.scanDetailBtn reverse:isReverse offsetY:-27 opacity:0 durationT:0.24 durationO:0.2 delay:0.04 type:kCAMediaTimingFunctionEaseIn];
        [self TransOpacityAnimate:self.scanProgressView reverse:isReverse offsetY:-27 opacity:0 durationT:0.24 durationO:0.2 delay:0.04 type:kCAMediaTimingFunctionEaseIn];
    } else {
        if(!isReverse) {
            *viewToShow = 3;
        }
        _isAnimating = 3;
        [self ScaleTransOpacityAnimate:self.resultAnimateUpView reverse:isReverse isCenter:NO type:kCAMediaTimingFunctionEaseOut];
        [self TransOpacityAnimate:self.resultAnimateBottomView reverse:isReverse offsetY:kAnimateBottomTransY duration:kAnimateDuration];
        [self TransOpacityAnimate:self.backToMainBtn reverse:isReverse offsetY:0 duration:kAnimateDuration];
    }
}
//小界面内切换
- (void)showAnimateInSmallReverseLogic:(BOOL)isReverse viewToShow:(NSInteger*)viewToShow {
    if(self.cleanStatus == CleanStatusFirst|| self.cleanStatus == CleanStatusMainPage) {
        if(!isReverse) {
            *viewToShow = 3;
        }
        _isAnimating = 3;
        [self TransOpacityAnimate:self.mainViewTitleLabel reverse:isReverse offsetY:16 opacity:0 durationT:0.16 durationO:0.16 delay:0 type:kCAMediaTimingFunctionEaseIn];
        [self TransOpacityAnimate:self.mainViewDescLabel reverse:isReverse offsetY:0 opacity:0 durationT:0.16 durationO:0.16 delay:0 type:kCAMediaTimingFunctionEaseIn];
        [self TransOpacityAnimate:self.startScanBtn reverse:isReverse offsetY:-48 opacity:0 durationT:0.16 durationO:0.12 delay:0 type:kCAMediaTimingFunctionEaseIn];
    } else if(self.cleanStatus == CleanStatusScanProgress) {
        if(!isReverse) {
            *viewToShow = 6;
            _isAnimating = 6;
            [self ScaleTransOpacityAnimate:self.processAnimateUpView reverse:isReverse isCenter:YES type:kCAMediaTimingFunctionEaseIn];
        } else {
            _isAnimating = 5;
        }
        [self TransOpacityAnimate:self.processAnimateScanUpView reverse:isReverse offsetY:-7 opacity:0 durationT:0.12 durationO:0.2 delay:0 type:kCAMediaTimingFunctionEaseOut];
        [self TransOpacityAnimate:self.processAnimateScanBottomView reverse:isReverse offsetY:-26 opacity:0 durationT:0.12 durationO:0.2 delay:0 type:kCAMediaTimingFunctionEaseOut];
        [self TransOpacityAnimate:self.scanPathLabel reverse:isReverse offsetY:0 opacity:0 durationT:0.12 durationO:0.12 delay:0 type:kCAMediaTimingFunctionEaseOut];
        [self TransOpacityAnimate:self.scanDetailBtn reverse:isReverse offsetY:0 opacity:0 durationT:0.12 durationO:0.12 delay:0 type:kCAMediaTimingFunctionEaseOut];
        [self TransOpacityAnimate:self.scanProgressView reverse:isReverse offsetY:0 opacity:0 durationT:0.12 durationO:0.12 delay:0 type:kCAMediaTimingFunctionEaseOut];
    } else if (self.cleanStatus == CleanStatusCleanProgress) {
        if(!isReverse) {
            *viewToShow = 6;
        }
        _isAnimating = 6;
        [self ScaleTransOpacityAnimate:self.processAnimateUpView reverse:isReverse isCenter:YES type:kCAMediaTimingFunctionEaseIn];
        [self TransOpacityAnimate:self.processAnimateScanUpView reverse:isReverse offsetY:-7 opacity:0 durationT:0.12 durationO:0.2 delay:0 type:kCAMediaTimingFunctionEaseOut];
        [self TransOpacityAnimate:self.processAnimateScanBottomView reverse:isReverse offsetY:-26 opacity:0 durationT:0.12 durationO:0.2 delay:0 type:kCAMediaTimingFunctionEaseOut];
        [self TransOpacityAnimate:self.scanPathLabel reverse:isReverse offsetY:0 opacity:0 durationT:0.12 durationO:0.12 delay:0 type:kCAMediaTimingFunctionEaseOut];
        [self TransOpacityAnimate:self.scanDetailBtn reverse:isReverse offsetY:0 opacity:0 durationT:0.12 durationO:0.12 delay:0 type:kCAMediaTimingFunctionEaseOut];
        [self TransOpacityAnimate:self.scanProgressView reverse:isReverse offsetY:0 opacity:0 durationT:0.12 durationO:0.12 delay:0 type:kCAMediaTimingFunctionEaseOut];
    } else {
        if(!isReverse) {
            *viewToShow = 5;
        }
        _isAnimating = 5;
        [self ScaleTransOpacityAnimate:self.resultAnimateUpView reverse:isReverse isCenter:YES type:kCAMediaTimingFunctionEaseOut];
        [self TransOpacityAnimate:self.resultTitleLabel reverse:isReverse offsetY:16 opacity:0 durationT:0.16 durationO:0.16 delay:0 type:kCAMediaTimingFunctionEaseIn];
        [self TransOpacityAnimate:self.resultAnimateBottomUView reverse:isReverse offsetY:0 opacity:0 durationT:0.16 durationO:0.16 delay:0 type:kCAMediaTimingFunctionEaseIn];
        [self TransOpacityAnimate:self.resultAnimateBottomBView reverse:isReverse offsetY:-48 opacity:0 durationT:0.16 durationO:0.12 delay:0 type:kCAMediaTimingFunctionEaseIn];
        [self TransOpacityAnimate:self.backToMainBtn reverse:isReverse offsetY:0 duration:kAnimateDuration];
    }
}

- (void)ScaleTransOpacityAnimate:(NSView*)view reverse:(BOOL)isReverse isCenter:(BOOL)isCenter type:(NSString*)type {
    if(view == nil)
        return;
    NSSize size = view.frame.size;
    NSPoint origin = view.frame.origin;
    CGFloat scale = 0.6;
    NSPoint newOrigin = NSMakePoint(origin.x + size.width * (1 - scale) / 2, origin.y + size.height * (1 - scale) / 2);
    if(!isCenter) {
        newOrigin.x = kUpAnimatePointX;
        newOrigin.y = kUpAnimatePointY;
        scale = kUpAnimateSizeW / size.width;
    }
    
    
    CABasicAnimation *animation1 = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    CABasicAnimation *animation3 = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    CABasicAnimation *animation4 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    if(!isReverse) {
        animation1.fromValue = [NSNumber numberWithFloat:1.0];
        animation1.toValue = [NSNumber numberWithFloat:scale];
        animation2.fromValue = [NSNumber numberWithFloat:0];
        animation2.toValue = [NSNumber numberWithFloat:newOrigin.x - origin.x];
        animation3.fromValue = [NSNumber numberWithFloat:0];
        animation3.toValue = [NSNumber numberWithFloat:newOrigin.y - origin.y];
        animation4.fromValue = [NSNumber numberWithFloat:1];
        animation4.toValue = [NSNumber numberWithFloat:0];
    } else {
        animation1.toValue = [NSNumber numberWithFloat:1.0];
        animation1.fromValue = [NSNumber numberWithFloat:scale];
        animation2.toValue = [NSNumber numberWithFloat:0];
        animation2.fromValue = [NSNumber numberWithFloat:newOrigin.x - origin.x];
        animation3.toValue = [NSNumber numberWithFloat:0];
        animation3.fromValue = [NSNumber numberWithFloat:newOrigin.y - origin.y];
        animation4.toValue = [NSNumber numberWithFloat:1];
        animation4.fromValue = [NSNumber numberWithFloat:0];
    }
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.timingFunction = [CAMediaTimingFunction functionWithName:type];
    group.duration = kAnimateDuration;
    group.repeatCount = 1;
    group.delegate = self;
    group.animations = [NSArray arrayWithObjects:animation1, animation2, animation3, animation4, nil];
    group.timingFunction = [CAMediaTimingFunction functionWithName:type];
    
    if(!isReverse) {
        group.removedOnCompletion = NO;
        group.fillMode = kCAFillModeForwards;
    } else {
        group.fillMode = kCAFillModeBackwards;
    }
    
    [view.layer addAnimation:group forKey:@"scale-trans-opacity-layer"];
}


- (void)TransOpacityAnimate:(NSView*)view reverse:(BOOL)isReverse offsetY:(CGFloat)offsetY opacity:(CGFloat)opacity durationT:(CFTimeInterval) durationT durationO:(CFTimeInterval) durationO delay:(CGFloat)delay type:(NSString*)type {
    if(view == nil)
        return;
    CABasicAnimation *animation1 = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    if(!isReverse) {
        animation1.fromValue = [NSNumber numberWithFloat:0];
        animation1.toValue = [NSNumber numberWithFloat:offsetY];
        animation1.duration = durationT;
        animation2.fromValue = [NSNumber numberWithFloat:1];
        animation2.toValue = [NSNumber numberWithFloat:opacity];
        animation2.duration = durationO;
    } else {
        animation1.toValue = [NSNumber numberWithFloat:0];
        animation1.fromValue = [NSNumber numberWithFloat:offsetY];
        animation1.duration = durationT;
        animation2.toValue = [NSNumber numberWithFloat:1];
        animation2.fromValue = [NSNumber numberWithFloat:opacity];
        animation2.duration = durationO;
    }
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.beginTime = CACurrentMediaTime() + delay;
    group.duration = MAX(durationT, durationO);
    group.repeatCount = 1;
    group.delegate = self;
    group.animations = [NSArray arrayWithObjects:animation1, animation2, nil];
    group.timingFunction = [CAMediaTimingFunction functionWithName:type];
    
    if(!isReverse) {
        group.removedOnCompletion = NO;
        group.fillMode = kCAFillModeForwards;
        
        animation1.removedOnCompletion = NO;
        animation1.fillMode = kCAFillModeForwards;
        animation2.removedOnCompletion = NO;
        animation2.fillMode = kCAFillModeForwards;
    } else {
        group.fillMode = kCAFillModeBackwards;
        
        animation1.fillMode = kCAFillModeBackwards;
        animation2.fillMode = kCAFillModeBackwards;
    }
    
    [view.layer addAnimation:group forKey:@"trans-opacity-layer"];
}

- (void)TransOpacityAnimate:(NSView*)view reverse:(BOOL)isReverse offsetY:(CGFloat)offsetY duration:(CFTimeInterval) duration {
    if(view == nil)
        return;
    CABasicAnimation *animation1 = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    if(!isReverse) {
        animation1.fromValue = [NSNumber numberWithFloat:0];
        animation1.toValue = [NSNumber numberWithFloat:offsetY];
        animation2.fromValue = [NSNumber numberWithFloat:1];
        animation2.toValue = [NSNumber numberWithFloat:0];
    } else {
        animation1.toValue = [NSNumber numberWithFloat:0];
        animation1.fromValue = [NSNumber numberWithFloat:offsetY];
        animation2.toValue = [NSNumber numberWithFloat:1];
        animation2.fromValue = [NSNumber numberWithFloat:0];
    }
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = duration;
    group.repeatCount = 1;
    group.delegate = self;
    group.animations = [NSArray arrayWithObjects:animation1, animation2, nil];
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    if(!isReverse) {
        group.removedOnCompletion = NO;
        group.fillMode = kCAFillModeForwards;
    } else {
        group.fillMode = kCAFillModeBackwards;
    }
    
    [view.layer addAnimation:group forKey:@"trans-opacity-layer"];
}

-(void)notifyToStartScan{
    //开始启动扫描
    __weak LMCleanScanViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!weakSelf.isParseEnd) {
            usleep(10000);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:START_TO_SCAN object:nil];
            weakSelf.isParseEnd = NO;
        });
        [[QMCleanManager sharedManger] customStartScan:weakSelf array:self->_categoryArray];
    });
}


#pragma mark-
#pragma mark animation delegate

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    if(_isAnimating > 0)
        _isAnimating--;
    
    if(_isAnimateToShowBigCleanView > 0) {
        _isAnimateToShowBigCleanView--;
        if(!_isAnimateToShowBigCleanView) {
            [self showBigCleanViewLogic];
        }
    }
    
    if(_isAnimateToShowScanView > 0) {
        _isAnimateToShowScanView--;
        if(!_isAnimateToShowScanView) {
            //转场界面
            CleanStatus cleanStatus = self.cleanStatus;
            self.cleanStatus = CleanStatusScanProgress;
            [self reArrangeContentView:cleanStatus];
            //如果当前显示了toolView,在startScan:(id)sender方法中已经通知清理，不需要再次清理，只需要开启动画
            if(!self->_isCloseToolView){
                [self notifyToStartScan];
            }
            [self showAnimateReverse:YES viewToShow:nil isInSamll:YES];
        }
    }
    
    if(_isAnimateToShowMainView > 0) {
        _isAnimateToShowMainView--;
        if(!_isAnimateToShowMainView) {
            [self junpToMainPage:nil];
            
            [self showAnimateReverse:YES viewToShow:nil isInSamll:YES];
        }
    }
    
    if(_isAnimateToShowScanResView > 0) {
        _isAnimateToShowScanResView--;
        if(!_isAnimateToShowScanResView) {
            CleanStatus status = self.cleanStatus;
            if (_totalSize == 0) {
                self.cleanStatus = CleanStatusScanNoResult;
            }else{
                self.cleanStatus = CleanStatusScanResult;
            }
            [self reArrangeContentView:status];
            
            //            if ([[LMCleanerDataCenter shareInstance] isBigPage]) {
            //                [self showBigCleanViewNotUIAction];
            //            }
            [self showAnimateReverse:YES viewToShow:nil isInSamll:YES];
        }
    }
    
    if(_isAnimateToShowCleanResView > 0) {
        _isAnimateToShowCleanResView--;
        if(!_isAnimateToShowCleanResView) {
            
            CleanStatus status = self.cleanStatus;
            self.cleanStatus = CleanStatusCleanResult;
            [self reArrangeContentView:status];
            
            if ([[LMCleanerDataCenter shareInstance] isBigPage]) {
                [self showBigCleanViewNotUIAction];
            }
            [self showAnimateReverse:YES viewToShow:nil isInSamll:YES];
        }
    }
    
    if(_isAnimateToShowCleanView > 0) {
        _isAnimateToShowCleanView--;
        if(!_isAnimateToShowCleanView) {
            CleanStatus cleanStatus = self.cleanStatus;
            self.cleanStatus = CleanStatusCleanProgress;
            [self reArrangeContentView:cleanStatus];
            [[QMCleanManager sharedManger] startCleaner];
            
            [self showAnimateReverse:YES viewToShow:nil isInSamll:YES];
        }
    }
}

- (void)windowWillDismiss:(NSString *)clsName {
    if (clsName != nil) {
        [[LemonVCModel shareInstance].toolConMap setValue:nil forKey:clsName];
    }
}
    
-(CGPoint)getCenterPoint{
    CGPoint origin = self.view.window.frame.origin;
    CGSize size = self.view.window.frame.size;
    return CGPointMake(origin.x + size.width / 2, origin.y + size.height / 2);
}

#pragma mark-
#pragma mark btn action

- (void)networkChange:(NSNotification *)notif {
    NSDictionary *userInfo = [notif userInfo];
    self.networkType = [[userInfo objectForKey:@"network"] integerValue];
}

-(IBAction)back:(id)sender{
    [self backAction];
}

- (void)backAction {
    if(_isAnimating) return;
    [self reParseTheXml];
    [self _closeGuideIfNeeded];
    
    //获取一次当前授权状态
    [[LMCleanerDataCenter shareInstance] setAuthStatus:[QMFullDiskAccessManager getFullDiskAuthorationStatus]];
    //    [self junpToMainPage:nil];
    [self showAnimateReverse:NO viewToShow:&_isAnimateToShowMainView isInSamll:YES];
}

//主图形点击gesture
-(void)clickMainPic{
    [self startScan:nil];
}

- (IBAction)showToolView:(id)sender {
    //    [sender setEnabled:NO];
    if(_isAnimating) return;
    if (_canClickShowToolViewBtn) {
        _canClickShowToolViewBtn = NO;
        [self setShowToolBtnState];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self->_canClickShowToolViewBtn = YES;
        });
    }
}

#pragma mark -- LMFileMoveIntroduceVCDelegate
- (QMBaseWindowController *)getWindowControllerByClassname:(NSString *)className{
    QMBaseWindowController *controller = nil;
    
    controller = [[LemonVCModel shareInstance].toolConMap objectForKey:className];
    if (controller == nil) {
        controller = [[NSClassFromString(className) alloc] init];
        if ([controller isKindOfClass:[QMBaseWindowController class]]) {
            ((QMBaseWindowController*)controller).delegate = self;
        }
        [[LemonVCModel shareInstance].toolConMap setValue:controller forKey:className];
    }
    return controller;
}

- (void)fileMoveIntroduceVCDidStart {
    QMBaseWindowController *controller = [self getWindowControllerByClassname:@"LMFileMoveWnController"];
    [controller showWindow:self];
    [controller setWindowCenterPositon:[self getCenterPoint]];
}

- (IBAction)startScan:(id)sender {
    if ([self shouldShowFullDiskPrivacySettingPage]) {
        NSInteger count = [[NSUserDefaults standardUserDefaults] integerForKey:kLMFullAccessDisplayAfterInstallation_Count];
        [[NSUserDefaults standardUserDefaults] setInteger:++count forKey:kLMFullAccessDisplayAfterInstallation_Count];
        
        McSystemInfo *systemInfo = [[McSystemInfo alloc] init];
        NSDate *currentBootTime = [systemInfo UpdateBootTime];
        [[NSUserDefaults standardUserDefaults] setObject:currentBootTime forKey:kLMFullAccessDisplayAfterInstallation_LastBootTime];
        
        [self showFullDiskPrivacySettingPage];
        return;
    }
    
    if ([McCoreFunction isAppStoreVersion]){
        if (!isUserGiveHomePathPermission) {
            [self showOpenPanelGetPermission];
            return;
        }
    }
    NSLog(@"small start scan");
    if(_isAnimating) return;
    //    if ([_categoryArray count] == 0) {
    //        return;
    //    }
    if ([[LMCleanerDataCenter shareInstance] isScanning]) {
        return;
    }else{
        [[LMCleanerDataCenter shareInstance] setIsScanning:YES];
    }
    [[LMCleanerDataCenter shareInstance] setAuthStatus:[QMFullDiskAccessManager getFullDiskAuthorationStatus]];
    //    [self.startScanBtn setEnabled:NO];
    //还原现场
    _scanFileNums = 0;
    _startTimeInterval = [[NSDate date] timeIntervalSince1970];
    //    if (_isCloseToolView) {
    //        [self setShowToolBtnState];
    //    }
    [[LMCleanerDataCenter shareInstance] setTotalSelectSize:0];
    [[LMCleanerDataCenter shareInstance] setTotalSelectSize:0];
    [[LMCleanerDataCenter shareInstance] setProgressValues:0];
    NSUInteger timeInterval = [[NSDate date] timeIntervalSince1970];
    [[LMCleanerDataCenter shareInstance] setStartScanTime:timeInterval];
    
    //如果当前展示的是大界面，则跳转到清理详情页
    if(self->_isCloseToolView){
        self.cleanStatus = CleanStatusScanProgress;
        [self notifyToStartScan];
        [self showBigCleanViewNotUIAction];
    }
    //开始扫描展示切换动画（added by levey）
    [self showAnimateReverse:NO viewToShow:&_isAnimateToShowScanView isInSamll:YES];
}

- (IBAction)showScanDetail:(id)sender {
    if(_isAnimating) return;
    [self showBigCleanView:sender];
    
    //扫描过程中打开大界面，后面返回也不需要出现引导
    BOOL guideHasShown = [SharedPrefrenceManager getBool:GUIDE_HAS_SHOWN];
    if(!guideHasShown) {
        [SharedPrefrenceManager putBool:YES withKey:GUIDE_HAS_SHOWN];
    }
}

- (IBAction)showBigCleanView:(id)sender {
    if(_isAnimating) return;
    [self _closeGuideIfNeeded];
    
    //展示大界面时显示切换动画（added by levey）
    [self showAnimateReverse:NO viewToShow:&_isAnimateToShowBigCleanView isInSamll:YES];
}

//重新解析xml文件
-(void)reParseTheXml{
    NSLog(@"reParseTheXml start");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[QMCleanManager sharedManger] parseCleanXMLItem];
    });
}

-(void)showGetDirAccess{
    if (isUserGiveHomePathPermission) {//如果有权限 则直接写入
        NSString *userPath = [NSString getUserHomePath];
        NSURL *fileURL = [NSURL fileURLWithPath:userPath];
        
        NSError *error;
        NSData *bookmarkData = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess
                                 includingResourceValuesForKeys:nil
                                                  relativeToURL:nil
                                                          error:&error];
        if (bookmarkData != nil) {
            [LemonSuiteUserDefaults putData:bookmarkData withKey:userPath];
        }
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_APP_GET_DIR_PRIVACY object:nil userInfo:nil  deliverImmediately:YES];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showOpenPanelGetPermission];
        });
    }
    
}

//与showBigCleanView相同，只是不执行切换动画（added by levey）
- (void)showBigCleanViewNotUIAction {
    [self showBigCleanViewLogic];
}
//showBigCleanView原本逻辑，延迟到切换动画后执行（added by levey）
- (void)showBigCleanViewLogic {
    _totalSelectedSize = [[LMCleanerDataCenter shareInstance] totalSelectSize];
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setValue:OPEN_BIG_CLEAN_VIEW forKey:@"flag"];
    if (self.cleanStatus == CleanStatusScanResult) {
        [userInfo setValue:CLEAN_VIEW_TYPE_RESULT forKey:BIG_CLEAN_VIEW_TYPE];
    }else if (self.cleanStatus == CleanStatusScanNoResult){
        [userInfo setValue:CLEAN_VIEW_TYPE_NORESULT forKey:BIG_CLEAN_VIEW_TYPE];
        [userInfo setValue:[NSNumber numberWithUnsignedInteger:_totalSelectedSize] forKey:BIG_CLEAN_VIEW_FILE_SIZE];
        [userInfo setValue:[NSNumber numberWithUnsignedInteger:_scanTime] forKey:BIG_CLEAN_VIEW_TIME];
        [userInfo setValue:[NSNumber numberWithUnsignedInteger:_scanFileNums] forKey:BIG_CLEAN_VIEW_FILE_NUMS];
    }else if (self.cleanStatus == CleanStatusScanProgress){
        [userInfo setValue:CLEAN_VIEW_TYPE_SCANNING forKey:BIG_CLEAN_VIEW_TYPE];
    }else if (self.cleanStatus == CleanStatusCleanProgress){
        [userInfo setValue:CLEAN_VIEW_TYPE_CLEANNING forKey:BIG_CLEAN_VIEW_TYPE];
    }else if (self.cleanStatus == CleanStatusCleanResult){
        [userInfo setValue:OPEN_BIG_RESULT_VIEW forKey:@"flag"];
        [userInfo setValue:[NSNumber numberWithUnsignedInteger:_totalSelectedSize] forKey:BIG_RESULT_VIEW_FILE_SIZE];
        [userInfo setValue:[NSNumber numberWithUnsignedInteger:_cleanTime] forKey:BIG_RESULT_VIEW_TIME];
        [userInfo setValue:[NSNumber numberWithUnsignedInteger:_cleanFileNums] forKey:BIG_RESULT_VIEW_FILE_NUMS];
        //        __weak LMCleanScanViewController *weakSelf = self;
        //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        //            CleanStatus cleanStatus = weakSelf.cleanStatus;
        //            weakSelf.cleanStatus = CleanStatusMainPage;
        //            [weakSelf reArrangeContentView:cleanStatus];
        //        });
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_OR_CLOSE_BIG_CLEAN_VIEW object:nil userInfo:userInfo];
}

- (IBAction)stopScan:(id)sender {
    if(_isAnimating) return;
    [[QMCleanManager sharedManger] stopScan];
    _currentScanStop = YES;
    [[LMCleanerDataCenter shareInstance] setIsScanning:NO];
}

- (IBAction)cleanOrCompleteAction:(id)sender {
    if(_isAnimating) return;
    if (self.cleanStatus == CleanStatusScanResult) {
        if (_isCleanOrChooseRubbish) {
            [self setProgressSizeLabel];
            [self setCleanCategoryLabel];
            NSUInteger timeInterval = [[NSDate date] timeIntervalSince1970];
            [[LMCleanerDataCenter shareInstance] setStartCleanTime:timeInterval];
            [[LMCleanerDataCenter shareInstance] setIsCleanning:YES];
            [self startSmallClean:nil];
            _startTimeInterval = [[NSDate date] timeIntervalSince1970];
        }else{
            [self showBigCleanView:nil];
        }
        
    }else if((self.cleanStatus == CleanStatusCleanResult) || (self.cleanStatus == CleanStatusScanNoResult)){
        //        [self junpToMainPage:nil];
        [self reParseTheXml];
        [self showAnimateReverse:NO viewToShow:&_isAnimateToShowMainView isInSamll:YES];
    }
}

- (IBAction)closeGuide:(id)sender {
    if(_isAnimating) return;
    [self _closeGuideIfNeeded];
}

#pragma mark - function
-(void)setShowToolBtnState{
    [self.showToolBtn setImage:[NSImage imageNamed:@"open_tool_image_mid_state" withClass:self.class]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.04 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
        if (!self->_isCloseToolView) {
            [userInfo setValue:OPEN_TOOL_VIEW forKey:@"flag"];
            [self.showToolBtn setImage:[NSImage imageNamed:@"open_tool_image_open_state" withClass:self.class]];
        }else{
            [userInfo setValue:CLOSE_TOOL_VIEW forKey:@"flag"];
            [self.showToolBtn setImage:[NSImage imageNamed:@"open_tool_image_close_state" withClass:self.class]];
        }
        self->_isCloseToolView = !self->_isCloseToolView;
        [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_OR_CLOSE_TOOL_VIEW object:nil userInfo:userInfo];
        [SharedPrefrenceManager putBool:self->_isCloseToolView withKey:IS_SHOW_BIG_VIEW];
    });
}

-(void)updateShowToolBtnState:(NSNotification *)notify{
    NSDictionary *userInfo = notify.userInfo;
    BOOL state = [userInfo[K_SHOW_TOOL_VIEW_BTN_STATE] boolValue];
    [self setShowToolBtnWithOpenState:state];
}

//设置showToolBtn的状态，使用场景：初始化、从大界面切换回小界面
//state: YES  展示大界面
-(void)setShowToolBtnWithOpenState:(BOOL)state{
    if(state){
        [self.showToolBtn setImage:[NSImage imageNamed:@"open_tool_image_open_state" withClass:self.class]];
        self->_isCloseToolView = YES;
    }else{
        [self.showToolBtn setImage:[NSImage imageNamed:@"open_tool_image_close_state" withClass:self.class]];
        self->_isCloseToolView = NO;
    }
    [SharedPrefrenceManager putBool:state withKey:IS_SHOW_BIG_VIEW];
}

-(void)showOpenPanelGetPermission{
    NSString *userPath = [NSString getUserHomePath];
    NSLog(@"userpath = %@", userPath);
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    openDlg.allowsMultipleSelection = YES;
    openDlg.canChooseDirectories = YES;
    openDlg.canChooseFiles = YES;
    //    NSString* language = [[NSLocale preferredLanguages] objectAtIndex:0];
    [openDlg setPrompt:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_showOpenPanelGetPermission_openDlg_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    openDlg.delegate = self;
    openDlg.message = NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_showOpenPanelGetPermission_openDlg_2", nil, [NSBundle bundleForClass:[self class]], @"");
    openDlg.directoryURL = [NSURL URLWithString:userPath];
    __weak __typeof(self) weakSelf = self;
    [openDlg beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if(result == NSModalResponseOK){
            NSLog(@"click ok");
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                //            NSLog(@"path -------- %@", [@"~/Library/" stringByExpandingTildeInPath]);
                NSArray *urls = [openDlg URLs];
                NSURL *url = [urls objectAtIndex:0];
                NSString *path = [url path];
                //            NSLog(@"user select complate path = %@", path);
                if ([path isEqualToString:userPath]) {
                    strongSelf->isUserGiveHomePathPermission = YES;
                    [strongSelf.startScanBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_showOpenPanelGetPermission_startScanBtn_3", nil, [NSBundle bundleForClass:[self class]], @"") withColor:[NSColor whiteColor]];
                    [strongSelf.showToolBtn setHidden:NO];
                    [[LMBookMark defaultShareBookmark] saveBookmarkWithFilePath:path];
                    
                    NSURL *fileURL = [NSURL fileURLWithPath:userPath];
                    
                    NSError *error;
                    NSData *bookmarkData = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess
                                             includingResourceValuesForKeys:nil
                                                              relativeToURL:nil
                                                                      error:&error];
                    if (bookmarkData != nil) {
                        [LemonSuiteUserDefaults putData:bookmarkData withKey:userPath];
                        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_APP_GET_DIR_PRIVACY object:nil userInfo:nil  deliverImmediately:YES];
                    }
                }
            }
        }else{
            NSLog(@"click cancel");
            [[NSApplication sharedApplication] terminate:self];
        }
    }];
}

#pragma mark -- 弹出完全磁盘访问权限页面

- (BOOL)shouldShowFullDiskPrivacySettingPage {
    if (@available(macOS 14.0, *)) {
        // 初次安装
        if (_isShowedFullAccessWhenFirstInstallation) {
            return NO;
        }
        
        QMFullDiskAuthorationStatus authStatus = [QMFullDiskAccessManager getFullDiskAuthorationStatus];
        if (authStatus == QMFullDiskAuthorationStatusAuthorized) {
            return NO;
        }
        
        NSInteger count = [[NSUserDefaults standardUserDefaults] integerForKey:kLMFullAccessDisplayAfterInstallation_Count];
        if (count >= LemonFullAccessMaxDisplayAfterInstallation) {
            return NO;
        }
    
        NSDate *lastBootTime = [[NSUserDefaults standardUserDefaults] objectForKey:kLMFullAccessDisplayAfterInstallation_LastBootTime];
        McSystemInfo *systemInfo = [[McSystemInfo alloc] init];
        NSDate *currentBootTime = [systemInfo UpdateBootTime];
        
        /// 上次开机时间和本次开机时间相同
        if ([lastBootTime isEqualToDate:currentBootTime]) {
            return NO;
        }
        
        return YES;
    }
    
    return NO;
}

- (void)showFullDiskPrivacySettingPage {
    if (_getFullAccessController == nil) {
        _getFullAccessController = [GetFullAccessWndController shareInstance];
        _getFullAccessController.style = GetFullDiskPopVCStylePreScan;
        [_getFullAccessController setParaentCenterPos:[self getCenterPoint] suceessSeting:nil];
    }
    [_getFullAccessController.window makeKeyAndOrderFront:nil];
}

#pragma mark -- NSOpenSavePanelDelegate
#pragma mark -- - 获取权限选择方法回调
- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url NS_AVAILABLE_MAC(10_6){
    //    NSLog(@"user select shouldEnableURL = %@", [url path]);
    NSString *userPath = [NSString getUserHomePath];
    if([[url path] isEqualToString:userPath])
        return YES;
    return NO;
}

#pragma mark - 以下两个方法只是为了控制扫描过程界面刷新的频率

- (void)scanProgressRefresh:(id)sender
{
    CGFloat progress = 0;
    UInt64 scanTotalSize = 0;
    self.currentResultSizeInfo = [NSMutableDictionary dictionary];
    for (QMCategoryItem * categoryItem in _categoryArray)
    {
        progress += categoryItem.progressValue;
        [self.currentResultSizeInfo setValue:@(categoryItem.resultFileSize) forKey:categoryItem.categoryID];
        scanTotalSize += categoryItem.resultFileSize;
    }
    progress = progress / [_categoryArray count];
    [self.scanProgressView setValue:progress];
    [[LMCleanerDataCenter shareInstance] setProgressValues:progress];
    
    NSString *sizeString = [NSString sizeStringFromSize:scanTotalSize diskMode:YES];
    NSString *unitString = [NSString unitStringFromSize:scanTotalSize diskMode:YES];
    [self.sizeLabel setStringValue:sizeString];
    [self.unitLabel setStringValue:unitString];
    
    [self setScanCategorySizeLabelSize:self.nowCleanCategory inDic:self.currentResultSizeInfo];
    
    if (_currentScanStop)
    {
        //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(cleantimer.timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //            [self receiveScanStop];
        //        });
        [self.scanProgressView setValue:0];
        [[LMCleanerDataCenter shareInstance] setProgressValues:0];
        _currentScanStop = NO;
        [_scantimer invalidate];
        _scantimer = nil;
    }
    
    [self showFloatViewInfo];
}

-(void)cleanProgressRefresh:(id)sender{
    [self.scanProgressView setValue:_cleanProgress];
    [[LMCleanerDataCenter shareInstance] setProgressValues:_cleanProgress];
    //    UInt64 lastCleanItemSize = 0;
    //    for (NSInteger i = 1; i < _nowCategoryId; i++) {
    //        NSInteger itemSize = [[self.currentResultSizeInfo objectForKey:[NSString stringWithFormat:@"%ld", i]] integerValue];
    //        lastCleanItemSize += itemSize;
    //    }
    //    _removeSize = _itemRemoveSize + lastCleanItemSize;
    [self setProgressSizeLabel];
    [self setCleanCategoryLabel];
    if (_currentCleanStop) {
        [_cleantimer invalidate];
        _cleantimer = nil;
        _currentCleanStop = NO;
    }
    
    [self showFloatViewInfo];
}

-(void)updatePathRefresh:(id)sender{
    if ((_curPath != nil) && (_curPath.length > 0)) {
        [self.scanPathLabel setStringValue:_curPath];
    }
    if (_currentScanStop || _currentCleanStop) {
        [_updatePathTimer invalidate];
        _updatePathTimer = nil;
    }
}

- (void)receiveScanStop
{
    //_isScanEnd = YES;
    //self.scanProgressView.value = 0.0;
    
    // 是否显示结果
    //[windmillLayer setShowResult:(_totalSize > 0)];
    //    [windmillLayer outAnimationWithCompletionBlock:^{
    //
    //        [startView setHidden:NO];
    //        // 结果
    //        if (_totalSize > 0)
    //        {
    //            _resultViewController = [[QMResultViewController alloc] initWithCategoryArray:_categoryArray];
    //            [_resultViewController setDelegate:(id<QMResultDelegate>)self];
    //            [_resultViewController loadView];
    //            [topTitleText setStringValue:[NSString stringWithFormat:@"扫描出 %@ 垃圾",
    //                                          [NSString stringFromDiskSize:_totalSize delimiter:nil]]];
    //        }
    //        [backButton setHidden:(_totalSelectedSize != 0)];
    //        // 处理结果
    //        [self _showMainViewContent:(_totalSize > 0 ? QMResultNeedClean : QMResultGood) needAnimation:NO];
    //        //结果页面进场动画
    //        [QMINOUTAnimation getIn:startView completionBlock:NULL];
    //
    //    }];
}

#pragma mark-
#pragma mark clean XML parse

// 配置文件更新消息
- (void)knowledgeUpdateNotification:(NSNotification *)notification
{
    
}

- (void)cleanItemParseEnd:(NSNotification *)notification
{
    NSLog(@"cleanItemParseEnd stop");
    
    __weak LMCleanScanViewController * weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        LMCleanScanViewController *strongSelf = weakSelf;
        NSArray * array = [notification object];
        if (!array || [array count] == 0)
            return;
        weakSelf.categoryArray = array;
        [weakSelf.startScanBtn setEnabled:[strongSelf->_categoryArray count] > 0];
        [[LMCleanerDataCenter shareInstance] setCategoryArray:strongSelf->_categoryArray];
        self.isParseEnd = YES;
    });
    
    //[operatButton setEnabled:YES];
}

#pragma mark-
#pragma mark Scan Delegate
- (void)scanCategoryStart:(QMCategoryItem *)item{
    self.nowCleanCategory = [item.categoryID integerValue];
    [self setScanCategorySizeLabelColor:[item.categoryID integerValue]];
    [self setCircleImageViewAniWithCategoryId:item.categoryID isStart:YES];
    [item setShowHighlight:YES];
    [item setIsScanning:YES];
}

- (void)scanProgressInfo:(float)value
                scanPath:(NSString *)path
                category:(QMCategoryItem *)categoryItem
         subCategoryItem:(QMCategorySubItem *)subItem{
    _curPath = path;
    if (!_scantimer)
    {
        _scantimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(scanProgressRefresh:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_scantimer forMode:NSRunLoopCommonModes];
    }
    if (!_updatePathTimer) {
        _updatePathTimer = [NSTimer timerWithTimeInterval:0.016 target:self selector:@selector(updatePathRefresh:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_updatePathTimer forMode:NSRunLoopCommonModes];
    }
}

-(void)scanSubCategoryDidStart:(QMCategorySubItem *)subItem{
    [subItem setIsScanning:YES];
    //    self.timeInterval = [[NSDate date] timeIntervalSince1970];
}

- (void)scanSubCategoryDidEnd:(QMCategorySubItem *)subItem{
    //    NSTimeInterval endInterval = [[NSDate date] timeIntervalSince1970];
    //    if ((endInterval - self.timeInterval) > 0.1) {
    //        NSLog(@"subItem[%@] scan time = %f", [subItem title], endInterval - self.timeInterval);
    //    }
    
    [subItem setIsScanning:NO];
    [subItem setIsScaned:YES];
    _totalSize += subItem.resultFileSize;
    _totalSelectedSize += subItem.resultSelectedFileSize;
    [[LMCleanerDataCenter shareInstance] setTotalSize:_totalSize];
    [[LMCleanerDataCenter shareInstance] setTotalSelectSize:_totalSelectedSize];
    //    NSInteger nowScanSize = _totalSize / (1000 * 1000);
    //    [self.sizeLabel setStringValue:[NSString stringWithFormat:@"%ld", nowScanSize]];
}

- (void)scanCategoryDidEnd:(QMCategoryItem *)item{
    NSLog(@"small cleanCategoryEnd = %@", item.title);
    [item setIsScanning:NO];
    _scanFileNums += [item scanFileNums];
    [[LMCleanerDataCenter shareInstance] setScanFileNumss:_scanFileNums];
    [self setScanCategorySizeLabelSize:[item.categoryID integerValue] inDic:self.currentResultSizeInfo];
}

- (void)scanCategoryAllDidEnd:(long long)num {
    NSLog(@"small all did end");
    self.fileMoveTotalNum = num;
    [[LMCleanerDataCenter shareInstance] setIsScanning:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:SCAN_DID_END object:nil];
    _scanTime = [[NSDate date] timeIntervalSince1970] - _startTimeInterval;
    [[LMCleanerDataCenter shareInstance] setScanTimess:_scanTime];
    _currentScanStop = YES;
    
    [self showAnimateReverse:NO viewToShow:&_isAnimateToShowScanResView isInSamll:YES];
    
    //开始入库一次扫描记录
    UInt64 sysSize = 0;
    UInt64 appSize = 0;
    UInt64 intSize = 0;
    for (QMCategoryItem *categoryItem in _categoryArray) {
        if([categoryItem.categoryID isEqualToString:@"1"]){
            sysSize = categoryItem.resultFileSize;
        }else if ([categoryItem.categoryID isEqualToString:@"2"]){
            appSize = categoryItem.resultFileSize;
        }else if ([categoryItem.categoryID isEqualToString:@"3"]){
            intSize = categoryItem.resultFileSize;
        }
    }
    
    [[LMCleanerDataCenter shareInstance] addCleanRecordWithTotalSize:_totalSize sysSize:sysSize appSize:appSize intSize:intSize cleanType:CleanResultTypeScan fileNum:_scanFileNums oprateTime:_scanTime];
    
    //自动适配的subItem的项目 categorykey == 1 如果size大小为0 直接先remove掉
    [[LMCleanerDataCenter shareInstance] removeSoftAdaptSubItemSizeIsZero];
}

#pragma mark-
#pragma mark Clean Delegate

- (void)cleanProgressInfo:(float)value item:(QMCategoryItem *)item path:(NSString *)path  totalSize:(NSUInteger)totalSize{
    if (!_cleantimer)
    {
        _cleantimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(cleanProgressRefresh:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_cleantimer forMode:NSRunLoopCommonModes];
    }
    if (!_updatePathTimer) {
        _updatePathTimer = [NSTimer timerWithTimeInterval:0.016 target:self selector:@selector(updatePathRefresh:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_updatePathTimer forMode:NSRunLoopCommonModes];
    }
    if (path.length > 0) {
        _removeSize += totalSize;
        _cleanProgress = value;
        _curPath = path;
        //        [self.scanPathLabel setStringValue:path];
        //        [self.currentCleanSizeInfo setValue:@(_removeSize) forKey:item.categoryID];
        [self setScanCategorySizeLabelColor:[item.categoryID integerValue]];
        if ([item.categoryID isEqualToString:@"1"]) {
            _sysSelectSize -= totalSize;
        }else if ([item.categoryID isEqualToString:@"2"]){
            _appSelectSize -= totalSize;
        }else if ([item.categoryID isEqualToString:@"3"]){
            _intSelectSize -= totalSize;
        }
        //        NSInteger scanSize = [[self.currentResultSizeInfo objectForKey:item.categoryID] integerValue];
        //        _itemRemoveSize = scanSize - totalSize;
        //        _nowCategoryId = [item.categoryID integerValue];
        //        NSLog(@"剩余清理的数据大小 %ld 清理的进度 %f, path = %@ categoryID = %@", totalSize, value, path, item.categoryID);
    }
}

- (void)cleanCategoryStart:(QMCategoryItem *)categoryItem{
    [categoryItem setIsCleanning:YES];
    [categoryItem setShowHignlightClean:YES];
    [self setCircleImageViewAniWithCategoryId:categoryItem.categoryID isStart:YES];
}

- (void)cleanCategoryEnd:(QMCategoryItem *)categoryItem{
    [categoryItem removeAllResultItem];
    [categoryItem setIsCleanning:NO];
    NSLog(@"clean cleanCategoryEnd = %@", categoryItem.title);
    if ([categoryItem.categoryID isEqualToString:@"1"]) {
        _sysSelectSize = 0;
    }else if ([categoryItem.categoryID isEqualToString:@"2"]){
        _appSelectSize = 0;
    }else if ([categoryItem.categoryID isEqualToString:@"3"]){
        _intSelectSize = 0;
    }
}

- (void)cleanFileNums:(NSUInteger) cleanFileNums{
    _cleanFileNums = cleanFileNums;
}

- (void)cleanSubCategoryStart:(QMCategorySubItem *)subCategoryItem{
    [subCategoryItem setIsCleanning:YES];
}

- (void)cleanSubCategoryEnd:(QMCategorySubItem *)subCategoryItem{
    [subCategoryItem setIsCleanning:NO];
}

- (void)cleanResultDidEnd:(NSUInteger)totalSize leftSize:(NSUInteger)leftSize{
    NSLog(@"清理完成");
    [[LMCleanerDataCenter shareInstance] setIsCleanning:NO];
    _currentCleanStop = YES;
    //    [_internetRubbishImageView stopAni];
    _cleanTime = [[NSDate date] timeIntervalSince1970] - _startTimeInterval;
    
    _totalSelectedSize = [[LMCleanerDataCenter shareInstance] totalSelectSize];
    [[LMCleanerDataCenter shareInstance] addCleanRecordWithTotalSize:_totalSelectedSize sysSize:_sysSelectSize appSize:_appSelectSize intSize:_intSelectSize cleanType:CleanResultTypeRemove fileNum:_scanFileNums oprateTime:_cleanTime];
    if ([[LMCleanerDataCenter shareInstance] isBigPage]) {
        //大界面切换大界面，不执行切换动画（added by levey）
        //        [self showBigCleanView:nil];
        CleanStatus status = self.cleanStatus;
        self.cleanStatus = CleanStatusCleanResult;
        [self reArrangeContentView:status];
        [self showBigCleanViewNotUIAction];
    }else{
        [self showAnimateReverse:NO viewToShow:&_isAnimateToShowCleanResView isInSamll:YES];
    }
    
    [[LMCleanerDataCenter shareInstance] setAuthStatus:[QMFullDiskAccessManager getFullDiskAuthorationStatus]];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_CLENER_CLEAN_SUCCESS object:nil userInfo:nil  deliverImmediately:YES];
    NSLog(@"lemon app send main_cleaner_clean_success notification: %@", MAIN_CLENER_CLEAN_SUCCESS);
}

#pragma mark -- choose category delegate
-(void)selectCategory:(NSUInteger)categoryNum{
    UInt64 totalSize = 0;
    if (categoryNum == 0) {
        if (self.cleanStatus == CleanStatusScanResult) {
            totalSize = _totalSize;
        }else if(self.cleanStatus == CleanStatusCleanResult){
            totalSize = [[LMCleanerDataCenter shareInstance] sysSelectSize] + [[LMCleanerDataCenter shareInstance] appSelectSize] + [[LMCleanerDataCenter shareInstance] intSelectSize];
        }
        
        if (self.cleanStatus == CleanStatusScanResult) {
            [self.resultTipLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_selectCategory_resultTipLabel_1", nil, [NSBundle bundleForClass:[self class]], @"")];
            [self.resultTipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(self.resultView);
                make.centerY.equalTo(self.resultTipImageView);
            }];
        }else if(self.cleanStatus == CleanStatusCleanResult){
            [self.resultTipImageView setHidden:NO];
            [self.resultTipLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_selectCategory_resultTipLabel_2", nil, [NSBundle bundleForClass:[self class]], @"")];
            [self.resultTipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.resultTipImageView.mas_right).offset(10);
                make.centerY.equalTo(self.resultTipImageView);
            }];
        }
    }else{
        [self.resultTipImageView setHidden:YES];
        if (self.cleanStatus == CleanStatusScanResult) {
            QMCategoryItem *item = [self getCategoryItemById:[NSString stringWithFormat:@"%ld", categoryNum]];
            totalSize = item.resultFileSize;
            [self.resultTipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(self.resultView);
                make.centerY.equalTo(self.resultTipImageView);
            }];
            if(categoryNum == 1){
                [self.resultTipLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_selectCategory_resultTipLabel_3", nil, [NSBundle bundleForClass:[self class]], @"")];
            }else if (categoryNum == 2){
                [self.resultTipLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_selectCategory_resultTipLabel_4", nil, [NSBundle bundleForClass:[self class]], @"")];
            }else if (categoryNum == 3){
                [self.resultTipLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_selectCategory_resultTipLabel_5", nil, [NSBundle bundleForClass:[self class]], @"")];
            }
        }else if(self.cleanStatus == CleanStatusCleanResult){
            [self.resultTipImageView setHidden:YES];
            if(categoryNum == 1){
                totalSize = [[LMCleanerDataCenter shareInstance] sysSelectSize];
                [self.resultTipLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_selectCategory_resultTipLabel_6", nil, [NSBundle bundleForClass:[self class]], @"")];
            }else if (categoryNum == 2){
                totalSize = [[LMCleanerDataCenter shareInstance] appSelectSize];
                [self.resultTipLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_selectCategory_resultTipLabel_7", nil, [NSBundle bundleForClass:[self class]], @"")];
            }else if (categoryNum == 3){
                totalSize = [[LMCleanerDataCenter shareInstance] intSelectSize];
                [self.resultTipLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_selectCategory_resultTipLabel_8", nil, [NSBundle bundleForClass:[self class]], @"")];
            }
            [self.resultTipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(self.resultCircleImageView);
                make.centerY.equalTo(self.resultTipImageView);
            }];
        }
        
        
    }
    NSString *sizeString = [NSString stringFromDiskSize:totalSize];
    [self.resultSizeLabel setStringValue:sizeString];
}

#pragma mark -- show window when nouse on category
- (void)onProgressViewMouseEnter:(id)sender {
    [self.floatViewFrame setHidden:NO];
    if(sender == self.systemRubbishImageView) {
        _floatViewIdx = kCategorySys;
    } else if(sender == self.appRubbishImageView) {
        _floatViewIdx = kCategoryApp;
    } else if(sender == self.internetRubbishImageView) {
        _floatViewIdx = kCategoryInt;
    } else {
        _floatViewIdx = kCategoryNil;
    }
    [self showFloatViewInfo];
}

- (void)onProgressViewMouseExit:(id)sender {
    [self.floatViewFrame setHidden:YES];
    _floatViewIdx = kCategoryNil;
}

- (void)showFloatViewInfo {
    if([_floatViewIdx isEqualToString:kCategoryNil])
        return;
    for(QMCategoryItem* item in self.categoryArray) {
        if([item.categoryID isEqualToString:_floatViewIdx]) {
            _floatViewTitle.stringValue = item.title;
            _floatViewDesc.stringValue = item.tips;
            
            BOOL isShowHighlight = (self.cleanStatus == CleanStatusCleanProgress) ? item.showHignlightClean : item.showHighlight;
            if([_floatViewIdx isEqualToString:kCategorySys]) {
                if(isShowHighlight)
                    _floatViewIcon.image = [bundle imageForResource:@"sys_enable"];
                else
                    _floatViewIcon.image = [bundle imageForResource:@"sys_disable"];
                _floatViewBg.image = [bundle imageForResource:@"float_win_bg_left"];
            } else if([_floatViewIdx isEqualToString:kCategoryApp]) {
                if(isShowHighlight)
                    _floatViewIcon.image = [bundle imageForResource:@"app_enable"];
                else
                    _floatViewIcon.image = [bundle imageForResource:@"app_disable"];
                _floatViewBg.image = [bundle imageForResource:@"float_win_bg_mid"];
            } else if([_floatViewIdx isEqualToString:kCategoryInt]) {
                if(isShowHighlight)
                    _floatViewIcon.image = [bundle imageForResource:@"int_enable"];
                else
                    _floatViewIcon.image = [bundle imageForResource:@"int_disable"];
                _floatViewBg.image = [bundle imageForResource:@"float_win_bg_right"];
            }
            if(self.cleanStatus == CleanStatusCleanProgress) {
                [_floatViewScanning setHidden:!item.isCleanning];
                _floatViewScanning.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_showFloatViewInfo__floatViewScanning_1", nil, [NSBundle bundleForClass:[self class]], @"");
            } else {
                [_floatViewScanning setHidden:!item.isScanning];
                _floatViewScanning.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_showFloatViewInfo__floatViewScanning_2", nil, [NSBundle bundleForClass:[self class]], @"");
            }
            if(isShowHighlight) {
                [_floatViewTitle setTextColor:[NSColor colorWithHex:0xffbe46]];
                //                [_floatViewSize setTextColor:[NSColor colorWithHex:0x515151]];
                [self setTitleColorForTextField:_floatViewSize];
                [_floatViewSize setFont:[NSFont systemFontOfSize:16]];
                if(self.cleanStatus == CleanStatusCleanProgress) {
                    if([self isCategoryNoSelect:item])
                        _floatViewSize.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_showFloatViewInfo__floatViewSize_3", nil, [NSBundle bundleForClass:[self class]], @"");
                    else if(!item.isCleanning)
                        _floatViewSize.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_showFloatViewInfo__floatViewSize_4", nil, [NSBundle bundleForClass:[self class]], @"");
                    else {
                        if([_floatViewIdx isEqualToString:kCategorySys])
                            _floatViewSize.stringValue = [NSString stringFromDiskSize:_sysSelectSize];
                        else if([_floatViewIdx isEqualToString:kCategoryApp])
                            _floatViewSize.stringValue = [NSString stringFromDiskSize:_appSelectSize];
                        else if([_floatViewIdx isEqualToString:kCategoryInt])
                            _floatViewSize.stringValue = [NSString stringFromDiskSize:_intSelectSize];
                    }
                } else {
                    _floatViewSize.stringValue = [NSString stringFromDiskSize:item.resultFileSize];
                }
            } else {
                //                [_floatViewTitle setTextColor:[NSColor colorWithHex:0x515151]];
                [self setTitleColorForTextField:_floatViewTitle];
                [_floatViewSize setTextColor:[NSColor colorWithHex:0x94979b]];
                [_floatViewSize setFont:[NSFont systemFontOfSize:14]];
                if(self.cleanStatus == CleanStatusCleanProgress) {
                    if([self isCategoryNoSelect:item])
                        _floatViewSize.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_showFloatViewInfo__floatViewSize_5", nil, [NSBundle bundleForClass:[self class]], @"");
                    else
                        _floatViewSize.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_showFloatViewInfo__floatViewSize_6", nil, [NSBundle bundleForClass:[self class]], @"");
                } else {
                    _floatViewSize.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanScanViewController_showFloatViewInfo__floatViewSize_7", nil, [NSBundle bundleForClass:[self class]], @"");
                }
            }
        }
    }
}

- (BOOL)isCategoryNoSelect:(QMCategoryItem*)item {
    if([item.categoryID isEqualToString:kCategorySys])
        return [[LMCleanerDataCenter shareInstance] sysSelectSize] == 0;
    if([item.categoryID isEqualToString:kCategoryApp])
        return [[LMCleanerDataCenter shareInstance] appSelectSize] == 0;
    if([item.categoryID isEqualToString:kCategoryInt])
        return [[LMCleanerDataCenter shareInstance] intSelectSize] == 0;
    return YES;
}

@end
