//
//  LMDuplicateResultViewController.m
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/20.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "LMDuplicateScanResultViewController.h"
#import <Masonry/Masonry.h>
#import "DuplicateSubItemCellView.h"
#import "DuplicateRootCellView.h"
#import "ExpandOutlineView.h"
#import "LMDuplicateSelectFoldersViewController.h"
#import "LMDuplicateCleanResultViewController.h"
#import "LMDuplicateCleanViewController.h"
#import "QMDuplicateItemManager.h"
#import <Quartz/Quartz.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMCoreFunction/NSEvent+Extension.h>
#import "DuplicateRowView.h"
#import "SizeHelper.h"
#import "LMDuplicateWindowController.h"
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/MMScroller.h>
#import <QMUICommon/MMScrollView.h>
#import <QMUICommon/COSwitch.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/LMBorderButton.h>
#import <QMUICommon/LMAppThemeHelper.h>

#define FILTER_BTN_COLOR_SEL    0x515151
#define FILTER_BTN_COLOR_NO_SEL 0x94979b

#define KEY_DUPLICATE_SMART_SCAN_ALERT_SHOWN_BOOL  @"duplicate_smart_scan_alert_show"


@interface LMDuplicateScanResultViewController () <QLPreviewItem, NSTableViewDelegate, NSTableViewDataSource, NSOutlineViewDataSource, NSOutlineViewDelegate> {
    NSBundle *bundle;
    QMDuplicateFile *selectedDuplicateFile;
    QMDuplicateBatch *selectedDuplicateBatch;
    NSArray *categoryArray;
    NSMutableArray *clickTextViewArray;

    NSMutableSet *collapseItemSet;
    BOOL manualClickCollapseButton;

    NSButton *filterCategoryBtn;
    NSTextField *previewFileNameLabel;
    NSTextField *previewFileSizeLabel;
    NSImageView *iconImageView;

    int _selectedFileItemsCount; //选择的文件数量
    int _selectedFolderItemsCount; // 选择的文件夹数量
    float _selectedItemsSize;

}

@property(nonatomic) ExpandOutlineView *fileOutlineView;
@property(nonatomic) NSScrollView *outlineScrollView;
@property(nonatomic) NSTableView *previewTableView;
@property(nonatomic) NSTextField *descTextField;
@property(nonatomic) NSView *bottomLineView;
@property(nonatomic) NSButton *cleanBtn;
@property(nonatomic) QLPreviewView *previewView;
@property(nonatomic) NSView *previewContainer;
@property(nonatomic) NSView *outlineSplitLineView;
@property(nonatomic) NSView *noDataAlertView;
@property(nonatomic) BOOL showPreview;
@property(nonatomic) BOOL autoSelect;
@property(weak)NSView *topLineView;



@property(nonatomic) NSMutableArray *currentItemArray;  // 区分 resultArray, currentItemArray是根据category进行分割的.两个 array中元素数量不同,但元素是相同的.


@end


@implementation LMDuplicateScanResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    collapseItemSet = [[NSMutableSet alloc] init];
    _showPreview = YES;
    _autoSelect = YES;

    [self initData];
    [self initView];
    [self updatePreviewState];
    [self updateAutoSelected];
    [self updateTitleSelectInfo];

}

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 780, 482)];
    self.view = view;
}


- (void)initView {
    [self setupTitleViews];
    [self setupCategoryViews];
    [self setupOutlineView];
    [self setupPreview];
    [self setupAlertView]; // 没有内容时的提示框.
}

- (void)setupTitleViews {
    //添加icon图标
    iconImageView = [[NSImageView alloc] init];
    iconImageView.image = [NSImage imageNamed:@"duplicate_small" withClass:self.class];
    iconImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    [self.view addSubview:iconImageView];


    NSTextField *titleTextField = [LMViewHelper createNormalLabel:24 fontColor:[LMAppThemeHelper getTitleColor]];
    [self.view addSubview:titleTextField];
    titleTextField.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_setupTitleViews_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""), [self calculateTotalDuplicateFilesSize]];

    NSTextField *descTextField = [LMViewHelper createNormalLabel:14 fontColor:[NSColor colorWithHex:0x94979B]];
    [self.view addSubview:descTextField];
    self.descTextField = descTextField;
    self.descTextField.font = [NSFontHelper getLightSystemFont:14];
    descTextField.stringValue = NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_setupTitleViews_descTextField_2", nil, [NSBundle bundleForClass:[self class]], @"");


    //添加返回按钮
    LMBorderButton *backBtn = [[LMBorderButton alloc] init];
    backBtn.title = NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_setupTitleViews_backBtn_3", nil, [NSBundle bundleForClass:[self class]], @"");
    backBtn.font = [NSFont systemFontOfSize:12];
    backBtn.target = self;
    backBtn.action = @selector(clickBackBtn);
    [self.view addSubview:backBtn];


    _cleanBtn = [LMViewHelper createNormalGreenButton:20 title:NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_setupTitleViews_1553072147_4", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.view addSubview:_cleanBtn];
    _cleanBtn.target = self;
    _cleanBtn.action = @selector(clickCleanBtn);
    [_cleanBtn setEnabled:NO];

    [iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(66);
        make.left.mas_equalTo(44);
        make.top.mas_equalTo(35);
    }];


    [titleTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-415);
        make.left.mas_equalTo(self->iconImageView.mas_right).offset(20);
    }];

    [descTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleTextField);
        make.top.equalTo(titleTextField.mas_bottom).offset(2);
    }];

    // 这里 一个 left 可以相对于2个 view, 可以保证 总是离两个 view 都合适.
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@60);
        make.height.equalTo(@24);
        make.left.equalTo(titleTextField.mas_right).mas_equalTo(20);
        make.centerY.equalTo(titleTextField);
    }];

    [_cleanBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-31);
        make.top.mas_equalTo(self.view).offset(41);
        make.width.mas_equalTo(148);
        make.height.mas_equalTo(48);
    }];
}

- (void)setupCategoryViews {

    //分割线上----
    NSView *topLineView = [[NSView alloc] init];
    [self.view addSubview:topLineView];
    self.topLineView = topLineView;
    [topLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(38);
        make.right.equalTo(self.view).offset(-32);
        make.height.mas_equalTo(1);
        make.top.equalTo(self.view).offset(108);
    }];

    //初始化选择类型的几个 view, 循环添加
    //-------start--------
    categoryArray = @[NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_setupCategoryViews_1553072448_1", nil, [NSBundle bundleForClass:[self class]], @""),
            NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_setupCategoryViews_1553072448_2", nil, [NSBundle bundleForClass:[self class]], @""),
            NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_setupCategoryViews_1553072448_3", nil, [NSBundle bundleForClass:[self class]], @""),
            NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_setupCategoryViews_1553072448_4", nil, [NSBundle bundleForClass:[self class]], @""),
            NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_setupCategoryViews_1553072591_1", nil, [NSBundle bundleForClass:[self class]], @""),
            NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_setupCategoryViews_1553072147_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    clickTextViewArray = [[NSMutableArray alloc] init];

    NSView *tempConstraintRightView = nil;
    for (int i = 0; i < categoryArray.count; i++) {
        NSString *title = categoryArray[(NSUInteger) i];

        NSButton *categoryButton = [LMViewHelper createNormalTextButton:14 title:@"" textColor:[NSColor colorWithHex:0x515151]];

//        //设置一个 tag, 用于后面点击事件时判断类型
        categoryButton.tag = i;
        categoryButton.title = title;
        [clickTextViewArray addObject:categoryButton];
        [self.view addSubview:categoryButton];
        if (!tempConstraintRightView) {
            [categoryButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.view).offset(38);
                make.top.equalTo(topLineView.mas_bottom).offset(8);
                make.height.equalTo(@24);
            }];
        } else {
            [categoryButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(tempConstraintRightView.mas_right).offset(16);
                make.top.equalTo(topLineView.mas_bottom).offset(8);
                make.height.equalTo(@24);
            }];
        }

        tempConstraintRightView = categoryButton;
        if (i == 0) {
            [self filterBtnSetFont:categoryButton font:[NSFontHelper getRegularSystemFont:14] color:[LMAppThemeHelper getFixedTitleColor]];
            filterCategoryBtn = categoryButton;
        } else {
            [self filterBtnSetFont:categoryButton font:[NSFontHelper getLightSystemFont:14] color:[NSColor colorWithHex:FILTER_BTN_COLOR_NO_SEL]];;
        }

        categoryButton.target = self;
        categoryButton.action = @selector(clickCategoryButton:);
    }
    //-------end--------

    //分割线下----
    _bottomLineView = [[NSView alloc] init];
    [self.view addSubview:_bottomLineView];
    [_bottomLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(topLineView);
        make.height.mas_equalTo(1);
        make.top.equalTo(topLineView.mas_bottom).offset(41);
    }];

    // previewButton
    NSTextField *previewLabel = [LMViewHelper createNormalLabel:14 fontColor:[NSColor colorWithHex:0x94979B]];
    previewLabel.font = [NSFontHelper getLightSystemFont:14];
    previewLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_setupCategoryViews_previewLabel_2", nil, [NSBundle bundleForClass:[self class]], @"");
    [self.view addSubview:previewLabel];

    COSwitch *previewSwitch = [[COSwitch alloc] init];
    [self.view addSubview:previewSwitch];
    previewSwitch.isAnimator = FALSE;
    previewSwitch.on = _showPreview;  // 首次不触发动画.
    previewSwitch.isAnimator = YES;
    __weak LMDuplicateScanResultViewController *weakSelf = self;
    [previewSwitch setOnValueChanged:^(COSwitch *button) {
        [weakSelf clickPreviewButton];
    }];
    [previewSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@30);
        make.height.equalTo(@14);
        make.centerY.equalTo(previewLabel);
        make.right.equalTo(self.view).offset(-33);
    }];

    [previewLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topLineView).offset(12);
        make.right.equalTo(previewSwitch.mas_left).offset(-10);
    }];

    // auto select Button
    NSTextField *autoSelectLabel = [LMViewHelper createNormalLabel:14 fontColor:[NSColor colorWithHex:0x94979B]];
    autoSelectLabel.font = [NSFontHelper getLightSystemFont:14];
    autoSelectLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_setupCategoryViews_autoSelectLabel", nil, [NSBundle bundleForClass:[self class]], @"");
    [self.view addSubview:autoSelectLabel];

    COSwitch *auotSelectSwitch = [[COSwitch alloc] init];
    [self.view addSubview:auotSelectSwitch];
    auotSelectSwitch.isAnimator = FALSE;
    auotSelectSwitch.on = _autoSelect;
    auotSelectSwitch.isAnimator = YES;
    [auotSelectSwitch setOnValueChanged:^(COSwitch *button) {
        [weakSelf clickAutoSelectButton];
    }];

    [auotSelectSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@30);
        make.height.equalTo(@14);
        make.centerY.equalTo(previewLabel);
        make.right.equalTo(previewLabel.mas_left).offset(-30);
    }];

    [autoSelectLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(auotSelectSwitch);
        make.right.equalTo(auotSelectSwitch.mas_left).offset(-10);
    }];

}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:self.topLineView];
    [LMAppThemeHelper setDivideLineColorFor:self.bottomLineView];
    [LMAppThemeHelper setDivideLineColorFor:self.outlineSplitLineView];
    //切换mode后，button颜色不会自动变化，所以需要手动更新
    [self filterBtnSetFont:filterCategoryBtn
                      font:[NSFontHelper getRegularSystemFont:14]
                     color:[LMAppThemeHelper getFixedTitleColor]];
}

- (void)filterBtnSetFont:(NSButton *)btn font:(NSFont *)font color:(NSColor *)color {
    NSString *str = btn.attributedTitle.string;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    NSDictionary *dictAttr = @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};
    NSAttributedString *attr = [[NSAttributedString alloc] initWithString:str attributes:dictAttr];
    [attributedString appendAttributedString:attr];
    btn.attributedTitle = attributedString;
}

- (void)setupPreview {
    _previewContainer = [[NSView alloc] init];
    [self.view addSubview:_previewContainer];
    [_previewContainer setHidden:YES];

    previewFileNameLabel = [LMViewHelper createNormalLabel:14 fontColor:[LMAppThemeHelper getTitleColor]];
    [_previewContainer addSubview:previewFileNameLabel];
    previewFileNameLabel.lineBreakMode = NSLineBreakByTruncatingHead;

    previewFileSizeLabel = [LMViewHelper createNormalLabel:14 fontColor:[LMAppThemeHelper getTitleColor]];
    [_previewContainer addSubview:previewFileSizeLabel];

    NSScrollView *previewScrollView = [[NSScrollView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    [_previewContainer addSubview:previewScrollView];
    [previewScrollView setDrawsBackground:NO];
    previewScrollView.hasVerticalScroller = YES;
    previewScrollView.autohidesScrollers = YES;
//    previewScrollView.scrollerStyle = NSScrollerStyleLegacy;

//    NoBackgroundScroller *scroller = [[NoBackgroundScroller alloc]init];
    MMScroller *scroller = [[MMScroller alloc] init];
    [previewScrollView setVerticalScroller:scroller];

    _previewTableView = [[NSTableView alloc] init];
    previewScrollView.documentView = _previewTableView;
    _previewTableView.headerView = nil;
    _previewTableView.delegate = self;
    _previewTableView.dataSource = self;
    _previewTableView.backgroundColor = [LMAppThemeHelper getMainBgColor];

//    _previewTableView.target = self;
//    _previewTableView.action = @selector(clickTableView);

    NSTableColumn *col1 = [[NSTableColumn alloc] initWithIdentifier:@"tableViewCol1"];
    col1.resizingMask = NSTableColumnAutoresizingMask;
    col1.editable = NO;
    [_previewTableView addTableColumn:col1];
    [_previewTableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
    [_previewTableView sizeLastColumnToFit];

    [_previewContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(354);
        make.right.equalTo(self.view);
        make.top.equalTo(self.bottomLineView);
        make.bottom.equalTo(self.view);
    }];

    [previewFileNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-121);
        make.left.equalTo(self->_previewContainer).offset(3);
        make.width.lessThanOrEqualTo(@280);
    }];

    [previewFileSizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self->previewFileNameLabel);
        make.right.equalTo(self->_previewContainer).offset(-36);
    }];

    [previewScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self->_previewContainer);
        make.top.equalTo(self->previewFileNameLabel.mas_bottom).offset(9);
        make.bottom.equalTo(self->_previewContainer);
    }];

}

- (void)setupAlertView {

    NSView *alertView = [[NSView alloc] init];
    [self.view addSubview:alertView];
    self.noDataAlertView = alertView;

    [alertView setHidden:YES];

    NSImageView *alertImageView = [[NSImageView alloc] init];
    [alertView addSubview:alertImageView];
    alertImageView.image = [NSImage imageNamed:@"no_data_alert" withClass:self.class];
    alertImageView.imageScaling = NSImageScaleProportionallyUpOrDown;

    NSTextField *alertLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979B]];
    alertLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_setupAlertView_alertLabel_1", nil, [NSBundle bundleForClass:[self class]], @"");
    alertLabel.font = [NSFontHelper getLightSystemFont:12];
    [alertView addSubview:alertLabel];

    [alertView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view);
        make.height.equalTo(@310);
        make.width.equalTo(self.view);
        make.left.equalTo(self.view);
    }];

    [alertImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@144);
        make.bottom.equalTo(alertView).offset(-128);
        make.centerX.equalTo(alertView);
    }];

    [alertLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(alertView).offset(-92);
        make.centerX.equalTo(alertView);
    }];
}

// 为了 fix preview 在特殊情况下出现的问题,
// 比如将一个很大的 .dmg 文件后缀改为 .png, 显示这个文件时, preview 会出现一直显示 loading状态, 即使跳到下一个文件,调用refreshPreviewItem也不会正常显示下一个文件. 所以每次 preview 显示文件时, 每次重新 生成并 add preview.
- (void)resetPreview {
    if (_previewView && _previewView.superview)
        [_previewView removeFromSuperview];
    _previewView = [[QLPreviewView alloc] initWithFrame:NSZeroRect style:QLPreviewViewStyleCompact];
    [self->_previewContainer addSubview:_previewView];
    [_previewView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self->_previewContainer);
        make.right.equalTo(self->_previewContainer).offset(-36);
        make.bottom.equalTo(self.view).offset(-155);
    }];

    _previewView.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
    __weak LMDuplicateScanResultViewController *weakSelf = self;
    [_previewView setPreviewItem:weakSelf];
    [_previewView refreshPreviewItem];

}

- (void)showDefaultPreview {

    // 当 outlineView 按照类别重置 dataSource 时,需要修改默认预览的 data.
    if (_currentItemArray != nil && _currentItemArray.count > 0) {
        if (![_currentItemArray containsObject:selectedDuplicateBatch]) {
            selectedDuplicateFile = nil;
            selectedDuplicateBatch = nil;
        }
    } else {
        selectedDuplicateFile = nil;
        selectedDuplicateBatch = nil;
    }

    //  如果没有选择的 item, 默认选择show 第一个item
    if (selectedDuplicateFile == nil || selectedDuplicateBatch == nil) {
        if (_currentItemArray != nil && _currentItemArray.count > 0) {
            selectedDuplicateBatch = _currentItemArray[0];
            if (selectedDuplicateBatch.subItems != nil && selectedDuplicateBatch.subItems.count > 0) {
                selectedDuplicateFile = selectedDuplicateBatch.subItems[0];
            }
        }
    }

    if (selectedDuplicateFile != nil && selectedDuplicateBatch != nil) {

        [self.previewContainer setHidden:NO];
        [self showSelectedItemInfo:selectedDuplicateBatch subItem:selectedDuplicateFile];

        NSInteger idx = [_fileOutlineView rowForItem:selectedDuplicateBatch];
        if (idx >= 0) {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:(NSUInteger) idx];
            [_fileOutlineView selectRowIndexes:indexSet byExtendingSelection:NO];
        }
    } else {
        // 如果没有 outlineView  没有 data,则不显示 preview
        [self.previewContainer setHidden:YES];
    }
}

- (void)resetClickView:(NSInteger)tag {
    switch (tag) {
        case 0:
            [self resetDataByType:QMFileTypeAll];
            break;
        case 1:
            [self resetDataByType:QMFileTypeMusic];
            break;
        case 2:
            [self resetDataByType:QMFileTypeVideo];
            break;
        case 3:
            [self resetDataByType:QMFileTypeDocument];
            break;
        case 4:
            [self resetDataByType:QMFileTypePicture];
            break;
        case 5:
            [self resetDataByType:QMFileTypeOther | QMFileTypeArchive | QMFileTypeFolder | QMFileTypeInstall];
            break;
        default:
            break;
    }
}

- (void)resetDataByType:(QMFileTypeEnum)fileType { // option是多个变量的集合.

    [_currentItemArray removeAllObjects];
    for (QMDuplicateBatch *batch in _resultArray) {
        if ((batch.fileType & fileType) == batch.fileType) {
            [_currentItemArray addObject:batch];
        }
    }

    [self privateReloadOutlineViewData];

    // preview 界面也重置
    if (self->_showPreview) {
        [self showDefaultPreview];
    }

}

- (void)initData {
    bundle = [NSBundle bundleForClass:self.class];
    _currentItemArray = [_resultArray mutableCopy];
}

- (void)setupOutlineView {
    self.fileOutlineView = [[ExpandOutlineView alloc] init];

    NSTableColumn *resultColumn = [[NSTableColumn alloc] initWithIdentifier:@"DuplicateCleanResult"];
    resultColumn.resizingMask = NSTableColumnAutoresizingMask;
    [resultColumn setWidth:200];
    [_fileOutlineView addTableColumn:resultColumn];
    _fileOutlineView.delegate = self;
    _fileOutlineView.dataSource = self;
    [_fileOutlineView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
    [_fileOutlineView setHeaderView:nil];
    _fileOutlineView.target = self;
    _fileOutlineView.action = @selector(clickOutlineView:);

    MMScrollView *scrollView = [[MMScrollView alloc] init];
    [scrollView setDrawsBackground:NO];
//    scrollView.scrollerStyle = NSScrollerStyleLegacy;
//    [scrollView setScrollerKnobStyle:NSScrollerKnobStyleLight];

    scrollView.hasVerticalScroller = YES;
    scrollView.autohidesScrollers = NO;
    scrollView.documentView = _fileOutlineView;

    MMScroller *scroller = [[MMScroller alloc] init];
    [scrollView setVerticalScroller:scroller];

    [self.view addSubview:scrollView];
    self.outlineScrollView = scrollView;

    NSView *outlineSplitLineView = [[NSView alloc] init];
    self.outlineSplitLineView = outlineSplitLineView;
    [self.view addSubview:outlineSplitLineView];
    [outlineSplitLineView setHidden:YES];

    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self->_bottomLineView.mas_bottom).offset(2);
        make.bottom.mas_equalTo(self.view);
        make.left.equalTo(self.view).offset(38);
        make.right.equalTo(self.view).offset(-32);
    }];

    [outlineSplitLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.height.equalTo(scrollView);
        make.left.equalTo(scrollView.mas_right);
        make.width.equalTo(@1);
    }];

}

#pragma mark-
#pragma mark preview delegate

- (NSURL *)previewItemURL {
    if (selectedDuplicateFile == nil || selectedDuplicateFile.filePath == nil) {
        return nil;
    }
    return [NSURL fileURLWithPath:selectedDuplicateFile.filePath];
}

- (NSString *)previewItemTitle {
    if (selectedDuplicateFile == nil || selectedDuplicateFile.filePath == nil) {
        return nil;
    }
    return selectedDuplicateFile.filePath;
}


// MARK: outlineView -- start ---

- (nullable NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item {
    return [[DuplicateRowView alloc] init];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        QMDuplicateBatch *duplicateItem = _currentItemArray[(NSUInteger) index];
        return duplicateItem;
    } else {
        QMDuplicateBatch *tempItem = (QMDuplicateBatch *) item;
        return [tempItem subItems][(NSUInteger) index];
    }
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil)
        return [_currentItemArray count];
    else
        return [[(QMDuplicateBatch *) item subItems] count];
}

// 这个是在 outlineView 绘制items 时,判断是否应该展开.
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if (self->_showPreview) {
        return NO;
    }
    return [item isKindOfClass:QMDuplicateBatch.class];

}

// 这个一般是在用户点击展开按钮或者调用 expand api 时,判断是否应该展开.
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item {
    if ([collapseItemSet containsObject:item] && !manualClickCollapseButton) { //自动切换(比如 preview 模式和非 preview 模式 点击切换时,应该保持 outlineView item 的展开/收缩状态)
        return NO;
    }
    NSArray *array = [((QMDuplicateBatch *) item) subItems];
    return [array count] > 0;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([item isKindOfClass:QMDuplicateBatch.class]) {

        QMDuplicateBatch *tempBatch = (QMDuplicateBatch *) item;
        DuplicateRootCellView *rootCellView = [outlineView makeViewWithIdentifier:@"duplicateRootCellView" owner:self];

        if (rootCellView == nil) {
            rootCellView = [[DuplicateRootCellView alloc] init];
            rootCellView.identifier = @"duplicateRootCellView";
        }

        rootCellView.expandItemDelegate = self;
        rootCellView.checkBoxUpdateDelegate = self;
        rootCellView.item = tempBatch;
        [rootCellView updateViewsWithItem:tempBatch withPreview:self->_showPreview];

        BOOL expand = [outlineView isItemExpanded:item];
        if (expand) {
            [rootCellView.expandButton setState:NSControlStateValueOff];
        } else {
            [rootCellView.expandButton setState:NSControlStateValueOn];
        }
        return rootCellView;

    } else {
        DuplicateSubItemCellView *subItemCellView = [outlineView makeViewWithIdentifier:@"duplicateSubItemCellView" owner:self];
        if (subItemCellView == nil) {
            subItemCellView = [[DuplicateSubItemCellView alloc] init];
            subItemCellView.identifier = @"duplicateSubItemCellView";
        }

        QMDuplicateFile *tempItem = (QMDuplicateFile *) item;
        subItemCellView.checkBoxUpdateDelegate = self;
        subItemCellView.item = tempItem;
        [subItemCellView updateViewsWithItem:tempItem withPreview:self->_showPreview];
        return subItemCellView;
    }

}


- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {

    if ([item isKindOfClass:QMDuplicateBatch.class]) {
        return 44;
    } else {
        return 30;
    }

}


- (void)expandOrCollapseItem:(QMDuplicateBatch *)item {

    manualClickCollapseButton = YES;
    if ([_fileOutlineView isItemExpanded:item]) {
        [_fileOutlineView.animator collapseItem:item];
        [collapseItemSet addObject:item];
    } else {
        [_fileOutlineView.animator expandItem:item];
        [collapseItemSet removeObject:item];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    if (_showPreview && item) {

        // fix bug: 用户使用 up/down 按键切换 item 选中状态时,应该也修改预览的内容.
        NSLog(@"shouldSelectItem ....");
        QMDuplicateBatch *batch = (QMDuplicateBatch *) item;
        if (batch.subItems == nil || batch.subItems.count <= 0) {
            return NO;
        }
        [self showSelectedItemInfo:batch subItem:batch.subItems[0]];
        return YES;
    }
    return NO;
}

// didClickTableColumn 一般只有点击 headView 时触发.
//-(void)outlineView:(NSOutlineView *)outlineView didClickTableColumn:(NSTableColumn *)tableColumn{
//}
- (void)clickOutlineView:(NSView *)view {
    int idx = (int) _fileOutlineView.clickedRow;
    if (idx < 0) {
        return;
    }
    id item = [_fileOutlineView itemAtRow:idx];

    // fix bug: click 事件是在 outlineView/tableView 中的处理比较奇怪.
    // 1. 是在 mouse up 的时候才真正触发 click 事件回调,而不是 down 的时候, 如果是 drag 模式.(down 在 subView1中,而 up event 在 app window外面/或者在 outlineView 外面, 仍然可以正常触发 click 回调事件.并且clickedRow是正常的.
    NSPoint point = [NSEvent mouseLocationInView:view];
    NSRect rect = [_fileOutlineView rectOfRow:idx];
    BOOL inRect = NSPointInRect(point, rect);
    if (!inRect) {
        NSLog(@"clickOutlineView... inrect is %d, rect is %@, event point is %@", inRect, NSStringFromRect(rect), NSStringFromPoint(point));
        NSLog(@"mouse up event not in item view , stop execute outline expand or collapse");
        return;
    }

    if (item == nil) {
        return;
    } else if ([item isKindOfClass:QMDuplicateBatch.class]) {
        if (_showPreview) {

            // 点击时 outlineView时会触发 shouldSelectItem方法,在shouldSelectItem更改 subItem 的预览.(因为 当 outlineView 某一item 被选中时,点击  down/up 按键时,会自动选中下一条/上一条,这时候也需要切换 预览的内容.

        } else {
//            点击外部 item 时自动关闭打开
            [self expandOrCollapseItem:(QMDuplicateBatch *) item];

            //修改 rowView button 的状态.
            NSView *itemView = [self.fileOutlineView viewAtColumn:0 row:idx makeIfNecessary:NO];
            if (itemView && [itemView isKindOfClass:DuplicateRootCellView.class]) {
                DuplicateRootCellView *rootView = (DuplicateRootCellView *) itemView;
                [rootView.expandButton setNextState];
            }

        }
    } else if ([item isKindOfClass:QMDuplicateFile.class]) {

//        点击内部 item 模拟 checkButton 选中
//        QMDuplicateItem *parentItem = nil;
//        id tempItem = [_fileOutlineView parentForItem:item];
//        if (tempItem != nil && [tempItem isKindOfClass:QMDuplicateItem.class]) {
//            parentItem = tempItem;
//        }
//
//        NSView *cellView = [_fileOutlineView viewAtColumn:0 row:idx makeIfNecessary:NO];
//        [self mockSubItemClick:item parentItem:parentItem cellView:cellView];
    }
}


// MARK: outlineView -- end ---



// MARK: tableView -- start --



- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    int idx = (int) _previewTableView.selectedRow;
    if (idx < 0) {
        return;
    }
    NSUInteger uIdx = (NSUInteger) idx;

    QMDuplicateBatch *batch = selectedDuplicateBatch;
    if (batch == nil || batch.subItems == nil || batch.subItems.count <= idx) {
        return;
    }
    //点击 row 自动勾选
    //    NSView *cellView = [_previewTableView viewAtColumn:0 row:idx makeIfNecessary:NO];
    //    [self mockSubItemClick:item.subItems[(NSUInteger) idx] parentItem:item cellView:cellView];

    QMDuplicateFile *subItem = batch.subItems[uIdx];
    if (subItem) {
        previewFileNameLabel.stringValue = [subItem.filePath lastPathComponent];
    }

    if (selectedDuplicateBatch.subItems && selectedDuplicateBatch.subItems.count > idx) {
        selectedDuplicateFile = selectedDuplicateBatch.subItems[uIdx];
        [self resetPreview];
    }
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return [[DuplicateRowView alloc] init];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 34;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    QMDuplicateBatch *batch = selectedDuplicateBatch;
    if (batch != nil && batch.subItems != nil) {
        return batch.subItems.count;
    }
    return 0;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    QMDuplicateBatch *item = selectedDuplicateBatch;
    if (item == nil || item.subItems == nil || item.subItems.count <= row) {
        return nil;
    }

    DuplicateSubItemCellView *subItemCellView = [tableView makeViewWithIdentifier:@"duplicateItemTableCellView" owner:self];
    if (subItemCellView == nil) {
        subItemCellView = [[DuplicateSubItemCellView alloc] init];
        subItemCellView.identifier = @"duplicateItemTableCellView";
    }

    QMDuplicateFile *tempItem = item.subItems[(NSUInteger) row];
    subItemCellView.checkBoxUpdateDelegate = self;
    subItemCellView.item = tempItem;
    [subItemCellView updateViewsWithItem:tempItem withPreview:_showPreview];
    return subItemCellView;
}

// MARK: tableView -- end --


- (void)mockSubItemClick:(QMDuplicateFile *)item parentItem:(QMDuplicateBatch *)parentItem cellView:(NSView *)cellView {
    if (cellView && [cellView isKindOfClass:DuplicateSubItemCellView.class]) {
        DuplicateSubItemCellView *subItemCellView = (DuplicateSubItemCellView *) cellView;
        NSControlStateValue stateBefore = subItemCellView.checkBox.state;
        [subItemCellView.checkBox performClick:subItemCellView.checkBox];
        NSControlStateValue stateAfter = subItemCellView.checkBox.state;
        NSLog(@"outlineViewSelectionDidChange before: %ld, after: %ld", (long) stateBefore, (long) stateAfter);

        //预览时显示最近选中的

        [self showSelectedItemInfo:parentItem subItem:item];
    }
}

// MARK: button action

- (void)clickAutoSelectButton {
    NSLog(@"%s", __FUNCTION__);

    _autoSelect = !_autoSelect;
    
    [self updateAutoSelected];
}


- (void)clickBackBtn {
    LMDuplicateWindowController *windowController = self.view.window.windowController;
    if (windowController) {
        [windowController.itemManager removeAllResult];
    }
    LMDuplicateSelectFoldersViewController *fileViewController = [[LMDuplicateSelectFoldersViewController alloc] init];
    self.view.window.contentViewController = fileViewController;
}

- (void)clickCleanBtn {
    BOOL showAlert = [[NSUserDefaults standardUserDefaults] boolForKey:KEY_DUPLICATE_SMART_SCAN_ALERT_SHOWN_BOOL];
    if(showAlert || !_autoSelect){
        [self innerClean];
    }else{
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert.accessoryView setFrameOrigin:NSMakePoint(0, 0)];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = NSLocalizedStringFromTableInBundle(@"LMDuplicateScanResultViewController_Alert_message", nil, [NSBundle bundleForClass:[self class]], @"");
        NSButton *cancelButton =  [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMDuplicateScanResultViewController_Alert_button_cancel", nil, [NSBundle bundleForClass:[self class]], @"")];
        NSButton *okButton = [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMDuplicateScanResultViewController_Alert_button_ok", nil, [NSBundle bundleForClass:[self class]], @"")];
        
        
        // 设置第一响应键位(return button)
        [okButton setKeyEquivalent: @"\033"];
        [cancelButton setKeyEquivalent:@"\r"];
        
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn) {
                NSLog(@"user select cancel clean becuase smart select");
            }else{
                [self innerClean];
            }
        }];
        
        [self  disableSmartScanAlertShow];
    }
    
}

- (void)disableSmartScanAlertShow{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:KEY_DUPLICATE_SMART_SCAN_ALERT_SHOWN_BOOL];
}


- (void)innerClean{
    LMDuplicateWindowController *windowController = self.view.window.windowController;
    if (windowController) {
        // 显示开始清除进度页面
        LMDuplicateCleanViewController *cleanProgressController = [[LMDuplicateCleanViewController alloc] init];
        self.view.window.contentViewController = cleanProgressController;
        windowController.itemManager.delegate = cleanProgressController;
        [windowController.itemManager removeDuplicateItem:_resultArray toTrash:YES];
    }
}

- (void)clickCategoryButton:(NSButton *)sender {

    if (filterCategoryBtn) {
        [self filterBtnSetFont:filterCategoryBtn
                          font:[NSFontHelper getLightSystemFont:14]
                         color:[NSColor colorWithHex:FILTER_BTN_COLOR_NO_SEL]];
    }
    filterCategoryBtn = sender;
    [self filterBtnSetFont:sender
                      font:[NSFontHelper getRegularSystemFont:14]
                     color:[LMAppThemeHelper getFixedTitleColor]];

    [self resetClickView:sender.tag];

}


- (void)clickPreviewButton {
    NSLog(@"%s", __FUNCTION__);

    [self changePreviewState];
}

- (void)changePreviewState {
    _showPreview = !_showPreview;
    [self updatePreviewState];

}

- (void)updatePreviewState {
    if (_showPreview) {
        [self.outlineScrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self->_bottomLineView.mas_bottom);
            make.bottom.mas_equalTo(self.view);
            make.left.equalTo(self.view);
            make.right.equalTo(self.view).offset(-433);
        }];

        [self privateReloadOutlineViewData];
        [self showDefaultPreview];
    } else {
        [self.outlineScrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self->_bottomLineView.mas_bottom);
            make.bottom.mas_equalTo(self.view);
            make.left.equalTo(self.view).offset(0);
            make.right.equalTo(self.view);
        }];
        [self privateReloadOutlineViewData];
        [self.previewContainer setHidden:YES];
    }
}

- (void)updateAutoSelected {
    if (_autoSelect) {
        [QMDuplicateItemManager autoSelectedResult:_resultArray];
        for (QMDuplicateBatch *item in _resultArray) {
            item.selectState = NSControlStateValueMixed;
        }

    } else {
        for (QMDuplicateBatch *item in _resultArray) {

            for (QMDuplicateFile *subItem in item.subItems) {
                subItem.selected = FALSE;
            }
            item.selectState = NSControlStateValueOff;
        }
    }

    [self privateReloadOutlineViewData];
    [_previewTableView reloadData];
    [self updateTitleSelectInfo];
}


- (NSString *)calculateTotalDuplicateFilesSize {
    if (!_resultArray) {
        return NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_calculateTotalDuplicateFilesSize_1553072147_1", nil, [NSBundle bundleForClass:[self class]], @"");
    }

    UInt64 totalSize = 0;
    for (QMDuplicateBatch *item in _resultArray) {
        if (!item.subItems) {
            continue;
        }
        totalSize += item.fileSize * item.subItems.count;
    }

    return [SizeHelper getFileSizeStringBySize:totalSize];
}


- (void)updateTitleSelectInfo {
    int selectedFileItemsCount = 0;
    int selectedFolderItemsCount = 0;
    float selectedItemsSize = 0;

    for (QMDuplicateBatch *batch in _resultArray) {
        for (QMDuplicateFile *dupFile in batch.subItems) {
            
            if(dupFile.selected){
                if (batch.fileType == QMFileTypeFolder ) {
                    selectedFolderItemsCount++;
                } else {
                    selectedFileItemsCount++;
                }
                selectedItemsSize += dupFile.fileSize;
            }
         
        }
    }
    _selectedFileItemsCount = selectedFileItemsCount;
    _selectedFolderItemsCount = selectedFolderItemsCount;
    _selectedItemsSize = selectedItemsSize;


    //如果没有选中的 item 隐藏选中信息
    if (_selectedFileItemsCount == 0 && _selectedFolderItemsCount == 0) {
        [_cleanBtn setEnabled:NO];
        self.descTextField.stringValue = NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_updateTitleMessage_descTextField_1", nil, [NSBundle bundleForClass:[self class]], @"");

    } else {
        [_cleanBtn setEnabled:YES];
        NSString *folderStr = @"";
        NSString *fileStr = @"";

        NSUInteger fileStart = 0;
        NSUInteger fileLen = 0;
        NSUInteger folderStart = 0;
        NSUInteger folderLen = 0;

        NSString *prefixStr = NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_updateTitleMessage_prefixStr_2", nil, [NSBundle bundleForClass:[self class]], @"");

        if (_selectedFileItemsCount > 0) {
            NSString *fileCountStr = [NSString stringWithFormat:@"%i", _selectedFileItemsCount];
            fileStr = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_updateTitleMessage_NSString_3", nil, [NSBundle bundleForClass:[self class]], @""), fileCountStr];
            fileStart = prefixStr.length;
            fileLen = fileCountStr.length;
        }

        if (_selectedFolderItemsCount > 0) {
            NSString *folderCountStr = [NSString stringWithFormat:@"%i", _selectedFolderItemsCount];
            folderStr = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_updateTitleMessage_NSString_4", nil, [NSBundle bundleForClass:[self class]], @""), folderCountStr];
            folderStart = prefixStr.length + fileStr.length;
            folderLen = folderCountStr.length;

        }

        NSString *sizeString = [NSString stringWithFormat:@"%@", [SizeHelper getFileSizeStringBySize:_selectedItemsSize]];
        NSString *totalString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMDuplicateResultViewController_updateTitleMessage_NSString_5", nil, [NSBundle bundleForClass:[self class]], @""), prefixStr, fileStr, folderStr, sizeString];

        NSDictionary *normalAttributes = @{
                NSForegroundColorAttributeName: [NSColor colorWithHex:0x94979B],
                NSFontAttributeName: [NSFontHelper getLightSystemFont:14]
        };

        NSDictionary *colorAttributes = @{
                NSForegroundColorAttributeName: [NSColor colorWithHex:0xFFAA09]
        };
        // 自定义颜色.
        NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:totalString attributes:normalAttributes];

        if (fileStart > 0) {
            [attributeString addAttributes:colorAttributes range:NSMakeRange(fileStart, fileLen)];
        }
        if (folderStart > 0) {
            [attributeString addAttributes:colorAttributes range:NSMakeRange(folderStart, folderLen)];
        }

        NSRange sizeRange = [totalString rangeOfString:sizeString];
        [attributeString addAttributes:colorAttributes range:sizeRange];

        self.descTextField.attributedStringValue = attributeString;
    }
}

- (void)updateDupBatchSelectedState:(QMDuplicateBatch *)dupBatch button:(NSButton *)sender {
    NSLog(@"%s ....: state:%ld", __FUNCTION__, sender.state);
    dupBatch.selectState = sender.state;

    // 父item 状态 更新, 更新所有的子item状态.
    
    switch (dupBatch.selectState) {
        case NSControlStateValueOn:
          
            for (QMDuplicateFile *dupFile  in [dupBatch subItems]) {
                if (!dupFile.selected) {
                    dupFile.selected = YES;
                }
            }
            
            break;
        case NSControlStateValueMixed:
            [QMDuplicateItemManager autoSelectedResult:@[dupBatch]];
            break;
        case NSControlStateValueOff:  // mix/on => off
            for (QMDuplicateFile *dupFile  in [dupBatch subItems]) {
                
                if (dupFile.selected) {
                    dupFile.selected = NO;
                }
            }
            break;
    }
    
    for (QMDuplicateFile *dupFile  in [dupBatch subItems]) {
        //非 preview 状态
        if (_showPreview) {
            // tableView 的 reloadData 可以做到如果 dupBatch 的数量没有变化, reload 的时候 dupBatch 的位置也会同刷新前一样.
            [_previewTableView reloadData];

        } else {
            NSInteger dupFileRow = [_fileOutlineView rowForItem:dupFile];
            if (dupFileRow >= 0) {
                NSView *tempView = [_fileOutlineView viewAtColumn:0 row:dupFileRow makeIfNecessary:NO];
                if (tempView && [tempView isKindOfClass:DuplicateSubItemCellView.class]) {
                    DuplicateSubItemCellView *subItemView = (DuplicateSubItemCellView *) tempView;
                    [subItemView updateViewsWithItem:dupFile withPreview:_showPreview];
                }
            }
        }
    }

    // 更改本栏视觉显示
    NSInteger superItemRow = [_fileOutlineView rowForItem:dupBatch];
    if (superItemRow >= 0) {
        NSView *superItemView = [_fileOutlineView viewAtColumn:0 row:superItemRow makeIfNecessary:NO];
        if ([superItemView isKindOfClass:DuplicateRootCellView.class]) {
            DuplicateRootCellView *superCellView = (DuplicateRootCellView *) superItemView;
            [superCellView updateViewsWithItem:dupBatch withPreview:_showPreview];
        }

        // 因为点击 checkButton 并不会触发 outlineView 的 click 方法(用于更改 row 的 selected 状态,所以这里需要模拟)
        if (_showPreview) {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange((NSUInteger) superItemRow, 1)];
            [self outlineView:self.fileOutlineView shouldSelectItem:dupBatch];  //在shouldSelectItem更改 subItem 的预览.
            [self.fileOutlineView selectRowIndexes:indexSet byExtendingSelection:NO];  // 直接调用selectRowIndexes 不会调用 [delegate outlineView: shouldSelectItem:]方法,所以前面要主动调用.

        }
    }

    //更改顶部 title 视觉显示.
    [self updateTitleSelectInfo];

}

- (void)updateDupFileSelectedState:(QMDuplicateFile *)item button:(NSButton *)sender {

    item.selected = sender.state == NSControlStateValueOn;

    QMDuplicateBatch *superItem;
    if (_showPreview) { // 没有 outlineView
        superItem = selectedDuplicateBatch;
    } else {
        superItem = [self->_fileOutlineView parentForItem:item];
    }

    // 更新 superItem 显示
    if (superItem) {

        NSInteger selectedNum = 0;
        for (QMDuplicateFile *tempItem in [superItem subItems]) {
            if (tempItem.selected) {
                selectedNum += 1;
            }
        }

        NSControlStateValue superItemState;
        if (selectedNum == 0) {
            superItemState = NSControlStateValueOff;
        } else if (selectedNum < [superItem subItems].count) {
            superItemState = NSControlStateValueMixed;
        } else {
            superItemState = NSControlStateValueOn;
        }

        superItem.selectState = superItemState;

        NSInteger superItemRow = [_fileOutlineView rowForItem:superItem];
        if (superItemRow >= 0) {
            NSView *superItemView = [_fileOutlineView viewAtColumn:0 row:superItemRow makeIfNecessary:NO];
            if ([superItemView isKindOfClass:DuplicateRootCellView.class]) {
                DuplicateRootCellView *superCellView = (DuplicateRootCellView *) superItemView;
                [superCellView updateViewsWithItem:superItem withPreview:_showPreview];
            }
        }
    }

    [self updateTitleSelectInfo];

}

- (void)showSelectedItemInfo:(QMDuplicateBatch *)parentItem subItem:(QMDuplicateFile *)item {
    selectedDuplicateFile = item;
    selectedDuplicateBatch = parentItem;


    if (_showPreview) {
        [self resetPreview];

        previewFileNameLabel.stringValue = selectedDuplicateBatch ? selectedDuplicateBatch.fileName : @"";
//        NSString *value = [item.filePath stringByReplacingOccurrencesOfString:@"/" withString:@" > "];
//        value = [value substringFromIndex:2];
        previewFileSizeLabel.stringValue = [SizeHelper getFileSizeStringBySize:item.fileSize];
        [self.previewTableView reloadData];
    }

}

- (void)privateReloadOutlineViewData {
    manualClickCollapseButton = NO;
    [_fileOutlineView reloadData]; // 为了改变 expand的状态
    [_fileOutlineView.animator expandItem:nil expandChildren:YES]; // 展开所有项
    [_fileOutlineView reloadData]; // 第二次是保证 expand button 显示的样式.

    if (_currentItemArray.count > 0) {
        [_noDataAlertView setHidden:YES];
        [_outlineSplitLineView setHidden:!_showPreview];
    } else {
        [_noDataAlertView setHidden:NO];
        [_outlineSplitLineView setHidden:YES];

    }
}


@end
