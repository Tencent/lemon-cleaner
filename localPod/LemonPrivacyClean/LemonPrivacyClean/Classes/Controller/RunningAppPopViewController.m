//
//  RunningAppPopViewController.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "RunningAppPopViewController.h"
#import <QMUICommon/LMViewHelper.h>
#import <Masonry/Masonry.h>
#import "BrowserAppTableCellView.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/LMGradientTitleButton.h>
#import "QMUICommon/LMBorderButton.h"
#import "QMUICommon/LMRectangleButton.h"
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/MMScroller.h>

@interface RunningAppPopViewController () <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate>

@property(strong) NSTextField *runningAppsLabel;

@property(strong) NSArray *browserApps;

@property(weak) PrivacyResultViewController *superViewController;


@end

@implementation RunningAppPopViewController

// apps: not null
- (instancetype)initWithApps:(NSArray *)apps superController:(PrivacyResultViewController *)controller {
    self = [super init];
    if (self) {
        self.browserApps = apps;
        self.superViewController = controller;
        [self loadView];
    }

    return self;
}

- (void)loadView {
    NSRect rect = NSMakeRect(0, 0, 342, 370);
    NSView *view = [[NSView alloc] initWithFrame:rect];

//    view.wantsLayer = YES;
//    view.layer.backgroundColor = [NSColor whiteColor].CGColor;
    view.layer.cornerRadius = 5;
    view.layer.masksToBounds = YES;
    self.view = view;
    [self viewDidLoad];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupWindow];
    [self setupViews];
    [self updateLabel];
}

- (void)viewWillAppear {
    NSWindow *window = self.view.window;
    if (window) {
        window.titleVisibility = NSWindowTitleHidden;
        window.titlebarAppearsTransparent = YES;
        window.styleMask = NSWindowStyleMaskFullSizeContentView ;

        
        window.opaque = NO;
        window.showsToolbarButton = NO;
//        window.movableByWindowBackground = YES; //window 可随拖动移动
        [window setBackgroundColor:[NSColor clearColor]];
        
        CGFloat xPos = NSWidth([[window screen] frame])/2 - NSWidth([window frame])/2;
        CGFloat yPos = NSHeight([[window screen] frame])/2 - NSHeight([window frame])/2;
        if(_parentViewController){
            NSWindow *parentWindow = _parentViewController.view.window;
            if (parentWindow) {
                xPos = NSWidth([parentWindow frame])/2 - NSWidth([window frame])/2 + parentWindow.frame.origin.x;
                yPos = NSHeight([parentWindow frame])/2 - NSHeight([window frame])/2 + parentWindow.frame.origin.y;
            }
        }
     
        [window setFrame:NSMakeRect(xPos, yPos, NSWidth([window frame]), NSHeight([window frame])) display:YES];
    }
}

- (void)setupViews {

    NSImageView *alertImageView = [[NSImageView alloc] init];
    [self.view addSubview:alertImageView];
    alertImageView.image = [NSImage imageNamed:@"alert" withClass:self.class];
    alertImageView.imageScaling = NSImageScaleProportionallyUpOrDown;

    NSTextField *runningAppsLabel = [LMViewHelper createNormalLabel:16 fontColor:[LMAppThemeHelper getTitleColor]];
    [self.view addSubview:runningAppsLabel];
    self.runningAppsLabel = runningAppsLabel;

    MMScroller *scroller = [[MMScroller alloc] init];
    NSScrollView *container = [[NSScrollView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    [container setVerticalScroller:scroller];
    container.autohidesScrollers = YES;
    [self.view addSubview:container];
    
    container.drawsBackground = NO;
    container.hasVerticalScroller = YES;
    container.hasHorizontalScroller = NO;

    NSButton *killAllButton = [LMViewHelper createSmallGreenButton:12 title:NSLocalizedStringFromTableInBundle(@"RunningAppPopViewController_setupViews_killAllButton _1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.view addSubview:killAllButton];
    killAllButton.wantsLayer = YES;
    killAllButton.layer.cornerRadius = 2;
    killAllButton.target = self;
    killAllButton.action = @selector(killAllAppsButtonClick);

    
    LMBorderButton *cancelButton = [[LMBorderButton alloc] init];
    [self.view addSubview:cancelButton];
    cancelButton.title = NSLocalizedStringFromTableInBundle(@"RunningAppPopViewController_setupViews_cancelButton_2", nil, [NSBundle bundleForClass:[self class]], @"");
    cancelButton.target = self;
    cancelButton.action = @selector(cancelKillButtonClick);
    cancelButton.font = [NSFont systemFontOfSize:12];

    NSTableView *tableView = [[NSTableView alloc] init];
    tableView.backgroundColor = [LMAppThemeHelper getMainBgColor];
    
    container.documentView = tableView;
    tableView.headerView = nil;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;

    NSTableColumn *col1 = [[NSTableColumn alloc] initWithIdentifier:@"col1"];
    col1.resizingMask = NSTableColumnAutoresizingMask;
    col1.editable = NO;
    [tableView addTableColumn:col1];
    [tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
    [tableView sizeLastColumnToFit];

    [alertImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(34);
        make.left.equalTo(self.view).offset(23);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(40);
    }];

    [runningAppsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(alertImageView.mas_right).offset(23);
        make.centerY.equalTo(alertImageView);
    }];

    [killAllButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(24);
        make.right.equalTo(self.view).offset(-20);
        make.bottom.equalTo(self.view).offset(-10);
    }];

    [cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(24);
        make.right.equalTo(killAllButton.mas_left).offset(-10);
        make.centerY.equalTo(killAllButton);
    }];


    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(25);
        make.right.mas_equalTo(self.view).offset(-30);
        make.top.mas_equalTo(self.view).offset(102);
        make.bottom.mas_equalTo(self.view).offset(-50);
    }];

    // 这里可以改变 container 的大小, 进一步改变 self.view 的大小
//    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.width.mas_equalTo(container);
//        make.height.mas_equalTo(container);
//    }];
}


// MARK :[self dismissController:nil];  (被弹出的页面调用)   [self dismissViewController:vc]; (弹出者调用)
// dismissController 不会触发 window 的 shouldClose willClose 方法
- (void)killAllAppsButtonClick {
    NSLog(@"killAllAppsButtonClick ...");
    [self dismissController:nil];
    if (self.superViewController) {
//        [self.superViewController startToInnerScan:self.browserApps needKill:YES];
        [self.superViewController cleanActionWithRunningApps:self.browserApps needKill:YES];
    }
}

- (void)cancelKillButtonClick {
    NSLog(@"cancelKillButtonClick ...");
    [self dismissController:nil];
}

- (void)setupWindow {
    self.view.window.delegate = self;
    self.view.window.title = @"";
    self.title = @"";
}

- (void)killSimpleAppAndCloseWindow:(BrowserApp *)app {
    NSLog(@"killAppAndCloseWindow ...");
    [self dismissController:nil];
    if (self.superViewController) {
//        [self.superViewController startToInnerScan:@[app] needKill:YES];
        [self.superViewController cleanActionWithRunningApps:@[app] needKill:YES];
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    id sender = notification.object;
    NSLog(@"windowWillClose ... sender is %@", sender);
}

- (BOOL)windowShouldClose:(NSWindow *)sender {
    NSLog(@"windowShouldClose ... sender is %@", sender);
    return YES;
}

- (void)updateLabel {
    NSInteger runningNum = 0;
    for (BrowserApp *app in self.browserApps) {
        if (app.isRunning) {
            runningNum++;
        }
    }

    if (runningNum > 0) {

        NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc]init];
        paragraph.lineSpacing = 6.0;
        NSDictionary *normalAttributes = @{
                                           NSForegroundColorAttributeName:[LMAppThemeHelper getTitleColor],
                                           NSFontAttributeName: [NSFontHelper getRegularSystemFont:16],
                                           NSParagraphStyleAttributeName: paragraph
                                           };
        NSString *showString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"RunningAppPopViewController_updateLabel_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""), runningNum];
        NSAttributedString *attributeString = [[NSAttributedString alloc]initWithString:showString attributes:normalAttributes];
        self.runningAppsLabel.attributedStringValue = attributeString;
    }
}


- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 50;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.browserApps == nil ? 0 : self.browserApps.count;
}


- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *tableColumnIdentifier = tableColumn.identifier;
    BrowserAppTableCellView *cell = [tableView makeViewWithIdentifier:tableColumnIdentifier owner:nil];

    BrowserApp *app = self.browserApps[(NSUInteger) row];
    if (!cell) {
        cell = [[BrowserAppTableCellView alloc] init];
        cell.identifier = tableColumnIdentifier;
    }

    cell.controller = self;
    [cell updateViewsBy:app];

    return cell;
}
@end
