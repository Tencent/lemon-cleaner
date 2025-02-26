//
//  LemonCleanViewController.m
//  LemonMonitor
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "LMCleanViewController.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/QMProgressView.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/AcceptSubViewClickOutlineView.h>

#import "McMonitorFuction.h"
#import "QMPurgeRAM.h"
#import <QMCoreFunction/McCoreFunction.h>

#import "McStatInfoConst.h"
#import "LMMemoryCellView.h"
#import "McStatMonitor.h"
#import "LMMonitorTrashManager.h"
#import "LemonMonitroHelpParams.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>

#import "LMTrashSizeCheckWindowController.h"

/*
 刷新UI的原因:
 kREFRESH_MODE_NOTIFY,因为通知而刷新
 kREFRESH_MODE_KILL,因为结束了进程所以刷新
 kREFRESH_MODE_SHOW,因为界面显示而刷新
 */
#define kREFRESH_MODE_NOTIFY 1
#define kREFRESH_MODE_KILL   2
#define kREFRESH_MODE_SHOW   3
#define MAX_COUNT_ITEM  20

#define DEFAULT_APP_PATH        @"/Applications/Tencent Lemon.app"
#define UPDATE_APP_NAME         @"LemonUpdate.app"

@implementation LMMemoryItem
@end

@interface LMCleanViewController ()<NSOutlineViewDelegate, NSOutlineViewDataSource>{
    NSView* trashContainerView;
    NSView* trashCleaningView;
    NSView* trashCleanedView;
    NSView* trashCleannessView; // 无垃圾的 container
    NSView* trashScanningView; // 正在扫描的 container

    NSView* memContainerView;
    NSView* memCleaningView;
    NSView* memCleanedView;
    NSTextField* memCountText;
    NSImageView* memReleaseImageView;
    NSTextField* memTipsText;
    NSTimer *memReleaseTimer;
    NSInteger memRadianOffset;
    NSTextField *_trashCountText;
    NSTextField *_trashCleanedCountText;
    NSTextField *_memCountText;
    NSTextField *_cpuTemperatureText;

    NSView *processMemContainer;
    NSImageView *processMemPlaceHolderImageView;
    
    NSView *divisionView;
    
    NSBundle *myBundle;

    QMProgressView* _cleanProgressView;


    BOOL bActionMemCleaning;

    NSArray *memoryItems;
//    QMTrackOutlineView *listView;
    AcceptSubViewClickOutlineView *listView;
    
    NSTimer *scanTrashTimer;
}

@property (nonatomic, assign) BOOL hasAppearTip;

@end

@implementation LMCleanViewController

- (void)startMonitor
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recivedRAMInfoChanged:)
                                                 name:kMemoryCPUInfoNotification
                                               object:nil];
}

- (void)stopMonitor
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kMemoryCPUInfoNotification
                                                  object:nil];
}

- (void)loadView{
    NSRect rect = NSMakeRect(0, 0, 340, 340);
    NSView *view = [[NSView alloc] initWithFrame:rect];
    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hasAppearTip = NO;
    // Do view setup here.
    myBundle = [NSBundle bundleForClass:[self class]];

    [self showTrashContainerView:YES:0];
    [self showTrashCleanessView:YES];
    [self showMemContainerView:true];
    [self setupMemoryOutlineView];
    
    [LMMonitorTrashManager sharedManager].delegate = self;

}


- (void)viewWillAppear
{
    NSLog(@"%s", __FUNCTION__);
    [super viewWillAppear];
    [self changeTrashViewState];
    // 开启内存监控
    [self refreshProcMemUIWithInfo:nil mode:kREFRESH_MODE_SHOW];

    [[LemonMonitroHelpParams sharedInstance] startStatMemory];
}
- (void)viewWillDisappear
{
    [super viewWillDisappear];
    [[LemonMonitroHelpParams sharedInstance] stopStatMemory];
}

- (void)changeTrashViewState
{
    LMMonitorTrashManager *manager = [LMMonitorTrashManager sharedManager];
    NSInteger trashSize = [manager getTrashSize];
    
    NSLog(@"changeTrashViewState ... phase is %u, trashsize is %ld", manager.trashPhase, trashSize);
    
    if(manager.trashPhase == TrashCleaning){
        [self showTrashContainerView:NO:0];
        [self showTrashCleaningView:YES];
    }else if(trashSize== -1 &&
       (manager.trashPhase == TrashScanNotStart ||  manager.trashPhase == TrashScaning)){
        // 显示正在扫描中
        [self showTrashCleanessView:NO];
        [self showScaningTrashView:YES];
        [self showTrashContainerView:NO:0];
        
    }else if(trashSize == 0){
        // 显示很干净
        [self showTrashCleanessView:YES];
        [self showScaningTrashView:NO];
        [self showTrashContainerView:NO:0];
    }else{
        // 显示具体的数值.
        [self showTrashCleanessView:NO];
        [self showScaningTrashView:NO];
        [self showTrashContainerView:YES:trashSize];
    }
    
}

- (void)dealloc
{
    
    if(scanTrashTimer){
        [scanTrashTimer invalidate];
        scanTrashTimer = nil;
    }
    [self cancelMemReleaseAnimation];
}


-(void) setupMemoryOutlineView
{
//    NSClipView *container = [[NSClipView alloc] init]; //必须是NSClipView 嵌套这个不能 scroll 的 outlineView,否则会出现 outlineView 偏移.
    
    //需要设置NSTableColumn的最小宽度，就不会偏移
    NSScrollView *container = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 10, 300, 250)];
//    container.hasVerticalScroller = YES;
    container.autohidesScrollers = YES;

    
    self->processMemContainer = container;
    
    AcceptSubViewClickOutlineView *outline = [[AcceptSubViewClickOutlineView alloc] init];
    self->listView = outline;
    outline.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    outline.floatsGroupRows = NO;
    outline.indentationMarkerFollowsCell = NO;
    outline.headerView = nil;
    outline.backgroundColor = [LMAppThemeHelper getMainBgColor];;
    if (@available(macOS 11.0, *)) {
        outline.style = NSTableViewStyleFullWidth;
    } else {
        // Fallback on earlier versions
    }
    NSTableColumn *col1 = [[NSTableColumn alloc] initWithIdentifier:@"col1"];
    col1.resizingMask = NSTableColumnAutoresizingMask;
    col1.editable = NO;
    col1.minWidth = 340.f;
    col1.headerCell.stringValue = @"header";
    [outline addTableColumn:col1];
    [outline setOutlineTableColumn:col1];
    
    //    NSScrollView *container = [[NSScrollView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    //    MMScroller *scroller = [[MMScroller alloc] init];
    //    [container setVerticalScroller:scroller];
    //    container.autohidesScrollers = NO;
    //    container.hasVerticalScroller = YES;
    //    container.hasHorizontalScroller = NO;
    //    container.drawsBackground = NO;
    
    //    container.documentView = outline;
    
    [self.view addSubview:container];
    outline.delegate = self;
    outline.dataSource = self;
    
    
    // NSEdgeInsetsMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right)
    container.wantsLayer = YES;
    container.layer.backgroundColor = [NSColor redColor].CGColor;
    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(141);
        make.bottom.equalTo(self.view);
    }];
    
    container.documentView = outline;

    
    NSImageView *placeHolderImageView = [LMViewHelper createNormalImageView];
    [self.view addSubview:placeHolderImageView];
    placeHolderImageView.hidden = YES;
    self->processMemPlaceHolderImageView = placeHolderImageView;
    placeHolderImageView.image = [myBundle imageForResource:@"process_mem_placeholder"];
    
    [placeHolderImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@168);
        make.height.equalTo(@159);
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(158);
    }];
}

- (void)showTrashContainerView:(BOOL)bShow :(uint64)trashSize
{
    BOOL bNeedCreate = false;
    
    if (bShow)
    {
        if (trashContainerView != nil)
        {
            [trashContainerView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = true;
        }
    }
    else
    {
        if (trashContainerView != nil)
        {
            [trashContainerView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = false;
        }
    }
    
    if (!bNeedCreate)
    {
        if (trashSize > 0) {
            _trashCountText.stringValue = [NSString stringFromDiskSize:trashSize];
        }
        return;
    }
    
    // create view
    NSView* containerView = [[NSView alloc] init];
    trashContainerView = containerView;
    
    // icon
    NSImageView* trashIcon = [[NSImageView alloc] init];
    [trashIcon setImage:[myBundle imageForResource:@"lemon_clean_icon"]];
    
    // layout
    [self layoutTrashView:containerView :trashIcon];
    
    // lable wording 1
    NSTextField *trashCountText = [LMViewHelper createNormalLabel:20 fontColor:[LMAppThemeHelper getTitleColor]];
    trashCountText.stringValue = [NSString stringFromDiskSize:trashSize];
    trashCountText.font = [NSFontHelper getMediumSystemFont:20];
    [containerView addSubview:trashCountText];
    [trashCountText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(containerView).offset(94);
        make.top.mas_equalTo(containerView.mas_top).offset(27);
    }];
    _trashCountText = trashCountText;
    
    // lable wording 2
    NSTextField* trashTipsText = [NSTextField labelWithStringCompat:NSLocalizedStringFromTableInBundle(@"LMCleanViewController_showTrashContainerView_1553842683_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    trashTipsText.font = [NSFontHelper getLightSystemFont:12];
    trashTipsText.textColor = [NSColor colorWithHex:0x7E7E7E alpha:1.0];
    [containerView addSubview:trashTipsText];
    [trashTipsText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(containerView).offset(94);
        make.top.equalTo(trashCountText.mas_bottom).offset(3);
    }];
    
    // button
    NSButton* trashCleanButton = [LMViewHelper createSmallGreenButton:12 title:NSLocalizedStringFromTableInBundle(@"LMCleanViewController_showTrashContainerView_1553842683_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    [trashCleanButton setTarget:self];
    [trashCleanButton setAction:@selector(clickTrashClean)];
    [containerView addSubview:trashCleanButton];
    [trashCleanButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(trashIcon);
        make.right.mas_equalTo(containerView.mas_right).offset(-20);
        make.width.equalTo(@60);
        make.height.equalTo(@24);
    }];
    
}

- (void) showTrashCleaningView:(BOOL)bShow
{
    BOOL bNeedCreate = false;
    
    if (bShow)
    {
        if (trashCleaningView != nil)
        {
            [trashCleaningView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = true;
        }
    }
    else
    {
        if (trashCleaningView != nil)
        {
            [trashCleaningView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = false;
        }
    }
    
    if (!bNeedCreate)
    {
        return;
    }
    
    // create view
    NSLog(@"showTrashCleaningView enter time=%f", [[NSDate date] timeIntervalSince1970]);
    NSView* containerView = [[NSView alloc] init];
    trashCleaningView = containerView;
    
    // icon
    NSImageView* trashIcon = [[NSImageView alloc] initWithFrame:NSZeroRect];
    [trashIcon setImage:[myBundle imageForResource:@"lemon_trash_cleaning"]];
    
    
    // layout
    [self layoutTrashView:containerView :trashIcon];
    
    // lable wording
    NSTextField *trashTipsText = [LMViewHelper createNormalLabel:20 fontColor:[LMAppThemeHelper getTitleColor]];
    trashTipsText.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanViewController_showTrashCleaningView_trashTipsText_1", nil, [NSBundle bundleForClass:[self class]], @"");
    trashTipsText.font = [NSFontHelper getMediumSystemFont:20];
    [containerView addSubview:trashTipsText];
    [trashTipsText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(trashIcon.mas_right).offset(20);
        make.top.mas_equalTo(containerView.mas_top).offset(28);
    }];
    
    // progress view
    QMProgressView* cleanProgressView = [[QMProgressView alloc] initWithFrame:NSMakeRect(0, 20, 94, 4)];
    cleanProgressView.backColor = [NSColor colorWithSRGBRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.1];
    cleanProgressView.fillColor = [NSColor colorWithSRGBRed:0/255.0 green:0xD8/255.0 blue:0x99/255.0 alpha:1.0];
    //    cleanProgressView.borderColor = [NSColor blackColor];
    cleanProgressView.minValue = 0.0;
    cleanProgressView.maxValue = 1.0;
    cleanProgressView.value = 0.5;
    [cleanProgressView setWantsLayer:YES];
    [containerView addSubview:cleanProgressView];
    [cleanProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(186);
        make.height.mas_equalTo(4);
        make.left.equalTo(trashTipsText);
        make.top.equalTo(trashTipsText.mas_bottom).offset(6);
        
    }];
    _cleanProgressView = cleanProgressView;
    
    NSLog(@"showTrashCleaningView leave time=%f", [[NSDate date] timeIntervalSince1970]);
}

- (void) showTrashCleanedView:(BOOL)bShow :(uint64)size
{
    BOOL bNeedCreate = false;
    
    if (bShow)
    {
        if (trashCleanedView != nil)
        {
            [trashCleanedView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = true;
        }
    }
    else
    {
        if (trashCleanedView != nil)
        {
            [trashCleanedView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = false;
        }
    }
    
    if (!bNeedCreate)
    {
        if (size > 0) {
            _trashCleanedCountText.stringValue = [NSString stringFromDiskSize:size];
        }
        return;
    }
    
    // create view
    NSLog(@"showTrashCleanedView enter time=%f", [[NSDate date] timeIntervalSince1970]);
    NSView* containerView = [[NSView alloc] init];
    trashCleanedView = containerView;
    
    // icon
    NSImageView* trashIcon = [[NSImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [trashIcon setImage:[myBundle imageForResource:@"lemon_trash_cleaned"]];
    
    // layout
    [self layoutTrashView:containerView :trashIcon];
    
    // lable wording 1
    NSTextField *trashCountText = [LMViewHelper createNormalLabel:20 fontColor:[LMAppThemeHelper getTitleColor]];
    trashCountText.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanViewController_showTrashCleanedView_trashCountText_1", nil, [NSBundle bundleForClass:[self class]], @"");
    [containerView addSubview:trashCountText];
    [trashCountText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(containerView).offset(94);
        make.top.mas_equalTo(containerView.mas_top).offset(27);
    }];
    _trashCleanedCountText = trashCountText;
    
    // lable wording 2
    NSTextField* trashTipsText = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979B]];
    trashTipsText.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanViewController_showTrashCleanedView_NSString_2", nil, [NSBundle bundleForClass:[self class]], @""),[NSString stringFromDiskSize:size]];
    [containerView addSubview:trashTipsText];
    [trashTipsText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(containerView).offset(94);
        make.top.equalTo(trashCountText.mas_bottom).offset(3);
    }];
    
    NSLog(@"showTrashCleanedView leave time=%f, size: %@, size(int):%llu", [[NSDate date] timeIntervalSince1970],[NSString stringFromDiskSize:size], size);
}

- (void) showTrashCleanessView:(BOOL)bShow
{
    BOOL bNeedCreate = false;
    
    if (bShow)
    {
        if (trashCleannessView != nil)
        {
            [trashCleannessView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = true;
        }
    }
    else
    {
        if (trashCleannessView != nil)
        {
            [trashCleannessView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = false;
        }
    }
    
    if (!bNeedCreate)
    {
        return;
    }
    
    // create view
    NSLog(@"showTrashCleanessView enter time=%f", [[NSDate date] timeIntervalSince1970]);
    NSView* containerView = [[NSView alloc] init];
    trashCleannessView = containerView;
    
    // icon
    NSImageView* trashIcon = [[NSImageView alloc] init];
    [trashIcon setImage:[myBundle imageForResource:@"lemon_clean_icon"]];
    
    // layout
    [self layoutTrashView:containerView :trashIcon];
    
    // lable wording 1
    NSTextField *trashTipsText1 = [LMViewHelper createNormalLabel:20 fontColor:[LMAppThemeHelper getTitleColor]];
    trashTipsText1.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanViewController_showTrashCleanessView_trashTipsText1_1", nil, [NSBundle bundleForClass:[self class]], @"");
    trashTipsText1.font = [NSFontHelper getMediumSystemFont:20];
    [containerView addSubview:trashTipsText1];
    [trashTipsText1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(containerView.mas_top).offset(27);
        make.left.mas_equalTo(trashIcon.mas_right).offset(18);
    }];
    
    // lable wording 2
    NSTextField *trashTipsText2 = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x7E7E7E]];
    trashTipsText2.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanViewController_showTrashCleanessView_trashTipsText2_2", nil, [NSBundle bundleForClass:[self class]], @"");
    
    
    trashTipsText2.textColor = [NSColor colorWithHex:0x94979B];
    [containerView addSubview:trashTipsText2];
    [trashTipsText2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(trashTipsText1.mas_bottom).offset(3);
        make.left.mas_equalTo(trashIcon.mas_right).offset(18);
    }];
    
    NSLog(@"showTrashCleanessView leave time=%f", [[NSDate date] timeIntervalSince1970]);
}


- (void) showScaningTrashView:(BOOL)bShow
{
    BOOL bNeedCreate = false;
    
    if (bShow)
    {
        if (trashScanningView != nil)
        {
            [trashScanningView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = true;
        }
    }
    else
    {
        if (trashScanningView != nil)
        {
            [trashScanningView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = false;
        }
    }
    
    if (!bNeedCreate)
    {
        return;
    }
    
    NSView* containerView = [[NSView alloc] init];
    trashScanningView = containerView;
    
    // icon
    NSImageView* trashIcon = [[NSImageView alloc] init];
    [trashIcon setImage:[myBundle imageForResource:@"lemon_clean_icon"]];
    
    // layout
    [self layoutTrashView:containerView :trashIcon];
    
    // lable wording 1
    NSTextField *trashTipsText1 = [LMViewHelper createNormalLabel:20 fontColor:[LMAppThemeHelper getTitleColor]];
    trashTipsText1.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanViewController_showScaningTrashView_trashTipsText1_1", nil, [NSBundle bundleForClass:[self class]], @"");
    trashTipsText1.font = [NSFontHelper getMediumSystemFont:20];
    [containerView addSubview:trashTipsText1];
    [trashTipsText1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(containerView.mas_top).offset(27);
        make.left.mas_equalTo(trashIcon.mas_right).offset(18);
    }];
    
    // lable wording 2
    NSTextField *trashTipsText2 = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x7E7E7E]];
    trashTipsText2.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanViewController_showScaningTrashView_trashTipsText2_2", nil, [NSBundle bundleForClass:[self class]], @"");
    
    
    trashTipsText2.textColor = [NSColor colorWithHex:0x94979B];
    [containerView addSubview:trashTipsText2];
    [trashTipsText2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(trashTipsText1.mas_bottom).offset(3);
        make.left.mas_equalTo(trashIcon.mas_right).offset(18);
    }];
    
    NSLog(@"showScaningTrashView leave time=%f", [[NSDate date] timeIntervalSince1970]);
}
- (void) showMemContainerView:(BOOL)bShow
{
    BOOL bNeedCreate = false;
    
    if (bShow)
    {
        if (memContainerView != nil)
        {
            [memContainerView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = true;
        }
    }
    else
    {
        if (memContainerView != nil)
        {
            [memContainerView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = false;
        }
    }
    
    if (!bNeedCreate)
    {
        return;
    }
    
    // create view
    NSView* containerView = [[NSView alloc] init];
    memContainerView = containerView;
    
    // icon
    NSImageView* memIcon = [[NSImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [memIcon setImage:[myBundle imageForResource:@"lemon_mem_gray"]];
    
    // layout
    [self layoutMemView:containerView:memIcon];
    
    // lable wording 1
    NSTextField *memTipsText = [LMViewHelper createNormalLabel:12 fontColor:[LMAppThemeHelper getTitleColor]];
    memTipsText.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanViewController_showMemContainerView_memTipsText_1", nil, [NSBundle bundleForClass:[self class]], @"");
    [containerView addSubview:memTipsText];
    [memTipsText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(containerView);
        make.left.mas_equalTo(memIcon.mas_right).offset(1);
    }];
    
    // lable wording 2
    NSTextField *memCountText = [LMViewHelper createNormalLabel:14 fontColor:[NSColor colorWithHex:0xFFAA09]];
    memCountText.stringValue = @"50%";
    [containerView addSubview:memCountText];
    [memCountText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(containerView);
        make.left.mas_equalTo(memTipsText.mas_right).offset(8);
    }];
    _memCountText = memCountText;
    
    // button
    NSTextField *memButtonText = [NSTextField labelWithStringCompat:NSLocalizedStringFromTableInBundle(@"LMCleanViewController_showMemContainerView_memButtonText _2", nil, [NSBundle bundleForClass:[self class]], @"")];
    memButtonText.font = [NSFont systemFontOfSize:12];
    memButtonText.textColor = [NSColor colorWithHex:0x1A83F7 alpha:1.0];
    [containerView addSubview:memButtonText];
    [memButtonText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(containerView);
        make.right.mas_equalTo(containerView.mas_right).offset(-20);
    }];
    
    NSClickGestureRecognizer *click = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(onMemClean)];
    [memButtonText addGestureRecognizer:click];
    
}

- (void) showMemCleaningView:(BOOL)bShow
{
    BOOL bNeedCreate = false;
    
    if (bShow)
    {
        if (memCleaningView != nil)
        {
            [memCleaningView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = true;
        }
    }
    else
    {
        if (memCleaningView != nil)
        {
            [memCleaningView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = false;
        }
    }
    
    if (!bNeedCreate)
    {
        if (bShow) {
            [self startMemReleaseAnimation];
        }
        return;
    }
    
    // create view
    NSView* containerView = [[NSView alloc] init];
    memCleaningView = containerView;
    
    // icon
    NSImageView* memIcon = [[NSImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    memIcon.wantsLayer = YES;
    [memIcon setImage:[myBundle imageForResource:@"lemon_mem_release"]];
    memReleaseImageView = memIcon;
  
    // layout
    [self layoutMemView:containerView:memIcon];
    
    // lable wording
    NSTextField *memTipsText = [LMViewHelper createNormalLabel:12 fontColor:[LMAppThemeHelper getTitleColor]];
    memTipsText.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanViewController_showMemCleaningView_memTipsText_1", nil, [NSBundle bundleForClass:[self class]], @"");
    [containerView addSubview:memTipsText];
    self->memTipsText = memTipsText;
    [memTipsText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(containerView);
        make.left.mas_equalTo(memIcon.mas_right).offset(2);
    }];
    
    [self startMemReleaseAnimation];

}


- (void)startMemReleaseAnimation
{
    [self cancelMemReleaseAnimation];
    
    // 整理动画
    self->memReleaseTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(showMemReleaseAnimation) userInfo:nil repeats:YES];

}

-(void)cancelMemReleaseAnimation
{
    if(memReleaseTimer){
        [memReleaseTimer invalidate];
        memReleaseTimer = nil;
    }
}

-(void)showMemReleaseAnimation
{
    if(self->memRadianOffset % 150 == 0){
        NSString *tips = memTipsText.stringValue;
        if ([tips containsString:@"..."]){
            tips = [tips stringByReplacingOccurrencesOfString:@"..." withString:@"."];
        }else if ([tips containsString:@".."]){
            tips = [tips stringByReplacingOccurrencesOfString:@".." withString:@"..."];
        }else if ([tips containsString:@"."]){
            tips = [tips stringByReplacingOccurrencesOfString:@"." withString:@".."];
        }else{
            tips = [tips stringByAppendingString:@"."];
        }
        memTipsText.stringValue = tips;
    }

    [memReleaseImageView.layer setAnchorPoint:NSMakePoint(0.5, 0.5)];
    CGPoint center = CGPointMake(CGRectGetMidX(memReleaseImageView.frame), CGRectGetMidY(memReleaseImageView.frame));
    memReleaseImageView.layer.position = center;
    CGAffineTransform ourTransform = CGAffineTransformMakeRotation( ( self->memRadianOffset * M_PI ) / 180 );
    self->memRadianOffset += 10;
    [memReleaseImageView.layer setAffineTransform: ourTransform];

}

- (void) showMemCleanedView:(BOOL)bShow :(uint64_t)purgeSize :(uint64_t)totalSize
{
    BOOL bNeedCreate = false;
    
    if (bShow)
    {
        if (memCleanedView != nil)
        {
            [memCleanedView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = true;
        }
        if (memCountText) {
            double purgeRate = 0;
            if (totalSize > 0) {
                purgeRate = purgeSize*1.0/totalSize;
            }
            memCountText.stringValue = [[NSString alloc] initWithFormat:@"%d%%" ,(int)round(purgeRate*100)];
        }
    }
    else
    {
        if (memCleanedView != nil)
        {
            [memCleanedView setHidden:!bShow];
            bNeedCreate = false;
        }
        else
        {
            bNeedCreate = false;
        }
    }
    
    if (!bNeedCreate)
    {
        return;
    }
    
    // create view
    NSView* containerView = [[NSView alloc] init];
    memCleanedView = containerView;
    
    // icon
    NSImageView* memIcon = [[NSImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [memIcon setImage:[myBundle imageForResource:@"lemon_mem_gray"]];
    
    // layout
    [self layoutMemView:containerView:memIcon];
    
    // lable wording
    NSTextField* memTipsText1 = [LMViewHelper createNormalLabel:12 fontColor:[LMAppThemeHelper getTitleColor]];
    memTipsText1.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanViewController_showMemCleanedView_memTipsText1_1", nil, [NSBundle bundleForClass:[self class]], @"");
    [containerView addSubview:memTipsText1];
    [memTipsText1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(containerView);
        make.left.mas_equalTo(memIcon.mas_right).offset(2);
    }];
    
    double purgeRate = 0;
    if (totalSize > 0) {
        purgeRate = purgeSize*1.0/totalSize;
    }
    memCountText =  [LMViewHelper createNormalLabel:14 fontColor:[NSColor colorWithHex:0xFFAA09]];
    memCountText.stringValue = [[NSString alloc] initWithFormat:@"%d%%" ,(int)round(purgeRate*100)];
    [containerView addSubview:memCountText];
    [memCountText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(containerView);
        make.left.mas_equalTo(memTipsText1.mas_right).offset(8);
    }];
    
    NSTextField* memTipsText2 = [LMViewHelper createNormalLabel:12 fontColor:[LMAppThemeHelper getTitleColor]];
    memTipsText2.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanViewController_showMemCleanedView_memTipsText2_2", nil, [NSBundle bundleForClass:[self class]], @"");
    [containerView addSubview:memTipsText2];
    [memTipsText2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(containerView);
        make.left.mas_equalTo(memCountText.mas_right).offset(8);
    }];
    NSLog(@"%s  %d", __FUNCTION__, (int)round(purgeRate*100));
}


- (void)layoutTrashView:(NSView*)containerView :(NSImageView*)trashIcon
{
    
//    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:containerView];
    containerView.layer.cornerRadius = 4.0;
    // container view
    [self.view addSubview:containerView];
    [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.height.equalTo(@103);
        make.top.equalTo(self.view).offset(1);
    }];
    
    // image
    [containerView addSubview:trashIcon];
    [trashIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(containerView);
        make.left.equalTo(containerView).offset(22);
        make.height.equalTo(@60);
        make.width.equalTo(@60);
    }];
}



- (void)layoutMemView:(NSView*)containerView :(NSImageView*)memIcon
{
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:containerView];
    containerView.layer.cornerRadius = 4.0;
    
    divisionView = [LMViewHelper createPureColorView:[NSColor colorWithHex:0xF1F1F1]];
    
    [containerView addSubview:divisionView];
    
    // add
    [self.view addSubview:containerView];
    [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.height.equalTo(@44);
        make.top.equalTo(self.view).offset(104);
    }];
    
    
    [divisionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(containerView).offset(-20);
        make.centerX.equalTo(containerView);
        make.height.equalTo(@1);
        make.top.equalTo(containerView);
    }];
    
    // icon
    [containerView addSubview:memIcon];
    [memIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(containerView);
        make.left.equalTo(containerView).offset(13);
        make.height.equalTo(@32);
        make.width.equalTo(@32);
    }];
}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:divisionView];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:memContainerView];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:memCleanedView];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:memCleaningView];
}

// 扫描结束(通知) 由三种状态, 能拿到结果. 未有结果(显示正在扫描中)  扫描结束(更新界面,无论原来是正在扫描中还是已有数据).
-(void)onReceiveTrashScanEnding
{
    
}

- (void) clickTrashClean
{
    NSLog(@"clickTrashClean enter.");
    
    // UI
    [self showTrashContainerView:NO:0];
    [self showTrashCleaningView:YES];
    
    [[LMMonitorTrashManager sharedManager] cleanTrash];
}

- (void) onMemClean
{
    NSLog(@"onMemClean enter.");
        
    // set status
    bActionMemCleaning = YES;
    
    // UI
    [self showMemContainerView:NO];
    [self showMemCleanedView:NO :0:0];
    [self showMemCleaningView:YES];
    
    //释放前记录内存值
    NSArray *beforeSizeArray = [[McMonitorFuction sharedFuction] memoryStateInfo][@"SizeArray"];
    uint64_t startUsedSize = [beforeSizeArray[4] unsignedLongLongValue] - [beforeSizeArray[5] unsignedLongLongValue];
    
    // purge RAM
    dispatch_async(kQMDEFAULT_GLOBAL_QUEUE, ^{
        [QMPurgeRAM purge];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //释放后记录内存值
            NSArray *afterSizeArray = [[McMonitorFuction sharedFuction] memoryStateInfo][@"SizeArray"];
            uint64_t totalSize = [afterSizeArray[4] unsignedLongLongValue];
            uint64_t endUsedSize = totalSize - [afterSizeArray[5] unsignedLongLongValue];//[afterSizeArray[4] unsignedLongLongValue] - [afterSizeArray[0] unsignedLongLongValue];
            NSLog(@"%s, %llu,  %llu", __FUNCTION__, startUsedSize, endUsedSize);
            uint64_t purgeSize = (startUsedSize>endUsedSize) ? (startUsedSize-endUsedSize) : 0;
            [self showMemCleanedView:YES :purgeSize :totalSize];
            dispatch_async(kQMDEFAULT_GLOBAL_QUEUE, ^{
                sleep(3);
                bActionMemCleaning = NO;
            });
        });
    });
}


// mark : begin QMLiteCleanerDelegate

- (void)scanProgressInfo:(float)value scanPath:(NSString *)path
{
//    NSLog(@"scanProgressInfo value=%f", value);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_cleanProgressView setValue:value/2];
    });
}

- (void)scanDidEnd
{
    // 扫描结束并不会调用scanDidEnd的回调. 扫描时时子线程同步方法. scan 结束后直接更改 UI. 具体方法在onTrashScan()中.
    // 另外真正清理时会重新扫描一次.
    NSLog(@"scanDidEnd...");
}

- (void)cleanProgressInfo:(float)value
{
    NSLog(@"cleanProgressInfo value=%f", value);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_cleanProgressView setValue:value/2 + 0.5];
    });
}
- (void)cleanDidEnd:(UInt64)size
{
    NSLog(@"monitor cleanDidEnd size=%llu", size);
    
    // 先显示清理结果,然后延迟一段时间后显示无垃圾页面
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [_cleanProgressView setValue:1.0];
//        [self showTrashContainerView:NO:0];
//        [self showTrashCleaningView:NO];
//        [self showTrashCleanedView:YES:[[LMMonitorTrashManager sharedManager] getTrashSize] ];
//    });
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2000 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
//        [self showTrashContainerView:NO:0];
//        [self showTrashCleaningView:NO];
//        [self showTrashCleanedView:NO:0];
//        [self showTrashCleanessView:YES];
//    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showTrashContainerView:NO:0];
        [self showTrashCleaningView:NO];
        [self showTrashCleanedView:NO:0];
        [self showTrashCleanessView:YES];
    });
}



-(void)recivedRAMInfoChanged:(NSNotification *)notification
{
    if (bActionMemCleaning == YES) {
        return;
    }
    
    NSDictionary* info = notification.object;
    NSArray *memInfo = nil;
    if (info)
        memInfo = [info objectForKey:@"SizeArray"];
    else
        memInfo = [[McMonitorFuction sharedFuction] memoryStateInfo][@"SizeArray"];
    
    uint64_t totalSize = [memInfo[4] unsignedLongLongValue];
    uint64_t usedSize = totalSize - [memInfo[5] unsignedLongLongValue];
    double usedRate = usedSize*1.0/totalSize;
    //显示内存占用值
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMemCleaningView:NO];
        [self cancelMemReleaseAnimation];
        [self showMemCleanedView:NO :0 :0];
        [self showMemContainerView:YES];
        [_memCountText setStringValue:[[NSString alloc] initWithFormat:@"%d%%" ,(int)round(usedRate*100)]];
        [self refreshProcMemUIWithInfo:notification.object mode:kREFRESH_MODE_NOTIFY];

    });
    
    //    NSLog(@"recivedRAMInfoChanged:totalSize=%llu,usedSize=%llu", totalSize, usedSize);
}

// end QMLiteCleanerDelegate
- (void)refreshProcMemUIWithInfo:(NSDictionary *)info mode:(int)mode
{
    //获取进程
    if (mode == kREFRESH_MODE_KILL || mode == kREFRESH_MODE_SHOW || ![NSEvent mouseInView:listView])
    {
//        NSArray *processInfo = [McStatMonitor shareMonitor].processInfo;
//        NSArray *processInfos = [[McCoreFunction shareCoreFuction] processInfo:NULL totalMemory:NULL];
        
        [[McCoreFunction shareCoreFuction] processInfo:NULL totalMemory:NULL block:^(NSArray *processInfos) {
            if (processInfos == nil && self.hasAppearTip == NO) {
                self.hasAppearTip = YES;
                [self repairApp];
            }
            NSArray *topMemoryArray = [LemonMonitroHelpParams sharedInstance].topMemoryArray;
            if (topMemoryArray && topMemoryArray.count > 0) {
                
    //            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"resident_size" ascending:NO];
    //            NSArray *memArray = [self.topMemoryArray sortedArrayUsingDescriptors:@[sortDescriptor]];
    //            const int maxCount = 5;
    //            if (memArray.count > maxCount) {
    //                memArray = [memArray subarrayWithRange:NSMakeRange(0, maxCount)];
    //            }
                
                for (int i = 0; i < processInfos.count; i++) {
                    McProcessInfoData *data = [processInfos objectAtIndex:i];
                    for (int j = 0; j < topMemoryArray.count; j++) {
                        McProcessInfoData *topdata = [topMemoryArray objectAtIndex:j];
                        if (topdata.pid == data.pid) {
                            data.resident_size = topdata.resident_size;
                        }
                    }
                }
            }
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"resident_size" ascending:NO];
            processInfos = [processInfos sortedArrayUsingDescriptors:@[sortDescriptor]];
            
            //最多只能显示20个,并且保留前台应用.
            const int maxCount = MAX_COUNT_ITEM;
    //        if (processInfos.count > maxCount) {
    //            processInfos = [processInfos subarrayWithRange:NSMakeRange(0, maxCount)];
    //        }
            // 头部的五个应用
            NSMutableArray *head5Processes = [NSMutableArray array];
            for(McProcessInfoData *processInfo in processInfos){
                
                NSRunningApplication *runningApp = [NSRunningApplication runningApplicationWithProcessIdentifier:processInfo.pid];
                if(runningApp && runningApp.activationPolicy == NSApplicationActivationPolicyRegular){
                    [head5Processes addObject:processInfo];
                }
                
                if(head5Processes.count >= maxCount){
                    break;
                }
            }
            processInfos = head5Processes;
            
            NSArray *memoryInfo = [processInfos map:^id(McProcessInfoData *data, NSUInteger index) {
                NSRunningApplication *runningApp = [NSRunningApplication runningApplicationWithProcessIdentifier:data.pid];
                LMMemoryItem *item = [[LMMemoryItem alloc] init];
                item.icon = runningApp.icon ?: [[NSWorkspace sharedWorkspace] iconForFile:data.pExecutePath];
                item.name = runningApp.localizedName ?: data.pName;
                item.pid = data.pid;
                item.memorySize = data.resident_size;
                return item;
            }];
            
            memoryItems = [NSArray arrayWithArray:memoryInfo];
            if([memoryItems count] == 0){
                NSLog(@"%s memoryItems count is 0, processInfo is %@", __FUNCTION__, processInfos);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if([memoryItems count] <= 0){
                    self->processMemContainer.hidden = YES;
                    self->processMemPlaceHolderImageView.hidden = NO;
                }else{
                    self->processMemContainer.hidden = NO;
                    self->processMemPlaceHolderImageView.hidden = YES;
                }
                [listView reloadData];
            });
        }];
    }
}

- (void)repairApp
{
    NSArray *arguments = @[@"needRepair"];
    
    NSString *updatePath = [[DEFAULT_APP_PATH stringByAppendingPathComponent:@"Contents/Frameworks"]
                            stringByAppendingPathComponent:UPDATE_APP_NAME];
    
    [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:updatePath]
                                                  options:NSWorkspaceLaunchWithoutAddingToRecents
                                            configuration:@{NSWorkspaceLaunchConfigurationArguments: arguments}
                                                    error:NULL];
}

#pragma mark -
#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item)
    {
        if([memoryItems count] < MAX_COUNT_ITEM){
            return [memoryItems count];
        }else{
            return MAX_COUNT_ITEM;
        }
        
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item)
    {
        return [memoryItems objectAtIndex:index];
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return NO;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    return 38;
}

#pragma mark -
#pragma mark NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    LMMemoryItem *memoryItem = (LMMemoryItem *)item;
    LMMemoryCellView *cellView = [outlineView makeViewWithIdentifier:@"Cell" owner:nil];
    if (cellView == nil){
        cellView = [[LMMemoryCellView alloc] init];
        cellView.identifier = @"Cell";
    }
    cellView.killDelegate = self;
    [cellView.procImageView setImage:memoryItem.icon];
    [cellView.procField setStringValue:QMSafeSTR(memoryItem.name)];
    if ([cellView.procField respondsToSelector:@selector(setAllowsExpansionToolTips:)]) {
        [cellView.procField setAllowsExpansionToolTips:YES];
    }
    NSString *sizeString = [NSString stringFromDiskSize:memoryItem.memorySize];
    [cellView.memoryField setStringValue:sizeString];
    cellView.progress = [self calculateMemItemRate:memoryItem];
    cellView.outlineView = listView;
    cellView.cellRow = [listView rowForItem:item];
    cellView.needsDisplay = YES;
    [cellView setNeedsUpdateConstraints:YES];
    return cellView;
}

- (void)killProcess:(id)sender
{
//    NSInteger idx = [listView trackRow];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:KILL_PROCESS_AT_MONITOR object:self userInfo:nil];

    if(!sender){
        return;
    }
    NSInteger idx = [listView rowForView:sender];
    if (idx == -1)
    {
        return;
    }
    LMMemoryItem *showItem = [listView itemAtRow:idx];
    if (!showItem)
    {
        return;
    }
    
    [[McCoreFunction shareCoreFuction] killProcessByID:showItem.pid];
    [[McStatMonitor shareMonitor] refreshProcessInfo];
    
    [self refreshProcMemUIWithInfo:nil mode:kREFRESH_MODE_KILL];    
}

- (double)calculateMemItemRate:(LMMemoryItem *)memoryItem
{
    if(memoryItems && [memoryItems count] > 0){
        LMMemoryItem *firstItem = [memoryItems objectAtIndex:0];
        if(firstItem.memorySize > 0){
            return (double)memoryItem.memorySize /(double) firstItem.memorySize ;
        }
    }
    return 0;
}
@end



