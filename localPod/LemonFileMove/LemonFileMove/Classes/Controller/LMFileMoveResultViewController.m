//
//  LMFileMoveResultViewController.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveResultViewController.h"
#import "LMFileMoveResultSuccessView.h"
#import "LMFileMoveManger.h"
#import "LMFileMoveCommonDefines.h"

#import <QMUICommon/QMBaseWindowController.h>
#import <QMUICommon/LMBorderButton.h>

#import "LMFileMoveResultFailureRowView.h"
#import "LMFileMoveResultFailureCategoryCell.h"
#import "LMFileMoveResultFailureSubCategoryCell.h"
#import "LMFileMoveResultFailureFileCell.h"

#import "LMResultItem.h"
#import "LMFileMoveFeatureDefines.h"

@interface LMFileMoveResultViewController () <NSOutlineViewDelegate, NSOutlineViewDataSource>

@property (nonatomic, strong) LMFileMoveResultSuccessView *successView;

@property (nonatomic, strong) NSOutlineView *outlineView;
@property (nonatomic, strong) NSMutableArray *appArr;

@end

@implementation LMFileMoveResultViewController

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:CGRectMake(0, 0, 1000, 618)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)viewWillLayout {
    [super viewWillLayout];
    [self.outlineView setBackgroundColor:lm_backgroundColor()];
}

- (void)showSuccessView {
    LMFileMoveManger *fileManager = [LMFileMoveManger shareInstance];
    self.successView = [LMFileMoveResultSuccessView resultViewWithType:fileManager.targetPathType
                                                          releaseSpace:fileManager.selectedFileSize
                                                        targetFilePath:fileManager.targetPath];
    [self.view addSubview:self.successView];
    [self.successView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    __weak typeof(self) weakSelf = self;
    self.successView.showInFinderLabelOnClickHandler = ^{
        [weakSelf showTargetFileInFinder];
    };
    
    self.successView.returnButtonClickHandler = ^{
        [weakSelf launchLemonApp];
    };
}

- (void)showFailureView {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self _setupFailureData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _setupFailureView];
        });
    });
}

- (void)_setupFailureData {
    NSArray *array = [LMFileMoveManger shareInstance].appArr;
    NSMutableArray <LMAppCategoryItem *> *resultArray = [NSMutableArray array];
    for (LMAppCategoryItem *appItem in array) {
        if (appItem.isMoveFailed) {
            LMAppCategoryItem *copyAppItem = [appItem copy];
            copyAppItem.subItems = [NSMutableArray array];
            [resultArray addObject:copyAppItem];

            for (LMFileCategoryItem *fileItem in appItem.subItems) {
                if (fileItem.isMoveFailed) {
                    LMFileCategoryItem *copyFileItem = [fileItem copy];
                    copyFileItem.subItems = [NSMutableArray array];
                    [copyAppItem.subItems addObject:copyFileItem];
                    
                    for (LMResultItem *resultItem in fileItem.subItems) {
                        if (resultItem.isMoveFailed) {
                            [copyFileItem.subItems addObject:resultItem];
                        }
                    }
                }
            }
        }
    }
    
    self.appArr = resultArray;
}

- (void)_setupFailureView {
    LMFileMoveManger *fileMoveManager = [LMFileMoveManger shareInstance];
    NSTextField *titleLabel = [NSTextField labelWithStringCompat:LM_LOCALIZED_STRING(@"Done")];
    titleLabel.font = [NSFont systemFontOfSize:32];
    [LMAppThemeHelper setTitleColorForTextField:titleLabel];
    [self.view addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(50);
        make.top.equalTo(self.view).offset(70);
    }];
    
    NSTextField *detailLabel = [NSTextField labelWithStringCompat:@""];
    detailLabel.font = [NSFont systemFontOfSize:14];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    LM_APPEND_ATTRIBUTED_STRING(text, LM_LOCALIZED_STRING(@"Transferred "), LM_COLOR_GRAY, 14);
    long long movedFileSize = fileMoveManager.movedFileSize - fileMoveManager.moveFailedFileSize;
    NSString *movedFileSizeText = [[LMFileMoveManger shareInstance] sizeNumChangeToStr:movedFileSize];
    LM_APPEND_ATTRIBUTED_STRING(text, movedFileSizeText, LM_COLOR_YELLOW, 16);
    detailLabel.attributedStringValue = text;
    [self.view addSubview:detailLabel];
    [detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleLabel);
        make.top.equalTo(titleLabel.mas_bottom).offset(8);
    }];
    
    NSTextField *showInFinderLabel = [NSTextField labelWithStringCompat:LM_LOCALIZED_STRING(@"Show in Finder")];
    showInFinderLabel.font = [NSFont systemFontOfSize:14];
    showInFinderLabel.textColor = LM_COLOR_BLUE;
    [self.view addSubview:showInFinderLabel];
    NSClickGestureRecognizer *recognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(showTargetFileInFinder)];
    [showInFinderLabel addGestureRecognizer:recognizer];
    [showInFinderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(detailLabel.mas_right).offset(8);
        make.centerY.equalTo(detailLabel);
    }];
    
    LMBorderButton *returnButton = [[LMBorderButton alloc] init];
    [self.view addSubview:returnButton];
    returnButton.title = LM_LOCALIZED_STRING(@"Back to Menu");
    returnButton.target = self;
    returnButton.action = @selector(launchLemonApp);
    returnButton.fontSize = 20;
    returnButton.font = [NSFont systemFontOfSize:20];
    [returnButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-50);
        make.top.equalTo(self.view).offset(76);
        make.size.mas_equalTo(CGSizeMake(148, 48));
    }];
       
    // -----分割线-----
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

    NSTextField *descLabel = [NSTextField labelWithStringCompat:@""];
    NSMutableAttributedString *errorText = [[NSMutableAttributedString alloc] init];
    LM_APPEND_ICON_AND_STRING(errorText, LM_IMAGE_NAMED(@"file_move_error_icon"), CGSizeMake(16, 16), LM_LOCALIZED_STRING(@"Some files failed to export, check space and permissions."), [NSFont systemFontOfSize:14], LM_COLOR_GRAY);
    descLabel.attributedStringValue = errorText;
    descLabel.font = [NSFont systemFontOfSize:14];
    descLabel.textColor = LM_COLOR_GRAY;
    [self.view addSubview:descLabel];
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleLabel);
        make.top.equalTo(lineView.mas_bottom).offset(24);
    }];
    
    NSTableColumn *tableColumn = [[NSTableColumn alloc] init];
    tableColumn.resizingMask = NSTableColumnAutoresizingMask;
    NSOutlineView *outlineView = [[NSOutlineView alloc] init];
    outlineView.delegate = self;
    outlineView.dataSource = self;
    outlineView.allowsColumnResizing = YES;
    outlineView.headerView = nil;
    outlineView.wantsLayer = YES;
    [outlineView setBackgroundColor:lm_backgroundColor()];
    [outlineView addTableColumn:tableColumn];
    self.outlineView = outlineView;
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    scrollView.documentView = outlineView;
    scrollView.hasVerticalScroller = YES;
    scrollView.autohidesScrollers = YES;
    [self.view addSubview:scrollView];
    [scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(descLabel.mas_bottom).offset(15);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
}

#pragma mark - OutlineView Delegate

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item {
    return [[LMFileMoveResultFailureRowView alloc] init];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (!item) {
        return [self.appArr objectAtIndex:index];
    }
    if ([item isKindOfClass:[LMAppCategoryItem class]]) {
        return [[item subItems] objectAtIndex:index];
    } else if ([item isKindOfClass:[LMFileCategoryItem class]]) {
        return [[item subItems] objectAtIndex:index];
    }
    return item;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    if ([item isKindOfClass:[LMAppCategoryItem class]]) {
        return [LMFileMoveResultFailureCategoryCell cellHeight];
    } else if ([item isKindOfClass:[LMFileCategoryItem class]]) {
        return [LMFileMoveResultFailureSubCategoryCell cellHeight];
    } else if ([item isKindOfClass:[LMResultItem class]]) {
        return [LMFileMoveResultFailureFileCell cellHeight];
    }
    return 0;
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
    if (!item) {
        return [self.appArr count];
    }

    if ([item isKindOfClass:[LMAppCategoryItem class]]) {
        return [[item subItems] count];
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
    LMFileMoveResultFailureBaseCell *cell = nil;
    if ([item isKindOfClass:[LMAppCategoryItem class]]) {
        cell = [outlineView makeViewWithIdentifier:[LMFileMoveResultFailureCategoryCell cellID] owner:self];
        if (!cell) {
            cell = [[LMFileMoveResultFailureCategoryCell alloc] init];
            cell.identifier = [LMFileMoveResultFailureCategoryCell cellID];
        }
    } else if ([item isKindOfClass:[LMFileCategoryItem class]]) {
        cell = [outlineView makeViewWithIdentifier:[LMFileMoveResultFailureSubCategoryCell cellID] owner:self];
        if (!cell) {
            cell = [[LMFileMoveResultFailureSubCategoryCell alloc] init];
            cell.identifier = [LMFileMoveResultFailureSubCategoryCell cellID];
        }
    } else if ([item isKindOfClass:[LMResultItem class]]) {
        cell = [outlineView makeViewWithIdentifier:[LMFileMoveResultFailureFileCell cellID] owner:self];
        if (!cell) {
            cell = [[LMFileMoveResultFailureFileCell alloc] init];
            cell.identifier = [LMFileMoveResultFailureFileCell cellID];
        }
    }

    [cell setCellData:item];
    return cell;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return NO;
}

#pragma mark - Action

- (void)showTargetFileInFinder {
    NSString *targetPath = [LMFileMoveManger shareInstance].targetPath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
        [[NSWorkspace sharedWorkspace] selectFile:targetPath
                         inFileViewerRootedAtPath:[targetPath stringByDeletingLastPathComponent]];
    } else {
        [[NSWorkspace sharedWorkspace] selectFile:NSHomeDirectory() inFileViewerRootedAtPath:NSHomeDirectory()];
    }
}

- (void)launchLemonApp {
#ifndef APPSTORE_VERSION
    [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/Tencent Lemon.app"];
#else
    [[NSNotificationCenter defaultCenter] postNotificationName:@"notify_open_lemon_main_page" object:nil];
#endif
    QMBaseWindowController *windowController = self.view.window.windowController;
    [windowController close];
}

@end
