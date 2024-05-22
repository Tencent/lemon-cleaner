//
//  LMFileMoveMainVC.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveMainVC.h"
#import <QMUICommon/LMRectangleButton.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/LMBigLoadingView.h>
#import <QMUICommon/LMBorderButton.h>
#import <QMCoreFunction/QMEnvironmentInfo.h>
#import <QMCoreFunction/LMBookMark.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import "NSColor+Extension.h"
#import "QMProgressView.h"
#import "LMFileMoveManger.h"
#import <QMUICommon/QMMoveOutlineView.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import "LMFileMoveRowView.h"
#import "LMFileCategoryItem.h"
#import "LMAppCategoryItem.h"
#import "LMResultItem.h"
#import "LMFileMoveBaseCell.h"
#import <AppKit/NSTableView.h>
#import "LMBaseItem.h"
#import "LMDiskCollectionViewItem.h"
#import "LMFileCustomPathView.h"
#import "Disk.h"
#import <QMUICommon/LMBorderButton.h>
#import <QMCoreFunction/NSString+Extension.h>
#import "LMFileMoveWnController.h"
#import "LMFileMoveManger.h"
#import "LMFileMoveDefines.h"
#import "LMFileMoveCommonDefines.h"
#import "LMFileMoveFeatureDefines.h"

#define FILEMOVE_CATEGORY_INDENTIFIER         @"filemoveCategoryCellView"
#define FILEMOVE_SUB_CATEGORY_INDENTIFIER     @"filemoveSubCategoryCellView"
#define FILEMOVE_RESULT_INDENTIFIER           @"filemoveResultCellView"
#define Lemon_KB_To_GB                        1000000000.0
#define Disk_No_Need_Remove                   -1
#define Disk_No_Exist                         0

@interface LMFileMoveMainVC () <LMFileMoveMangerDelegate, NSCollectionViewDelegate, NSCollectionViewDataSource, LMFileCustomPathViewDelegate, LMDiskCollectionViewItemDelegate, NSOpenSavePanelDelegate>

// 扫描页组件
@property (weak) IBOutlet NSView *scanView;
@property (weak) IBOutlet NSTextField *scanBigText;
@property (weak) IBOutlet NSTextField *currentScanFileName;
@property (weak) IBOutlet QMProgressView *scanViewProgressView;

// 选择页组件
@property (strong) IBOutlet NSView *selecetView;
@property (weak) IBOutlet NSTextField *bigTitleTextField;
@property (weak) IBOutlet NSTextField *totalSizeDesTextFiled;
@property (weak) IBOutlet NSTextField *selectSizeDesTextField;
@property (weak) IBOutlet NSTextField *defaultTextFiled;
@property (weak) IBOutlet LMRectangleButton *nextButton;
@property (weak) IBOutlet NSScrollView *scrollerView;
@property (weak) IBOutlet QMMoveOutlineView *outlineView;

// 存储路径组件
@property (strong) IBOutlet NSView *diskView;
@property (weak) IBOutlet NSTextField *diskBigTitleTextField;
@property (weak) IBOutlet LMRectangleButton *diskNextButton;
@property (weak) IBOutlet NSTextField *diskDefaultTextField;
@property (weak) IBOutlet NSView *diskLocalBgView;
@property (weak) IBOutlet NSTextField *diskLocationTip;
@property (weak) IBOutlet NSTextField *diskLocationTextField;
@property (weak) IBOutlet NSCollectionView *collectionView;
@property (nonatomic, strong) NSCollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) NSMutableArray *diskModelArr;
@property (weak) IBOutlet NSScrollView *diskScrollView;
@property (weak) IBOutlet NSBox *verticalLine;
@property (weak) IBOutlet LMFileCustomPathView *customFilePathView;
@property (weak) IBOutlet NSTextField *customTextField;
@property (weak) IBOutlet LMBorderButton *backButton;
@property (weak) IBOutlet NSTextField *diskSelectSizeTextField;
@property (weak) IBOutlet NSTextField *externalTip;
@property (weak) IBOutlet NSTextField *customTip;

@property (nonatomic, assign) long long currentTotalSize;
@property (nonatomic, assign) long long totalSize;
@property (nonatomic, strong) NSMutableArray *appArr;
@property (nonatomic, strong) NSMutableArray *categoryItemArr;//三个大项 item  用于展开子项

@property (nonatomic, assign) long long lastUpdateCellTime; // 毫秒。避免刷新过于频繁

@end

@implementation LMFileMoveMainVC

- (instancetype)init {
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        _totalSize = [[NSUserDefaults standardUserDefaults] doubleForKey:@"Lemon_KB_To_GB"];
        _categoryItemArr = [NSMutableArray array];
        _diskModelArr = [NSMutableArray array];
        self.lastUpdateCellTime = 0;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(diskDidAppear:) name:@"DADiskDidAppearNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(diskDidDisappear:) name:@"DADiskDidDisppearNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(diskDidChange:) name:@"DADiskDidChangeNotification" object:nil];
    }
    return self;
}

#pragma mark - public

- (void)showStartView {
    //
    [self.scanView setHidden:NO];
    [self.selecetView setHidden:YES];
    [self.diskView setHidden:YES];
    //
    self.scanViewProgressView.value = 0.0;
    self.scanBigText.stringValue = NSLocalizedStringFromTableInBundle(@"Scanning", nil, [NSBundle bundleForClass:[self class]], @"");
    self.scanBigText.textColor = [LMAppThemeHelper getTitleColor];
    self.currentScanFileName.stringValue = @" ";
    //
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [LMFileMoveManger shareInstance].delegate = self;
        [[LMFileMoveManger shareInstance] startScan];
    });
}

- (void)showSelectView {
    dispatch_async(dispatch_get_main_queue(), ^{
        //
        [self.scanView setHidden:YES];
        [self.diskView setHidden:YES];
        [self.selecetView setHidden:NO];
        //
        self.nextButton.target = self;
        self.nextButton.action = @selector(clickEnterDiskView);
        self.bigTitleTextField.stringValue = NSLocalizedStringFromTableInBundle(@"Select files to export", nil, [NSBundle bundleForClass:[self class]], @"");
        self.defaultTextFiled.stringValue = NSLocalizedStringFromTableInBundle(@"Files created before 90 days ago will be selected by default.", nil, [NSBundle bundleForClass:[self class]], @"");
        [self.nextButton setTitle:NSLocalizedStringFromTableInBundle(@"Next", nil, [NSBundle bundleForClass:[self class]], @"")];
        [self.backButton setTitle:NSLocalizedStringFromTableInBundle(@"Back", nil, [NSBundle bundleForClass:[self class]], @"")];
        self.diskDefaultTextField.stringValue = NSLocalizedStringFromTableInBundle(@"To save space on your Mac you can move your files to external storage directly or after exporting files to the local disk.", nil, [NSBundle bundleForClass:[self class]], @"");
        self.diskLocationTip.stringValue = NSLocalizedStringFromTableInBundle(@"Destination：", nil, [NSBundle bundleForClass:[self class]], @"");
        self.externalTip.stringValue = NSLocalizedStringFromTableInBundle(@"External Storage", nil, [NSBundle bundleForClass:[self class]], @"");
        self.customTip.stringValue = NSLocalizedStringFromTableInBundle(@"Custom", nil, [NSBundle bundleForClass:[self class]], @"");
        //
        [self.outlineView setHeaderView:nil];
        if (@available(macOS 10.14, *)) {
            [self.outlineView setBackgroundColor:[NSColor colorNamed:@"view_bg_color" bundle:[NSBundle mainBundle]]];
        } else {
            [self.outlineView setBackgroundColor:[NSColor whiteColor]];
        }
        //单击展开和收起
        self.outlineView.target = self;
        self.outlineView.action = @selector(clickExpandOrShrink);
        [self.outlineView reloadData];
        // 自动展开第一层
        NSInteger itemCount = [self.appArr count];
        if (itemCount > 0) {
            for (NSInteger i = 0; i < itemCount; i++) {
                id item = [self.outlineView itemAtRow:i];
                [self.categoryItemArr addObject:item];
            }
            for (id item in self.categoryItemArr) {
                [self.outlineView expandItem:item expandChildren:NO];
            }
        }
        float totalNumGB = (self.totalSize/(Lemon_KB_To_GB));
        self.totalSizeDesTextFiled.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Total %.1f GB, selected", nil, [NSBundle bundleForClass:[self class]], @""),totalNumGB];
        long long selectedNum = [LMFileMoveManger shareInstance].selectedFileSize;
        self.selectSizeDesTextField.stringValue = [[LMFileMoveManger shareInstance] sizeNumChangeToStr:selectedNum];
        if (selectedNum == 0) {
            [self.nextButton setEnabled:NO];
        } else {
            [self.nextButton setEnabled:YES];
        }
    });
}

- (void)showDiskView {
    //
    [self.scanView setHidden:YES];
    [self.selecetView setHidden:YES];
    [self.diskView setHidden:NO];
    //
    self.diskNextButton.enabled = NO;
    self.diskBigTitleTextField.stringValue = NSLocalizedStringFromTableInBundle(@"Select a folder to save files", nil, [NSBundle bundleForClass:[self class]], @"");
    [self.diskNextButton setTitle:NSLocalizedStringFromTableInBundle(@"Transfer", nil, [NSBundle bundleForClass:[self class]], @"")];

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    if (LM_IS_CHINESE_LANGUAGE) {
        LM_APPEND_ATTRIBUTED_STRING(text, @"将会导出", LM_COLOR_GRAY, 14);
        LM_APPEND_ATTRIBUTED_STRING(text, self.selectSizeDesTextField.stringValue, LM_COLOR_YELLOW, 14);
        LM_APPEND_ATTRIBUTED_STRING(text, @"文件", LM_COLOR_GRAY, 14);
    } else {
        LM_APPEND_ATTRIBUTED_STRING(text, self.selectSizeDesTextField.stringValue, LM_COLOR_YELLOW, 14);
        LM_APPEND_ATTRIBUTED_STRING(text, @" files are to be transferred.", LM_COLOR_GRAY, 14);
    }
    self.diskSelectSizeTextField.attributedStringValue = text;
    
    self.diskLocalBgView.wantsLayer = YES;
    self.diskLocalBgView.layer.backgroundColor = [NSColor colorWithHex:0x909090 alpha:0.1].CGColor;
    self.diskLocationTip.textColor = [LMAppThemeHelper getFixedTitleColor];
    self.diskLocationTextField.textColor = [LMAppThemeHelper getFixedTitleColor];
    self.diskLocationTextField.font = [NSFontHelper getRegularPingFangFont:13.0f];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    if (@available(macOS 10.13, *)) {
        [self.diskScrollView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
        self.collectionView.backgroundColors  = @[[LMAppThemeHelper getMainBgColor]];
    } else {
        self.collectionView.layer.backgroundColor = NSColor.whiteColor.CGColor;
    }
    //注册cell
    [self.collectionView registerClass:[LMDiskCollectionViewItem class] forItemWithIdentifier:@"LMDiskCollectionViewItem"];
    //设置item的大小以及间距
    self.flowLayout = [[NSCollectionViewFlowLayout alloc] init];
    self.flowLayout.itemSize = NSMakeSize(140, 202); // item大小
    self.flowLayout.sectionInset = NSEdgeInsetsMake(0, 0, 0, 0);
    self.flowLayout.minimumLineSpacing = 5; // 最小横向间距
    self.flowLayout.minimumInteritemSpacing = 0; // 最小竖向间距
    self.flowLayout.scrollDirection = NSCollectionViewScrollDirectionHorizontal;
    self.collectionView.collectionViewLayout = self.flowLayout;
    self.collectionView.wantsLayer = YES;
    // 设置可选择 ！！！注意！！！不设置为YES会导致点击item无效果
    self.collectionView.selectable = YES;
    //
    [self.verticalLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.diskScrollView.mas_right).offset(20);
        make.height.equalTo(@240);
        make.width.equalTo(@1);
        make.bottom.equalTo(self.view).offset(-75);
    }];
    
    self.customFilePathView.delegate = self;
    [self.customFilePathView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.diskScrollView.mas_right).offset(40);
        make.height.equalTo(@202);
        make.width.equalTo(@140);
        make.bottom.equalTo(self.diskScrollView);
    }];
    
    [self.customTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.diskScrollView.mas_right).offset(40);
    }];
   
}
                   
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self.view addSubview:self.selecetView];
    [self.view addSubview:self.diskView];
}

#pragma mark - NSNotificationCenter

- (void)reloadCollection {
    
    NSUInteger count = self.diskModelArr.count;
    int width = 0;
    if (count <= 1) {
        width = 140;
    } else if (count >= 5 ) {
        width = 721;
    } else {
        width = 145 * (int)count;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.diskScrollView.frame = NSMakeRect(50, 80, width, 202);
        [self.collectionView reloadData];
    });
}
    
- (void)diskDidAppear:(NSNotification *)notif {
    Disk *disk = notif.object;

    NSLog(@"1-disk: %@===%@", disk.BSDName,disk);
    if (disk.isMounted) {
        [self addDisksObject:disk];
    }
    NSLog(@"1设备：%lu",(unsigned long)self.diskModelArr.count);
    [self reloadCollection];
}

- (void)diskDidDisappear:(NSNotification *)notif {
    Disk *disk = notif.object;

    NSLog(@"2-disk: %@===%@", disk.BSDName,disk);
    [self removeDisksObject:notif.object];
    NSLog(@"2设备：%lu",(unsigned long)self.diskModelArr.count);
    [self reloadCollection];
}

- (void)diskDidChange:(NSNotification *)notif {
    Disk *disk = notif.object;
    NSLog(@"3-disk: %@===%@", disk.BSDName,disk);
    if (disk.isMounted) {
        [self addDisksObject:disk];
    } else {
        [self removeDisksObject:disk];
    }
    NSLog(@"3设备：%lu",(unsigned long)self.diskModelArr.count);
    [self reloadCollection];
}


- (void)removeDisksObject:(Disk *)object {
    int index = Disk_No_Need_Remove;
    for (int num = 0; num < self.diskModelArr.count; num ++) {
        Disk *disk = self.diskModelArr[num];
        if ([disk.BSDName isEqualToString:object.BSDName]) {
            index = num;
        }
    }
    if (index != Disk_No_Need_Remove) {
        [self.diskModelArr removeObjectAtIndex:index];
    }
}

- (void)addDisksObject:(Disk *)object {
    for (Disk *disk in self.diskModelArr) {
        if ([disk.BSDName isEqualToString:object.BSDName]) {
            return;
        }
    }
    [self.diskModelArr addObject:object];
}

#pragma mark -- NSOpenSavePanelDelegate

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url NS_AVAILABLE_MAC(10_6){
    NSLog(@"user select shouldEnableURL = %@", [url path]);
    NSString *userPath = [NSString getUserHomePath];
    BOOL isDir = NO;
    BOOL existed = [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDir];
    if(([[url path] isEqualToString:userPath] || [[url path] hasPrefix:userPath]) && isDir && existed)
        return YES;
    return NO;
}

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError NS_AVAILABLE_MAC(10_6){
    NSLog(@"user select validateURL = %@", [url path]);
    NSString *userPath = [NSString getUserHomePath];
    BOOL isDir = NO;
    BOOL existed = [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDir];
    if(([[url path] isEqualToString:userPath] || [[url path] hasPrefix:userPath]) && isDir && existed)
        return YES;
    return NO;
}

#pragma mark - LMFileCustomPathViewDelegate/LMDiskCollectionViewItemDelegate

- (void)fileCustomPathViewDidClick {
    
    NSString *userPath = [NSString stringWithFormat:@"%@/Desktop",[NSString getUserHomePath]];
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    openDlg.allowsMultipleSelection = YES;
    openDlg.canChooseDirectories = YES;
    openDlg.canChooseFiles = YES;
    [openDlg setPrompt:NSLocalizedStringFromTableInBundle(@"Ok", nil, [NSBundle bundleForClass:[self class]], @"")];
    openDlg.delegate = self;
    openDlg.message = @"";
    openDlg.directoryURL = [NSURL URLWithString:userPath];
    [openDlg beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if(result == NSModalResponseOK){
            NSLog(@"click ok");
            NSArray *urls = [openDlg URLs];
            NSURL *url = [urls objectAtIndex:0];
            NSString *path = [url path];
            path = [NSString stringWithFormat:@"%@/柠檬清理_文件搬家/",path];
            self.diskLocationTextField.stringValue = path;
            [[LMFileMoveManger shareInstance] didSelectedTargetPath:path pathType:LMFileMoveTargetPathTypeLocalPath];
            self.diskNextButton.enabled = YES;
            [self.customFilePathView changeMaskLightColor:YES];
            [self.collectionView reloadData];
        }else{
            NSLog(@"click cancel");
        }
    }];
}

- (void)collectionViewItemBeSelect:(Disk *)model {
    NSURL *pathUrl = [model.diskDescription objectForKey:@"DAVolumePath"];
    NSString *path = [[pathUrl absoluteString] stringByRemovingPercentEncoding];
    path = [path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    path = [NSString stringWithFormat:@"%@柠檬清理_文件搬家/",path];
    if (path) {
        self.diskLocationTextField.stringValue = path;
        [[LMFileMoveManger shareInstance] didSelectedTargetPath:path pathType:LMFileMoveTargetPathTypeDisk];
        self.diskNextButton.enabled = YES;
    }
    [self.customFilePathView changeMaskLightColor:NO];
}

#pragma mark - NSCollectionViewDelegate
                   
- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
   return 1;
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.diskModelArr.count == Disk_No_Exist) {
        return 1;
    } else {
        return self.diskModelArr.count;
    }
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    LMDiskCollectionViewItem *item = [collectionView makeItemWithIdentifier:@"LMDiskCollectionViewItem" forIndexPath:indexPath];
    if (!item) {
        item = [[LMDiskCollectionViewItem alloc] initWithNibName:@"LMDiskCollectionViewItem" bundle:nil];
    }

    item.delegate = self;
    if (self.diskModelArr.count == Disk_No_Exist) {
        [item setNoneDisk];
    } else {
        NSUInteger row = (NSUInteger) indexPath.item;
        Disk *disk = self.diskModelArr[row];
        [item setDiskModel:disk];
    }
   return item;
}
      
#pragma mark - Action

- (IBAction)diskBackBtn:(id)sender {
    [self reloadCollection];
    [self.customFilePathView changeMaskLightColor:NO];
    self.diskLocationTextField.stringValue = @"";
    self.diskNextButton.enabled = NO;
    [self showSelectView];
}

- (IBAction)diskNextBtn:(id)sender {
    LMFileMoveWnController *wc = self.view.window.windowController;
    [wc showProcessView];
    [[NSNotificationCenter defaultCenter] postNotificationName:LM_FILE_MOVE_DID_START_NOTIFICATION object:nil];
}

- (void)clickEnterDiskView {
    [self showDiskView];
    [self reportSelectStates];
}
                   
- (void)clickExpandOrShrink {
    NSInteger row = self.outlineView.clickedRow;
    id item = [self.outlineView itemAtRow:row];
    if ([item isKindOfClass:LMResultItem.class]) {
        return;
    }
    if ([self.outlineView isItemExpanded:item]) {
        [self.outlineView.animator collapseItem:item];
    }else{
        [self.outlineView.animator expandItem:item];
    }
}


- (void)checkButtonAction:(id)sender {
    NSButton *checkBtn = (NSButton *) sender;
    
    // 每次点击 button, 默认会更改 button 的 state, 但是正常点击却不会是 off -> mix 的状态, 所以 mix 的状态时
    if (checkBtn.state == NSMixedState) {
        checkBtn.state = NSOnState;
    }
    
    NSInteger row = [_outlineView rowForView:checkBtn];
    if (row != -1) {
        LMBaseItem *item = [_outlineView itemAtRow:row];
        
        // 更改自己子item的 所有状态.
        [item setStateWithSubItemsIfHave:checkBtn.state];
        // 更改父item 的 所有状态.
        [self refreshSuperItemState:row];
        [self.outlineView reloadData];

    }
    //
    long long selectedNum = [[LMFileMoveManger shareInstance] caculateSize];
    self.selectSizeDesTextField.stringValue = [[LMFileMoveManger shareInstance] sizeNumChangeToStr:selectedNum];
    if (selectedNum == 0) {
        [self.nextButton setEnabled:NO];
    } else {
        [self.nextButton setEnabled:YES];
    }
}

- (void)refreshSuperItemState:(NSInteger)curRow {
    id item = [self.outlineView itemAtRow:curRow];
    
    LMBaseItem *tempItem = item;
    
    while (YES) {
        id parentItem = [_outlineView parentForItem:tempItem];
        if (parentItem == nil) {
            NSLog(@"%s tempItem %@ can't get parentItem", __FUNCTION__, tempItem);
            break;
        }
        tempItem = parentItem;
        //  根据自己子item的状态去更新 自己的 stateValue
        if ([tempItem isKindOfClass:[LMAppCategoryItem class]] || [tempItem isKindOfClass:[LMFileCategoryItem class]] ) {
            [tempItem updateSelectState];
        }
    }
}


#pragma mark outline view delegate

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item {
    return [[LMFileMoveRowView alloc] init];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (!item)
        return  [self.appArr objectAtIndex:index];;
    if ([item isKindOfClass:[LMAppCategoryItem class]]) {
        return [[item subItems] objectAtIndex:index];
    } else if ([item isKindOfClass:[LMFileCategoryItem class]]) {
        return [[item subItems] objectAtIndex:index];
    }
    return item;
}


- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
   
    if ([item isKindOfClass:[LMAppCategoryItem class]]) {
        return 42;
    } else if ([item isKindOfClass:[LMFileCategoryItem class]]) {
        return 32;
    } else if ([item isKindOfClass:[LMResultItem class]])
    {
        return 32;
    }
    return 30;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if ([item isKindOfClass:[LMAppCategoryItem class]]) {
        return YES;
    }  else if ([item isKindOfClass:[LMFileCategoryItem class]]) {
        return [[item subItems] count] > 0;
    } else if ([item isKindOfClass:[LMResultItem class]]) {
        return NO;
    }
    return YES;
}


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (!item) return [self.appArr count];

    if ([item isKindOfClass:[LMAppCategoryItem class]]) {
        return 6;
    } else if ([item isKindOfClass:[LMFileCategoryItem class]]) {
        return [[item subItems] count];
    } else if ([item isKindOfClass:[LMResultItem class]]) {
        return 0;
    }
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return item;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    LMFileMoveBaseCell *cell = nil;
    if ([item isKindOfClass:[LMAppCategoryItem class]]) {
        cell = [outlineView makeViewWithIdentifier:FILEMOVE_CATEGORY_INDENTIFIER owner:self];
    } else if ([item isKindOfClass:[LMFileCategoryItem class]]) {
        cell = [outlineView makeViewWithIdentifier:FILEMOVE_SUB_CATEGORY_INDENTIFIER owner:self];
    } else if ([item isKindOfClass:[LMResultItem class]]) {
        cell = [outlineView makeViewWithIdentifier:FILEMOVE_RESULT_INDENTIFIER owner:self];
    }

    [cell.checkButton setTarget:self];
    [cell.checkButton setAction:@selector(checkButtonAction:)];

    [cell setCellData:item];
    // 当前是否选中
    // [cell setHightLightStyle:([_outLineView selectedRow] == [_outLineView rowForItem:item])];

    return cell;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return NO;
}

#pragma mark - LMFileMoveMangerDelegate

- (void)fileMoveMangerScan:(NSString *)path size:(long long)size {
    self.currentTotalSize = self.currentTotalSize + size;
    float value = self.currentTotalSize / (self.totalSize * 1.0);
    if (value >= 1) {
        value = 1;
    }
    
    long long currentTime = [[NSDate date] timeIntervalSince1970] * 1000;
    if (labs(self.lastUpdateCellTime - currentTime) < 100 && fabs(1.0 - value) > 0.05) {
        return;
    }
    self.lastUpdateCellTime = currentTime;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.scanViewProgressView.value = value;
        if (path) {
            self.currentScanFileName.stringValue = path;
        }
    });
}

- (void)fileMoveMangerScanFinished {
    self.appArr = [LMFileMoveManger shareInstance].appArr;
    [self showSelectView];
}

#pragma mark - Report

- (void)reportSelectStates {
    for (LMAppCategoryItem *appItem in [LMFileMoveManger shareInstance].appArr) {
        int isAppSelected = (appItem.selecteState == NSControlStateValueOff ? 0 : 1);
        float appSize = appItem.fileSize/ 1000.0;
        
        int isFile90BeforeSelected = 0;
        int isFile90AfterSelected = 0;
        int isImage90BeforeSelected = 0;
        int isImage90AfterSelected = 0;
        int isVideo90BeforeSelected = 0;
        int isVideo90AfterSelected = 0;

        float file90BeforeSize = 0;
        float file90AfterSize = 0;
        float image90BeforeSize = 0;
        float image90AfterSize = 0;
        float video90BeforeSize = 0;
        float video90AfterSize = 0;

        for (LMFileCategoryItem *fileItem in appItem.subItems) {
            float fileSize = fileItem.fileSize / 1000.0;
            int isSelected = (fileItem.selecteState == NSControlStateValueOff ? 0 : 1);
            switch (fileItem.type) {
                case LMFileCategoryItemType_File90Before:
                    file90BeforeSize = fileSize;
                    isFile90BeforeSelected = isSelected;
                    break;
                case LMFileCategoryItemType_File90:
                    file90AfterSize = fileSize;
                    isFile90AfterSelected = isSelected;
                    break;
                case LMFileCategoryItemType_Image90Before:
                    image90BeforeSize = fileSize;
                    isImage90BeforeSelected = isSelected;
                    break;
                case LMFileCategoryItemType_Image90:
                    image90AfterSize = fileSize;
                    isImage90AfterSelected = isSelected;
                    break;
                case LMFileCategoryItemType_Video90Before:
                    video90BeforeSize = fileSize;
                    isVideo90BeforeSelected = isSelected;
                    break;
                case LMFileCategoryItemType_Video90:
                    video90AfterSize = fileSize;
                    isVideo90AfterSelected = isSelected;
                    break;
                default:
                    break;
            }
        }
    }
}

@end
