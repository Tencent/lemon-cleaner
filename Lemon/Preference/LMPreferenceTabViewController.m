//
//  PreferenceTabViewController.m
//  Lemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMPreferenceTabViewController.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import "LMBaseLineSegmentedControl.h"
#import "PreferenceViewController.h"
#import "LMPreferenceStatusBarViewController.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/LanguageHelper.h>
//#import "MC"

@interface LMPreferenceTabViewController ()

@property NSSegmentedControl *segmentedControl;
@property NSArray *controllers;
@property NSMutableArray *tableViewItems;
@property NSInteger tabIndex;
@property (nonatomic, strong) NSTabViewItem *currentItem;
@property (weak) NSTextField *windowTitle;
@property (weak) NSView *windowTitleBgView;
@property (weak) NSView *dividLineView;
@property (strong) PreferenceViewController *preferenceViewController;
@property (strong) LMPreferenceStatusBarViewController *statusBarViewController;
@end

@implementation LMPreferenceTabViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
   
    // Do view setup here.
}

- (instancetype)init {
    self = [super init];
    if (self) {
//        [self loadView];
    }
    
    return self;
}

- (instancetype)initWithWindowController: (PreferenceWindowController*)wndController
{
    self = [super init];
    if (self) {
        self.myWC = wndController;
    }
    return self;
}

- (void)loadView{
    NSView *view;
    if(@available(macOS 10.14, *)){
        if([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese){
            view = [[NSView alloc]initWithFrame:NSMakeRect(0, 0, 529, 560)];//英文状态下，10.14版本 421
        }else{
            view = [[NSView alloc]initWithFrame:NSMakeRect(0, 0, 529, 550)];//中文状态下，10.14版本 411
        }

    }
    else{
        if([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese){
            view = [[NSView alloc]initWithFrame:NSMakeRect(0, 0, 529, 580)];//英文状态下，10.14版本以下 472
        }else{
            view = [[NSView alloc]initWithFrame:NSMakeRect(0, 0, 529, 567)];//中文状态下，10.14版本以下 447
        }
    }
    self.view = view;
    view.layer.cornerRadius = 4;
    view.layer.masksToBounds = YES;
    //    [self viewDidLoad];
}

- (void)viewWillLayout{
    [super viewWillLayout];
    [self setLayerBackgroundWithMainBgColorFor:self.windowTitleBgView];
    [LMAppThemeHelper setDivideLineColorFor:self.dividLineView];
}

-(void)setLayerBackgroundWithMainBgColorFor:(NSView *) view{
    view.wantsLayer = YES;
    if (@available(macOS 10.14, *)) {
        if([self isDarkMode]){
            view.layer.backgroundColor = [NSColor colorWithHex:0x353743].CGColor;
        }else{
            //F9F9F9
            view.layer.backgroundColor = [NSColor colorWithHex:0xF9F9F9].CGColor;
        }
    } else {
        view.layer.backgroundColor = [NSColor colorWithHex:0xF9F9F9].CGColor;
    }
}

-(void)initView{
    NSView *windowTitleBgView = [[NSView alloc]init];
    [self.view addSubview:windowTitleBgView];
    [windowTitleBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.height.mas_equalTo(45);
        make.top.left.equalTo(self.view);
    }];
    self.windowTitleBgView = windowTitleBgView;
    self.windowTitleBgView.wantsLayer = YES;
    self.windowTitleBgView.layer.backgroundColor = [NSColor redColor].CGColor;
    
    //window 标题栏
    NSTextField *windowTitle = [self buildLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_tfWindowTitle _8", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFont systemFontOfSize:16] color:[LMAppThemeHelper getTitleColor]];
    self.windowTitle = windowTitle;
    [self.windowTitleBgView addSubview:self.windowTitle];
    [self.windowTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.centerX.equalTo(self.windowTitleBgView);
    }];
    
    [self initData];
    [self initSegmentControl];
    
    NSView *dividLineView = [[NSView alloc]init];
    [self.view addSubview:dividLineView];
    self.dividLineView = dividLineView;
    [self.dividLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentedControl.mas_bottom).offset(1);
        make.left.equalTo(self.view);
        make.width.equalTo(self.view);
        make.height.mas_equalTo(1);
    }];
    
}

- (NSTextField*)buildLabel:(NSString*)title font:(NSFont*)font color:(NSColor*)color{
    NSTextField *labelTitle = [[NSTextField alloc] init];
    labelTitle.stringValue = title;
    labelTitle.font = font;
    labelTitle.alignment = NSTextAlignmentLeft;
    labelTitle.bordered = NO;
    labelTitle.editable = NO;
    labelTitle.textColor = color;
    labelTitle.backgroundColor = [NSColor clearColor];
    return labelTitle;
}

-(void)initData{
    NSString *generalString = NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_tabBar_title_general", nil, [NSBundle bundleForClass:[self class]], @"");
     NSString *statusBarString = NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_tabBar_title_statusBar", nil, [NSBundle bundleForClass:[self class]], @"");
    NSArray *titles = @[generalString,statusBarString];
    self.tableViewItems = [[NSMutableArray alloc]init];
    self.preferenceViewController = [[PreferenceViewController alloc] init];
    self.statusBarViewController = [[LMPreferenceStatusBarViewController alloc]init];
    self.controllers = @[self.preferenceViewController,self.statusBarViewController];
    [self.controllers enumerateObjectsUsingBlock:^(NSViewController   *controller, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *title = titles[idx];
        NSString *identifier = [NSString stringWithFormat:@"%lu-%@[%p]", (unsigned long)idx, title, controller];
        NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:identifier];
        item.view = controller.view;
        item.label = title;
        [self.tableViewItems addObject:item];
    }];
    self.tabIndex = 0;
}

-(void)initSegmentControl{
    self.segmentedControl = [[LMBaseLineSegmentedControl alloc]init];
    [self.view addSubview:self.segmentedControl];
    self.segmentedControl.focusRingType = NSFocusRingBelow;
    [self.segmentedControl setFrameSize:NSMakeSize(140, 43)];
    //    self.segmentedControl.background
    self.segmentedControl.target = self;
    self.segmentedControl.action = @selector(onClickSemgnetControl:);
    [_segmentedControl addObserver:self forKeyPath:@"selectedSegment" options:NSKeyValueObservingOptionNew context:NULL];
    [self.segmentedControl bind:@"selectedSegment" toObject:self withKeyPath:@"tabIndex" options:nil];
    [self.segmentedControl setSegmentCount: self.controllers.count];
    CGFloat width = self.segmentedControl.frame.size.width / self.controllers.count;
    [self.tableViewItems enumerateObjectsUsingBlock:^(NSTabViewItem *item, NSUInteger idx, BOOL *stop) {
        [self->_segmentedControl setLabel:item.label forSegment:idx];
        [self->_segmentedControl setWidth:width forSegment:idx];
    }];
    if (self.tableViewItems.count > 0) {
        self.currentItem = self.tableViewItems[0];
    }
    [_segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@140);
        make.height.equalTo(@43);
        make.left.equalTo(self.view).offset(12);
        make.top.equalTo(self.windowTitle.mas_bottom).offset(5);
    }];
}

- (void)setCurrentItem:(NSTabViewItem *)item
{
    if (_currentItem) {
        [_currentItem.view removeFromSuperview];
    }
    [self.view addSubview:item.view];
    [item.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.left.equalTo(self.view);
        make.top.equalTo(self.segmentedControl.mas_bottom).offset(2);
        make.bottom.equalTo(self.view).offset(-10);
    }];
    _currentItem = item;
}

- (NSTabViewItem *)selectedItem
{
    if (self.tableViewItems.count == 0) return nil;
    if (_segmentedControl.selectedSegment < 0 || _segmentedControl.selectedSegment >= self.tableViewItems.count) return nil;
    return self.tableViewItems[_segmentedControl.selectedSegment];
}

- (void)onClickSemgnetControl:(NSSegmentedControl *)sender
{
    NSTabViewItem *item = [self selectedItem];
    if (_currentItem == item) return;
    self.currentItem = item;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _segmentedControl && [keyPath isEqualToString:@"selectedSegment"]) {
        [self onClickSemgnetControl:object];
    }
}



@end

