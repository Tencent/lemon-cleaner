//
//  OwlWhiteListViewController.m
//  Lemon
//
//  Created by  Torsysmeng on 2018/8/28.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlWhiteListViewController.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/MMScroller.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/LMBorderButton.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/LMReferenceDefines.h>
#import "OwlListPlaceHolderView.h"
#import "NSAlert+OwlExtend.h"
#import "OwlTableRowView.h"
#import "OwlSelectViewController.h"
#import "OwlWindowController.h"
#import "Owl2Manager.h"
#import "OwlViewController.h"
#import "OwlConstant.h"
#import "Owl2WlAppItem.h"

#import "OwlWhitelistFoldCell.h"
#import "OwlWhitelistExpandCell.h"

@interface OwlWhiteListViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property(nonatomic, readonly) NSRect frame;

@property(nonatomic, strong) NSView *titleContainer;
@property(nonatomic, strong) NSView *topContainer;
@property(nonatomic, strong) NSView *centerContainer;
@property(nonatomic, strong) NSView *bottomContainer;

// titleContainer
@property(nonatomic, strong) NSTextField *tfTitle;

// topContainer
@property(nonatomic, strong) NSTextField *labelSpecApp;
@property(nonatomic, strong) NSTextField *labelSpecType;
@property(nonatomic, strong) NSTextField *labelSpecOp;
@property(nonatomic, strong) NSTextField *labelSpecOperation;
@property(nonatomic, strong) NSView *bLineview;

// centerContainer
@property(nonatomic, strong) OwlListPlaceHolderView *listPlaceHolderView;
@property(nonatomic, strong) MMScroller *scroller;
@property(nonatomic, strong) NSScrollView *scrollView;
@property(nonatomic, strong) NSTableView *tableView;

// bottomContainer
@property(nonatomic, strong) NSButton *cancelBtn;
@property(nonatomic, strong) NSButton *addBtn;

// data
@property (nonatomic, strong) NSMutableArray<Owl2WlAppItem *> *wlList;

@end

@implementation OwlWhiteListViewController

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.selectWindowController) {
        [self.selectWindowController close];
        self.selectWindowController = nil;
    }
}

- (instancetype)initWithFrame:(NSRect)frame{
    self = [super init];
    if (self) {
        _frame = frame;
    }
    return self;
}

- (void)loadView {
    NSView *contentView = [[NSView alloc] initWithFrame:self.frame];
    contentView.wantsLayer = YES;
    CALayer *layer = [[CALayer alloc] init];
    layer.backgroundColor = [NSColor whiteColor].CGColor;
    contentView.layer = layer;
    
    self.view = contentView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [self setupSubviews];
    [self setupSubviewsLayout];
    [self reloadData];
    [self setupNotification];
}

                      
-(void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.view];
    [LMAppThemeHelper setDivideLineColorFor:self.bLineview];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.scroller];
}


- (void)setupSubviews {
    [self.view addSubview:self.titleContainer];
    [self.view addSubview:self.topContainer];
    [self.view addSubview:self.centerContainer];
    [self.view addSubview:self.bottomContainer];
    
    // titleContainer
    [self.titleContainer addSubview:self.tfTitle];
    
    // topContainer
    [self.topContainer addSubview:self.labelSpecApp];
    [self.topContainer addSubview:self.labelSpecType];
    [self.topContainer addSubview:self.labelSpecOp];
    [self.topContainer addSubview:self.labelSpecOperation];
    [self.topContainer addSubview:self.bLineview];
    
    // centerContainer
    [self.centerContainer addSubview:self.listPlaceHolderView];
    [self.scrollView setDocumentView:self.tableView];
    [self.centerContainer addSubview:self.scrollView];
    
    
    // bottomContainer
    [self.bottomContainer addSubview:self.addBtn];
}

- (void)setupSubviewsLayout {
    
    // titleContainer
    [self.tfTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(0);
    }];
    
    // topContainer
    [self.labelSpecApp mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(OwlElementLeft - kOwlLeftRightMarginForTableCell);
        make.centerY.mas_equalTo(0);
        make.width.mas_lessThanOrEqualTo(142 - kOwlHorizontalTextSpacing);
    }];
    [self.labelSpecType mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(166 - kOwlLeftRightMarginForTableCell);
        make.centerY.mas_equalTo(0);
    }];
    [self.labelSpecOp mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(278 - kOwlLeftRightMarginForTableCell);
        make.centerY.mas_equalTo(0);
        make.width.mas_lessThanOrEqualTo(250 - kOwlHorizontalTextSpacing);
    }];
    [self.labelSpecOperation mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(528 - kOwlLeftRightMarginForTableCell);
        make.centerY.mas_equalTo(0);
    }];
    [self.bLineview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(-kOwlLeftRightMarginForTableCell);
        make.right.mas_equalTo(kOwlLeftRightMarginForTableCell);
        make.height.mas_equalTo(1);
        make.bottom.mas_equalTo(0);
    }];
    
    // centerContainer
    [self.listPlaceHolderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
    
    // bottomContainer
    [self.addBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-OwlElementLeft);
        make.centerY.mas_equalTo(0);
        if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
            make.size.mas_equalTo(NSMakeSize(104, 24));
        } else {
            make.size.mas_equalTo(NSMakeSize(72, 24));
        }
    }];
    
}

- (void)setupNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(whiteListChange:) name:OwlWhiteListChangeNotication object:nil];
}

- (void)whiteListChange:(NSNotification*)no{
    [self reloadData];
}

- (void)reloadData {
    NSDictionary *wlDic = [Owl2Manager sharedManager].wlDic.copy;
    NSArray *wlList = [wlDic owl_toWlAppItemsFromContainExpandWlList:self.wlList] ? : @[];
    NSArray *sortWlList = [wlList sortedArrayUsingComparator:^NSComparisonResult(Owl2WlAppItem *obj1, Owl2WlAppItem *obj2) {
        return [obj1.name compare:obj2.name]; // 升序
    }];
    self.wlList = [[NSMutableArray alloc] initWithArray:sortWlList];
    
    [self reloadWhiteList];
}

- (void)reloadWhiteList{
    // 是否展示占位图
    self.scrollView.hidden = (0 == self.wlList.count);
    self.listPlaceHolderView.hidden = (0 != self.wlList.count);
    
    [self.tableView reloadData];
}

#pragma mark - sender

- (void)clickBtn:(id)sender{
    if (!self.selectWindowController || !self.selectWindowController.window.contentViewController) {
        NSRect prect = self.view.window.frame;
        NSRect srect = NSMakeRect(prect.origin.x + (prect.size.width - self.view.frame.size.width) / 2, prect.origin.y + (prect.size.height - self.view.frame.size.height) / 2, self.view.frame.size.width, self.view.frame.size.height);
        NSLog(@"clickBtn: %@", NSStringFromRect(srect));
        NSViewController *viewController = [[OwlSelectViewController alloc] initWithFrame:srect];
        self.selectWindowController = [[OwlWindowController alloc] initViewController:viewController];
        [self.selectWindowController.window setReleasedWhenClosed:NO];
        [self.view.window addChildWindow:self.selectWindowController.window ordered:NSWindowAbove];
        [self.selectWindowController showWindow:nil];
        [self.selectWindowController.window setFrame:srect display:NO];
    } else {
        [(OwlSelectViewController*)(self.selectWindowController).window.contentViewController reloadData];
        [self.selectWindowController showWindow:nil];
    }
}

#pragma mark NSTableViewDelegate

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    Owl2WlAppItem *appItem = self.wlList[row];
    if (appItem.isExpand) {
        return OwlWLCellExpandHeight + OwlWLCellFoldHeight;
    }
    return OwlWLCellFoldHeight;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    Owl2WlAppItem *appItem = self.wlList[row];
    OwlWhitelistCell *cell = nil;
    if (appItem.isExpand) {
        OwlWhitelistExpandCell *expandCell = [tableView makeViewWithIdentifier:@"OwlWhitelistExpandCell" owner:self];
        if (!expandCell) {
            expandCell = [[OwlWhitelistExpandCell alloc] initWithFrame:NSZeroRect];
            expandCell.identifier = @"OwlWhitelistExpandCell";
        }
        cell = expandCell;
        
        @weakify(self);
        void (^updateSwitchStateBlock)(BOOL enable, Owl2LogHardware hardware) = ^(BOOL enable, Owl2LogHardware hardware) {
            [appItem setWatchValue:enable forHardware:hardware];
            [[Owl2Manager sharedManager] addWhiteWithAppItem:appItem];
        };
        expandCell.cameraCheckAction = ^(LMCheckboxButton *btn) {
            updateSwitchStateBlock(btn.state, Owl2LogHardwareVedio);
        };
        expandCell.audioCheckAction = ^(LMCheckboxButton *btn) {
            updateSwitchStateBlock( btn.state, Owl2LogHardwareAudio);
        };
        expandCell.speakerCheckAction = ^(LMCheckboxButton *btn) {
            updateSwitchStateBlock(btn.state, Owl2LogHardwareSystemAudio);
        };
        expandCell.screenCheckAction = ^(LMCheckboxButton *btn) {
            updateSwitchStateBlock(btn.state, Owl2LogHardwareScreen);
            if (@available(macOS 15.0, *)) {
                // nothing
            } else {
                if (btn.state) {
                    [NSAlert owl_showScreenPrivacyProtection];
                }
            }
        };
        expandCell.automaticCheckAction = ^(LMCheckboxButton *btn) {
            updateSwitchStateBlock(btn.state, Owl2LogHardwareAutomation);
        };
        
    } else {
        OwlWhitelistFoldCell *foldCell = [tableView makeViewWithIdentifier:@"OwlWhitelistFoldCell" owner:self];
        if (!foldCell) {
            foldCell = [[OwlWhitelistFoldCell alloc] initWithFrame:NSZeroRect];
            foldCell.identifier = @"OwlWhitelistFoldCell";
        }
        cell = foldCell;
    }
    
    @weakify(self);
    cell.foldOrExpandAction = ^{
        @strongify(self);
        NSLog(@"foldOrExpandAction row: %ld", (long)row);
        appItem.isExpand = !appItem.isExpand;
        
        [self.tableView reloadData];
    };
    cell.removeAction = ^ {
        @strongify(self);
        NSLog(@"action row: %ld", (long)row);
        // 移除中有通知，会导致刷新，故此处不再刷新
        [[Owl2Manager sharedManager] removeAppWhiteItemWithIdentifier:appItem.identifier];
        [self.wlList removeObject:appItem];
    };
    
    [cell updateAppItem:appItem];
    return cell;
}

- (nullable NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row{
    OwlWLTableRowView *view = [tableView makeViewWithIdentifier:@"OwlTableRowView" owner:self];
    if (!view) {
        view = [[OwlWLTableRowView alloc] initWithFrame:NSZeroRect];
        view.identifier = @"OwlTableRowView";
    }
    Owl2WlAppItem *appItem = self.wlList[row];
    view.isExpand = appItem.isExpand;
    return view;
}

#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.wlList.count;
}

#pragma mark - getter

- (NSView *)titleContainer {
    if (!_titleContainer) {
        _titleContainer = [[NSView alloc] initWithFrame:NSMakeRect(0, self.frame.size.height - kOwlTitleViewHeight, self.frame.size.width, kOwlTitleViewHeight)];
    }
    return _titleContainer;
}

- (NSView *)topContainer {
    if (!_topContainer) {
        _topContainer = [[NSView alloc] initWithFrame:NSMakeRect(kOwlLeftRightMarginForTableCell, self.frame.size.height - kOwlTopViewHeight - 8 - kOwlTitleViewHeight, self.frame.size.width - kOwlLeftRightMarginForTableCell * 2, kOwlTopViewHeight)];
    }
    return _topContainer;
}

- (NSView *)centerContainer {
    if (!_centerContainer) {
        _centerContainer = [[NSView alloc] initWithFrame:NSMakeRect(0, kOwlBottomViewHeight, self.frame.size.width, self.frame.size.height - kOwlBottomViewHeight - kOwlTopViewHeight - 8 - kOwlTitleViewHeight)];
    }
    return _centerContainer;
}

- (NSView *)bottomContainer {
    if (!_bottomContainer) {
        _bottomContainer = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, kOwlBottomViewHeight)];
    }
    return _bottomContainer;
}

- (NSTextField *)tfTitle {
    if (!_tfTitle) {
        _tfTitle = [[NSTextField alloc] initWithFrame:NSZeroRect];
        _tfTitle.alignment = NSTextAlignmentCenter;
        _tfTitle.bordered = NO;
        _tfTitle.editable = NO;
        _tfTitle.backgroundColor = [NSColor clearColor];
        _tfTitle.font = [NSFontHelper getMediumSystemFont:16];
        _tfTitle.textColor = [LMAppThemeHelper getTitleColor];
        _tfTitle.stringValue = LMLocalizedSelfBundleString(@"白名单", nil);
    }
    return _tfTitle;
}

- (NSTextField *)labelSpecApp {
    if (!_labelSpecApp) {
        _labelSpecApp = [OwlWhitelistCell buildLabel:LMLocalizedSelfBundleString(@"软件进程", nil) font:[NSFontHelper getMediumSystemFont:12] color:[LMAppThemeHelper getSecondTextColor]];
    }
    return _labelSpecApp;
}

- (NSTextField *)labelSpecType {
    if (!_labelSpecType) {
        _labelSpecType = [OwlWhitelistCell buildLabel:LMLocalizedSelfBundleString(@"应用类型", nil) font:[NSFontHelper getMediumSystemFont:12] color:[LMAppThemeHelper getSecondTextColor]];
    }
    return _labelSpecType;
}

- (NSTextField *)labelSpecOp {
    if (!_labelSpecOp) {
        _labelSpecOp = [OwlWhitelistCell buildLabel:LMLocalizedSelfBundleString(@"已允许权限类型", nil) font:[NSFontHelper getMediumSystemFont:12] color:[LMAppThemeHelper getSecondTextColor]];
    }
    return _labelSpecOp;
}

- (NSTextField *)labelSpecOperation {
    if (!_labelSpecOperation) {
        _labelSpecOperation = [OwlWhitelistCell buildLabel:LMLocalizedSelfBundleString(@"操作", nil) font:[NSFontHelper getMediumSystemFont:12] color:[LMAppThemeHelper getSecondTextColor]];
    }
    return _labelSpecOperation;
}

- (NSView *)bLineview {
    if (!_bLineview) {
        _bLineview = [[NSView alloc] init];
        _bLineview.wantsLayer = YES;
        CALayer *lineLayer = [[CALayer alloc] init];
        lineLayer.backgroundColor = [NSColor colorWithWhite:0.96 alpha:1].CGColor;
        _bLineview.layer = lineLayer;
    }
    return _bLineview;
}

- (OwlListPlaceHolderView *)listPlaceHolderView {
    if (!_listPlaceHolderView) {
        _listPlaceHolderView = [[OwlListPlaceHolderView alloc] initWithTitle:LMLocalizedSelfBundleString(@"暂无白名单应用", nil)];
    }
    return _listPlaceHolderView;
}

- (MMScroller *)scroller {
    if (!_scroller) {
        _scroller = [[MMScroller alloc] init];
        [_scroller setWantsLayer:YES];
    }
    return _scroller;
}

- (NSScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[NSScrollView alloc] initWithFrame:self.centerContainer.bounds];
        [_scrollView setHasVerticalScroller:YES];
        [_scrollView setHasHorizontalScroller:NO];
        [_scrollView setAutohidesScrollers:YES];
        [_scrollView setAutoresizesSubviews:YES];
        [_scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [_scrollView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
        [_scrollView setVerticalScroller:self.scroller];
    }
    return _scrollView;
}

- (NSTableView *)tableView {
    if (!_tableView) {
        _tableView = [[NSTableView alloc] initWithFrame:self.scrollView.frame];
        [_tableView setDelegate:self];
        [_tableView setDataSource:self];
        [_tableView setBackgroundColor:[NSColor whiteColor]];
        [_tableView setAutoresizesSubviews:YES];
        _tableView.intercellSpacing = NSMakeSize(0, 0);
        [_tableView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
        [_tableView setHeaderView:nil];
        if (@available (macOS 11.0, *)) {
            _tableView.style = NSTableViewStyleFullWidth;
        }
        
        NSTableColumn *timeColumn = [[NSTableColumn alloc] initWithIdentifier:@""];
        timeColumn.width = self.frame.size.width;
        [_tableView addTableColumn:timeColumn];

    }
    return _tableView;
}

- (NSButton *)addBtn {
    if (!_addBtn) {
        _addBtn = [LMViewHelper createSmallGreenButton:12 title:LMLocalizedSelfBundleString(@"添加应用", nil)];
        _addBtn.wantsLayer = YES;
        _addBtn.layer.cornerRadius = 2;
        _addBtn.target = self;
        _addBtn.action = @selector(clickBtn:);
    }
    return _addBtn;
}

@end
