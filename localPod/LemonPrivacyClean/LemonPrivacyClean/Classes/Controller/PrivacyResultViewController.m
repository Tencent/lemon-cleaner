//
//  PrivacyResultViewController.m
//  FMDBDemo
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "PrivacyResultViewController.h"
#import "ResultTableRowView.h"
#import "PrivacyAppTableCellView.h"
#import "PrivacyCategoryTableCellView.h"
#import "PrivacyItemTableCellView.h"
#import <QMUICommon/LMViewHelper.h>
#import "PrivacyWindowController.h"
#import "QMExtension.h"
#import "PrivacyDataManager.h"
#import <Masonry/Masonry.h>
#import "BrowserApp.h"
#import "RunningAppPopViewController.h"
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/MMScroller.h>
#import <QMUICommon/MMScroller.h>

#import <QMUICommon/GetFullDiskPopViewController.h>
#import <QMUICommon/GetFullAccessWndController.h>
#import <QMCoreFunction/QMFullDiskAccessManager.h>
#import <QMUICommon/MMScrollView.h>


@interface PrivacyResultViewController () <NSOutlineViewDelegate, NSOutlineViewDataSource> {
    NSTableView *tableView;
    NSOutlineView *_outlineView;
    NSTextField *titleLabel;
    NSButton *_cleanButton;
}

@property (strong, nonatomic) GetFullAccessWndController *getFullAccessWndController;
@property BOOL        hasFullDiskAccessAuthority; //是否有完全磁盘访问权限(10.14(不含)系统下默认有).

@property(readwrite, strong, nonatomic) NSString *testString;
@property(readwrite, strong, nonatomic) NSMutableArray *tests;


@end


@implementation PrivacyResultViewController

//- (void)testGesture {
//    NSGestureRecognizer *gesture = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(setupUI)];
//    [gesture setValue:@"test" forKey:@"test"];  // MARK : 这是KVC
//    NSDictionary *dict = @{@"test": @"test"};
//}

- (void)testKVO {
//    self.testString = @"turn0";
//    [self addObserver:self forKeyPath:@"testString" options:NSKeyValueObservingOptionOld context:nil];
//    self.testString = @"turn1";
//    self.testString = @"turn2";

    NSString *str1 = @"1";
    NSString *str2 = @"2";
    NSString *str3 = @"3";

    self.tests = [[NSMutableArray alloc] initWithArray:@[str1, str2]];
    [self addObserver:self forKeyPath:@"tests" options:NSKeyValueObservingOptionOld context:nil];
//    self.testString = @"turn1";
//    self.testString = @"turn2";
//    [self.tests removeObject:str1];  // 直接 remove 不会触发 NSArray 的 KVO
//    [self.tests addObject:str3];
    [self addTestStr:str3];

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    NSLog(@"observeValueForKeyPath  %@", self.testString);

    for (NSString *key in change) {
        NSLog(@".... %@: %@", key, change[key]);
    }
}
- (NSMutableArray *)testArray {
    return [self mutableArrayValueForKey:NSStringFromSelector(@selector(tests))];
}

- (void)addTestStr:(NSString *)newStr {
    [[self testArray] addObject:newStr];
}



- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadView];
    }
    return self;
}

- (void)loadView {
    NSRect rect = NSMakeRect(0, 0, 780, 482);
    NSView *view = [[NSView alloc] initWithFrame:rect];
//    [view setWantsLayer:YES];
//    [view.layer setBackgroundColor:NSColor.whiteColor.CGColor];
    self.view = view;
    [self viewDidLoad];
}

- (void)viewDidLoad {
    [self setupUI];
    
    if( [QMFullDiskAccessManager getFullDiskAuthorationStatus] != QMFullDiskAuthorationStatusAuthorized) {
        _hasFullDiskAccessAuthority = NO;
    }else{
        _hasFullDiskAccessAuthority = YES;
    }
}



- (void)updateViewsBy:(PrivacyData *)data {
    if (data) {
        self.privacyData = data;
//        默认全选中状态
//        [data setStateWithSubItemsIfHave:NSControlStateValueOn];
        [data calculateSubItemsTotalNum];
    } else {
        self.privacyData = [[PrivacyData alloc] init];
        self.privacyData.subItems = [[NSArray alloc] init];
    }

    [_outlineView reloadData];
    //展开第一项
    if(self.privacyData && self.privacyData.subItems && self.privacyData.subItems.count > 0){
        PrivacyAppData *firstAppData = self.privacyData.subItems[0];
        [_outlineView expandItem:firstAppData];
    }
    [self updateTitleView];
}


- (void)setupUI {
    [self setupTitleView];
    [self setupOutlineView];
}


- (void)setupTitleView {

    NSImageView *imageView = [LMViewHelper createNormalImageView];
    imageView.image = [NSImage imageNamed:@"privacy_clean" withClass:self.class];
    imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    [self.view addSubview:imageView];


    NSTextField *label = [LMViewHelper createNormalLabel:20 fontColor:[LMAppThemeHelper getTitleColor]];
    self->titleLabel = label;
    [self.view addSubview:label];

    NSButton *cleanButton = [LMViewHelper createNormalGreenButton:20 title:NSLocalizedStringFromTableInBundle(@"PrivacyResultViewController_setupTitleView_cleanButton _1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.view addSubview:cleanButton];
    self->_cleanButton = cleanButton;
    [cleanButton setEnabled:NO];
    cleanButton.target = self;
    cleanButton.action = @selector(clickCleanButton);

    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(72);
        make.top.equalTo(self.view).offset(48);
        make.left.equalTo(self.view).offset(40);
    }];

    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(imageView.mas_right).offset(16);
        make.centerY.equalTo(imageView);
    }];

    [cleanButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-40);
        make.width.mas_equalTo(148);
        make.height.mas_equalTo(48);
        make.centerY.equalTo(imageView);
    }];

}


- (void)cleanActionWithRunningApps:(NSArray *)apps needKill:(BOOL)needKill{
    PrivacyWindowController *windowController = self.view.window.windowController;
    if (windowController) {
        [windowController showCleanProcessViewController:self.privacyData runningApps:apps needKill:needKill];
    }
}

- (void)updateTitleView {
    NSInteger totalSelectedNum = 0;
    for (PrivacyAppData *appData in self.privacyData.subItems) {
        totalSelectedNum += appData.selectedSubItemNum;
    }
    // 注意 outline refresh的时候 只 refresh 到了 app那一层,需要也 refresh 最顶层 privacyData
    self.privacyData.selectedSubItemNum = totalSelectedNum;

    if (totalSelectedNum <= 0) {
        [self->_cleanButton setEnabled:NO];
        titleLabel.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"PrivacyResultViewController_updateTitleView_NSString_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    } else {
        [self->_cleanButton setEnabled:YES];
        titleLabel.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"PrivacyResultViewController_updateTitleView_NSString_2", nil, [NSBundle bundleForClass:[self class]], @""), totalSelectedNum];
    }
}


- (void)setupOutlineView {

    MMScrollView *container = [[MMScrollView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    MMScroller *scroller = [[MMScroller alloc] init];
    [container setVerticalScroller:scroller];
    container.autohidesScrollers = YES;
    container.hasVerticalScroller = YES;
    container.hasHorizontalScroller = NO;
    // 暗黑主题下scrollbar 会自动变黑，这里需要设置drawsBackground=NO
    container.drawsBackground = NO;
//    container.backgroundColor = NSColor.whiteColor;


    NSOutlineView *outline = [[NSOutlineView alloc] init];
    self->_outlineView = outline;
    //  selectionHighlightStyle The selection highlight style used by the table view to indicate row and column selection.
    outline.selectionHighlightStyle = NSTableViewSelectionHighlightStyleSourceList;
    // A Boolean value indicating whether the table view draws grouped rows as if they are floating.
    outline.floatsGroupRows = NO;
    //indentationPerLevel :The per-level indentation, measured in points.
//    outline.indentationPerLevel = 16.f;
    //indentationMarkerFollowsCell : A Boolean value indicating whether the indentation marker symbol displayed in the outline column should be indented along with the cell contents.
    outline.indentationMarkerFollowsCell = NO;
    outline.headerView = nil;
    [outline setBackgroundColor:[LMAppThemeHelper getMainBgColor]];

    NSTableColumn *col1 = [[NSTableColumn alloc] initWithIdentifier:@"col1"];
    col1.resizingMask = NSTableColumnAutoresizingMask;
    col1.editable = NO;
    col1.minWidth = 200.f;
    col1.headerCell.stringValue = @"header";
    [outline addTableColumn:col1];
    [outline setOutlineTableColumn:col1];

    container.documentView = outline;
    [self.view addSubview:container];
    outline.delegate = self;
    outline.dataSource = self;
    
    outline.target = self;
    outline.action = @selector(clickOutLineView);

    // NSEdgeInsetsMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right)
    NSEdgeInsets padding = NSEdgeInsetsMake(140, 0, 0, 0);
    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view).with.insets(padding);
    }];
}


- (void)addBaseSubItemRow:(NSMutableIndexSet *)indexSet categoryItem:(BasePrivacyData *)item {
    // 添加需要刷新row
    if (item.subItems == nil) return;

    for (BasePrivacyData *subItem in item.subItems) {
        NSInteger tempRow = [self->_outlineView rowForItem:subItem];
        if (tempRow != -1) [indexSet addIndex:(NSUInteger) tempRow];
        [self addBaseSubItemRow:indexSet categoryItem:subItem];
    }
}



// MARK: dataSource
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        return self.privacyData.subItems.count;
    } else if ([item isKindOfClass:PrivacyAppData.class]) {
        PrivacyAppData *newItem = (PrivacyAppData *) item;
        return newItem.subItems.count;
    } else if ([item isKindOfClass:PrivacyCategoryData.class]) {
        PrivacyCategoryData *newItem = (PrivacyCategoryData *) item;
        return newItem.subItems.count;
    }
    return 0;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if (item == nil) {
        return self.privacyData.subItems.count > 0;
    } else if ([item isKindOfClass:PrivacyAppData.class]) {
        PrivacyAppData *newItem = (PrivacyAppData *) item;
        return newItem.subItems.count > 0;
    } else if ([item isKindOfClass:PrivacyCategoryData.class]) {
        PrivacyCategoryData *newItem = (PrivacyCategoryData *) item;
        return newItem.subItems.count > 0;
    }
    return false;
}


// MARK: delegate
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        return self.privacyData.subItems[(NSUInteger) index];
    } else if ([item isKindOfClass:PrivacyAppData.class]) {
        PrivacyAppData *newItem = (PrivacyAppData *) item;
        return newItem.subItems[(NSUInteger) index];
    } else if ([item isKindOfClass:PrivacyCategoryData.class]) {
        PrivacyCategoryData *newItem = (PrivacyCategoryData *) item;
        return newItem.subItems[(NSUInteger) index];
    }
    return [[NSObject alloc]init];
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    if ([item isKindOfClass:PrivacyItemData.class]) {
        return 40;
    } else if ([item isKindOfClass:PrivacyCategoryData.class]) {
        return 64;
    } else if ([item isKindOfClass:PrivacyAppData.class]) {
        return 64;
    }
    return 40;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return @"outlineView objectValueForTableColumn ....";
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {

    // 对于 app 栏
    if ([item isKindOfClass:PrivacyAppData.class]) {
        NSString *appIdentifier = [tableColumn.identifier stringByAppendingString:@"_app"];

        PrivacyAppTableCellView *appTableCellView = [outlineView makeViewWithIdentifier:appIdentifier owner:nil];

        if (appTableCellView == nil) {
            appTableCellView = [[PrivacyAppTableCellView alloc] init];
            // MARK: cell必须设置identifier.才不会每次都生成新的 view
            appTableCellView.identifier = appIdentifier;
        }
        appTableCellView.hasFullDiskAccessAuthority = _hasFullDiskAccessAuthority;
        appTableCellView.delegate = self;

        PrivacyAppData *app = item;
        [appTableCellView updateViewBy:app];
        appTableCellView.checkButton.target = self;
        appTableCellView.checkButton.action = @selector(checkButtonAction:);
        if(app.totalSubNum <= 0){
//            [appTableCellView.checkButton setHidden:YES];
            [appTableCellView.checkButton setEnabled: NO];
        }else{
//            [appTableCellView.checkButton setHidden:NO];
            [appTableCellView.checkButton setEnabled: YES];
        }
        return appTableCellView;
    } else if ([item isKindOfClass:PrivacyCategoryData.class]) {

        NSString *categoryIdentifier = [tableColumn.identifier stringByAppendingString:@"_category"];

        PrivacyCategoryTableCellView *categoryTableCellView = [outlineView makeViewWithIdentifier:categoryIdentifier owner:nil];
        if (categoryTableCellView == nil) {
            categoryTableCellView = [[PrivacyCategoryTableCellView alloc] init];
            categoryTableCellView.identifier = categoryIdentifier;
        }
        
        id parentItem = [outlineView parentForItem:item];
        categoryTableCellView.delegate = self;

        categoryTableCellView.hasFullDiskAccessAuthority = _hasFullDiskAccessAuthority;
        if(parentItem && [parentItem isKindOfClass:PrivacyAppData.class]){
            PrivacyAppData *appData = (PrivacyAppData *)parentItem;
            categoryTableCellView.belongSafari = appData.appType == PRIVACY_APP_SAFARI ? YES : NO;
        }else{
            categoryTableCellView.belongSafari = NO;
        }
        
        PrivacyCategoryData *category = item;
        [categoryTableCellView updateViewByItem:category];
        categoryTableCellView.checkButton.target = self;
        categoryTableCellView.checkButton.action = @selector(checkButtonAction:);
        if(category.totalSubNum <= 0){
            [categoryTableCellView.checkButton setHidden:YES];
        }else{
            [categoryTableCellView.checkButton setHidden:NO];
        }

        return categoryTableCellView;
    } else if ([item isKindOfClass:PrivacyItemData.class]) {

        NSString *itemIdentifier = [tableColumn.identifier stringByAppendingString:@"_item"];

        PrivacyItemTableCellView *itemTableCellView = [outlineView makeViewWithIdentifier:itemIdentifier owner:nil];
        if (itemTableCellView == nil) {
            itemTableCellView = [[PrivacyItemTableCellView alloc] init];
            itemTableCellView.identifier = itemIdentifier;
        }

        PrivacyItemData *itemData = item;
        [itemTableCellView updateViewBy:itemData];
        itemTableCellView.checkButton.target = self;
        itemTableCellView.checkButton.action = @selector(checkButtonAction:);
        return itemTableCellView;
    } else {
        return nil;
    }


}


// group row 的形式: 在header 的右侧显示 show/hide 按钮, 而不是左侧显示 箭头.                                 
// Returns a Boolean that indicates whether a given row should be drawn in the “group row” style.
// If the cell in that row is an instance of NSTextFieldCell and contains only a string value, the “group row” style attributes are automatically applied for that cell.

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
//    return [item isKindOfClass:Item.class];
    if ([outlineView parentForItem:item]) {
        // If not nil; then the item has a parent.
        return NO;
    }
    return NO;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return NO;
}

- (nullable NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item {
    ResultTableRowView *rowView = [[ResultTableRowView alloc] initWithFrame:NSZeroRect];
    return rowView;
}

// MARK: click action

-(void)clickOutLineView{
    int idx = (int) _outlineView.clickedRow;
    if (idx < 0) {
        return;
    }
    BOOL needExpand = NO;
    id item = [_outlineView itemAtRow:idx];
    if(item == nil){
        return;
    }else if ([item isKindOfClass: PrivacyAppData.class] ){
        needExpand = YES;
    }else if ([item isKindOfClass: PrivacyCategoryData.class] && ((PrivacyCategoryData *)item).subItems.count > 0){
        needExpand = YES;
    }
    if (needExpand) {
        BOOL isExpand = [_outlineView isItemExpanded:item];
        if (isExpand) {
            [_outlineView.animator collapseItem:item];
        } else {
            [_outlineView.animator expandItem:item];
        }
    }
}

- (void)clickCleanButton {
    
    NSArray *array = [PrivacyDataManager getInstalledAndRunningBrowserApps];
    if (!array) {
        array = [NSMutableArray alloc];
    }
    
    PrivacyData *data = self.privacyData;
    NSMutableArray *needCloseAppArray = [[NSMutableArray alloc] init];
    for (BrowserApp *app in array) {
        
        BOOL needCleanAndCloseApp = FALSE;
        if (app.isRunning) {
            for (PrivacyAppData *appData in data.subItems) {
                if (appData.appType == app.appType && appData.selectedSubItemNum > 0) {
                    needCleanAndCloseApp = YES;
                }
            }
        }
        
        if (needCleanAndCloseApp) {
            [needCloseAppArray addObject:app];
        }
    }
    
    
    //    扫描前 请求关闭 app
    if (needCloseAppArray.count > 0) {
        RunningAppPopViewController *controller = [[RunningAppPopViewController alloc] initWithApps:needCloseAppArray superController:self];
        controller.data = data;
        controller.parentViewController = self;
        [self presentViewControllerAsModalWindow:controller];
    } else {
        [self cleanActionWithRunningApps:nil needKill:NO];
    }
}

//  cell的 checkButton
- (void)checkButtonAction:(id)sender {
    NSButton *checkBtn = (NSButton *) sender;
    
    // 每次点击 button, 默认会更改 button 的 state, 但是正常点击却不会是 off -> mix 的状态, 所以 mix 的状态时
    if (checkBtn.state == NSMixedState) {
        checkBtn.state = NSOnState;
    }
    
    NSInteger row = [_outlineView rowForView:checkBtn];
    if (row != -1) {
        BasePrivacyData *item = [_outlineView itemAtRow:row];
        
        NSMutableIndexSet *reloadIndexSet = [NSMutableIndexSet indexSetWithIndex:(NSUInteger) row];
        
        // MARK: 如果是子项, 需要将所有的子项 / 父项 的状态全部改变.
        // 更改自己子item的 所有状态.
        [item setStateWithSubItemsIfHave:checkBtn.state];
        // 更改父item 的 所有状态.
        [self refreshSuperItemState:row needRefresh:reloadIndexSet];
        
        // 将子 item 全部添加到 needRefresh 中 (递归)
        
        // MARK: 这里无法使用 while(YES) 进行处理, 只能使用方法递归.
        // 以为向下的是树形结构, 而 while(YES) 只能 处理链式结构.
        
        //        BasePrivacyData tempItem = item;
        //        while (YES){
        //
        //            for (BasePrivacyData * subItem in [tempItem subItems]){
        //                NSInteger tempRow = [self->outlineView rowForItem:subItem];
        //                if (tempRow != -1) [reloadIndexSet addIndex:tempRow];
        //            }
        //        }
        //
        [self addBaseSubItemRow:reloadIndexSet categoryItem:item];
        
        
        if (@available(macOS 10.13, *)) {
            [reloadIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                
                // 重新刷新 tableView cell
                id itemData = [self->_outlineView itemAtRow:idx];
                NSView *view = [self->_outlineView viewAtColumn:0 row:idx makeIfNecessary:NO];
                
                // view 不存在的时候不需要 reload, 防止卡顿.
                // NSInteger tempRow = [self->_outlineView rowForItem:subItem]; 这个代码无论 item 处不处于展示的状态,都会有值.
                
                if (view){
                    // 在 10.11 系统上reloadItem 并不会触发 view重新生成. 很坑.
                    [self->_outlineView reloadItem:itemData];
                    
                    // 得到 tableRowView
                    ResultTableRowView *curTableRowView = [self->_outlineView rowViewAtRow:idx makeIfNecessary:NO];
                    [curTableRowView moveExpandButtonToFront];
                    // 从 tableView 中得到 cellView.
                    //            NSTableCellView *cellView = [curTableRowView viewAtColumn:0];
                    // TODO 如果 reload tableView 无法达到效果, 需要单独处理 cellView.
                }
            }];
        }else{
             [self->_outlineView reloadData];
        }
      
    }
    
    [self updateTitleView];
}

- (void)refreshSuperItemState:(NSInteger)curRow needRefresh:(NSMutableIndexSet *)reloadIndexSet {
    id item = [_outlineView itemAtRow:curRow];
    
    id tempItem = item;
    
    while (YES) {
        id parentItem = [_outlineView parentForItem:tempItem];
        if (parentItem == nil) {
            NSLog(@"%s tempItem %@ can't get parentItem", __FUNCTION__, tempItem);
            break;
        }
        
        tempItem = parentItem;
        //  根据自己子item的状态去更新 自己的 stateValue
        [tempItem refreshItemStateValue];
        
        NSInteger tempRow = [_outlineView rowForItem:tempItem];
        if (tempRow != -1) {
            [reloadIndexSet addIndex:(NSUInteger) tempRow];
        }else{
            NSLog(@"%s tempItem %@ can't has row", __FUNCTION__, tempItem);
        }
    }
}



// MARK: show full disk access 权限申请引导页

-(void)openFullDiskAccessSettingGuidePage
{
    if (!self.getFullAccessWndController) {
        self.getFullAccessWndController = [GetFullAccessWndController shareInstance];
        [self.getFullAccessWndController setParaentCenterPos:[self getCenterPoint] suceessSeting:nil];
    }
    
    [self.getFullAccessWndController.window makeKeyAndOrderFront:nil];
}

-(CGPoint)getCenterPoint
{
    CGPoint origin = self.view.window.frame.origin;
    CGSize size = self.view.window.frame.size;
    return CGPointMake(origin.x + size.width / 2, origin.y + size.height / 2);
}


-(void)hostWindowWillClose
{
    // 关闭隐私清理模块窗口时, 顺带关闭 提示获取权限的弹窗,(防止出现多个提示弹窗)
    if (self.getFullAccessWndController) {
        [self.getFullAccessWndController closeWindow];
        self.getFullAccessWndController = nil;
    }
}
@end


