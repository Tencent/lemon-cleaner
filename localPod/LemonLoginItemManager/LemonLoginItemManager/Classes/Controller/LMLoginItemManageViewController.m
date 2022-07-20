//
//  LMLoginItemManageViewController.m
//  LemonLoginItemManager
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "LMLoginItemManageViewController.h"
#import <QMAppLoginItemManage/QMAppLoginItemManage.h>
#import "LMAppLoginItemInfo.h"
#import "LMLoginItemAppInfoCellView.h"
#import "LMLoginItemFileCellView.h"
#import "LMLoginItemTypeCellView.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import "LMLineView.h"
#import <QMUICommon/QMMoveOutlineView.h>
#import "LMOutlineTableRowView.h"
#import <QMUICommon/MMScroller.h>
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import <QMUICommon/LMSortableButton.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSButton+Extension.h>
#import "LMLoginItemSearchTableCellView.h"
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/LMBigLoadingView.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMCoreFunction/NSAttributedString+Extension.h>
#import <QMCoreFunction/LanguageHelper.h>

#define LMLocalizedString(key,className)  NSLocalizedStringFromTableInBundle(key, nil, [NSBundle bundleForClass:className], @"");

typedef enum {
    LMLoginItemSortTypeName,
    LMLoginItemSortTypeStatus
}LMLoginItemSortType;

@interface LMLoginItemManageViewController ()<QMLoginItemManagerDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource, LMLoginItemCellViewDelegate, NSTableViewDelegate, NSTableViewDataSource>

@property(nonatomic) NSArray *launchItemArray;
@property(nonatomic) NSArray *systemLoginItemArray;
@property(nonatomic) NSArray *appLoginItemArray;
@property(nonatomic) NSMutableArray *dataArray;
@property(nonatomic) LMAppLoginItemInfo *otherLoginItemInfo;

@property (weak) IBOutlet NSView *outlineContentView;

@property (weak, nonatomic) IBOutlet NSOutlineView *outlineView;
@property (weak, nonatomic) IBOutlet LMLineView *topLineView;
@property (weak, nonatomic) IBOutlet LMLineView *bottomLineView;
@property (weak, nonatomic) IBOutlet NSScrollView *scrollView;
@property (weak, nonatomic) IBOutlet LMSortableButton *nameSortableBtn;
@property (weak, nonatomic) IBOutlet LMSortableButton *statusSortableButton;
@property (weak) IBOutlet NSTextField *columnSettingLabel;
@property (weak) IBOutlet NSTextField *columnCountLabel;

@property (nonatomic) LMLoginItemSortType sortType;
@property (nonatomic) SortOrderType sortOrderType;

//loading view
@property (weak) IBOutlet NSView *loadingContentView;
@property (weak) IBOutlet NSTextField *loadingLabel;
@property (weak) LMBigLoadingView *loadingView;


//搜索页面
@property (nonatomic) NSArray *searchResultArray;
@property (weak, nonatomic) IBOutlet NSView *searchContentView;
@property (weak, nonatomic) IBOutlet NSView *searchResultTipsContentView;
@property (weak, nonatomic) IBOutlet NSTableView *searchResultTableView;
@property (weak, nonatomic) IBOutlet NSSearchField *searchTextField;
@property (weak) IBOutlet NSScrollView *searchScrollView;

@property (weak, nonatomic) IBOutlet NSView *searchKeyContainerView;
@property (weak, nonatomic) IBOutlet NSTextField *searchResultTipsBeginLabel;
@property (weak, nonatomic) IBOutlet NSTextField *searchResutlTipsEndLabel;
@property (weak) IBOutlet NSTextField *searchEmptyLabel;


@property (weak) IBOutlet NSTextField *searchKeyWordLabel;
@property (weak) IBOutlet NSView *emptyView;
@property (weak) IBOutlet NSTextField *feedBackLabel;


@property (weak) IBOutlet NSTextField *windowTitle;

@end

@implementation LMLoginItemManageViewController

- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initLocalizeString];
    [self initView];
    [self initData];
}

- (void)initView {
    [self initTableView];
    [self initSearchKeyView];
    [self initSortButton];
    [self initLoadingView];
}

- (void)initLocalizeString {
    self.windowTitle.stringValue = LMLocalizedString(@"LemonLoginItemManagerViewController_window_title", self.class);
    self.nameSortableBtn.stringValue = LMLocalizedString(@"LemonLoginItemManagerViewController_column_name_app", self.class);
    self.statusSortableButton.stringValue = LMLocalizedString(@"LemonLoginItemManagerViewController_column_name_status", self.class);
    self.columnSettingLabel.stringValue = LMLocalizedString(@"LemonLoginItemManagerViewController_column_name_setting", self.class);
    self.columnCountLabel.stringValue = LMLocalizedString(@"LemonLoginItemManagerViewController_column_name_count", self.class);
    self.searchResultTipsBeginLabel.stringValue = LMLocalizedString(@"LemonLoginItemManagerViewController_search_result_tips_begin_label", self.class);
    self.searchEmptyLabel.stringValue = LMLocalizedString(@"LemonLoginItemManagerViewController_no_result", self.class);
    self.loadingLabel.stringValue = LMLocalizedString(@"LemonLoginItemManagerViewController_loading", self.class);
    self.searchTextField.placeholderString = LMLocalizedString(@"LemonLoginItemManagerViewController_search_tips", self.class);
    self.nameSortableBtn.title = LMLocalizedString(@"LemonLoginItemManagerViewController_column_name_app", self.class);
    self.statusSortableButton.title = LMLocalizedString(@"LemonLoginItemManagerViewController_column_name_status", self.class);
}

- (void)initTableView {
    MMScroller *scroller = [[MMScroller alloc] init];
    [self.scrollView setVerticalScroller:scroller];
    [self.scrollView setDrawsBackground:NO];
    self.outlineView.target = self;
    self.outlineView.action = @selector(outLineViewOnClick);
    self.outlineView.dataSource = self;
    self.outlineView.delegate = self;
    if (@available(macOS 11.0, *)) {
        self.outlineView.style = NSTableViewStyleFullWidth;
    } else {
        // Fallback on earlier versions
    }
    [self showView:self.outlineContentView];
    
    MMScroller *tableScroller = [[MMScroller alloc] init];
    [self.searchScrollView setVerticalScroller:tableScroller];
    [self.searchScrollView setDrawsBackground:NO];
    self.searchResultTableView.delegate = self;
    self.searchResultTableView.dataSource = self;
    self.searchResultTableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    self.searchResultTableView.intercellSpacing = NSMakeSize(0, 0);
}

-(void)initSortButton{
    [self.nameSortableBtn setSortOrderType:Ascending];
    [self.statusSortableButton setSortOrderType:Ascending];
    self.statusSortableButton.focusRingType = NSFocusRingTypeNone;
    self.nameSortableBtn.focusRingType = NSFocusRingTypeNone;
    [self updateFontColorForSortButton:self.statusSortableButton];
}

-(void)updateFontColorForSortButton: (LMSortableButton *)btn{
    [self.nameSortableBtn setFontColor:[NSColor colorWithHex:0x94979B]];
    [self.statusSortableButton setFontColor:[NSColor colorWithHex:0x94979B]];
    [btn setFontColor:[LMAppThemeHelper getTitleColor]];
}


- (void)viewWillLayout {
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:self.topLineView];
    [LMAppThemeHelper setDivideLineColorFor:self.bottomLineView];
}

+ (void)loadData {
    //    if (self.dataArray) {
    //
    //    }
}

- (void)initData {
    long startTime = [[NSDate date] timeIntervalSince1970];
    [self showView:self.loadingContentView];
    self.dataArray = [[NSMutableArray alloc] init];
    self.sortType = LMLoginItemSortTypeStatus;
    self.sortOrderType = Ascending;
    QMLoginItemManager *manager = [QMLoginItemManager shareInstance];
    manager.delegate = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.launchItemArray = [manager getLaunchServiceItems];
        self.systemLoginItemArray = [manager getSystemLoginItems];
        self.appLoginItemArray = [manager getAppLoginItems];
        [self handleData];
        [self sortData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingView invalidate];
            self.searchTextField.hidden = NO;
            if(self.dataArray.count == 0){
                [self showEmptyView];
            }else{
                [self.outlineView reloadData];
                [self showView:self.outlineContentView];
            }
        });
        
    });
    
}

#pragma mark -- handle data

- (void)handleData {
    //以App进行分类：将同一个App的启动项包装成一个LMAppLoginItemInfo,
    //LMAppLoginItemInfo中添加launchd service item数据
    for (QMBaseLoginItem *loginItem in self.launchItemArray) {
        if(loginItem.appName) {
            LMAppLoginItemInfo *itemInfo = [self getLoginItemInfoWithAppName:loginItem.appName];
            itemInfo.appPath = loginItem.appPath;
            [itemInfo addLaunchItem:loginItem];
        } else {
            //如果没有匹配到App，则归纳为未知应用
            if (!self.otherLoginItemInfo) {
                NSString *localString = LMLocalizedString(@"LemonLoginItemManagerViewController_unknown_app", self.class);
                self.otherLoginItemInfo = [[LMAppLoginItemInfo alloc] initWithAppName:localString];
            }
            [self.otherLoginItemInfo addLaunchItem:loginItem];
        }
    }
    //添加app login item数据
    for (QMBaseLoginItem *loginItem in self.appLoginItemArray) {
        LMAppLoginItemInfo *itemInfo = [self getLoginItemInfoWithAppName:loginItem.appName];
        itemInfo.appPath = loginItem.appPath;
        [itemInfo addAppLoginItem:loginItem];
    }
    
    //添加系统登录项数据
    for (QMBaseLoginItem *loginItem in self.systemLoginItemArray) {
        LMAppLoginItemInfo *itemInfo = [self getLoginItemInfoWithAppName:loginItem.appName];
        itemInfo.appPath = loginItem.appPath;
        [itemInfo addAppLoginItem:loginItem];
    }
    
    //将未知应用添加到数据源末尾
    if (self.otherLoginItemInfo) {
        [self.dataArray addObject:self.otherLoginItemInfo];
    }
    
    for (LMAppLoginItemInfo *itemInfo in self.dataArray) {
        NSArray *loginItemDataArray = itemInfo.getLoginItemData;
        NSArray *launchItemDataArray = itemInfo.getLaunchItemData;
        //统计App启动项的数量
        itemInfo.totalItemCount = loginItemDataArray.count + launchItemDataArray.count;
        [itemInfo updateEnableStatus];
        //统计App启动项类型和数量，以及每类对应的数据
        if (loginItemDataArray) {
            [itemInfo addAppLoginItemTypeInfoWithArray:loginItemDataArray];
        }
        if (launchItemDataArray) {
            [itemInfo addLaunchItemTypeInfoWithArray:launchItemDataArray];
        }
    }
}


- (LMAppLoginItemInfo *)getLoginItemInfoWithAppName:(NSString *)appName {
    for (LMAppLoginItemInfo *itemInfo in self.dataArray) {
        if ([itemInfo.appName isEqualToString:appName]) {
            return itemInfo;
        }
    }
    LMAppLoginItemInfo *itemInfo = [[LMAppLoginItemInfo alloc] initWithAppName:appName];
    itemInfo.enableStatus = LMAppLoginItemEnableStatusAllDisabled;
    [self.dataArray addObject:itemInfo];
    return itemInfo;
}

-(void)sortData{
    [self.dataArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        LMAppLoginItemInfo *item1 = (LMAppLoginItemInfo *)obj1;
        LMAppLoginItemInfo *item2 = (LMAppLoginItemInfo *)obj2;
        NSComparisonResult result = [item1.appName localizedCompare:item2.appName];
        if(self.sortType == LMLoginItemSortTypeStatus){
            if(item1.enableStatus < item2.enableStatus){
                result = NSOrderedAscending;
            } else {
                result = NSOrderedDescending;
            }
        }
        if(self.sortOrderType == Ascending)
            return result;
        return 0 - result;
    }];
}

#pragma mark -- click event

- (IBAction)headerSortBtnOnClick:(LMSortableButton *)sender {
    [self updateFontColorForSortButton:sender];
    if(sender == self.nameSortableBtn){
        if(self.sortType == LMLoginItemSortTypeName){
            [self.nameSortableBtn toggleSortType];
        }
        self.sortType = LMLoginItemSortTypeName;
    }
    if(sender == self.statusSortableButton){
        if(self.sortType == LMLoginItemSortTypeStatus){
            [self.statusSortableButton toggleSortType];
        }
        self.sortType = LMLoginItemSortTypeStatus;
    }
    self.sortOrderType = sender.sortOrderType;
    [self sortData];
    [self.outlineView reloadData];
}

- (void)outLineViewOnClick {
    NSInteger index = self.outlineView.clickedRow;
    if (index < 0) {
        return;
    }
    id item = [self.outlineView itemAtRow:index];
    if (!item) {
        return;
    }
    BOOL needExpand = NO;
    if ([item isKindOfClass:LMAppLoginItemInfo.class] || [item isKindOfClass:LMAppLoginItemTypeInfo.class]) {
        needExpand = YES;
    }
    if (needExpand) {
        BOOL isExpand = [self.outlineView isItemExpanded:item];
        if (isExpand) {
            [self.outlineView.animator collapseItem:item];
        } else {
            [self.outlineView.animator expandItem:item expandChildren:YES];
        }
    }
}

#pragma mark -- outline view delegate

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (!item) {
        return self.dataArray.count;
    }
    if ([item isKindOfClass:LMAppLoginItemInfo.class]) {
        LMAppLoginItemInfo *itemInfo = (LMAppLoginItemInfo *)item;
        return [itemInfo getLoginItemTypeData].count;
    }
    if ([item isKindOfClass:LMAppLoginItemTypeInfo.class]) {
        LMAppLoginItemTypeInfo *itemTypeInfo = (LMAppLoginItemTypeInfo *)item;
        return itemTypeInfo.itemCount;
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (!item) {
        return self.dataArray[index];
    }
    if ([item isKindOfClass:LMAppLoginItemInfo.class]) {
        LMAppLoginItemInfo *itemInfo = (LMAppLoginItemInfo *)item;
        return [itemInfo getLoginItemTypeData][index];
    }
    if ([item isKindOfClass:LMAppLoginItemTypeInfo.class]) {
        LMAppLoginItemTypeInfo *itemTypeInfo = (LMAppLoginItemTypeInfo *)item;
        return itemTypeInfo.loginItemData[index];
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if (!item) {
        return self.dataArray.count > 0;
    }
    if ([item isKindOfClass:LMAppLoginItemInfo.class]) {
        LMAppLoginItemInfo *itemInfo = (LMAppLoginItemInfo *)item;
        return [itemInfo getLoginItemTypeData].count > 0;
    }
    if ([item isKindOfClass:LMAppLoginItemTypeInfo.class]) {
        LMAppLoginItemTypeInfo *itemTypeInfo = (LMAppLoginItemTypeInfo *)item;
        return itemTypeInfo.loginItemData.count > 0;
    }
    return false;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    if ([item isKindOfClass:LMAppLoginItemInfo.class]) {
        return 60;
    }
    if ([item isKindOfClass:LMAppLoginItemTypeInfo.class]) {
        return 30;
    }
    if ([item isKindOfClass:QMBaseLoginItem.class]) {
        return 30;
    }
    return 40;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([item isKindOfClass:LMAppLoginItemInfo.class]) {
        LMLoginItemAppInfoCellView *cellView = [outlineView makeViewWithIdentifier:@"LMLoginItemAppInfoCellView" owner:self];
        cellView.delegate = self;
        [cellView setLoginItemInfo:item];
        return cellView;
    }
    if ([item isKindOfClass:LMAppLoginItemTypeInfo.class]) {
        LMLoginItemTypeCellView *cellView = [outlineView makeViewWithIdentifier:@"LMLoginItemTypeCellView" owner:self];
        [cellView setLoginItemTypeInfo:item];
        return cellView;
    }
    if ([item isKindOfClass:QMBaseLoginItem.class]) {
        LMLoginItemFileCellView *cellView = [outlineView makeViewWithIdentifier:@"LMLoginItemFileCellView" owner:self];
        cellView.delegate = self;
        [cellView setLoginItem:item];
        return cellView;
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return NO;
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item {
    LMOutlineTableRowView *rowView = [[LMOutlineTableRowView alloc] initWithFrame:NSZeroRect];
    return rowView;
}

#pragma mark -- login item manager delegate

- (nonnull NSString *)exeCommonCmd:(nonnull NSString *)cmdString {
    return [QMShellExcuteHelper excuteCmd:cmdString];
}

- (void)enabelSystemLaunchItemWithFilePath:(NSString *)path label:(NSString *)label {
    [[McCoreFunction shareCoreFuction] enableLaunchSystemAsyncWithFilePath:path label:label block:nil];
}

- (void)disableSystemLaunchItemWithFilePath:(NSString *)path label:(NSString *)label {
    [[McCoreFunction shareCoreFuction] disableLaunchSystemAsyncWithFilePath:path label:label block:nil];
}

- (BOOL)isEnableForLaunchServiceLabel:(NSString *)label {
    return [[McCoreFunction shareCoreFuction] getLaunchSystemStatusWithlabel:label];
}

#pragma mark-- cell view delegate

- (void)clickSwitchButton:(COSwitch *)switchBtn onCellView:(LMBaseHoverTableCellView *)cellView {
    if ([cellView isKindOfClass:LMLoginItemAppInfoCellView.class]) {
        LMLoginItemAppInfoCellView *appInfoCellView = (LMLoginItemAppInfoCellView *)cellView;
        NSArray *launchItemData = [appInfoCellView.loginItemInfo getLaunchItemData];
        for (QMBaseLoginItem *loginItem in launchItemData) {
            loginItem.isEnable = switchBtn.on;
            [self udpateLoginItem:loginItem WithSwitchBtn:switchBtn];
        }
        NSArray *loginItemData = [appInfoCellView.loginItemInfo getLoginItemData];
        for (QMBaseLoginItem *loginItem in loginItemData) {
            loginItem.isEnable = switchBtn.on;
            [self udpateLoginItem:loginItem WithSwitchBtn:switchBtn];
        }
        [self.outlineView reloadItem:appInfoCellView.loginItemInfo reloadChildren:YES];
        return;
    }
    if ([cellView isKindOfClass:LMLoginItemFileCellView.class]) {
        LMLoginItemFileCellView *fileCellView = (LMLoginItemFileCellView *)cellView;
        id typeItem = [self.outlineView parentForItem:fileCellView.loginItem];
        LMAppLoginItemInfo *loginItemInfo = [self.outlineView parentForItem:typeItem];
        [loginItemInfo updateEnableStatus];
    }
}

- (void)udpateLoginItem:(QMBaseLoginItem *)loginItem WithSwitchBtn:(COSwitch *)button {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (button.on) {
            [loginItem enableLoginItem];
        } else {
            [loginItem disableLoginItem];
        }
    });
}

#pragma mark -- search

- (IBAction)searchFieldChanged:(id)sender {
    NSString *keyWords = self.searchTextField.stringValue;
    if (keyWords.length == 0) {
        [self.outlineView reloadData];
        [self showView:self.outlineContentView];
        return;
    }
    [self showView:self.searchContentView];
    NSMutableArray *array1 = [self.launchItemArray mutableCopy];
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"(fileName contains[cd] %@) OR (appName contains[cd] %@)",
                               keyWords,keyWords];
    [array1 filterUsingPredicate:predicate1];
    
    NSMutableArray *array2 = [self.appLoginItemArray mutableCopy];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"(loginItemAppName contains[cd] %@) OR (appName contains[cd] %@)",
                               keyWords,keyWords];
    [array2 filterUsingPredicate:predicate2];
    
    NSMutableArray *array3 = [self.systemLoginItemArray mutableCopy];
    NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"(appName contains[cd] %@) OR (appName contains[cd] %@)",
                               keyWords,keyWords];
    [array3 filterUsingPredicate:predicate3];
    
    [array1 addObjectsFromArray:array2];
    [array1 addObjectsFromArray:array3];
    self.searchResultArray = array1;
    if (self.searchResultArray.count == 0) {
        [self showView:self.emptyView];
        return;
    }
    [self updateSearchResultTipsViewWithCount:self.searchResultArray.count];
    self.searchKeyWordLabel.stringValue = keyWords;
    [self.searchResultTableView reloadData];
}

- (void)updateSearchResultTipsViewWithCount: (NSInteger)count {
    NSString *localString =  LMLocalizedString(@"LemonLoginItemManagerViewController_search_result_tips_begin_label_complex", self.class);
    if (count <= 1) {
        localString =  LMLocalizedString(@"LemonLoginItemManagerViewController_search_result_tips_begin_label_singular", self.class);
    }
    localString = [NSString stringWithFormat:localString,count];
    NSRange range = [localString rangeOfString:[NSString stringWithFormat:@"%ld",(long)count]];
    NSAttributedString *attrString = [self attributedWithString:localString keywordsRange:range];
    self.searchResultTipsBeginLabel.attributedStringValue = attrString;
}

- (NSAttributedString *)attributedWithString:(NSString *)string keywordsRange:(NSRange)range
{
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:string
                                                                                      attributes:@{NSForegroundColorAttributeName: [LMAppThemeHelper getTitleColor],
                                                                                                   NSFontAttributeName: [NSFont systemFontOfSize:12.0]}];
    [attributedStr addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x04D999] range:range];
    return attributedStr;
}

#pragma mark -- table view delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.searchResultArray.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 60;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    LMLoginItemSearchTableCellView *cellView = [self.searchResultTableView makeViewWithIdentifier:@"LMLoginItemSearchTableCellView" owner:self];
    [cellView setLoginItem:self.searchResultArray[row]];
    return cellView;
}

- (void)initSearchKeyView {
    self.searchKeyContainerView.wantsLayer = YES;
    self.searchKeyContainerView.layer.borderColor = [NSColor colorWithHex:0x04D999].CGColor;
    self.searchKeyContainerView.layer.cornerRadius = 2;
    self.searchKeyContainerView.layer.borderWidth = 1;
    self.searchKeyContainerView.layer.backgroundColor = [NSColor clearColor].CGColor;
}

- (IBAction)searchCloseButtonOnClick:(id)sender {
    self.searchTextField.stringValue = @"";
    [self.outlineView reloadData];
    [self showView:self.outlineContentView];
}

- (void)showView:(NSView *)view {
    self.outlineContentView.hidden = YES;
    self.searchContentView.hidden = YES;
    self.emptyView.hidden = YES;
    self.loadingContentView.hidden = YES;
    view.hidden = NO;
}

- (void)showEmptyView {
    self.outlineContentView.hidden = YES;
    self.searchContentView.hidden = YES;
    self.searchTextField.hidden = YES;
    self.loadingContentView.hidden = YES;
    self.emptyView.hidden = NO;
    self.searchEmptyLabel.stringValue = LMLocalizedString(@"LemonLoginItemManagerViewController_empty", self.class);
    [self showFeedBackLabel];
}

- (void)initLoadingView {
    if (!self.loadingView) {
        NSRect bounds = self.view.bounds;
        bounds.origin.x = (self.view.bounds.size.width - 160) / 2;
        bounds.origin.y = 184;
        bounds.size.width = 160;
        bounds.size.height = 160;
        LMBigLoadingView *loadingView = [[LMBigLoadingView alloc] initWithFrame:bounds];
        self.loadingView = loadingView;
        [self.loadingContentView addSubview:self.loadingView];
    }
    self.searchTextField.hidden = YES;
}

-(void)showFeedBackLabel {
    if([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese){
        self.feedBackLabel.hidden = YES;
        return;
    }
    self.feedBackLabel.hidden = NO;
    if(!self.feedBackLabel.stringValue || [self.feedBackLabel.stringValue isEqualToString:@""]) {
        [self.feedBackLabel setAllowsEditingTextAttributes: YES];
        [self.feedBackLabel setSelectable: YES];
        NSURL* url = [NSURL URLWithString:@"https://support.qq.com/products/36664"];
        NSMutableAttributedString* string = [[NSMutableAttributedString alloc] init];
        NSMutableAttributedString *attrString1 = [[NSMutableAttributedString alloc] initWithString:@"若有遗漏，请点此"];
        [attrString1 addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x94979B] range:NSMakeRange(0, attrString1.length)];
        [string appendAttributedString:attrString1];
        [string appendAttributedString: [NSAttributedString hyperlinkFromString:@" 联系我们 " withURL:url]];
        NSMutableAttributedString *attrString2 = [[NSMutableAttributedString alloc] initWithString:@"反馈"];
         [attrString2 addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x94979B] range:NSMakeRange(0, attrString2.length)];
        [string appendAttributedString:attrString2];
        [string addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:13] range:NSMakeRange(0,string.length)];
        // set the attributed string to the NSTextField
        [self.feedBackLabel setAttributedStringValue: string];
    }
}


@end
