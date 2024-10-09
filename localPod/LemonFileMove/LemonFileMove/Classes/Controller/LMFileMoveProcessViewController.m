//
//  LMFileMoveProcessViewController.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveProcessViewController.h"
#import "QMProgressView.h"
#import "LMFileMoveProcessCell.h"
#import "LMFileMoveCommonDefines.h"
#import "LMFileMoveWnController.h"
#import "LMFileMoveAlertViewController.h"

#import "LMFileMoveManger.h"
#import "LMAppCategoryItem.h"
#import "LMFileMoveProcessCellViewItem.h"

@interface LMFileMoveProcessViewController () <NSTableViewDelegate, NSTableViewDataSource, LMFileMoveMangerDelegate>

@property (nonatomic, strong) NSTextField *titleLabel; // "文件正在搬家"
@property (nonatomic, strong) NSTextField *detailLabel; // "已导出X，共X"
@property (nonatomic, strong) QMProgressView *progressView;

@property (nonatomic, strong) NSTextField *descLabel; // "文件导出至新位置后，原路径文件将被清理"

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTableView *tableView;

@property (nonatomic, strong) NSArray *selectedAppArray;
@property (nonatomic, strong) LMFileMoveProcessCellViewItem *wechatViewItem;
@property (nonatomic, strong) LMFileMoveProcessCellViewItem *qqViewItem;
@property (nonatomic, strong) LMFileMoveProcessCellViewItem *wecomViewItem;

@property (nonatomic, assign) long long lastUpdateCellTime; // 毫秒。避免刷新过于频繁
@property (nonatomic, assign) long long displayMovedFileSize;

@end

@implementation LMFileMoveProcessViewController

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:CGRectMake(0, 0, 1000, 618)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [self _setupViews];
}

- (void)startMoveFile {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self _setupData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _updateHeaderViewWithMovedFileSize:0 totalFileSize:[LMFileMoveManger shareInstance].selectedFileSize];
            [self _updateScrollViewConstraints];
            [self.tableView reloadData];
            [LMFileMoveManger shareInstance].delegate = self;
            [[LMFileMoveManger shareInstance] startMoveFile];
        });
    });
}

#pragma mark - Views

- (void)_setupViews {
    [self _setupHeaderView];
    [self _setupTableView];
}

- (void)_setupHeaderView {
    self.titleLabel = [NSTextField labelWithStringCompat:LM_LOCALIZED_STRING(@"Transferring")];
    self.titleLabel.font = [NSFont systemFontOfSize:32];
    [LMAppThemeHelper setTitleColorForTextField:self.titleLabel];
    [self.view addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(50);
        make.top.equalTo(self.view).offset(59.5);
    }];
    
    self.detailLabel = [NSTextField labelWithStringCompat:@""];
    self.detailLabel.font = [NSFont systemFontOfSize:14];
    [self.view addSubview:self.detailLabel];
    [self.detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleLabel);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.right.equalTo(self.view).offset(-50);
    }];
    
    self.progressView = [[QMProgressView alloc] initWithFrame:NSMakeRect(0, 0, 430, 5)];
    [self.view addSubview:self.progressView];
    self.progressView.borderColor = [NSColor clearColor];
    self.progressView.minValue = 0.0;
    self.progressView.maxValue = 1.0;
    self.progressView.value = 0.0;
    [self.progressView setWantsLayer:YES];
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleLabel);
        make.top.equalTo(self.detailLabel.mas_bottom).offset(16);
        make.size.mas_equalTo(CGSizeMake(430, 5));
    }];
    
    NSView *lineView = [[NSView alloc] init];
    [self.view addSubview:lineView];
    lineView.wantsLayer = YES;
    lineView.layer.backgroundColor = [NSColor colorWithHex:0x9A9A9A alpha:0.2].CGColor;
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(50);
        make.right.equalTo(self.view).offset(-50);
        make.top.equalTo(self.view).offset(167);
        make.height.mas_equalTo(1);
    }];
    
    self.descLabel = [NSTextField labelWithStringCompat:LM_LOCALIZED_STRING(@"Files can not put back to original folder after transfered.")];
    self.descLabel.font = [NSFont systemFontOfSize:14];
    self.descLabel.textColor = LM_COLOR_GRAY;

    [self.view addSubview:self.descLabel];
    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleLabel);
        make.top.equalTo(lineView.mas_bottom).offset(24);
    }];
}

- (void)_setupTableView {
    self.tableView = [[NSTableView alloc] init];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    [self.tableView setAutoresizesSubviews:YES];
    [self.tableView setBackgroundColor:lm_backgroundColor()];
    [self.tableView setHeaderView:nil];
    self.tableView.usesAlternatingRowBackgroundColors = YES;
    if (@available(macOS 11.0, *)) {
        self.tableView.style = NSTableViewStylePlain;
        self.tableView.intercellSpacing = NSMakeSize(0, 0);
    }
    NSTableColumn *portColumn = [[NSTableColumn alloc] initWithIdentifier:[LMFileMoveProcessCell cellID]];
    [self.tableView addTableColumn:portColumn];

    self.scrollView = [[NSScrollView alloc] init];
    [self.scrollView setHasVerticalScroller:YES];
    [self.scrollView setHasHorizontalScroller:NO];
    [self.scrollView setAutohidesScrollers:YES];
    [self.scrollView setAutoresizesSubviews:YES];
    [self.scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [self.scrollView setDocumentView:self.tableView];
    
    self.scrollView.wantsLayer = YES;
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithHex:0x000000 alpha:0.03]];
    [shadow setShadowOffset:NSMakeSize(0,1)];
    shadow.shadowBlurRadius = 24;
    [self.scrollView setShadow:shadow];
    
    [self.view addSubview:self.scrollView];
    [self _updateScrollViewConstraints];
    
    [self.tableView reloadData];
}

#pragma mark - Data

- (void)_setupData {
    NSMutableArray *array = [NSMutableArray array];
    for (LMAppCategoryItem *appItem in [LMFileMoveManger shareInstance].appArr) {
        if (appItem.selecteState != NSControlStateValueOff) {
            [array addObject:appItem];
            
            LMFileMoveProcessCellViewItem *viewItem = [LMFileMoveProcessCellViewItem viewItemWithAppCategoryItem:appItem];
            switch (appItem.type) {
                case LMAppCategoryItemType_WeChat:
                    self.wechatViewItem = viewItem;
                    break;
                case LMAppCategoryItemType_WeCom:
                    self.wecomViewItem = viewItem;
                    break;
                case LMAppCategoryItemType_QQ:
                    self.qqViewItem = viewItem;
                    break;
            }
        }
    }
    
    self.selectedAppArray = array;
    self.lastUpdateCellTime = 0;
}

#pragma mark - Update

- (void)_updateScrollViewConstraints {
    [self.scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.descLabel.mas_bottom).offset(16);
        make.height.mas_equalTo([LMFileMoveProcessCell cellHeight] * self.selectedAppArray.count);
    }];
}

- (void)_updateHeaderViewWithMovedFileSize:(long long)movedFileSize
                             totalFileSize:(long long)totalFileSize {
    self.displayMovedFileSize = MIN(MAX(movedFileSize, self.displayMovedFileSize), totalFileSize);
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    LM_APPEND_ATTRIBUTED_STRING(text, LM_LOCALIZED_STRING(@"Transferred "), LM_COLOR_GRAY, 14);
    NSString *movedFileSizeText = [[LMFileMoveManger shareInstance] sizeNumChangeToStr:self.displayMovedFileSize];
    LM_APPEND_ATTRIBUTED_STRING(text, movedFileSizeText, LM_COLOR_YELLOW, 16);
    LM_APPEND_ATTRIBUTED_STRING(text, LM_LOCALIZED_STRING(@" , total "), LM_COLOR_GRAY, 14);
    NSString *totalFileSizeText = [[LMFileMoveManger shareInstance] sizeNumChangeToStr:totalFileSize];
    LM_APPEND_ATTRIBUTED_STRING(text, totalFileSizeText, LM_COLOR_YELLOW, 16);
    self.detailLabel.attributedStringValue = text;
    
    self.progressView.value = MIN(self.displayMovedFileSize * 1.0 / totalFileSize, 1.0);
}

#pragma mark - NSTableView

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return [LMFileMoveProcessCell cellHeight];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    LMFileMoveProcessCell *cell = [tableView makeViewWithIdentifier:[LMFileMoveProcessCell cellID] owner:self];
    if (!cell) {
        cell = [[LMFileMoveProcessCell alloc] init];
        cell.identifier = [LMFileMoveProcessCell cellID];
        
        LMAppCategoryItem *appItem = self.selectedAppArray[row];        
        cell.viewItem = [self viewItemWithType:appItem.type];
    }
    
    return cell;
}

- (nullable NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return [[LMFileMoveProcessRowView alloc] init];
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView {
    return NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.selectedAppArray.count;
}

#pragma mark - LMFileMoveMangerDelegate

/// 开始移动某个App
- (void)lmFileMoveManager:(LMFileMoveManger *)manager startMovingAppCategoryType:(LMAppCategoryItemType)type {
    LMFileMoveProcessCellViewItem *viewItem = [self viewItemWithType:type];
    viewItem.status = LMFileMoveProcessCellStatusMoving;
}

/// 某个App移动完成
- (void)lmFileMoveManager:(LMFileMoveManger *)manager didFinishMovingAppCategoryType:(LMAppCategoryItemType)type appMoveFailedFileSize:(long long)appMoveFailedFileSize {
    LMFileMoveProcessCellViewItem *viewItem = [self viewItemWithType:type];
    if (appMoveFailedFileSize == 0) {
        viewItem.status = LMFileMoveProcessCellStatusDone;
    } else {
        viewItem.moveFailedFileSize = appMoveFailedFileSize;
        viewItem.status = LMFileMoveProcessCellStatusError;
    }
}

/// 进度更新
- (void)lmFileMoveManager:(LMFileMoveManger *)manager
      updateMovedFileSize:(long long)movedFileSize
            totalFileSize:(long long)totalFileSize {
    long long currentTime = [[NSDate date] timeIntervalSince1970] * 1000;
    if (labs(self.lastUpdateCellTime - currentTime) < 20) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _updateHeaderViewWithMovedFileSize:movedFileSize totalFileSize:totalFileSize];
    });
}

/// 正在移动某个文件
- (void)lmFileMoveManager:(LMFileMoveManger *)manager
           movingFileName:(NSString *)fileName
                 filePath:(NSString *)filePath
                 fileSize:(long long)fileSize
          appCategoryType:(LMAppCategoryItemType)type {
    long long currentTime = [[NSDate date] timeIntervalSince1970] * 1000;
    if (labs(self.lastUpdateCellTime - currentTime) < 20) {
        return;
    }
    self.lastUpdateCellTime = currentTime;

    LMFileMoveProcessCellViewItem *viewItem = [self viewItemWithType:type];
    viewItem.movingFileName = fileName;
    viewItem.movingFileSizeText = [[LMFileMoveManger shareInstance] sizeNumChangeToStr:fileSize];
    
    NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:filePath];
    viewItem.movingFileImage = image;
}

/// 移动完成
- (void)lmFileMoveManager:(LMFileMoveManger *)manager didFinishMovingSuccessfully:(BOOL)isSucceed {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _updateHeaderViewWithMovedFileSize:manager.selectedFileSize totalFileSize:manager.selectedFileSize];

        LMFileMoveWnController *wc = self.view.window.windowController;
        [wc showResultViewWithSuccessStatus:isSucceed];
    });
}

#pragma mark - Public

- (void)showCloseWindowAlert {
    __weak typeof(self) weakSelf = self;

    LMFileMoveAlertViewController *viewController = [[LMFileMoveAlertViewController alloc] initWithImage:LM_IMAGE_NAMED(@"file_move_warning_icon") title:LM_LOCALIZED_STRING(@"Stop the Transfering?") continueButtonTitle:LM_LOCALIZED_STRING(@"Continue") stopButtonTitle:LM_LOCALIZED_STRING(@"Abort") continueHandler:^{
        // 继续导出
    } stopHandler:^{
        [[LMFileMoveManger shareInstance] stopMoveFile];
        [weakSelf.view.window.windowController close];
    }];
    [self presentViewControllerAsModalWindowInCenter:viewController windowSize:LM_FILE_MOVE_ALERT_WINDOW_SIZE];
}

#pragma mark - Private

- (LMFileMoveProcessCellViewItem *)viewItemWithType:(LMAppCategoryItemType)type {
    switch (type) {
        case LMAppCategoryItemType_QQ:
            return self.qqViewItem;
        case LMAppCategoryItemType_WeChat:
            return self.wechatViewItem;
        case LMAppCategoryItemType_WeCom:
            return self.wecomViewItem;
    }
}

- (void)presentViewControllerAsModalWindowInCenter:(NSViewController *)viewController
                                        windowSize:(CGSize)windowSize {
    [self presentViewControllerAsModalWindow:viewController];
    if (viewController.view.window) {
        CGFloat x = NSMidX(self.view.window.frame) - windowSize.width / 2;
        CGFloat y = NSMidY(self.view.window.frame) - windowSize.height / 2;
        [viewController.view.window setFrame:CGRectMake(x, y, windowSize.width, windowSize.height) display:YES];
    }
}

@end
