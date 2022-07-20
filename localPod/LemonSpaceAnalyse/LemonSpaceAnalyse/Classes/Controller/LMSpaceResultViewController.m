//
//  LMSpaceResultViewController.m
//  LemonSpaceAnalyse
//
//  
//

#import "LMSpaceResultViewController.h"
#import "LMSpaceTableRowView.h"
#import "LMItem.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMBorderButton.h>
#import <QMUICommon/COSwitch.h>
@import YMTreeMap;
#import "LMSpaceView.h"
#import "LMSpaceModel.h"
#import <QMCoreFunction/NSImage+Extension.h>

#import <QMUICommon/LMPathBarView.h>
#import <math.h>
#import "McSpaceAnalyseWndController.h"
#import <Quartz/Quartz.h>
#import <QMCoreFunction/QMEnvironmentInfo.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import "LMThemeManager.h"
#import "LMBigSpaceView.h"
#import "LMSpaceModelManager.h"
#import "LMSpaceButton.h"

#define LMSpaceTableRowIdentifier @"LMSpaceTableRowIdentifier"

@interface LMSpaceResultViewController ()<NSTableViewDelegate, NSTableViewDataSource,LMSpaceViewDelegate,QLPreviewItem>
@property (weak) IBOutlet NSView *headerBigView;

@property (weak) IBOutlet NSTextField *headerTitle;
@property (weak) IBOutlet NSTextField *headerAvaText;
@property (weak) IBOutlet NSTextField *headerTotalText;
@property(nonatomic, strong) LMSpaceButton *reScanButton;
//可视化文件夹视图
@property (weak) IBOutlet NSView *visualizedViewBar;
@property (weak) IBOutlet NSView *visualizedView;
@property (weak) IBOutlet NSTextField *subFileSize;
@property (weak) IBOutlet NSTextField *subFileNum;
@property (weak) IBOutlet NSTextField *subFileFolderNum;
@property (weak) IBOutlet NSTextField *totalText;
@property (weak) IBOutlet NSTextField *fileText;
@property (weak) IBOutlet NSTextField *fileFolderText;
@property (weak) IBOutlet NSTextField *parentFileName;

//可视化tableview
@property (weak) IBOutlet NSTableView *tableView;
//可视化大背景图
@property (weak) IBOutlet NSView *spaceBigView;
//菜单导航栏
@property (weak) IBOutlet NSPathControl *pathControl;
//可视化文件视图
@property (weak) IBOutlet NSView *fileBigView;
@property (weak) IBOutlet NSTextField *fileName;
@property (weak) IBOutlet LMPathBarView *filePath;

@property (weak) IBOutlet NSTextField *fileSize;
@property (weak) IBOutlet NSButton *finderButton;

@property (weak) IBOutlet LMSpaceButton *leftButton;
@property (weak) IBOutlet LMSpaceButton *rightButton;


@property (weak) IBOutlet NSTextField *switchLabel;
@property (weak) IBOutlet COSwitch *switchButton;
@property (weak) IBOutlet NSView *listModeBigView;
@property (weak) IBOutlet NSTableView *tableViewOne;
@property (weak) IBOutlet NSTableView *tableViewTwo;
@property (weak) IBOutlet NSTableView *tableViewThree;

@property (weak) IBOutlet NSBox *lineOne;
@property (weak) IBOutlet NSBox *lineTwo;
@property (weak) IBOutlet NSBox *lineThree;



@property (nonatomic, assign) long tbOneCurrentRow;
@property (nonatomic, assign) long tbTwoCurrentRow;
@property (nonatomic, assign) long tbThreeCurrentRow;

@property(nonatomic, strong) QLPreviewView *previewView;
@property(nonatomic, strong) NSURL *showUrl;
@property(nonatomic, assign) BOOL isVisualMode;

@end

@implementation LMSpaceResultViewController

- (instancetype)init {
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        _isVisualMode = YES;
        _tbOneCurrentRow = -1;
        _tbTwoCurrentRow = -1;
        _tbThreeCurrentRow = -1;
        _isVisualMode = YES;
    }
    return self;
}

-(void)viewWillAppear{
    [super viewWillAppear];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSImage *image = [NSImage imageNamed:@"ic_star_over" withClass:self.class];

    if (@available(macOS 10.12, *)) {
        self.reScanButton = [LMSpaceButton buttonWithTitle:@"" image:image target:self action:@selector(reScanBtn)];
    } else {
        self.reScanButton = [[LMSpaceButton alloc] init];
        self.reScanButton.image = image;
        [self.reScanButton setTarget:self];
        [self.reScanButton setAction:@selector(reScanBtn)];
    }
    self.reScanButton.wantsLayer = YES;
    self.reScanButton.layer.cornerRadius = 2;
    self.reScanButton.font = [NSFont systemFontOfSize:12.0f];
    self.reScanButton.imagePosition = NSImageLeft;
    [self.headerBigView addSubview:self.reScanButton];

    [self.reScanButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@24);
        make.trailing.equalTo(self.view.mas_trailing).offset(-24);
        make.centerY.equalTo(self.headerBigView.mas_centerY);
    }];
    self.reScanButton.bordered = NO;

    self.headerAvaText.stringValue = NSLocalizedStringFromTableInBundle(@"avail.", nil, [NSBundle bundleForClass:[self class]], @"");
    self.headerTotalText.stringValue = NSLocalizedStringFromTableInBundle(@" / total", nil, [NSBundle bundleForClass:[self class]], @"");
    self.switchLabel.stringValue = NSLocalizedStringFromTableInBundle(@"Visualization Mode", nil, [NSBundle bundleForClass:[self class]], @"");
    self.fileText.stringValue = NSLocalizedStringFromTableInBundle(@"files", nil, [NSBundle bundleForClass:[self class]], @"");
    self.fileFolderText.stringValue = NSLocalizedStringFromTableInBundle(@"folders", nil, [NSBundle bundleForClass:[self class]], @"");
    self.reScanButton.title = NSLocalizedStringFromTableInBundle(@"Start Over", nil, [NSBundle bundleForClass:[self class]], @"");

    BOOL visualMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"kLemonSpaceMode"];
    self.isVisualMode = !visualMode;
    self.switchButton.on = !visualMode;
    
    self.parentFileName.font = [NSFont boldSystemFontOfSize:12.0f];

    self.listModeBigView.hidden = YES;
    self.listModeBigView.wantsLayer = YES;
    if ([LMThemeManager cureentTheme] == YES) {
        self.listModeBigView.layer.backgroundColor = [NSColor colorWithRed:37/255.0 green:38/255.0 blue:50/255.0 alpha:1.0].CGColor;
    }else{
        self.listModeBigView.layer.backgroundColor = [NSColor whiteColor].CGColor;
    }
    __weak typeof(self) weakSelf = self;
    [self.switchButton setOnValueChanged:^(COSwitch *button) {
        __strong __typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if(button.on == YES){
            [strongSelf setupViewMode:[LMSpaceModelManager sharedManger].itemModel.currentItem];
            strongSelf.isVisualMode = YES;
            strongSelf.listModeBigView.hidden = YES;
            strongSelf.tableView.hidden = NO;
            strongSelf.spaceBigView.hidden = NO;
        }else{
            [strongSelf setupListMode];
            strongSelf.isVisualMode = NO;
            strongSelf.listModeBigView.hidden = NO;
            strongSelf.tableView.hidden = YES;
            strongSelf.spaceBigView.hidden = YES;
            [strongSelf.visualizedView.subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj removeFromSuperview];
            }];
        }
        [[NSUserDefaults standardUserDefaults] setBool:!button.on forKey:@"kLemonSpaceMode"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }];
    //初始化tableView
    NSNib *nib = [[NSNib alloc] initWithNibNamed:NSStringFromClass([LMSpaceTableRowView class]) bundle:[NSBundle bundleForClass:self.class]];
    [self.tableView registerNib:nib forIdentifier:LMSpaceTableRowIdentifier];
    [self.tableViewOne registerNib:nib forIdentifier:LMSpaceTableRowIdentifier];
    [self.tableViewTwo registerNib:nib forIdentifier:LMSpaceTableRowIdentifier];
    [self.tableViewThree registerNib:nib forIdentifier:LMSpaceTableRowIdentifier];
    
    self.tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
    self.tableViewOne.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
    self.tableViewTwo.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
    self.tableViewThree.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
    
    [self.tableView setDoubleAction:@selector(doubleAction:)];
    [self.tableViewOne setDoubleAction:@selector(doubleAction:)];
    [self.tableViewTwo setDoubleAction:@selector(doubleAction:)];
    [self.tableViewThree setDoubleAction:@selector(doubleAction:)];
   
    [self.tableView setAction:@selector(singleAction:)];
    [self.tableViewOne setAction:@selector(singleAction:)];
    [self.tableViewTwo setAction:@selector(singleAction:)];
    [self.tableViewThree setAction:@selector(singleAction:)];
    
    if ([LMThemeManager cureentTheme] == YES) {
        self.tableView.backgroundColor = [NSColor colorWithRed:38/255.0 green:39/255.0 blue:50/255.0 alpha:1/1.0];
        self.tableViewOne.backgroundColor = [NSColor colorWithRed:38/255.0 green:39/255.0 blue:50/255.0 alpha:1/1.0];
        self.tableViewTwo.backgroundColor = [NSColor colorWithRed:38/255.0 green:39/255.0 blue:50/255.0 alpha:1/1.0];
        self.tableViewThree.backgroundColor = [NSColor colorWithRed:38/255.0 green:39/255.0 blue:50/255.0 alpha:1/1.0];
    }else{
        self.tableView.backgroundColor = [NSColor whiteColor];
        self.tableViewOne.backgroundColor = [NSColor whiteColor];
        self.tableViewTwo.backgroundColor = [NSColor whiteColor];
        self.tableViewThree.backgroundColor = [NSColor whiteColor];
        
    }
    
    //初始化pathControl
    [self.pathControl setAction:(@selector(changeLocationPathAction:))];
    //可视化文件
    self.fileBigView.hidden = YES;
    //
    self.leftButton.enabled = NO;
    self.rightButton.enabled = NO;
    self.leftButton.wantsLayer = YES;
    self.leftButton.layer.cornerRadius = 2;
    self.rightButton.wantsLayer = YES;
    self.rightButton.layer.cornerRadius = 2;
    //
    self.filePath.rightAlignment = NO;
    
    self.previewView = [[QLPreviewView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) style:QLPreviewViewStyleCompact];

    [self.fileBigView addSubview:self.previewView];
    [self.previewView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.fileBigView.mas_leading).offset(22);
        make.trailing.equalTo(self.fileBigView.mas_trailing).offset(-22);
        make.top.equalTo(self.fileBigView.mas_top).offset(20);
        make.bottom.equalTo(self.fileName.mas_top).offset(-20);
    }];
    
    //
    if ([LMThemeManager cureentTheme] == YES) {
        self.fileName.textColor = [NSColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1/1.0];
        self.fileSize.textColor = [NSColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1/1.0];
    }else{
        self.fileName.textColor = [NSColor colorWithRed:81/255.0 green:81/255.0 blue:81/255.0 alpha:1/1.0];
        self.fileSize.textColor = [NSColor colorWithRed:81/255.0 green:81/255.0 blue:81/255.0 alpha:1/1.0];
    }
    
//    NSString *totalSizeStr = [self changeSizeStr:[self getAllBytes]];
//    NSMutableAttributedString *totalStr = [[NSMutableAttributedString alloc] initWithString:totalSizeStr];
//
//    if ([LMThemeManager cureentTheme] == YES) {
//        [totalStr addAttribute:NSForegroundColorAttributeName
//                         value:[NSColor colorWithHex:0xFFFFFF]
//                     range:NSMakeRange(0, totalSizeStr.length)];
//    }else{
//        [totalStr addAttribute:NSForegroundColorAttributeName
//                         value:[NSColor colorWithHex:0x696969]
//                     range:NSMakeRange(0, totalSizeStr.length)];
//    }

//    self.totalSpaceSizeLabel.stringValue = totalSizeStr;
    

//    NSString *availSizeStr = [self changeSizeStr:[self getAllUsableBytes]];
//    NSMutableAttributedString *availStr = [[NSMutableAttributedString alloc] initWithString:availSizeStr];
//    if ([LMThemeManager cureentTheme] == YES) {
//        [availStr addAttribute:NSForegroundColorAttributeName
//                         value:[NSColor colorWithHex:0xFFFFFF]
//                     range:NSMakeRange(0, availSizeStr.length)];
//    }else{
//        [availStr addAttribute:NSForegroundColorAttributeName
//                         value:[NSColor colorWithHex:0x696969]
//                     range:NSMakeRange(0, availSizeStr.length)];
//    }

//    self.availableSpaceSizeLabel.stringValue = availSizeStr;
    
    if ([LMThemeManager cureentTheme] == YES) {
        self.totalText.textColor = [NSColor colorWithHex:0x989A9E];
        self.fileText.textColor = [NSColor colorWithHex:0x989A9E];
        self.fileFolderText.textColor = [NSColor colorWithHex:0x989A9E];
    }else{
        self.totalText.textColor = [NSColor colorWithHex:0x515151];
        self.fileText.textColor = [NSColor colorWithHex:0x515151];
        self.fileFolderText.textColor = [NSColor colorWithHex:0x515151];
    }
    self.totalText.stringValue = NSLocalizedStringFromTableInBundle(@"total ", nil, [NSBundle bundleForClass:[self class]], @"");
    
    self.visualizedView.wantsLayer = YES;
    self.visualizedViewBar.wantsLayer = YES;
    self.spaceBigView.wantsLayer = YES;
    
    
    if ([LMThemeManager cureentTheme] == YES) {
        self.visualizedView.layer.backgroundColor = [NSColor colorWithRed:38/255.0 green:38/255.0 blue:40/255.0 alpha:0.2/1.0].CGColor;
        self.visualizedViewBar.layer.backgroundColor = [NSColor colorWithRed:38/255.0 green:38/255.0 blue:40/255.0 alpha:0.2/1.0].CGColor;
    }else{
        self.visualizedView.layer.backgroundColor = [NSColor colorWithRed:222/255.0 green:228/255.0 blue:235/255.0 alpha:0.2/1.0].CGColor;
        self.visualizedViewBar.layer.backgroundColor = [NSColor colorWithRed:222/255.0 green:228/255.0 blue:235/255.0 alpha:0.2/1.0].CGColor;
    }
    
    
}

#pragma mark - Action

- (IBAction)leftBtn:(id)sender {
    LMItem *lastItem = [[LMSpaceModelManager sharedManger].itemModel.currentItems lastObject];
    [[LMSpaceModelManager sharedManger].itemModel.remindItems addObject:lastItem];
    [[LMSpaceModelManager sharedManger].itemModel.currentItems removeLastObject];
    
    LMItem *item = [[LMSpaceModelManager sharedManger].itemModel.currentItems lastObject];
    [LMSpaceModelManager sharedManger].itemModel.currentItem = item;
    
    [self setupViewMode:item];
    
    if ([LMSpaceModelManager sharedManger].itemModel.remindItems > 0) {
        self.rightButton.enabled = YES;
    }

    if ([LMSpaceModelManager sharedManger].itemModel.currentItems.count == 1) {
        self.leftButton.enabled = NO;
    }
    if(self.isVisualMode == NO){
        [self setupListMode];
    }
}

- (IBAction)rightBtn:(id)sender {
    LMItem *item = [[LMSpaceModelManager sharedManger].itemModel.remindItems lastObject];
    [[LMSpaceModelManager sharedManger].itemModel.currentItems addObject:item];
    [[LMSpaceModelManager sharedManger].itemModel.remindItems removeLastObject];

    [LMSpaceModelManager sharedManger].itemModel.currentChildItms = item.childItems;
    
    [self setupViewMode:item];

    if ([LMSpaceModelManager sharedManger].itemModel.remindItems.count > 0) {
        self.rightButton.enabled = YES;
    }else{
        self.rightButton.enabled = NO;
    }
    if ([LMSpaceModelManager sharedManger].itemModel.currentItems.count > 1) {
        self.leftButton.enabled = YES;
    }
    if(self.isVisualMode == NO){
        [self setupListMode];
    }
}
-(void)singleAction:(id)sender {
    NSTableView *tableView =  (NSTableView *)sender;
    if (tableView.selectedRow == -1) {
        return;
    }
    NSUInteger row = tableView.selectedRow;
    if (self.isVisualMode == YES) {
        LMItem *grandsonItem = [LMSpaceModelManager sharedManger].itemModel.currentChildItms[row];
        self.parentFileName.stringValue = grandsonItem.fileName;
        [self.visualizedView.subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
        if (grandsonItem.isDirectory == YES) {
            [self setSpaceVie:grandsonItem.childItems];
            self.fileBigView.hidden = YES;
            self.visualizedViewBar.hidden = NO;
            self.visualizedView.hidden = NO;
        }else{
            self.fileBigView.hidden = NO;
            self.visualizedViewBar.hidden = YES;
            self.visualizedView.hidden = YES;
            self.fileName.stringValue = grandsonItem.fileName;
            self.filePath.path = grandsonItem.fullPath;
            self.fileSize.stringValue = [self changeSizeStr:grandsonItem.sizeInBytes];
            self.showUrl = [NSURL fileURLWithPath:grandsonItem.fullPath];
            __weak typeof(self) weakSelf = self;
            [self.previewView setPreviewItem:weakSelf];
            [self.previewView refreshPreviewItem];
        }
    }else{
        if (tableView == self.tableViewOne) {
          
            LMItem *item = [LMSpaceModelManager sharedManger].itemModelOne.currentChildItms[row];
            
            if ([LMSpaceModelManager sharedManger].itemModel.currentItems.count == 1) {
                
            }else if ([LMSpaceModelManager sharedManger].itemModel.currentItems.count == 2){
                [[LMSpaceModelManager sharedManger].itemModel.currentItems removeLastObject];
            }else if ([LMSpaceModelManager sharedManger].itemModel.currentItems.count >= 3){
                [[LMSpaceModelManager sharedManger].itemModel.currentItems removeLastObject];
                [[LMSpaceModelManager sharedManger].itemModel.currentItems removeLastObject];
                
            }
            [LMSpaceModelManager sharedManger].itemModel.remindItems = [NSMutableArray array];
            self.rightButton.enabled = NO;
            if (item.isDirectory == NO || item.childItems.count == 0) {
                [LMSpaceModelManager sharedManger].itemModel.currentItem = [[LMSpaceModelManager sharedManger].itemModel.currentItems lastObject];
                self.tbThreeCurrentRow = row;
                [self setupListMode];
                return;
            }
            [LMSpaceModelManager sharedManger].itemModel.currentItem = item;
            [[LMSpaceModelManager sharedManger].itemModel.currentItems addObject:item];
            [LMSpaceModelManager sharedManger].itemModel.currentChildItms = item.childItems;

            [self setupListMode];
        }else if (tableView == self.tableViewTwo){
            
            LMItem *item = [LMSpaceModelManager sharedManger].itemModelTwo.currentChildItms[row];
            
            if ([LMSpaceModelManager sharedManger].itemModel.currentItems.count == 2){
                
            }else if ([LMSpaceModelManager sharedManger].itemModel.currentItems.count >= 3){
                [[LMSpaceModelManager sharedManger].itemModel.currentItems removeLastObject];
            }
       
            if (item.isDirectory == NO || item.childItems.count == 0) {
                [LMSpaceModelManager sharedManger].itemModel.currentItem = [[LMSpaceModelManager sharedManger].itemModel.currentItems lastObject];
                self.tbThreeCurrentRow = row;
                [self setupListMode];
                return ;
            }
            [LMSpaceModelManager sharedManger].itemModel.remindItems = [NSMutableArray array];
            self.rightButton.enabled = NO;
            [LMSpaceModelManager sharedManger].itemModel.currentItem = item;
            [[LMSpaceModelManager sharedManger].itemModel.currentItems addObject:item];
            [LMSpaceModelManager sharedManger].itemModel.currentChildItms = item.childItems;
           
            [self setupListMode];
        }else if (tableView == self.tableViewThree){
            
            LMItem *item = [LMSpaceModelManager sharedManger].itemModelThree.currentChildItms[row];
          
            if (item.isDirectory == NO || item.childItems.count == 0) {
                self.tbThreeCurrentRow = row;
                [self setupListMode];
                return;
            }
            [LMSpaceModelManager sharedManger].itemModel.remindItems = [NSMutableArray array];
            self.rightButton.enabled = NO;
            if ([LMSpaceModelManager sharedManger].itemModel.currentItems.count >= 3){
                [LMSpaceModelManager sharedManger].itemModel.currentItem = item;
                [[LMSpaceModelManager sharedManger].itemModel.currentItems addObject:item];
                [LMSpaceModelManager sharedManger].itemModel.currentChildItms = item.childItems;
            }
            [self setupListMode];
        }
        
    }
    
    
}
- (void)doubleAction:(id)sender {
    NSTableView *table =  (NSTableView *)sender;
    if (table.selectedRow == -1) {
        return;
    }
    LMItem *item;
    if (table == self.tableViewOne) {
        item = [LMSpaceModelManager sharedManger].itemModelOne.currentChildItms[(long)table.selectedRow];
        [[NSWorkspace sharedWorkspace] selectFile:item.fullPath
                         inFileViewerRootedAtPath:[item.fullPath stringByDeletingLastPathComponent]];
    }else if (table == self.tableViewTwo){
        item = [LMSpaceModelManager sharedManger].itemModelTwo.currentChildItms[(long)table.selectedRow];
        [[NSWorkspace sharedWorkspace] selectFile:item.fullPath
                         inFileViewerRootedAtPath:[item.fullPath stringByDeletingLastPathComponent]];
    }else if (table == self.tableViewThree){
        item = [LMSpaceModelManager sharedManger].itemModelThree.currentChildItms[(long)table.selectedRow];
        [[NSWorkspace sharedWorkspace] selectFile:item.fullPath
                         inFileViewerRootedAtPath:[item.fullPath stringByDeletingLastPathComponent]];
    }else{
        LMItem *item = [LMSpaceModelManager sharedManger].itemModel.currentChildItms[(long)table.selectedRow];
        if (item.isDirectory == NO || item.childItems.count == 0) {
            return;
        }
        
        [LMSpaceModelManager sharedManger].itemModel.currentItem = item;
        [[LMSpaceModelManager sharedManger].itemModel.currentItems addObject:item];

        if ([LMSpaceModelManager sharedManger].itemModel.currentItems.count > 1) {
            self.leftButton.enabled = YES;
        }
        [LMSpaceModelManager sharedManger].itemModel.remindItems = [NSMutableArray array];
        self.rightButton.enabled = NO;
        
        [self setupViewMode:item];
    }
}

- (IBAction)finderBtn:(id)sender {
    NSTableView *table =  self.tableView;
    LMItem *item = [LMSpaceModelManager sharedManger].itemModel.currentChildItms[(long)table.selectedRow];
    [[NSWorkspace sharedWorkspace] selectFile:item.fullPath
                     inFileViewerRootedAtPath:[item.fullPath stringByDeletingLastPathComponent]];
}

- (IBAction)changeLocationPathAction:(id)sender {
    NSPathControl *pathCntl = (NSPathControl *)sender;
    NSPathComponentCell *component = [pathCntl clickedPathComponentCell];
    NSURL *url = [component URL];
    if (url == nil) {
        return;
    }
    [self setPathControlUrl:url.path];
    
    LMItem *testItem = [[LMSpaceModelManager sharedManger].itemModel.currentItems lastObject];
    if ([testItem.fullPath isEqualToString:url.path]) {
        return;
    }
    
    NSUInteger idx = [self findIdxFromCurrentItems:url.path];
 
    NSUInteger num = (int)[LMSpaceModelManager sharedManger].itemModel.currentItems.count - idx - 1;
    while (num) {
        LMItem *item = [[LMSpaceModelManager sharedManger].itemModel.currentItems lastObject];
        [[LMSpaceModelManager sharedManger].itemModel.remindItems addObject:item];
        [[LMSpaceModelManager sharedManger].itemModel.currentItems removeLastObject];
        num -- ;
    }
    if ([LMSpaceModelManager sharedManger].itemModel.remindItems > 0) {
        self.rightButton.enabled = YES;
    }
    if ([LMSpaceModelManager sharedManger].itemModel.currentItems.count == 1) {
        self.leftButton.enabled = NO;
    }
    LMItem *item = [[LMSpaceModelManager sharedManger].itemModel.currentItems lastObject];
    [LMSpaceModelManager sharedManger].itemModel.currentItem = item;
    
    
    if (self.isVisualMode == NO) {
        [self setupListMode];
    }else{
        [self setupViewMode:item];
    }
}

- (void)reScanBtn {
    
    NSAlert *alert = [NSAlert new];

    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Confirm", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert setMessageText:NSLocalizedStringFromTableInBundle(@"Do you want to start Over？", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert setInformativeText:NSLocalizedStringFromTableInBundle(@"Current results won't be saved and you will need to run a new full disk scan to get new results.", nil, [NSBundle bundleForClass:[self class]], @"")];
    
   
    [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {

        if (returnCode == 1001) {
            self.listModeBigView.hidden = YES;
            self.tableView.hidden = NO;
            self.spaceBigView.hidden = NO;
            [self cleanModel];

            [self.visualizedView.subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj removeFromSuperview];
            }];
            [self.view.window.windowController restartScanView];
        }
    }];
}

- (void)setPathControlUrl:(NSString *)path {
    if (!path) {
        return;
    }
    NSString *startPath = @"/";
    startPath = [startPath stringByAppendingString:path];
    self.pathControl.URL = [NSURL fileURLWithPath:startPath];
}

#pragma mark - LMSpaceViewDelegate代理

-(void)LMSpaceViewmouseDown:(LMSpaceView *)view {
    LMItem *item = view.item;
    
    [[LMSpaceModelManager sharedManger].itemModel.currentItems addObject:item.parentDirectory];
    //当前item
    [LMSpaceModelManager sharedManger].itemModel.currentItem = item;
    //当前item数组
    [[LMSpaceModelManager sharedManger].itemModel.currentItems addObject:item];
    
    if ([LMSpaceModelManager sharedManger].itemModel.currentItems.count > 1) {
        self.leftButton.enabled = YES;
    }
    [LMSpaceModelManager sharedManger].itemModel.remindItems = [NSMutableArray array];
    self.rightButton.enabled = NO;
    if (item.childItems.count > 0) {
        LMItem *currentItem = item.childItems[0];
        self.parentFileName.stringValue = currentItem.fileName;
    }
    [self setupViewMode:item];
}

#pragma mark - NSTableViewDelegate代理

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.tableViewOne) {
        return [LMSpaceModelManager sharedManger].itemModelOne.currentChildItms.count;
    }else if (tableView == self.tableViewTwo){
        return [LMSpaceModelManager sharedManger].itemModelTwo.currentChildItms.count;
    }else if (tableView == self.tableViewThree){
        return [LMSpaceModelManager sharedManger].itemModelThree.currentChildItms.count;
    }else{
        return [LMSpaceModelManager sharedManger].itemModel.currentChildItms.count;
    }
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    if ([LMSpaceModelManager sharedManger].itemModel.currentItem == nil) {
        return nil;
    }
    LMItem *item;
    if (tableView == self.tableViewOne) {
        item = [LMSpaceModelManager sharedManger].itemModelOne.currentChildItms[row];
    }else if (tableView == self.tableViewTwo){
        item = [LMSpaceModelManager sharedManger].itemModelTwo.currentChildItms[row];
    }else if (tableView == self.tableViewThree){
        item = [LMSpaceModelManager sharedManger].itemModelThree.currentChildItms[row];
    }else{
        item = [LMSpaceModelManager sharedManger].itemModel.currentChildItms[row];
    }
    LMSpaceTableRowView * rowView = [tableView makeViewWithIdentifier:LMSpaceTableRowIdentifier owner:self];
   
    [rowView initUI];
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSImage *image = [workspace iconForFile:item.fullPath];
    if ([LMThemeManager isHiddenItemForPath:item.fullPath]) {
        [rowView setIcon:image isHidden:YES];
    }else{
        [rowView setIcon:image isHidden:NO];
    }
    
    [rowView setNameStr:item.fileName];
    [rowView setSizeStr:item.sizeInBytes];
    rowView.fullPath = item.fullPath;
    if(item.isDirectory == YES){
        [rowView countStrIsHidden:NO];
        NSArray *subArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:item.fullPath error:nil];
        if (subArr != nil && subArr.count > 0) {
            [rowView setCountStr:subArr.count];
        }else{
            [rowView setCountStr:0];
        }
        [rowView nextButtonIsHidden:NO];
    }else{
        
//        NSURL *url = [NSURL fileURLWithPath:item.fullPath];
//        url getResourceValue:<#(out id  _Nullable __autoreleasing * _Nonnull)#> forKey:(nonnull NSURLResourceKey) error:<#(out NSError *__autoreleasing  _Nullable * _Nullable)#>
        
        NSString *fileType = [[NSWorkspace sharedWorkspace] typeOfFile:item.fullPath error:nil];
        NSString *desc = [[NSWorkspace sharedWorkspace] localizedDescriptionForType:fileType];
        [rowView setType:desc];
        [rowView nextButtonIsHidden:YES];
    }
    
    return rowView;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 52;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    
    return YES;
}

#pragma mark - QLPreviewItem

- (NSURL *)previewItemURL {
    return  self.showUrl;
}

#pragma mark - 私有

//建立可视化-右侧图-bar
- (void)initBarWiht:(NSMutableArray *)array {
    __block long fileNum =0;
    __block long fileFolderNum = 0;
    NSString *sizeString = @"0";
    if(array == nil || array.count == 0){
        
    }else{
        [array enumerateObjectsUsingBlock:^(LMItem *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.isDirectory) {
                fileFolderNum ++;
            }else{
                fileNum ++;
            }
        }];
        LMItem *item = array[0];
        sizeString = [self changeSizeStr:item.parentDirectory.sizeInBytes];
    }
    
    NSMutableAttributedString *subFileSizeText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",sizeString]];
    [subFileSizeText addAttribute:NSForegroundColorAttributeName
                 value:[NSColor colorWithRed:255/255.0 green:169/255.0 blue:8/255.0 alpha:1/1.0]
                 range:NSMakeRange(0, subFileSizeText.length)];
    self.subFileSize.attributedStringValue = subFileSizeText;
    
    NSMutableAttributedString *subFileNumText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld",fileNum]];
    [subFileNumText addAttribute:NSForegroundColorAttributeName
                 value:[NSColor colorWithRed:255/255.0 green:169/255.0 blue:8/255.0 alpha:1/1.0]
                 range:NSMakeRange(0, subFileNumText.length)];
    self.subFileNum.attributedStringValue = subFileNumText;
    
    NSMutableAttributedString *subFileFolderNumText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld",fileFolderNum]];
    [subFileFolderNumText addAttribute:NSForegroundColorAttributeName
                 value:[NSColor colorWithRed:255/255.0 green:169/255.0 blue:8/255.0 alpha:1/1.0]
                range:NSMakeRange(0, subFileFolderNumText.length)];
    self.subFileFolderNum.attributedStringValue = subFileFolderNumText;

}

//数据初始化-视图初始化
- (void)initItemData:(LMItem *)item {
    
    [[LMSpaceModelManager sharedManger] itemModelNeedInit];
    
    NSString *title = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Disk Analyzer - Avail. %@ / Total %@", nil, [NSBundle bundleForClass:[self class]], @""),[self changeSizeStr:[self getAllUsableBytes]],[self changeSizeStr:[self getAllBytes]]];
    
    self.headerTitle.stringValue = title;
 
    
    [self.tableViewOne scrollRowToVisible:0];
    [self.tableViewOne selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:false];
    [self.tableViewTwo scrollRowToVisible:0];
    [self.tableViewTwo selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:false];
    [self.tableViewThree scrollRowToVisible:0];
    [self.tableViewThree selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:false];
    self.leftButton.enabled = NO;
    self.rightButton.enabled = NO;
    //初始化top
    [LMSpaceModelManager sharedManger].itemModel.topItem = item;
    //当前item
    [LMSpaceModelManager sharedManger].itemModel.currentItem = item;
    //当前item数组
    [[LMSpaceModelManager sharedManger].itemModel.currentItems addObject:item];
    
    if (item.childItems.count > 0) {
        LMItem *currentItem = item.childItems[0];
        self.parentFileName.stringValue = currentItem.fileName;
    }else{
        self.parentFileName.stringValue = @"Macintosh HD";
    }
    
    
    [self setupViewMode:item];

    
    if (self.isVisualMode == NO) {
        [self setupListMode];
        self.isVisualMode = NO;
        self.listModeBigView.hidden = NO;
        self.tableView.hidden = YES;
        self.spaceBigView.hidden = YES;
        [self.visualizedView.subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
    }
    
}

//建立可视化-左侧列表
- (void)setupViewMode:(LMItem *)item {
    if (item == nil) {
        return;
    }
    
    int num = -1;
    [self.visualizedView.subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    
    if (item.childItems != nil && item.childItems.count > 0) {
        if ([LMSpaceModelManager sharedManger].itemModel.remindItems.count > 0) {
            num = (int)[self findIdxFromChildItms:[[LMSpaceModelManager sharedManger].itemModel.remindItems lastObject] arr:item.childItems];
        }
        //排序
        [LMSpaceModelManager sharedManger].itemModel.currentChildItms = item.childItems;
        LMItem *grandsonItem;
        if (num == -1) {
            grandsonItem  = [LMSpaceModelManager sharedManger].itemModel.currentChildItms[0];
        }else{
            grandsonItem  = [LMSpaceModelManager sharedManger].itemModel.currentChildItms[num];
        }
        self.parentFileName.stringValue = grandsonItem.fileName;
        if (grandsonItem.isDirectory == YES) {
            [self setSpaceVie:grandsonItem.childItems];
            self.fileBigView.hidden = YES;
            self.visualizedViewBar.hidden = NO;
            self.visualizedView.hidden = NO;
        }else{
            self.fileBigView.hidden = NO;
            self.visualizedViewBar.hidden = YES;
            self.visualizedView.hidden = YES;
            self.fileName.stringValue = grandsonItem.fileName;
            self.filePath.path = grandsonItem.fullPath;
            self.fileSize.stringValue = [self changeSizeStr:grandsonItem.sizeInBytes];
            self.showUrl = [NSURL fileURLWithPath:grandsonItem.fullPath];
            __weak typeof(self) weakSelf = self;
            [self.previewView setPreviewItem:weakSelf];
            [self.previewView refreshPreviewItem];
        }
    }
    [self.tableView reloadData];
    [self setPathControlUrl:item.fullPath];
    if(num != -1){
        [self.tableView scrollRowToVisible:num];
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:num] byExtendingSelection:false];
    }else{
        [self.tableView scrollRowToVisible:0];
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:false];
    }
}

//建立非可视化列表
- (void)setupListMode {
    [LMSpaceModelManager sharedManger].itemModelOne = [[LMSpaceModel alloc] init];
    [LMSpaceModelManager sharedManger].itemModelTwo = [[LMSpaceModel alloc] init];
    [LMSpaceModelManager sharedManger].itemModelThree = [[LMSpaceModel alloc] init];

 
    [self.tableViewOne deselectRow:self.tableViewOne.selectedRow];
    [self.tableViewTwo deselectRow:self.tableViewTwo.selectedRow];
    [self.tableViewThree deselectRow:self.tableViewThree.selectedRow];
    
    if([LMSpaceModelManager sharedManger].itemModel.currentItems == nil || [LMSpaceModelManager sharedManger].itemModel.currentItems.count == 0){
        return;
    }
    
    if ([LMSpaceModelManager sharedManger].itemModel.currentItems.count == 1) {
        [LMSpaceModelManager sharedManger].itemModelOne.currentItem = [[LMSpaceModelManager sharedManger].itemModel.currentItems lastObject];
        [LMSpaceModelManager sharedManger].itemModelOne.currentChildItms = [LMSpaceModelManager sharedManger].itemModelOne.currentItem.childItems;
        [self reloadDataTableView];
        [self.tableViewOne scrollRowToVisible:self.tbOneCurrentRow];
        [self.tableViewOne selectRowIndexes:[NSIndexSet indexSetWithIndex:self.tbOneCurrentRow] byExtendingSelection:false];
        [self setPathControlUrl:[LMSpaceModelManager sharedManger].itemModelOne.currentItem.fullPath];
        self.lineTwo.hidden = YES;
        self.lineThree.hidden = YES;
    }else if ([LMSpaceModelManager sharedManger].itemModel.currentItems.count == 2) {
        [LMSpaceModelManager sharedManger].itemModelTwo.currentItem = [[LMSpaceModelManager sharedManger].itemModel.currentItems lastObject];
        [LMSpaceModelManager sharedManger].itemModelTwo.currentChildItms = [LMSpaceModelManager sharedManger].itemModelTwo.currentItem.childItems;
        
        [LMSpaceModelManager sharedManger].itemModelOne.currentItem = [[LMSpaceModelManager sharedManger].itemModel.currentItems objectAtIndex:[LMSpaceModelManager sharedManger].itemModel.currentItems.count-2];
        [LMSpaceModelManager sharedManger].itemModelOne.currentChildItms = [LMSpaceModelManager sharedManger].itemModelOne.currentItem.childItems;
        [self reloadDataTableView];
        [self setPathControlUrl:[LMSpaceModelManager sharedManger].itemModel.currentItem.fullPath];
        
        NSUInteger idx = [self findIdxFromChildItms:[LMSpaceModelManager sharedManger].itemModelTwo.currentItem arr:[LMSpaceModelManager sharedManger].itemModelOne.currentChildItms];
        [self.tableViewOne scrollRowToVisible:idx];
        [self.tableViewOne selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:false];
        
        [self setPathControlUrl:[LMSpaceModelManager sharedManger].itemModelTwo.currentItem.fullPath];
        
        self.lineTwo.hidden = NO;
        self.lineThree.hidden = YES;
    }else if ([LMSpaceModelManager sharedManger].itemModel.currentItems.count >= 3) {
        [LMSpaceModelManager sharedManger].itemModelThree.currentItem = [[LMSpaceModelManager sharedManger].itemModel.currentItems lastObject];
        [LMSpaceModelManager sharedManger].itemModelThree.currentChildItms = [LMSpaceModelManager sharedManger].itemModelThree.currentItem.childItems;
        
        [LMSpaceModelManager sharedManger].itemModelTwo.currentItem = [[LMSpaceModelManager sharedManger].itemModel.currentItems objectAtIndex:[LMSpaceModelManager sharedManger].itemModel.currentItems.count-2];
        [LMSpaceModelManager sharedManger].itemModelTwo.currentChildItms = [LMSpaceModelManager sharedManger].itemModelTwo.currentItem.childItems;
        
        [LMSpaceModelManager sharedManger].itemModelOne.currentItem = [[LMSpaceModelManager sharedManger].itemModel.currentItems objectAtIndex:[LMSpaceModelManager sharedManger].itemModel.currentItems.count-3];
        [LMSpaceModelManager sharedManger].itemModelOne.currentChildItms = [LMSpaceModelManager sharedManger].itemModelOne.currentItem.childItems;
        
        [self reloadDataTableView];
        [self setPathControlUrl:[LMSpaceModelManager sharedManger].itemModel.currentItem.fullPath];
        
        NSUInteger idx = [self findIdxFromChildItms:[LMSpaceModelManager sharedManger].itemModelTwo.currentItem arr:[LMSpaceModelManager sharedManger].itemModelOne.currentChildItms];
        [self.tableViewOne scrollRowToVisible:idx];
        [self.tableViewOne selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:false];
        
        NSUInteger idx2 = [self findIdxFromChildItms:[LMSpaceModelManager sharedManger].itemModelThree.currentItem arr:[LMSpaceModelManager sharedManger].itemModelTwo.currentChildItms];
        [self.tableViewTwo scrollRowToVisible:idx2];
        [self.tableViewTwo selectRowIndexes:[NSIndexSet indexSetWithIndex:idx2] byExtendingSelection:false];
        
        [self setPathControlUrl:[LMSpaceModelManager sharedManger].itemModelThree.currentItem.fullPath];
        self.lineTwo.hidden = NO;
        self.lineThree.hidden = NO;
    }
    if ([LMSpaceModelManager sharedManger].itemModel.currentItems.count > 1) {
        self.leftButton.enabled = YES;
    }else{
        self.leftButton.enabled = NO;
    }

}

//建立可视化-右侧图-图
- (void)setSpaceVie:(NSMutableArray *)array {
    [self initBarWiht:array];
    if(array == nil || array.count == 0){
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:CGRectMake(0, 0, 150, 150)];
        imageView.image = [NSImage imageNamed:@"icon_no_file" withClass:self.class];
        [self.visualizedView addSubview:imageView];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.visualizedView);
        }];
        
        return;
    }
    //数据预备处理
    //提取最多提取12且不为0的数
    NSMutableArray *sizeArr = [NSMutableArray array];
    
    __block int arrNum = 0;
    if (array != nil && array.count >0) {
        [array enumerateObjectsUsingBlock:^(LMItem *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(obj.sizeInBytes != 0 && arrNum < 30){
                arrNum ++;
                [sizeArr addObject:@(obj.sizeInBytes)];
            }
        }];
    }
    if (sizeArr.count == 0) {
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:CGRectMake(0, 0, 150, 150)];
        imageView.image = [NSImage imageNamed:@"icon_no_file" withClass:self.class];
        [self.visualizedView addSubview:imageView];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.visualizedView);
        }];
        
        return;
    }
    
    //12个数做log运算
    sizeArr = [self changeNumToLog:sizeArr];
    
    NSRect treeMapRect = CGRectMake(self.visualizedView.frame.origin.x + 5, self.visualizedView.frame.origin.y + 10, self.visualizedView.frame.size.width - 24, self.visualizedView.frame.size.height - 15);
    
    LMBigSpaceView *spaceView = [[LMBigSpaceView alloc] initWithFrame:self.visualizedView.bounds];
    spaceView.wantsLayer = YES;
    [self.visualizedView addSubview:spaceView];

    NSArray<NSNumber *> *values = sizeArr;
    YMTreeMap *tm = [[YMTreeMap alloc] initWithValues:values];
    NSArray<NSValue *> *treeMapRects = [tm tessellateInRect:treeMapRect];
    
    for (int num = 0; num < treeMapRects.count; num ++ ) {
        NSValue *rectVal = treeMapRects[num];
        NSRect spaceViewRect1 = CGRectMake(rectVal.rectValue.origin.x + 3, rectVal.rectValue.origin.y + 3, rectVal.rectValue.size.width - 6, rectVal.rectValue.size.height - 6);
        LMSpaceView *view = [[LMSpaceView alloc] initWithFrame:spaceViewRect1];
        view.delegate = self;
        view.moveDelegate = spaceView;
        view.item = array[num];
        [spaceView addSubview:view];
    }
}

- (void)cleanModel {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LEMON_SPACE_RESULT_NEED_CLEAN" object:nil userInfo:nil];
}

#pragma mark - 工具方法

- (void)reloadDataTableView {
    [self.tableViewOne reloadData];
    [self.tableViewTwo reloadData];
    [self.tableViewThree reloadData];
}


- (float)getAllUsableBytes {
    if (@available(macOS 10.13, *)) {
        NSError *error = nil;
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:NSHomeDirectory()];
        NSDictionary *results = [fileURL resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForImportantUsageKey] error:&error];
        if (!results) {
            NSLog(@"Error retrieving resource keys");
            return 0;
        }
        return [[results objectForKey:NSURLVolumeAvailableCapacityForImportantUsageKey] longLongValue];
    }else{
        NSError *error = nil;
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:NSHomeDirectory()];
        NSDictionary *results = [fileURL resourceValuesForKeys:@[NSURLVolumeAvailableCapacityKey] error:&error];
        if (!results) {
            NSLog(@"Error retrieving resource keys");
            return 0;
        }
        return [[results objectForKey:NSURLVolumeAvailableCapacityKey] longLongValue];
    }
}

- (float)getAllBytes {
    NSError *error = nil;
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:NSHomeDirectory()];
    NSDictionary *results = [fileURL resourceValuesForKeys:@[NSURLVolumeTotalCapacityKey] error:&error];
    if (!results) {
        NSLog(@"Error retrieving resource keys");
        return 0;
    }
    return [[results objectForKey:NSURLVolumeTotalCapacityKey] longLongValue];
}

- (NSMutableArray *)changeNumToLog:(NSMutableArray *)array {
    
    NSMutableArray *sizeArr = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(NSNumber *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        long long num = log(obj.longLongValue) * log(obj.longLongValue)*log(obj.longLongValue) * log(obj.longLongValue) * log(obj.longLongValue) * log(obj.longLongValue)*log(obj.longLongValue) * log(obj.longLongValue) * log(obj.longLongValue) * log(obj.longLongValue)*log(obj.longLongValue) * log(obj.longLongValue);

        if (idx > 0) {
            double firstNum = ((NSNumber *)sizeArr.firstObject).longLongValue;
            double ratio = num/(firstNum * 1.0);
            if (ratio > 0.02) {
                [sizeArr addObject:@(num)];
            }
        }else{
            [sizeArr addObject:@(num)];
        }
    }];
    return sizeArr;
}

- (NSString *)changeSizeStr:(long long)text {
    float resultSize = 0.0;
    NSString *fileSizeStr;
    if (text < 1000000){
        resultSize = text/1000.0;
        fileSizeStr = [NSString stringWithFormat:@"%0.2fKB",resultSize];
    }else if(text < 1000000000){
        resultSize = text/1000000.0;
        fileSizeStr = [NSString stringWithFormat:@"%0.2fMB",resultSize];
    }else{
        resultSize = text/1000000000.0;
        fileSizeStr = [NSString stringWithFormat:@"%0.2fGB",resultSize];
    }
    
    return fileSizeStr;
}

- (NSUInteger)findIdxFromCurrentItems:(NSString *)path {
    __block NSUInteger num = 0;
    [[LMSpaceModelManager sharedManger].itemModel.currentItems enumerateObjectsUsingBlock:^(LMItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([path isEqualToString:obj.fullPath]) {
            num = idx;
        }
    }];
    return num;
}

- (NSUInteger)findIdxFromChildItms:(LMItem *)item arr:(NSMutableArray *)arr {
    __block NSUInteger num = 0;
    [arr enumerateObjectsUsingBlock:^(LMItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (item == obj) {
            num = idx;
        }
    }];
    return num;
}

#pragma mark - 切换主题通知

-(void)viewWillLayout{
    [super viewWillLayout];
    if ([LMThemeManager cureentTheme] == YES) {
        self.listModeBigView.layer.backgroundColor = [NSColor colorWithRed:37/255.0 green:38/255.0 blue:50/255.0 alpha:1.0].CGColor;
        self.tableView.backgroundColor = [NSColor colorWithRed:37/255.0 green:38/255.0 blue:50/255.0 alpha:1/1.0];
        self.tableViewOne.backgroundColor = [NSColor colorWithRed:37/255.0 green:38/255.0 blue:50/255.0 alpha:1/1.0];
        self.tableViewTwo.backgroundColor = [NSColor colorWithRed:37/255.0 green:38/255.0 blue:50/255.0 alpha:1/1.0];
        self.tableViewThree.backgroundColor = [NSColor colorWithRed:37/255.0 green:38/255.0 blue:50/255.0 alpha:1/1.0];
        
        self.fileName.textColor = [NSColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1/1.0];
        self.fileSize.textColor = [NSColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1/1.0];
        self.totalText.textColor = [NSColor colorWithHex:0x989A9E];
        self.fileText.textColor = [NSColor colorWithHex:0x989A9E];
        self.fileFolderText.textColor = [NSColor colorWithHex:0x989A9E];
    }else{
        self.tableView.backgroundColor = [NSColor whiteColor];
        self.tableViewOne.backgroundColor = [NSColor whiteColor];
        self.tableViewTwo.backgroundColor = [NSColor whiteColor];
        self.tableViewThree.backgroundColor = [NSColor whiteColor];
        self.listModeBigView.layer.backgroundColor = [NSColor whiteColor].CGColor;
        self.totalText.textColor = [NSColor colorWithHex:0x515151];
        self.fileText.textColor = [NSColor colorWithHex:0x515151];
        self.fileFolderText.textColor = [NSColor colorWithHex:0x515151];
        
        self.fileName.textColor = [NSColor colorWithRed:81/255.0 green:81/255.0 blue:81/255.0 alpha:1/1.0];
        self.fileSize.textColor = [NSColor colorWithRed:81/255.0 green:81/255.0 blue:81/255.0 alpha:1/1.0];
    }
    if ([LMThemeManager cureentTheme] == YES) {
        self.visualizedView.layer.backgroundColor = [NSColor colorWithRed:38/255.0 green:38/255.0 blue:40/255.0 alpha:0.2/1.0].CGColor;
        self.visualizedViewBar.layer.backgroundColor = [NSColor colorWithRed:38/255.0 green:38/255.0 blue:40/255.0 alpha:0.2/1.0].CGColor;
    }else{
        self.visualizedView.layer.backgroundColor = [NSColor colorWithRed:222/255.0 green:228/255.0 blue:235/255.0 alpha:0.2/1.0].CGColor;
        self.visualizedViewBar.layer.backgroundColor = [NSColor colorWithRed:222/255.0 green:228/255.0 blue:235/255.0 alpha:0.2/1.0].CGColor;
    }
}

#pragma mark - over

- (void)windowWillClose:(NSNotification *)notification {
     [self cleanModel];
}

- (void)dealloc {
//    NSLog(@"__%s__",__FUNCTION__);
}

@end
