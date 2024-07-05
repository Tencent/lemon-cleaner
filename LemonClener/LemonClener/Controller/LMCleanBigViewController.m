//
//  LMCleanBigViewController.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMCleanBigViewController.h"
#import "QMCleanManager.h"
#import "LMCleanerDataCenter.h"
#import "CleanerCantant.h"
#import "CategoryCellView.h"
#import "BigCleanParaentCellView.h"
#import "QMResultTableRowView.h"
#import "CategoryCellView.h"
#import "SubCategoryCellView.h"
#import "QMDataConst.h"
#import <QMUICommon/LMImageButton.h>
#import <LemonClener/ToolModel.h>
#import "ToolCellView.h"
#import "LMResultButton.h"
#import <QMCoreFunction/NSString+Extension.h>
#import <QMUICommon/QMMoveOutlineView.h>
#import <QMUICommon/LMRectangleButton.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <QMCleanManager.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/QMProgressView.h>
#import <QMUICommon/LMBorderButton.h>
#import <QMUICommon/NSFontHelper.h>
#import "MacDeviceHelper.h"
#import "LMCleanerScroller.h"
#import "AnimationHelper.h"
#import <QMUICommon/GetFullAccessWndController.h>
#import <Masonry/Masonry.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import "LMFileMoveIntroduceVC.h"
#import "LMFileMoveWnController.h"
#import "LemonVCModel.h"
#import <LemonFileMove/LMFileMoveDefines.h>
#import <LemonFileMove/LMFileMoveFeatureDefines.h>

#define Lemon_KB_To_GB 1000000000.0
#define kItemIdDownloadSubItemID @"1007"

static NSString * const kLemonFileMoveIntroduceVCDidAppear = @"kLemonFileMoveIntroduceVCDidAppear";

@interface LMCleanBigViewController ()<NSOutlineViewDelegate, NSOutlineViewDataSource, NSTableViewDelegate, NSTableViewDataSource, QMCleanManagerDelegate, CAAnimationDelegate, LMFileMoveIntroduceVCDelegate, QMWindowDelegate>
{
    BOOL isDidAppear;
    NSArray * m_categoryArray;
    IBOutlet NSButton *_showInFinderButton;
    NSInteger _lastTag;
    BOOL _currentScanStop;
    BOOL _currentCleanStop;
    NSInteger _cleanFileNums;
    CGFloat _cleanProgress;
    QMCategoryItem *m_curCategoryItem;
    QMCategorySubItem *m_curSubCategoryItem;
    
    NSInteger _isAnimating;                     //动画计数，用于屏蔽动画中点击事件或跳转逻辑（切换动画同一时间只有一套，可以用一个计数简单处理）
    GetFullAccessWndController *getFullAccessController;
}
@property (nonatomic, strong) NSMutableArray *dataSource;//没有扫描出垃圾的数据源
@property (nonatomic, strong) NSMutableArray *categoryItemArr;//三个大项 item  用于展开子项
//resultView
@property (strong) IBOutlet NSView *scanResultView;
@property (strong) IBOutlet NSView *scanResultUpAnimateView;
@property (strong) IBOutlet NSScrollView *scanResultScrollView;
@property (weak) IBOutlet NSImageView *logoImageView;
@property (weak) IBOutlet LMRectangleButton *removeButton;
@property (strong, nonatomic) QMProgressView *scanProgressView;
@property (weak) IBOutlet LMBorderButton *backBtn;
@property (weak) IBOutlet NSTextField *rubbishSizeLabel;
@property (weak) IBOutlet NSTextField *rubbishSelectLabel;
@property (weak) IBOutlet NSTextField *rubbishSelectTitle;
@property (strong) IBOutlet NSView *topLineView;
@property (weak) IBOutlet QMMoveOutlineView *outLineView;
// 扫描过程限制刷新频率
@property (strong, nonatomic) NSTimer *scantimer;
//清理过程timer
@property (strong, nonatomic) NSTimer *cleantimer;
//刷新路径timer
@property (strong, nonatomic) NSTimer *updatePathTimer;
@property (strong, nonatomic) NSString *curPath;
//no result View
@property (strong) IBOutlet NSView *noResultView;
@property (strong) IBOutlet NSView *noResultUpAnimateView;
@property (weak) IBOutlet NSTextField *mainText;
@property (weak) IBOutlet NSTextField *fileNumText;
@property (weak) IBOutlet NSTextField *timeText;
@property (weak) IBOutlet NSTextField *introText;
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet LMRectangleButton *doneButton;
@property (weak) IBOutlet NSView *seprateLineView;
@property (nonatomic, assign) BOOL isShowBigScanView;
@property (nonatomic, strong) NSImageView *fileMoveIcon;
@property (nonatomic, strong) NSTextField *fileMoveLabel;
@property (nonatomic, strong) NSButton *fileMoveButton;
@property (nonatomic, strong) NSArray *fileMoveArr;

@end

@implementation LMCleanBigViewController

-(id)init{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        
    }
    
    return self;
}

#pragma mark -- 生命周期回调

-(void)viewDidAppear{
    [super viewDidAppear];
    isDidAppear = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self initData];
    [self initView];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -- 数据或界面初始化
-(void)initData{
    //    [[QMCleanManager sharedManger] setBigViewCleanDelegate:self];
    //    [self setResultTotalAndSelectSizeLabel];
    
    [[LMCleanerDataCenter shareInstance] setAuthStatus:[QMFullDiskAccessManager getFullDiskAuthorationStatus]];
    _isAnimating = 0;
    _categoryItemArr = [[NSMutableArray alloc] init];
    //    m_categoryArray = [[LMCleanerDataCenter shareInstance] getCategoryArray];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startScan) name:START_TO_SCAN object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scanDidEnd:) name:SCAN_DID_END object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(needDispalyCleaningPage) name:NEED_DISPLAY_BIG_VIEW_CLEANING object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showFullDiskPrivacySettingPage) name:START_TO_SHOW_FULL_DISK_PRIVACY_SETTING object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backAction) name:LM_FILE_MOVE_DID_START_NOTIFICATION object:nil];
    [self.removeButton setTitle:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_initData_removeButton_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.doneButton setTitle:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_initData_doneButton_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    self.introText.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_initData_introText_1", nil, [NSBundle bundleForClass:[self class]], @"");
    [self setTitleColorForTextField:self.introText];
    [self.introText mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.noResultView).offset(65);
        make.top.equalTo(self.seprateLineView.mas_bottom).offset(35);
    }];
}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:self.seprateLineView];
    [LMAppThemeHelper setDivideLineColorFor:self.topLineView];
}

-(void)initView{
    [self.view addSubview:self.scanResultView];
    [self.view addSubview:self.noResultView];
    
    [self.rubbishSizeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.logoImageView.mas_right).offset(22);
        make.top.equalTo(self.logoImageView).offset(13.5);
    }];

    [self.backBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.rubbishSizeLabel.mas_right).offset(20);
        make.centerY.equalTo(self.rubbishSizeLabel);
        make.width.equalTo(@60);
        make.height.equalTo(@24);
    }];
    
    [self.removeButton setHidden:YES];
    [self.removeButton setEnabled:NO];
    [self setProgressViewStyle];
    if (@available(macOS 10.14, *)) {
        [_outLineView setBackgroundColor:[NSColor colorNamed:@"view_bg_color" bundle:[NSBundle mainBundle]]];
    } else {
        [_outLineView setBackgroundColor:[NSColor whiteColor]];
    }
    [_outLineView setHeaderView:nil];
    //    [_outLineView setMoveOutlineViewDelegate:self];
    LMCleanerScroller *scroller = [[LMCleanerScroller alloc] init];
    [self.scanResultScrollView setVerticalScroller:scroller];
    self.scanResultScrollView.backgroundColor = [LMAppThemeHelper getMainBgColor];
    //单击展开和收起
    _outLineView.target = self;
    _outLineView.action = @selector(clickExpandOrShrink);
    
    [self.logoImageView setImageScaling:NSImageScaleProportionallyUpOrDown];
//    [self.rubbishSizeLabel setTextColor:[NSColor colorWithHex:0x515151]];
    [self setTitleColorForTextField:self.rubbishSizeLabel];
    [self.rubbishSelectLabel setTextColor:[NSColor colorWithHex:0xFFBE46]];
    [self.rubbishSelectTitle setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [self.rubbishSelectTitle setTextColor:[NSColor colorWithHex:0x94979b]];
//    [self.seprateLineView setWantsLayer:YES];
//    [self.seprateLineView.layer setBackgroundColor:[NSColor colorWithHex:0xe8e8e8 alpha:0.6].CGColor];
    [self initNoResultData];
    [self.noResultView becomeFirstResponder];
    [self.noResultView setAcceptsTouchEvents:YES];
    _tableView.headerView = nil;
    _tableView.backgroundColor = [LMAppThemeHelper getMainBgColor];
    
    [self setLabelFont];
    
    // 图标
    NSImageView *fileMoveIcon = [[NSImageView alloc] init];
    [fileMoveIcon setImage:[NSImage imageNamed:@"file_move_icons" withClass:[self class]]];
    self.fileMoveIcon = fileMoveIcon;
    [self.scanResultView addSubview:self.fileMoveIcon];
    [self.fileMoveIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(20);
        make.width.mas_equalTo(70);
        make.bottom.equalTo(self.logoImageView.mas_bottom).offset(-14);
        make.left.equalTo(self.logoImageView.mas_right).offset(20);
    }];
    self.fileMoveIcon.hidden = YES;
    // 文案
    NSTextField *fileMoveLabel = [[NSTextField alloc] init];
    fileMoveLabel.stringValue = @"文件、视频和图片已占999GB空间不敢清理？快试试";
    fileMoveLabel.wantsLayer = YES;
    fileMoveLabel.editable = NO;
    fileMoveLabel.lineBreakMode = NSLineBreakByTruncatingHead;
    fileMoveLabel.font = [NSFont systemFontOfSize:12];
    [fileMoveLabel setTextColor:[NSColor colorWithHex:0x989A9E]];
    fileMoveLabel.backgroundColor = [NSColor clearColor];
    fileMoveLabel.bordered = NO;
    self.fileMoveLabel = fileMoveLabel;
    [self.scanResultView addSubview:self.fileMoveLabel];
    [self.fileMoveLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(18);
        make.centerY.equalTo(self.fileMoveIcon);
        make.left.equalTo(self.fileMoveIcon.mas_right);
    }];
    self.fileMoveLabel.hidden = YES;
    // 按钮
    NSButton *fileMoveButton = [[NSButton alloc] init];
    fileMoveButton.bordered = NO;
    NSDictionary *dicAtt = @{NSForegroundColorAttributeName: [NSColor colorWithRed:25/255.0 green:131/255.0 blue:247/255.0 alpha:1/1.0]};
    fileMoveButton.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"File Moving", nil, [NSBundle bundleForClass:[self class]], @"") attributes:dicAtt];
    fileMoveButton.font = [NSFont systemFontOfSize:12];
    self.fileMoveButton = fileMoveButton;
    [self.scanResultView addSubview:self.fileMoveButton];
    [self.fileMoveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(18);
        make.centerY.equalTo(self.fileMoveIcon).offset(-2);
        make.left.equalTo(self.fileMoveLabel.mas_right);
    }];
    [self.fileMoveButton setTarget:self];
    [self.fileMoveButton setAction:@selector(fileMoveBtn)];
    self.fileMoveButton.hidden = YES;
    
}

- (void)fileMoveBtn {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kLemonFileMoveIntroduceVCDidAppear]) {
        LMFileMoveIntroduceVC *introduceVC =  [[LMFileMoveIntroduceVC alloc] init];
        introduceVC.delegate = self;
        [self presentViewControllerAsModalWindow:introduceVC];
        if (introduceVC.view.window) {
            CGSize windowSize = CGSizeMake(780, 482);
            CGFloat x = NSMidX(self.view.window.frame) - windowSize.width / 2;
            CGFloat y = NSMidY(self.view.window.frame) - windowSize.height / 2;
            [introduceVC.view.window setFrame:CGRectMake(x, y, windowSize.width, windowSize.height) display:YES];
        }
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kLemonFileMoveIntroduceVCDidAppear];
    } else {
        [self showFileMoveWindow];
    }
}

- (void)showFileMoveWindow {
    QMBaseWindowController *controller = [self getWindowControllerByClassname:@"LMFileMoveWnController"];
    [controller showWindow:self];
    [controller setWindowCenterPositon:[self getCenterPoint]];
}

-(void)setLabelFont{
    [_backBtn setFont:[NSFontHelper getLightSystemFont:12]];
    [_backBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_setLabelFont_backBtn_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [_rubbishSelectTitle setFont:[NSFontHelper getLightSystemFont:14]];
    [_rubbishSelectLabel setFont:[NSFontHelper getLightSystemFont:14]];
    [self.fileNumText setFont:[NSFontHelper getLightSystemFont:14]];
    [self.timeText setFont:[NSFontHelper getLightSystemFont:14]];
    [self.introText setFont:[NSFontHelper getLightSystemFont:14]];
    
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

#pragma mark -- 切换界面调用方法刷新页面
-(void)showScanBigView{
    NSLog(@"show big scan view");
    self.isShowBigScanView = YES;
    [[LMCleanerDataCenter shareInstance] setIsBigPage:YES];
    if ([self.removeButton isHidden]) {
        [self.removeButton setHidden:NO];
    }
    [_outLineView reloadData];
    [_outLineView scrollToBeginningOfDocument:nil];
    [[QMCleanManager sharedManger] setBigViewCleanDelegate:self];
    if ([[LMCleanerDataCenter shareInstance] isScanning]) {
        
        _currentScanStop = NO;
        //        [self.scanProgressView setHidden:NO];
        [self setViewIsScanningOrCleanning:YES];
        [self.removeButton setHidden:YES];
        [self.logoImageView setImage:[NSImage imageNamed:@"main_circle_bg_small" withClass:[self class]]];
    }else{
        [self.scanProgressView setValue:0];
        [self setViewIsScanningOrCleanning:NO];
        [self setRemoveButtonState];
        [self.logoImageView setImage:[NSImage imageNamed:@"big_circle_haverubbish" withClass:[self class]]];
    }
    
    [self setResultTotalAndSelectSizeLabel];
    [self.scanResultView setHidden:NO];
    [self.noResultView setHidden:YES];
}

-(void)showCleanBigView{
    NSLog(@"show big clean view");
    
    [[LMCleanerDataCenter shareInstance] setIsBigPage:YES];
    
    //    [_outLineView reloadData];
    [_outLineView scrollToBeginningOfDocument:nil];
    //    [[QMCleanManager sharedManger] setBigViewCleanDelegate:self];
    [self setRubbishSelectLabelSize];
    [self.removeButton setHidden:YES];
    [self setViewIsScanningOrCleanning:YES];
    [self.scanResultView setHidden:NO];
    [self.noResultView setHidden:YES];
    [self.logoImageView setImage:[NSImage imageNamed:@"main_circle_bg_small" withClass:[self class]]];
}

-(void)setViewIsScanningOrCleanning:(BOOL) isScanOrClean{
    if (isScanOrClean) {
        self.fileMoveIcon.hidden = YES;
        self.fileMoveButton.hidden = YES;
        self.fileMoveLabel.hidden = YES;
        [self.scanProgressView setHidden:NO];
        [self.rubbishSelectTitle setStringValue:@""];
        CGFloat progress = [[LMCleanerDataCenter shareInstance] progressValues];
        [self.scanProgressView setValue:progress];
        [self.rubbishSelectLabel setHidden:YES];
        [self.rubbishSelectTitle mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.scanResultView).offset(202);
            make.bottom.equalTo(self.logoImageView).offset(-13.5);
            make.height.equalTo(@22);
            make.width.lessThanOrEqualTo(@433);
        }];
    }else{
        [self.scanProgressView setHidden:YES];
        [self.scanProgressView setValue:0];
        [self.rubbishSelectLabel setHidden:NO];
        if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
            [self.rubbishSelectTitle mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.rubbishSizeLabel);
                make.top.equalTo(self.rubbishSizeLabel.mas_bottom).offset(8);
                make.width.lessThanOrEqualTo(@86);
                make.height.equalTo(@22);
            }];

            [self.rubbishSelectLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo(self.rubbishSelectTitle).offset(-2);
                make.left.equalTo(self.rubbishSelectTitle.mas_right).offset(2);
            }];
            
        }else{
            [self.rubbishSelectLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.logoImageView.mas_right).offset(22);
                make.top.equalTo(self.rubbishSizeLabel.mas_bottom).offset(8);
            }];
            [self.rubbishSelectTitle mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.rubbishSelectLabel.mas_right).offset(5);
                make.centerY.equalTo(self.rubbishSelectLabel);
            }];
        }
        [self.rubbishSelectTitle setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_setViewIsScanningOrCleanning_rubbishSelectTitle_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    }
}

-(void)setProgressViewStyle{
    self.scanProgressView = [[QMProgressView alloc] initWithFrame:NSMakeRect(202, 500, 433, 5)];
    //    [self.scanResultView addSubview:self.scanProgressView];
    [self.scanResultUpAnimateView addSubview:self.scanProgressView];
    self.scanProgressView.borderColor = [NSColor clearColor];
    self.scanProgressView.minValue = 0.0;
    self.scanProgressView.maxValue = 1.0;
    self.scanProgressView.value = 0.0;
    [self.scanProgressView setWantsLayer:YES];
}

-(void)setResultTotalAndSelectSizeLabel{
    NSArray *categoryArr = [[LMCleanerDataCenter shareInstance] getCategoryArray];
    UInt64 totalSize = 0;
    UInt64 selectSize = 0;
    for (QMCategoryItem *categoryItem in categoryArr) {
        totalSize += categoryItem.resultFileSize;
        selectSize += categoryItem.resultSelectedFileSize;
    }
    
    NSString *totalSizeString = [NSString stringFromDiskSize:totalSize];
    NSString *selectSizeString = [NSString stringFromDiskSize:selectSize];
    if ([[LMCleanerDataCenter shareInstance] isScanning]) {
        [self.rubbishSizeLabel setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_setResultTotalAndSelectSizeLabel_rubbishSizeLabel_1", nil, [NSBundle bundleForClass:[self class]], @""), totalSizeString]];
    }else{
        [self.rubbishSizeLabel setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_setResultTotalAndSelectSizeLabel_rubbishSizeLabel_2", nil, [NSBundle bundleForClass:[self class]], @""), totalSizeString]];
    }
    
    [self.rubbishSelectLabel setStringValue:[NSString stringWithFormat:@"%@", selectSizeString]];
}

//没有垃圾的初始化
-(void)setNoResultViewWithScanFileNum:(NSUInteger) fileNum  scanTime:(NSUInteger) scanTime{
    [self.scanResultView setHidden:YES];
    [self.noResultView setHidden:NO];
    [_mainText setStringValue:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_setNoResultViewWithScanFileNum_mainText_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    _mainText.alignment = NSTextAlignmentLeft;
    [self setTitleColorForTextField:_mainText];
    [_fileNumText setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_setNoResultViewWithScanFileNum_fileNumText_2", nil, [NSBundle bundleForClass:[self class]], @""), fileNum]];
    [_timeText setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_setNoResultViewWithScanFileNum_timeText_3", nil, [NSBundle bundleForClass:[self class]], @""), scanTime]];
    [self initNoResultData];
    [_tableView reloadData];
}

-(void)setRemoveButtonState{
    // 选择项改变 查看是否需要调整removeBtn的状态
    [[LMCleanerDataCenter shareInstance] refreshTotalSelectSize];
    UInt64 totalSelectSize = [[LMCleanerDataCenter shareInstance] totalSelectSize];
    if (totalSelectSize >0) {
        [self.removeButton setEnabled:YES];
    }else{
        [self.removeButton setEnabled:NO];
    }
}

-(void)setRubbishSelectLabelSize{
    UInt64 cleanLeftSize = [[LMCleanerDataCenter shareInstance] cleanLeftSize];
    NSString *selectSizeString = [NSString stringFromDiskSize:cleanLeftSize];
    NSString *sizeLabelStrring = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_setRubbishSelectLabelSize_sizeLabelStrring _1", nil, [NSBundle bundleForClass:[self class]], @""), selectSizeString];
    [self.rubbishSizeLabel setStringValue:sizeLabelStrring];
}

- (void)initNoResultData {
    self.dataSource = [[NSMutableArray alloc] init];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *toolConfigPath = @"";
    if ([McCoreFunction isAppStoreVersion]) {
        toolConfigPath = [mainBundle pathForResource:@"ToolConfigAppStore" ofType:@"plist"];
    } else {
        toolConfigPath = [mainBundle pathForResource:@"ToolConfig" ofType:@"plist"];
        NSString *language = [LanguageHelper getCurrentUserLanguage];
        if(language != nil){
            toolConfigPath = [mainBundle pathForResource:@"ToolConfig" ofType:@"plist" inDirectory:@"" forLocalization:language];
        }
    }
    
    NSDictionary *toolConfigDic = [NSDictionary dictionaryWithContentsOfFile:toolConfigPath];
    for (NSDictionary *toolItemKey in toolConfigDic.allKeys) {
        if ([[toolConfigDic objectForKey:toolItemKey] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *toolItemDic =[toolConfigDic objectForKey:toolItemKey];
            
            BOOL recommend = [toolItemDic[@"recommend"] boolValue];
            if(!recommend)
            continue;
            
            NSString *toolId = toolItemDic[@"toolId"];
            NSString *toolPicName = toolItemDic[@"toolPicName"];
            NSString *className = toolItemDic[@"className"];
            NSString *toolName = toolItemDic[@"toolName"];
            NSString *toolDesc = toolItemDic[@"toolDesc"];
            toolDesc = [toolDesc stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
            NSInteger reportId = [toolItemDic[@"reportId"] integerValue];
            
            ToolModel *toolModel = [[ToolModel alloc] initWithToolId:toolId toolPicName:toolPicName className:className toolName:toolName toolDesc:toolDesc reportId:reportId];
            [self.dataSource addObject:toolModel];
        }
    }
    [self.dataSource sortUsingComparator:^NSComparisonResult(ToolModel *obj1, ToolModel *obj2) {
        NSInteger obj1Integer = [obj1.toolId integerValue];
        NSInteger obj2Integer = [obj2.toolId integerValue];
        
        if (obj1Integer < obj2Integer) {
            return NSOrderedAscending;
        }else{
            return NSOrderedDescending;
        }
    }];
    
    [_tableView reloadData];
}

- (void)showAnimate {
    //reset animate view state
    [self.scanResultUpAnimateView.layer removeAllAnimations];
    [self.outLineView.layer removeAllAnimations];
    
    [self.noResultUpAnimateView.layer removeAllAnimations];
    [self.tableView.layer removeAllAnimations];
    
    //show animate
    [self showAnimateReverse:YES];
}

#pragma mark-
#pragma mark animation回调

- (void)showAnimateReverse:(BOOL)isReverse {
    NSView* bottomView = nil;
    if(!self.scanResultView.hidden) {
        bottomView = self.outLineView;
    } else {
        bottomView = self.tableView;
    }
    if(isReverse) {
        _isAnimating = 2;
        [AnimationHelper TransOpacityAnimate:self.scanResultUpAnimateView reverse:isReverse offsetTyep:NO offsetValue:80 opacity:0 durationT:0.16 durationO:0.24 delay:0.08 type:kCAMediaTimingFunctionEaseOut delegate:self];
        [AnimationHelper TransOpacityAnimate:bottomView reverse:isReverse offsetTyep:YES offsetValue:40 opacity:0 durationT:0.2 durationO:0.2 delay:0.28 type:kCAMediaTimingFunctionEaseOut delegate:self];
    } else {
        _isAnimating = 2;
        [AnimationHelper TransOpacityAnimate:self.scanResultUpAnimateView reverse:isReverse offsetTyep:NO offsetValue:80 opacity:0 durationT:0.16 durationO:0.24 delay:0.28 type:kCAMediaTimingFunctionEaseIn delegate:self];
        [AnimationHelper TransOpacityAnimate:bottomView reverse:isReverse offsetTyep:YES offsetValue:40 opacity:0 durationT:0.2 durationO:0.2 delay:0.08 type:kCAMediaTimingFunctionEaseIn delegate:self];
    }
}

#pragma mark-
#pragma mark animation delegate

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    if(_isAnimating > 0)
    _isAnimating--;
}

//back原本逻辑，等窗口移动后再执行（added by levey）
- (void)backLogic {
    [[LMCleanerDataCenter shareInstance] setIsBigPage:NO];
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setValue:CLOSE_BIG_CLEAN_VIEW forKey:@"flag"];
    [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_OR_CLOSE_BIG_CLEAN_VIEW object:nil userInfo:userInfo];
    if ([[LMCleanerDataCenter shareInstance] isScanning]) {
        [[QMCleanManager sharedManger] setBigViewCleanDelegate:nil];
    }
    
    _currentScanStop = YES;
    _currentCleanStop = YES;
    
    //展示切换动画，大界面动画跟窗口变化一起，不需要等动画完成再调用（added by levey）
    [self showAnimateReverse:NO];
}

-(CGPoint)getCenterPoint{
    CGPoint origin = self.view.window.frame.origin;
    CGSize size = self.view.window.frame.size;
    return CGPointMake(origin.x + size.width / 2, origin.y + size.height / 2);
}

#pragma mark -- 通知回调
-(void)startScan{
    self.fileMoveTotalNum = 0;
    self.fileMoveIcon.hidden = YES;
    self.fileMoveButton.hidden = YES;
    self.fileMoveLabel.hidden = YES;
    //    if (m_categoryArray == nil) {
    m_categoryArray = [[LMCleanerDataCenter shareInstance] getCategoryArray];
    [_outLineView reloadData];
    NSInteger itemCount = [m_categoryArray count];
    if (itemCount > 0) {
        for (NSInteger i = 0; i < itemCount; i++) {
            id item = [_outLineView itemAtRow:i];
            [_categoryItemArr addObject:item];
        }
        for (id item in _categoryItemArr) {
            [_outLineView expandItem:item expandChildren:NO];
        }
    }
    //    }
    [self.scanProgressView setValue:0];
}

//弹出完全磁盘访问权限页面
-(void)showFullDiskPrivacySettingPage{
    if (getFullAccessController == nil) {
        getFullAccessController = [GetFullAccessWndController shareInstance];
        [getFullAccessController setParaentCenterPos:[self getCenterPoint] suceessSeting:nil];
    }
    [getFullAccessController.window makeKeyAndOrderFront:nil];
}

-(void)scanDidEnd:(NSNotification *)noti{
    [[QMCleanManager sharedManger] setBigViewCleanDelegate:self];
    [_outLineView reloadData];
}

-(void)needDispalyCleaningPage{
    [[LMCleanerDataCenter shareInstance] setIsCleanning:YES];
    [_outLineView reloadData];
    [_outLineView scrollToBeginningOfDocument:nil];
    [self setViewIsScanningOrCleanning:YES];
    UInt64 scanSelectSize = [[LMCleanerDataCenter shareInstance] totalSelectSize];
    NSString *selectSizeString = [NSString stringFromDiskSize:scanSelectSize];
    NSString *sizeLabelStrring = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_needDispalyCleaningPage_sizeLabelStrring _1", nil, [NSBundle bundleForClass:[self class]], @""), selectSizeString];
    [self.rubbishSizeLabel setStringValue:sizeLabelStrring];
    [self.removeButton setHidden:YES];
    [self.logoImageView setImage:[NSImage imageNamed:@"main_circle_bg_small" withClass:[self class]]];
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_SELECT_SIZE object:nil];
}

#pragma mark -- 按钮回调

-(void)clickExpandOrShrink{
    NSInteger row = _outLineView.clickedRow;
    id item = [_outLineView itemAtRow:row];
    if ([item isKindOfClass:QMResultItem.class] && ([[item resultItemArray] count] == 0)) {
        return;
    }
    if ([_outLineView isItemExpanded:item]) {
        [_outLineView.animator collapseItem:item];
    }else{
        [_outLineView.animator expandItem:item];
    }
}

- (IBAction)back:(id)sender {
    [self backAction];
}

- (void)backAction {
    if(_isAnimating) return;
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kNewFeatureTip500"];
    NSLog(@"click the back imageview");
    //先执行窗口移动动画（added by levey）
    CGPoint oldOrigin = self.view.window.frame.origin;
    CGPoint newOrigin = [MacDeviceHelper getScreenOriginSmall:oldOrigin];
    CGSize size = self.view.window.frame.size;
    if(oldOrigin.x != newOrigin.x) {
        __weak NSViewController* weakSelf = self;
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [context setDuration:0.3];
            [[weakSelf.view.window animator] setFrame:NSMakeRect(newOrigin.x, newOrigin.y, size.width, size.height) display:YES];
        } completionHandler:^{
            [self backLogic];
        }];
    } else {
        [self backLogic];
    }
}

- (IBAction)startClean:(id)sender {
    if(_isAnimating) return;
    NSLog(@"startClean");
    
    if(self.isShowBigScanView) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kNewFeatureTip500"];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:START_SMALL_CLEAN object:nil userInfo:nil];
}

- (IBAction)experienceAction:(id)sender
{
    if(_isAnimating) return;
    NSInteger row = [_tableView rowForView:sender];
    ToolModel *toolModel = [self.dataSource objectAtIndex:row];
    NSLog(@"experienceAction name:%@", toolModel.className);
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setValue:toolModel.className forKey:EXPERIENCE_TOOL_CLASS_NAME];
    [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_EXPERIENCE_TOOL object:nil userInfo:userInfo];
}

- (IBAction)completeAction:(id)sender {
    if(_isAnimating) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:REPARSE_CLEAN_XML object:nil];
    NSLog(@"completeAction");
    //先执行窗口移动动画（added by levey）
    CGPoint oldOrigin = self.view.window.frame.origin;
    CGPoint newOrigin = [MacDeviceHelper getScreenOriginSmall:oldOrigin];
    CGSize size = self.view.window.frame.size;
    if(oldOrigin.x != newOrigin.x) {
        __weak NSViewController* weakSelf = self;
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [context setDuration:0.3];
            [[weakSelf.view.window animator] setFrame:NSMakeRect(newOrigin.x, newOrigin.y, size.width, size.height) display:YES];
        } completionHandler:^{
            [self completeActionLogic];
        }];
    } else {
        [self completeActionLogic];
    }
}

//completeAction原本逻辑，等窗口移动后再执行（added by levey）
- (void)completeActionLogic {
    [[LMCleanerDataCenter shareInstance] setIsBigPage:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:START_JUMP_MAINPAGE object:nil];
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setValue:CLOSE_BIG_RESULT_VIEW forKey:@"flag"];
    [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_OR_CLOSE_BIG_CLEAN_VIEW object:nil userInfo:userInfo];
    
    //展示切换动画，大界面动画跟窗口变化一起，不需要等动画完成再调用（added by levey）
    [self showAnimateReverse:NO];
}

//用来刷新subCate勾选框的选择状态
/*——勾选框逻辑
开始扫描—扫描正常结束，勾选框全部可勾选。系统垃圾和上网垃圾无垃圾不可展开，展示“很干净”；应用垃圾第二层无垃圾展示“0B”可展开，第三层无垃圾展示“很干净”不可展开
开始扫描—终止扫描，已扫描完成的项有勾选框，可勾选，和上述规则保持一致；未扫描的项没有勾选框，不可展开，不可勾选*/
- (void)refreshOutlineViewResult:(id)item cellView:(BigCleanParaentCellView *)cellView;
{
    NSCellStateValue stateValue = [item state];
    cellView.checkButton.state = stateValue;
    
    if ([[item resultItemArray] count] > 0 || [item isKindOfClass:[QMResultItem class]])
    {
        [cellView.checkButton setState:stateValue];
    }
    
    
    QMBaseItem * tempItem = item;
    QMCategorySubItem * subCategoryItem = nil;
    while (YES)
    {
        id parentItem = [_outLineView parentForItem:tempItem];
        
        if (parentItem && [parentItem isKindOfClass:QMCategoryItem.class])
        {
            subCategoryItem = (QMCategorySubItem*)tempItem;
            tempItem = parentItem;
            if ([subCategoryItem isScaned] || [subCategoryItem isScanning]) {
                [cellView.checkButton setHidden:NO];
            }else{
                [cellView.checkButton setHidden:YES];
            }
            if ([[subCategoryItem resultItemArray] count] == 0) {
                [cellView.checkButton setState:NSControlStateValueOff];
                if ([subCategoryItem isScaned]) {
                    [cellView.checkButton setState:subCategoryItem.state];
                }else{
                    //                    [cellView.checkButton setHidden:NO];
                    //                    if (![[LMCleanerDataCenter shareInstance] isScanning]) {
                    //                        [cellView.checkButton setState:subCategoryItem.state];
                    //                    }
                }
                //                                categoryItem.state = NSOffState;
            }
            else{
                //                [cellView.checkButton setHidden:NO];
            }
            
            //                        if (([[parentItem resultItemArray] count] == 0) || ([parentItem resultSelectedFileSize] == 0)) {
            //                            [parentItem setState:NSControlStateValueOff];
            //                        }
            
        } else {
            break;
        }
    }
}

- (void)addBaseSubItemRow:(NSMutableIndexSet *)indexSet categoryItem:(QMBaseItem *)item
{
    // 添加需要刷新row
    for (QMBaseItem * subItem in [item subItemArray])
    {
        NSInteger tempRow = [_outLineView rowForItem:subItem];
        if (tempRow != -1)  [indexSet addIndex:tempRow];
        [self addBaseSubItemRow:indexSet categoryItem:subItem];
    }
}

- (QMCategoryItem *)refreshItemState:(NSInteger)curRow needRemove:(BOOL)remove
{
    id item = [_outLineView itemAtRow:curRow];
    NSMutableIndexSet * reloadIndex = [NSMutableIndexSet indexSetWithIndex:curRow];
    // 刷新父项
    QMBaseItem * tempItem = item;
    if ([tempItem isKindOfClass:[QMCategorySubItem class]]) {
        [self refreshStateValue:tempItem];
    }
    QMCategoryItem * categoryItem = nil;
    while (YES)
    {
        id parentItem = [_outLineView parentForItem:tempItem];
        if (!parentItem)
        {
            categoryItem = (QMCategoryItem*)tempItem;
            break;
        }
        if (remove && [item isKindOfClass:[QMResultItem class]])
        {
            [reloadIndex removeIndex:[_outLineView rowForItem:item]];
            [[parentItem subItemArray] removeObject:item];
            if ([[parentItem subItemArray] count] == 0)
            item = parentItem;
        }
        tempItem = parentItem;
        [tempItem refreshStateValue];
        if ([tempItem isKindOfClass:[QMCategorySubItem class]]) {
            [self refreshStateValue:tempItem];
        }
        NSInteger tempRow = [_outLineView rowForItem:tempItem];
        if (tempRow != -1)    [reloadIndex addIndex:tempRow];
    }
    // 添加子项
    [self addBaseSubItemRow:reloadIndex categoryItem:item];
    
    if (@available(macOS 10.13, *)) {
        [reloadIndex enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            QMResultTableRowView * curTableRowView = [self->_outLineView rowViewAtRow:idx makeIfNecessary:NO];
            if(curTableRowView == nil)
                return;
            id item = [self->_outLineView itemAtRow:idx];
            [self->_outLineView reloadItem:item];
            [curTableRowView moveExpandButtonToFront];
            BigCleanParaentCellView * curTableCellView =  [curTableRowView viewAtColumn:0];
            [self refreshOutlineViewResult:item cellView:curTableCellView];
        }];
    }else{
        [self.outLineView reloadData];
    }
    
    
    return categoryItem;
}

- (void)checkButtonAction:(id)sender
{
    NSButton * checkBtn = (NSButton *)sender;
    NSLog(@"check btn state = %ld", checkBtn.state);
    if (checkBtn.state == NSMixedState)
    checkBtn.state = NSOnState;
    
    NSInteger row = [_outLineView rowForView:checkBtn];
    if (row != -1)
    {
        id item = [_outLineView itemAtRow:row];
        if ([[LMCleanerDataCenter shareInstance] isCleanning] || [[LMCleanerDataCenter shareInstance] isScanning]) {
            if([item isKindOfClass:[QMCategorySubItem class]] && ![item isScanning] && ![item isScaned]){
                checkBtn.state = NSOffState;
                return;
            }
            checkBtn.state = [item state];
            return;
        }
        
        if (checkBtn.state == NSOnState) {
            [self showAlertIfNeededWhenSelectItem:item control:checkBtn];
        }

        if ([item isKindOfClass:[QMCategorySubItem class]] && [item isScaned]) {
            //写入数据库，记住用户选择
            if (checkBtn.state == NSOnState) {
                [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[item subCategoryID] selectStatus:CleanSubcateSelectStatusSelect];
            } else {
                if ([item state] == NSMixedState) {
                    [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[item subCategoryID] selectStatus:CleanSubcateSelectStatusDeselect];
                } else {
                    [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[item subCategoryID] selectStatus:CleanSubcateSelectStatusDeselect];
                }
            }
            
            if (([item showAction] == YES) && (checkBtn.state == NSOnState) && ([item defaultState] != NSOffState)) {
                [item setState:checkBtn.state];//先把子项进行刷新 切换成mixed后无法刷新子项了
                checkBtn.state = [item defaultState];
            }
        } else if ([item isKindOfClass:[QMActionItem class]]) {
            // Note: 写入数据库，记住用户选择
            // Note: 比较内存和数据库存储状态，如果当前清理项选中状态发生变化，则更新内存状态
            if (checkBtn.state == NSOnState) {
                [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[item actionID] selectStatus:CleanSubcateSelectStatusSelect];
            } else {
                if ([item state] == NSMixedState) {
                    [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[item actionID] selectStatus:CleanSubcateSelectStatusDeselect];
                } else {
                    [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[item actionID] selectStatus:CleanSubcateSelectStatusDeselect];
                }
            }
        }

        [item setState:checkBtn.state];
        
        
        QMCategoryItem * categoryItem = [self refreshItemState:row needRemove:NO];
        NSMutableDictionary * itemCheckDict = [[[QMDataCenter defaultCenter] objectForKey:kQMCleanItemCheck] mutableCopy];
        if (!itemCheckDict) itemCheckDict = [NSMutableDictionary dictionary];
        
        if (![categoryItem showResult])
        {
            for (QMCategorySubItem * categorySubItem in [categoryItem m_categorySubItemArray])
            {
                if ([categorySubItem showAction])
                {
                    for (QMActionItem * actionItem in [categorySubItem m_actionItemArray])
                    {
                        NSString * actionID = actionItem.actionID;
                        [itemCheckDict setObject:[NSNumber numberWithInteger:[actionItem state]] forKey:actionID];
                    }
                }
                NSString * subCategoryID = categorySubItem.subCategoryID;
                [itemCheckDict setObject:[NSNumber numberWithInteger:[categorySubItem state]] forKey:subCategoryID];
            }
        }
        [itemCheckDict setObject:[NSNumber numberWithInteger:[categoryItem state]] forKey:categoryItem.categoryID];
        
        [[QMDataCenter defaultCenter] setObject:itemCheckDict forKey:kQMCleanItemCheck];
        
        //        NSLog(@"category item select size = %ld", categoryItem.resultSelectedFileSize);
        
        //        [_delegate resultItemSelectedChange];
        [self setRemoveButtonState];
        [self setResultTotalAndSelectSizeLabel];
    }
}


- (void)refreshStateValue:(QMBaseItem *)item {
    int checkOnFlags = 0;
    int checkMixFlags = 0;
    NSUInteger totalSubCount = 0;
    NSMutableArray * array = [item subItemArray];
    if ([item isKindOfClass:[QMCategoryItem class]]) {
        if ([(QMCategoryItem *)item showResult]) {
            // 没有子项，根据结果刷新
            for (QMResultItem * subItem in [item resultItemArray]) {
                if (subItem.state == NSOnState) {
                    checkOnFlags++;
                } else if (subItem.state == NSMixedState) {
                    checkMixFlags++;
                }
            }
            totalSubCount = [[item resultItemArray] count];
        } else {
            // 有子项分类
            for (QMCategorySubItem * subItem in array) {
                if (subItem.state == NSOnState) {
                    checkOnFlags++;
                } else if (subItem.state == NSMixedState) {
                    checkMixFlags++;
                }
            }
            totalSubCount = [array count];
        }
    } else if ([item isKindOfClass:[QMCategorySubItem class]]) {
        if ([(QMCategorySubItem *)item showAction]) {
            // 根据行为刷新
            for (QMActionItem * subItem in array) {
                [self refreshStateValue:subItem];
                if (subItem.state == NSOnState) {
                    checkOnFlags++;
                } else if (subItem.state == NSMixedState) {
                    checkMixFlags++;
                }
            }
            totalSubCount = [array count];
        } else {
            // 根据结果刷新
            for (QMResultItem * subItem in [item resultItemArray]){
                if (subItem.state == NSOnState) {
                    checkOnFlags++;
                } else if (subItem.state == NSMixedState) {
                    checkMixFlags++;
                }
            }
            totalSubCount = [[item resultItemArray] count];
        }
    } else if ([item isKindOfClass:[QMActionItem class]]) {
        // 有子项分类
        for (QMResultItem * subItem in array) {
            if (subItem.state == NSOnState) {
                checkOnFlags++;
            } else if (subItem.state == NSMixedState) {
                checkMixFlags++;
            }
        }
        totalSubCount = [array count];
    }
    
    if ([item isKindOfClass:[QMCategorySubItem class]]) {
        // Category - item
        QMCategorySubItem *currentItem = (QMCategorySubItem *)item;
        if (totalSubCount == 0) {
            if (item.m_stateValue != NSOffState) {
                [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[currentItem subCategoryID] selectStatus:CleanSubcateSelectStatusSelect];
            } else {
                [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[currentItem subCategoryID] selectStatus:CleanSubcateSelectStatusDeselect];
            }
        } else {
            if (checkOnFlags == totalSubCount) {
                [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[currentItem subCategoryID] selectStatus:CleanSubcateSelectStatusSelect];
            } else if (checkOnFlags == 0 && checkMixFlags ==0) {
                [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[currentItem subCategoryID] selectStatus:CleanSubcateSelectStatusDeselect];
            } else {
                [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[currentItem subCategoryID] selectStatus:CleanSubcateSelectStatusDeselect];
            }
        }
    } else if ([item isKindOfClass:[QMActionItem class]]) {
        // Category - item - action
        QMActionItem *currentItem = (QMActionItem *)item;
        if (totalSubCount == 0) {
            if (item.m_stateValue != NSOffState) {
                [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[currentItem actionID ] selectStatus:CleanSubcateSelectStatusSelect];
            } else {
                [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[currentItem actionID ] selectStatus:CleanSubcateSelectStatusDeselect];
            }
        } else {
            if (checkOnFlags == totalSubCount) {
                // 子项全选
                [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[currentItem actionID ] selectStatus:CleanSubcateSelectStatusSelect];
            } else if (checkOnFlags == 0 && checkMixFlags ==0) {
                // 子项全选数量等于0 且 子项混合选中数量等于0（子项下还有子项）
                [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[currentItem actionID ] selectStatus:CleanSubcateSelectStatusDeselect];
            } else {
                [[LMCleanerDataCenter shareInstance] addSubcateStatusToDatabaseWithId:[currentItem actionID ] selectStatus:CleanSubcateSelectStatusDeselect];
            }
        }
    }
    
}

- (void)showAlertIfNeededWhenSelectItem:(QMCategorySubItem *)item control:(NSButton *)button{
    if (![item isKindOfClass:QMCategorySubItem.class]) {
        return;
    }
    if (![item.subCategoryID isEqualToString:kItemIdDownloadSubItemID]) {
        return;
    }
    BOOL isShowed = [[NSUserDefaults standardUserDefaults] boolForKey:LMCLEAN_DOWNLOAD_SELECT_ALL_ALERT_SHOWED];
    if (isShowed) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:LMCLEAN_DOWNLOAD_SELECT_ALL_ALERT_SHOWED];
    
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert.accessoryView setFrameOrigin:NSMakePoint(0, 0)];
    alert.alertStyle = NSAlertStyleInformational;
    alert.messageText = NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_downloadSelectAll_alert_titleString_1", nil, [NSBundle bundleForClass:[self class]], @"");
    alert.informativeText = NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_downloadSelectAll_alert_descString_1", nil, [NSBundle bundleForClass:[self class]], @"");
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_downloadSelectAll_alert_okButtonString_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_downloadSelectAll_alert_cancelButtonString_1", nil, [NSBundle bundleForClass:[self class]], @"")];

    __weak typeof(self) weakSelf = self;
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            
        } else {
            button.state = NSControlStateValueOff;
            [weakSelf checkButtonAction:button];
        }
    }];
    
}

#pragma mark -- 扫描或者清理定时器回调方法
- (void)scanProgressRefresh:(id)sender
{
//    NSLog(@"big enter scanProgressRefresh:");
    [_outLineView reloadItem:m_curSubCategoryItem];
    CGFloat progress = 0;
    UInt64 scanTotalSize = 0;
    UInt64 scanSelectSize = 0;
    for (QMCategoryItem * categoryItem in m_categoryArray)
    {
        progress += categoryItem.progressValue;
        scanTotalSize += categoryItem.resultFileSize;
        scanSelectSize += categoryItem.resultSelectedFileSize;
    }
    progress = progress / [m_categoryArray count];
    [self.scanProgressView setValue:progress];
    
    NSString *totalSizeString = [NSString stringFromDiskSize:scanTotalSize];
    NSString *totalLabelString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_scanProgressRefresh_totalLabelString _1", nil, [NSBundle bundleForClass:[self class]], @""), totalSizeString];
    [self.rubbishSizeLabel setStringValue:totalLabelString];
    NSString *selectSizeString = [NSString stringFromDiskSize:scanSelectSize];
    [self.rubbishSelectLabel setStringValue:selectSizeString];
    
    if (_currentScanStop)
    {
        int totalNumGB = self.fileMoveTotalNum/(Lemon_KB_To_GB);
        if(totalNumGB >= 1) {
            self.fileMoveIcon.hidden = NO;
            self.fileMoveButton.hidden = NO;
            self.fileMoveLabel.hidden = NO;
            [[NSUserDefaults standardUserDefaults] setDouble:self.fileMoveTotalNum forKey:@"Lemon_KB_To_GB"];
            if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
                self.fileMoveLabel.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"needFileMoveTitle", nil, [NSBundle bundleForClass:[self class]], @""),totalNumGB];
            } else {
                self.fileMoveLabel.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"needFileMoveTitle", nil, [NSBundle bundleForClass:[self class]], @"")];
            }
        }
        _currentScanStop = NO;
        [_scantimer invalidate];
        _scantimer = nil;
        NSLog(@"big scanProgressRefresh before");
        if ([[LMCleanerDataCenter shareInstance] isScanning] ||[[LMCleanerDataCenter shareInstance] isCleanning]) {
            return;
        }
        NSLog(@"big scanProgressRefresh after");
        totalLabelString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_scanProgressRefresh_1553048057_2", nil, [NSBundle bundleForClass:[self class]], @""), totalSizeString];
        [self.rubbishSizeLabel setStringValue:totalLabelString];
        [self setViewIsScanningOrCleanning:NO];
        [self.logoImageView setImage:[NSImage imageNamed:@"big_circle_haverubbish" withClass:[self class]]];
        long long totalSize = [[LMCleanerDataCenter shareInstance] totalSize];
        if (totalSize == 0) {
            NSLog(@"big scanProgressRefresh == 0");
            [self setNoResultViewWithScanFileNum:[[LMCleanerDataCenter shareInstance] scanFileNumss] scanTime:[[LMCleanerDataCenter shareInstance] scanTimess]];
            [self.noResultView setHidden:NO];
            [self.scanResultView setHidden:YES];
        }else{
            NSLog(@"big scanProgressRefresh > 0");
            [self.removeButton setHidden:NO];
            [self setRemoveButtonState];
        }
        
    }
}

-(void)cleanProgressRefresh:(id)sender{
    [self.scanProgressView setValue:_cleanProgress];
    
    UInt64 scanTotalSize = 0;
    UInt64 scanSelectSize = 0;
    for (QMCategoryItem * categoryItem in m_categoryArray)
    {
        scanTotalSize += categoryItem.resultFileSize;
        scanSelectSize += categoryItem.resultSelectedFileSize;
    }
    //
    [self setRubbishSelectLabelSize];
    if (_currentCleanStop) {
        [_cleantimer invalidate];
        _cleantimer = nil;
        _currentCleanStop = NO;
        //        [self setViewIsScanningOrCleanning:NO];
    }
}

-(void)updatePathRefresh:(id)sender{
    if ((_curPath != nil) && (_curPath.length > 0)) {
        if ([[LMCleanerDataCenter shareInstance] isScanning]) {
            [self.rubbishSelectTitle setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_updatePathRefresh_rubbishSelectTitle_1", nil, [NSBundle bundleForClass:[self class]], @""), _curPath]];
        }else if([[LMCleanerDataCenter shareInstance] isCleanning]){
            [self.rubbishSelectTitle setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanBigViewController_updatePathRefresh_rubbishSelectTitle_2", nil, [NSBundle bundleForClass:[self class]], @""), _curPath]];
        }
    }
    if (_currentScanStop || _currentCleanStop) {
        [_updatePathTimer invalidate];
        _updatePathTimer = nil;
    }
}

#pragma mark -
#pragma mark outline view delegate

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
    QMResultTableRowView *rowView = [[QMResultTableRowView alloc] initWithFrame:NSZeroRect];
    return rowView;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item) return [m_categoryArray objectAtIndex:index];
    
    if ([item isKindOfClass:[QMCategorySubItem class]])
    {
        if ([item showAction])
        return [[item m_actionItemArray] objectAtIndex:index];
        return [[item resultItemArray] objectAtIndex:index];
    }
    else if ([item isKindOfClass:[QMActionItem class]])
    {
        return [[item resultItemArray] objectAtIndex:index];
    }
    else if ([item isKindOfClass:[QMCategoryItem class]])
    {
        if (![item showResult])
        return [[item m_categorySubItemArray] objectAtIndex:index];
        else if ([[item resultItemArray] count] > 0)
        return [[item resultItemArray] objectAtIndex:index];
    }
    else if ([item isKindOfClass:[QMResultItem class]])
    {
        return [[item subItemArray] objectAtIndex:index];
    }
    return item;
}


- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    if ([item isKindOfClass:[QMCategoryItem class]])
    {
        return 40;
    }
    else if ([item isKindOfClass:[QMCategorySubItem class]])
    {
        return 30;
    }
    else if ([item isKindOfClass:[QMActionItem class]])
    {
        return 30;
    }
    else if ([item isKindOfClass:[QMResultItem class]])
    {
        return 30;
    }
    return 30;
}

// Returns a Boolean value that indicates whether the a given item is expandable
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if ([item isKindOfClass:[QMCategoryItem class]])
    return ([[item m_categorySubItemArray] count] >= 1 || [[item resultItemArray] count] > 0);
    else if ([item isKindOfClass:[QMCategorySubItem class]])
    {
        if ([item showAction]){
            //            if ([item resultFileSize] == 0) {
            //                return NO;
            //            }
            if (![item isScaned]) {
                return NO;
            }
            return [[item m_actionItemArray] count] > 0;
        }
        if ([[LMCleanerDataCenter shareInstance] isCleanning]) {
            return NO;
        }
        if ([item isScanning]) {
            return NO;
        }
        return [[item resultItemArray] count] > 0;
    }
    else if ([item isKindOfClass:[QMActionItem class]])
    {
        return [[item subItemArray] count] > 0;
    }
    else if ([item isKindOfClass:[QMResultItem class]])
    {
        return [[item subItemArray] count] > 0;
    }
    return NO;
}

// Returns the number of child items encompassed by a given item
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item) return [m_categoryArray count];
    
    if ([item isKindOfClass:[QMCategoryItem class]])
    {
        if (![item showResult])
        return [[item m_categorySubItemArray] count];
        return [[item resultItemArray] count];
    }
    else if ([item isKindOfClass:[QMCategorySubItem class]])
    {
        if ([item showAction])
        return [[item m_actionItemArray] count];
        return [[item resultItemArray] count];
    }
    else if ([item isKindOfClass:[QMActionItem class]])
    {
        return [[item subItemArray] count];
    }
    else if ([item isKindOfClass:[QMResultItem class]])
    {
        return [[item subItemArray] count];
    }
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item{
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return item;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    BigCleanParaentCellView *cell = nil;
    if ([item isKindOfClass:[QMCategoryItem class]])
    {
        cell = [outlineView makeViewWithIdentifier:CATEGORY_CELLVIEW_INDENTIFIER owner:self];
    }
    else if ([item isKindOfClass:[QMCategorySubItem class]])
    {
        cell = [outlineView makeViewWithIdentifier:SUB_CATEGORY_CELLVIEW_INDENTIFIER owner:self];
    }
    else if ([item isKindOfClass:[QMActionItem class]])
    {
        cell = [outlineView makeViewWithIdentifier:ACTION_CELLVIEW_INDETIFIER owner:self];
    }
    else if ([item isKindOfClass:[QMResultItem class]])
    {
        cell = [outlineView makeViewWithIdentifier:RESULT_CELLVIEW_INDENTIFIER owner:self];
    }
    [cell.checkButton setTarget:self];
    [cell.checkButton setAction:@selector(checkButtonAction:)];
    
    [self refreshOutlineViewResult:item cellView:cell];
    
    [cell setCellData:item];
    // 当前是否选中
    //    [cell setHightLightStyle:([_outLineView selectedRow] == [_outLineView rowForItem:item])];
    
    return cell;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    //    id subItem = [[item subItemArray] lastObject];
    //    if ([subItem isKindOfClass:[QMResultItem class]]
    //        && [[(QMResultItem *)subItem subItemArray] count] == 0)
    //        return YES;
    return NO;
}

#pragma mark -- qmclean manager delegate
- (void)scanCategoryStart:(QMCategoryItem *)item{
    NSLog(@"big scanCategoryStart");
    [_outLineView reloadItem:item reloadChildren:NO];
}
- (void)scanProgressInfo:(float)value
                scanPath:(NSString *)path
                category:(QMCategoryItem *)categoryItem
         subCategoryItem:(QMCategorySubItem *)subItem{
    if (![[LMCleanerDataCenter shareInstance] isScanning]) {
        return;
    }
    if ([self.scanProgressView isHidden]) {
        [self.scanProgressView setHidden:NO];
    }
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
//    [_outLineView reloadItem:subItem];
    m_curSubCategoryItem = subItem;
}

- (void)scanSubCategoryDidEnd:(QMCategorySubItem *)subItem{
    [_outLineView reloadItem:subItem];
    NSLog(@"big scanSubCategoryDidEnd = %@", [subItem title]);
}
- (void)scanCategoryDidEnd:(QMCategoryItem *)item{
    [_outLineView reloadItem:item reloadChildren:NO];
    NSLog(@"big scanCategoryDidEnd = %@", [item title]);
}
- (void)scanCategoryAllDidEnd:(long long)num {
    self.fileMoveTotalNum = num;
    _currentScanStop = YES;
    NSLog(@"bigscanview  scanCategoryAllDidEnd currentstop yes");
    [_outLineView reloadData];
    if (_scantimer == nil) {
        [self scanProgressRefresh:nil];
    }
}

- (void)cleanCategoryStart:(QMCategoryItem *)categoryItem{
    m_curCategoryItem = categoryItem;
    [_outLineView reloadItem:categoryItem reloadChildren:NO];
}

- (void)cleanCategoryEnd:(QMCategoryItem *)categoryItem{
    [_outLineView reloadItem:categoryItem reloadChildren:NO];
}

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
        //        NSLog(@"big 剩余清理的数据大小 %ld 清理的进度 %f, path = %@ categoryID = %@", totalSize, value, path, item.categoryID);
        _cleanProgress = value;
        _curPath = path;
    }
}

- (void)cleanFileNums:(NSUInteger) cleanFileNums{
    _cleanFileNums = cleanFileNums;
}

- (void)cleanSubCategoryStart:(QMCategorySubItem *)subCategoryItem{
    //    NSLog(@"subItem name start= %@", [subCategoryItem title]);
    //    [_outLineView reloadItem:subCategoryItem];
}

- (void)cleanSubCategoryEnd:(QMCategorySubItem *)subCategoryItem {
    if (m_curCategoryItem == nil) {
        return;
    }
//    NSLog(@"subItem name end = %@", [subCategoryItem title]);
    NSTableViewAnimationOptions aniOptions = NSTableViewAnimationEffectNone;
    if ([[LMCleanerDataCenter shareInstance] isBigPage]) {
        aniOptions = NSTableViewAnimationSlideUp;
    }
    @try {
        [_outLineView beginUpdates];
        [_outLineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:0] inParent:m_curCategoryItem withAnimation:aniOptions];
        [_outLineView endUpdates];
    } @catch (NSException *exception) {
        NSLog(@"exception cleanSubCategoryEnd = %@", exception);
    }
}

- (void)cleanResultDidEnd:(NSUInteger)totalSize leftSize:(NSUInteger)leftSize{
    _currentCleanStop = YES;
}

#pragma mark -- tableview delegate
#pragma mark-
#pragma mark talbe view delegate

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return [self.dataSource count];
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row{
    ToolCellView * view = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    ToolModel *toolModel = [self.dataSource objectAtIndex:row];
    [view setCellWithToolModel:toolModel];
    view.experienceBtn.action = @selector(experienceAction:);
    return view;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}

#pragma mark - QMWindowDelegate

- (void)windowWillDismiss:(NSString *)clsName {
    if (clsName != nil) {
        [[LemonVCModel shareInstance].toolConMap setValue:nil forKey:clsName];
    }
}

@end
