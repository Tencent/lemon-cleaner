//
//  OwlSelectViewController.m
//  PrivacyProtect
//
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlSelectViewController.h"
#import "OwlTableRowView.h"
#import "Owl2Manager.h"
#import "OwlConstant.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/MMScroller.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/LMBorderButton.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/LMCheckboxButton.h>
#import <QMUICommon/QMStaticField.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/LMReferenceDefines.h>
#import "OwlWhiteListViewController.h"
#import <QMCoreFunction/LanguageHelper.h>
#import "OwlListPlaceHolderView.h"
#import "utilities.h"
#import "OwlConstant.h"


@interface OwlSelectCellView : NSView

@property (nonatomic, strong) LMCheckboxButton *selectCheckBox;
@property (nonatomic, strong) NSImageView *iconImageView;
@property (nonatomic, strong) NSTextField *labelProcess;
@property (nonatomic, strong) NSTextField *labelAppType;

@property (nonatomic, copy) void(^selectedBlock)(BOOL isSelected);
@end

@implementation OwlSelectCellView

- (instancetype)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.selectCheckBox = [[LMCheckboxButton alloc] init];
        self.selectCheckBox.imageScaling = NSImageScaleProportionallyDown;
        self.selectCheckBox.title = @"";
        [self.selectCheckBox setButtonType:NSButtonTypeSwitch];
        self.selectCheckBox.allowsMixedState = NO;
        [self.selectCheckBox setTarget:self];
        [self.selectCheckBox setAction:@selector(selectCheckBoxClicke:)];
        [self addSubview:self.selectCheckBox];
        
        self.iconImageView = [[NSImageView alloc] init];
        self.iconImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
        [self addSubview:self.iconImageView];
        
        self.labelProcess = [[NSTextField alloc] init];
        self.labelProcess.alignment = NSTextAlignmentLeft;
        self.labelProcess.bordered = NO;
        self.labelProcess.editable = NO;
        self.labelProcess.backgroundColor = [NSColor clearColor];
        self.labelProcess.font = [NSFontHelper getLightSystemFont:12];
        self.labelProcess.textColor = [LMAppThemeHelper getColor:LMColor_Title_Black];
        self.labelProcess.maximumNumberOfLines = 1;
        self.labelProcess.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:self.labelProcess];
        
        self.labelAppType = [[NSTextField alloc] init];
        self.labelAppType.alignment = NSTextAlignmentLeft;
        self.labelAppType.bordered = NO;
        self.labelAppType.editable = NO;
        self.labelAppType.backgroundColor = [NSColor clearColor];
        self.labelAppType.font = [NSFontHelper getLightSystemFont:12];
        self.labelAppType.textColor = [LMAppThemeHelper getColor:LMColor_Title_Black];

        self.labelAppType.maximumNumberOfLines = 1;
        [self addSubview:self.labelAppType];
        
        
        [self.selectCheckBox mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(24);
            make.centerY.mas_equalTo(0);
            make.size.mas_equalTo(NSMakeSize(14, 14));
        }];
        
        [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self.mas_left).offset(50);
            make.size.equalTo(@(NSMakeSize(20, 20)));
        }];
        
        [self.labelProcess mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self.iconImageView.mas_right).offset(12);
            make.width.equalTo(@230);
        }];
        
        [self.labelAppType mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self.mas_left).offset(408);
        }];
    }
    return self;
}

- (void)selectCheckBoxClicke:(LMCheckboxButton *)btn {
    if (self.selectedBlock) self.selectedBlock(btn.state != NSControlStateValueOff);
}

@end

@interface OwlSelectViewController () <NSTableViewDelegate, NSTableViewDataSource> {
    NSTableView *tableView;
    QMStaticField *tfSelected;
}
@property (nonatomic, strong) NSMutableArray *appArray;
@property (weak) NSView *bLineview;
@property(weak) MMScroller *scroller;
@property (nonatomic, strong) OwlListPlaceHolderView *listPlaceHolderView;
@property (nonatomic, strong) NSScrollView *scrollView;

@end

@implementation OwlSelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (instancetype)initWithFrame:(NSRect)frame{
    self = [super init];
    if (self) {
        NSView *contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height - 0/*OwlWindowTitleHeight*/)];
        contentView.wantsLayer = YES;
        CALayer *layer = [[CALayer alloc] init];
        layer.backgroundColor = [NSColor whiteColor].CGColor;
        contentView.layer = layer;
        
        NSRect scrollViewRect = NSMakeRect(0, 52, frame.size.width, frame.size.height - 80 - 52);
        
        // list 为空占位图 “暂无可添加应用”
        self.listPlaceHolderView = [[OwlListPlaceHolderView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"暂无可添加应用", nil, [NSBundle bundleForClass:[self class]], nil)];
        self.listPlaceHolderView.frame = scrollViewRect;
        [contentView addSubview:self.listPlaceHolderView];
        
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:scrollViewRect];
        self.scrollView = scrollView;
        
        tableView = [[NSTableView alloc] init];
        [tableView setDelegate:self];
        [tableView setDataSource:self];
        [tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
        [tableView setAutoresizesSubviews:YES];
        tableView.headerView = nil;
        if (@available(macOS 11.0, *)) {
            tableView.style = NSTableViewStyleFullWidth;
        }
        
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutohidesScrollers:YES];
        [scrollView setAutoresizesSubviews:YES];
        [scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [scrollView setDocumentView:tableView];
        
        MMScroller *scroller = [[MMScroller alloc] init];
        self.scroller = scroller;
        scroller.wantsLayer = YES;
        [scroller.layer setBackgroundColor:[LMAppThemeHelper getMainBgColor].CGColor];
        [scrollView setVerticalScroller:scroller];
        [tableView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
        
        NSTableColumn *timeColumn = [[NSTableColumn alloc] initWithIdentifier:@"owlSelectCellView"];
        timeColumn.width = frame.size.width;
        //[timeColumn.headerCell setStringValue:@"时间"];
        [timeColumn.headerCell setFont:[NSFontHelper getMediumSystemFont:12]];
        [timeColumn.headerCell setTextColor:[LMAppThemeHelper getSecondTextColor]];
        [timeColumn.headerCell setAlignment:NSTextAlignmentCenter];
        [tableView addTableColumn:timeColumn];

        tableView.frame = NSMakeRect(0, 0, scrollView.frame.size.width, scrollView.frame.size.height);
        [contentView addSubview:scrollView];
        self.view = contentView;
        
        NSTextField *tfTitle = [[NSTextField alloc] initWithFrame:NSZeroRect];
        tfTitle.alignment = NSTextAlignmentCenter;
        tfTitle.bordered = NO;
        tfTitle.editable = NO;
        tfTitle.backgroundColor = [NSColor clearColor];
        tfTitle.stringValue = NSLocalizedStringFromTableInBundle(@"应用列表", nil, [NSBundle bundleForClass:[self class]], nil);
        tfTitle.font = [NSFontHelper getMediumSystemFont:16];
        tfTitle.textColor = [LMAppThemeHelper getTitleColor];
        [contentView addSubview:tfTitle];
        
        NSView *bLineview = [[NSView alloc] init];
        CALayer *lineLayer = [[CALayer alloc] init];
        lineLayer.backgroundColor = [NSColor colorWithWhite:0.90 alpha:1].CGColor;
        bLineview.layer = lineLayer;
        self.bLineview = bLineview;
        [contentView addSubview:bLineview];
        
        NSTextField *labelProcess = [[NSTextField alloc] init];
        labelProcess.alignment = NSTextAlignmentLeft;
        labelProcess.bordered = NO;
        labelProcess.editable = NO;
        labelProcess.stringValue = NSLocalizedStringFromTableInBundle(@"软件进程", nil, [NSBundle bundleForClass:[self class]], nil);
        labelProcess.backgroundColor = [NSColor clearColor];
        labelProcess.font = [NSFontHelper getMediumSystemFont:12];
        labelProcess.textColor = [LMAppThemeHelper getSecondTextColor];
        [contentView addSubview:labelProcess];
        
        NSTextField *labelAppType = [[NSTextField alloc] init];
        labelAppType.alignment = NSTextAlignmentLeft;
        labelAppType.bordered = NO;
        labelAppType.editable = NO;
        labelAppType.stringValue = NSLocalizedStringFromTableInBundle(@"应用类型", nil, [NSBundle bundleForClass:[self class]], nil);
        labelAppType.backgroundColor = [NSColor clearColor];
        labelAppType.font = [NSFontHelper getMediumSystemFont:12];
        labelAppType.textColor = [LMAppThemeHelper getSecondTextColor];
        [contentView addSubview:labelAppType];
        
        tfSelected = [[QMStaticField alloc] initWithFrame:NSZeroRect];
        tfSelected.font = [NSFont systemFontOfSize:13];
        [contentView addSubview:tfSelected];
        
        [tfTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@9);
            make.centerX.equalTo(contentView);
        }];
        
        [labelProcess mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(52));
            if (@available(macOS 11.0, *)) {
                make.left.equalTo(@(52+5));
            } else {
                make.left.equalTo(@52);
            }
        }];
        
        [labelAppType mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(52));
            if (@available(macOS 11.0, *)) {
                make.left.equalTo(@(408+5));
            } else {
                make.left.equalTo(@(408));
            }
        }];
        
        [bLineview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(OwlWindowTitleHeight));
            make.left.equalTo(contentView);
            make.height.equalTo(@1);
            make.width.equalTo(contentView);
        }];
        
        [tfSelected mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(-15);
            make.left.mas_equalTo(24);
        }];
        
        [self setupBottomView];
        [self loadData];
        
    }
    return self;
}

- (void)setupBottomView {
    
    LMBorderButton *cancelBtn = [[LMBorderButton alloc] init];
    cancelBtn.title = NSLocalizedStringFromTableInBundle(@"取消", nil, [NSBundle bundleForClass:[self class]], @"");
    cancelBtn.target = self;
    cancelBtn.action = @selector(cancelBtnClicked:);
    cancelBtn.font = [NSFontHelper getRegularSystemFont:12];
    
    NSButton *addBtn = [LMViewHelper createSmallGreenButton:12 title:NSLocalizedStringFromTableInBundle(@"添加应用", nil, [NSBundle bundleForClass:[self class]], nil)];
    addBtn.wantsLayer = YES;
    addBtn.layer.cornerRadius = 2;
    addBtn.target = self;
    addBtn.action = @selector(addAppBtnClicked:);
    
    [self.view addSubview:cancelBtn];
    [self.view addSubview:addBtn];
    
    [addBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@(-16));
        make.right.equalTo(self.view).offset(-16);
        make.height.equalTo(@24);
        make.width.equalTo(@68);
    }];
    [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(addBtn);
        make.right.mas_equalTo(addBtn.mas_left).offset(-8);
        if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
            make.size.mas_equalTo(NSMakeSize(52, 24));
        } else {
            make.size.mas_equalTo(NSMakeSize(44, 24));
        }
    }];
}

- (void)loadData {
    _wlModelArray = [[NSMutableArray alloc] init];
    _appArray = [[Owl2Manager sharedManager] getAllAppInfoWithIndexArray:nil];
    [self reloadData];
}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:self.bLineview];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.scroller];
}

- (void)dealloc{
    
}

#pragma mark -

- (void)cancelBtnClicked:(NSButton *)btn {
    [self.view.window close];
    ((OwlWhiteListViewController*)self.view.window.parentWindow.contentViewController).selectWindowController = nil;
}

- (void)addAppBtnClicked:(NSButton *)btn{
    NSLog(@"%s _wlModelArray: %lu", __FUNCTION__, (unsigned long)_wlModelArray.count);
    NSString *strApps = @"";
    for (NSDictionary *appDic in self.wlModelArray) {
        BOOL isSelected = [[appDic objectForKey:@"isSelected"] boolValue];
        if (isSelected) {
            [[Owl2Manager sharedManager] addAppWhiteItem:appDic];
            if ([strApps length] > 0) {
                strApps = [[strApps stringByAppendingString:@"|"] stringByAppendingString:[appDic objectForKey:OwlAppName]];
            } else {
                strApps = [strApps stringByAppendingString:[appDic objectForKey:OwlAppName]];
            }
        }
    }
    [self.view.window close];
    ((OwlWhiteListViewController*)self.view.window.parentWindow.contentViewController).selectWindowController = nil;
}


#pragma mark NSTableViewDelegate
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    return 40;
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSString *idenifier = @"owlSelectCellView";
    OwlSelectCellView *view = [tableView makeViewWithIdentifier:idenifier owner:self];
    if (view == nil) {
        view = [[OwlSelectCellView alloc] initWithFrame:NSMakeRect(0, 0, tableColumn.width, 32)];
        view.identifier = idenifier;
    }
    view = [[OwlSelectCellView alloc] initWithFrame:NSMakeRect(0, 0, tableColumn.width, 32)];
    view.identifier = idenifier;
    
    // 勾选状态
    NSMutableDictionary *appDic = self.wlModelArray[row];
    view.selectCheckBox.state = [[appDic objectForKey:@"isSelected"] boolValue];
    @weakify(self);
    view.selectedBlock = ^(BOOL isSelected) {
        @strongify(self);
        [appDic setObject:@(isSelected) forKey:@"isSelected"];
        [self updateSelectLabel];
    };
    
    // icon
    @weakify(view);
    void(^setupIconBlock)(NSImage *image) = ^(NSImage *image) {
        @strongify(view);
        view.iconImageView.image = image;
    };
    
    NSString *iconPath = [appDic valueForKey:OwlAppIcon];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (iconPath && [iconPath length] > 0 && [fm fileExistsAtPath:iconPath]) {
        NSImage * iconImage = nil;
        iconImage = [[NSImage alloc] initWithContentsOfFile:iconPath];
        if (iconImage != nil)
        {
            [iconImage setSize:NSMakeSize(64, 64)];
            setupIconBlock(iconImage);
        }
    } else {
        NSImage *image = nil;
        NSString *appPath = [appDic valueForKey:OwlBubblePath];
        if ([appPath isKindOfClass:NSString.class]) {
            image = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
        }
        
        if (image) {
            setupIconBlock(image);
        } else if ([iconPath isEqualToString:@"console"]) {
            NSBundle *bundle = [NSBundle bundleForClass:[self class]];
            setupIconBlock([bundle imageForResource:@"defaultTeminate"]);
        } else {
            setupIconBlock([self getDefaultAppIcon]);
        }
    }
    
    // 特殊处理，在MacOS 15以上 图书应用的/System/Applications/Books.app/Contents/Resources/AppIcon.icns
    // 是一张纯黑图片
    if (@available(macOS 15.0, *)) {
        NSImage *image = getAppImage(appDic, AppleIBookIdentifier);
        if (image) {
            setupIconBlock(image);
        }
    }
    
    view.labelProcess.stringValue = [appDic objectForKey:OwlAppName] ?:@"";
    if ([[appDic objectForKey:OwlAppleApp] boolValue]) {
        view.labelAppType.stringValue = NSLocalizedStringFromTableInBundle(@"系统应用", nil, [NSBundle bundleForClass:[self class]], nil);
    } else {
        view.labelAppType.stringValue = NSLocalizedStringFromTableInBundle(@"第三方应用", nil, [NSBundle bundleForClass:[self class]], nil);
    }
    return view;
}

- (nullable NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row{
    return [[OwlTableRowView alloc] initWithFrame:NSZeroRect];
}

#pragma mark NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.wlModelArray.count;
}

#pragma mark -

- (NSImage*)getDefaultAppIcon{
    static NSImage *defaultIcon = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
        [defaultIcon setSize:NSMakeSize(64, 64)];
    });
    return defaultIcon;
}

- (void)reloadData{
    [_wlModelArray removeAllObjects];
    for (NSMutableDictionary *appDic in self.appArray) {
        [appDic setObject:[NSNumber numberWithBool:NO] forKey:@"isSelected"];
        [appDic setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchCamera];
        [appDic setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchAudio];
        [appDic setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchSpeaker];
        NSString *identifier = [appDic objectForKey:OwlIdentifier];
        BOOL isExist = NO;
        for (NSDictionary *item in [Owl2Manager sharedManager].wlArray) {
            if ([[item objectForKey:OwlIdentifier] isEqualToString:identifier]) {
                isExist = YES;
                break;
            }
        }
        if (isExist) {
            continue;
        }
        
        // 这个写法！！！
        [_wlModelArray addObject:appDic.mutableCopy];
    }
    [self updateSelectLabel];
    
    self.scrollView.hidden = (0 == _wlModelArray.count);
    self.listPlaceHolderView.hidden = (0 != _wlModelArray.count);
    
    [tableView reloadData];
}

- (void)updateSelectLabel{
    int selectCount = 0;
    
    for (NSDictionary *appDic in self.wlModelArray) {
        if ([[appDic objectForKey:@"isSelected"] boolValue]) {
            selectCount++;
        }
    }
    NSString *strCount = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"OwlSelectViewController_updateSelectLabel_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""), selectCount];
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc]initWithString:strCount];
    NSRange range = [strCount rangeOfString:[NSString stringWithFormat:@" %d ", selectCount]];
    
    [attrStr addAttributes:@{NSFontAttributeName:[NSFontHelper getLightSystemFont:12],
                             NSForegroundColorAttributeName: [NSColor colorWithHex:0x7E7E7E]}
                     range:NSMakeRange(0, strCount.length)];
    [attrStr addAttributes:@{NSFontAttributeName:[NSFontHelper getLightSystemFont:12],
                             NSForegroundColorAttributeName: [NSColor colorWithHex:0x7E7E7E]}
                     range:NSMakeRange(range.location, range.length)];
    tfSelected.attributedStringValue = attrStr;
}

@end
