//
//  LMPreferenceStatusBarViewController.m
//  Lemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMPreferenceStatusBarViewController.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/COSwitch.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSTextField+Extension.h>
#import <QMUICommon/LMCheckboxButton.h>

#define kLemonShowMonitorCfg            @"kLemonShowMonitorCfg"
#define STATUS_TYPE_BOOTSHOW (0x40000000)
// 状态栏显示方式
#define STATUS_TYPE_LOGO (1 << 0)
#define STATUS_TYPE_MEM  (1 << 1)
#define STATUS_TYPE_DISK (1 << 2)
#define STATUS_TYPE_TEP  (1 << 3)
#define STATUS_TYPE_FAN  (1 << 4)
#define STATUS_TYPE_NET  (1 << 5)
#define STATUS_TYPE_CPU  (1 << 6)
#define STATUS_TYPE_GPU  (1 << 7)
#define STATUS_TYPE_GLOBAL (0x80000000)
#define STATUS_TYPE_BOOTSHOW (0x40000000)
#define kLemonStatusOptionsChanged @"kLemonStatusOptionsChanged"
#define kStatusChangedNotification @"StatusChangedNotification"


@interface LMPreferenceStatusBarViewController ()

@property(nonatomic) NSInteger myStatusType;
@property(weak) NSView* bootMonitorLineView;
@property(weak) NSTextField *tfMonitorWarningTips;
@property(nonatomic) NSMutableDictionary* myStatusControls;
@property(strong) NSMutableArray *iconContainerViews;
@end

@implementation LMPreferenceStatusBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
     _myStatusControls = [[NSMutableDictionary alloc] init];
     self.iconContainerViews = [[NSMutableArray alloc]init];
    [self initView];
    // Do view setup here.
}

- (void)loadView
{
    NSRect rect = NSMakeRect(0, 0, 530, 325); //不包括箭头
    NSView *view = [[NSView alloc] initWithFrame:rect];
    self.view = view;
}

- (void)viewWillLayout{
    [super viewWillLayout];
    for (NSView* containerView in self.iconContainerViews) {
        containerView.wantsLayer = YES;
        containerView.layer.backgroundColor = [self getIconContainerBgColor].CGColor;
    }
    [LMAppThemeHelper setDivideLineColorFor:_bootMonitorLineView];
}
-(void)initView{
    NSTextField *showStatusBarIconText = [self buildLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_bootMonitorTitle _16", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFont systemFontOfSize:14] color:[LMAppThemeHelper getTitleColor]];
    
    // 状态栏开机启动项设置
    _myStatusType = [[[NSUserDefaults standardUserDefaults] objectForKey:kLemonShowMonitorCfg] integerValue];
    COSwitch *bootMonitorSwitch = [[COSwitch alloc] init];
    bootMonitorSwitch.on = (_myStatusType & STATUS_TYPE_BOOTSHOW) > 0 ? YES : NO;
    __weak typeof(self) weakSelf = self;
    [bootMonitorSwitch setOnValueChanged:^(COSwitch *button) {
        dispatch_async(dispatch_get_main_queue(), ^{
            button.isEnable = NO;
            NSLog(@"monitorSwitch setOnValueChanged: %d", button.on);
            
            if (button.on) {
                NSLog(@"preference:global=%d", button.on);
                
                weakSelf.myStatusType |= STATUS_TYPE_BOOTSHOW;
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:weakSelf.myStatusType] forKey:kLemonShowMonitorCfg];
            } else {
                NSLog(@"preference:global=%d", button.on);
                
                weakSelf.myStatusType &= ~STATUS_TYPE_BOOTSHOW;
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:weakSelf.myStatusType] forKey:kLemonShowMonitorCfg];
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                button.isEnable = YES;
            });
        });
    }];
    
    NSView* bootMonitorLineView = [[NSView alloc] init];
    self.bootMonitorLineView = bootMonitorLineView;
    
    
    // 状态栏图标显示
    NSTextField *tfMonitorTitle = [self buildLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_tfMonitorTitle _9", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFont systemFontOfSize:14] color:[LMAppThemeHelper getTitleColor]];
    NSImageView *monitorImageView = [[NSImageView alloc] init];
    if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
        monitorImageView.image = [[NSBundle mainBundle] imageForResource:@"navigation_bar_pattern_ch"];
    }else{
        monitorImageView.image = [[NSBundle mainBundle] imageForResource:@"navigation_bar_pattern_en"];
    }
    
    NSTextField* tfMonitorWarningTips = [self buildLabel:NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_1553049563_10", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFont systemFontOfSize:12] color:[NSColor colorWithHex:0x94979B]];
    self.tfMonitorWarningTips = tfMonitorWarningTips;
    [tfMonitorWarningTips setHidden:YES];
    
    NSString *appLogoTitle = nil;
    if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
        appLogoTitle = @"Logo";
    }else{
        appLogoTitle = @"App\n logo";
    }
    NSView* optLogo = [self getOptionView:@"logo":appLogoTitle:STATUS_TYPE_LOGO];
    NSView* optMem = [self getOptionView:@"stat_mem":NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_1553049563_11", nil, [NSBundle bundleForClass:[self class]], @""):STATUS_TYPE_MEM];
    NSView* optDisk = [self getOptionView:@"stat_disk":NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_1553049563_12", nil, [NSBundle bundleForClass:[self class]], @""):STATUS_TYPE_DISK];
    NSView* optCpuTem = [self getOptionView:@"stat_cpu_temperature":NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_1553049563_13", nil, [NSBundle bundleForClass:[self class]], @""):STATUS_TYPE_TEP];
    NSView* optCpuFan = [self getOptionView:@"stat_cpu_fan":NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_1553049563_14", nil, [NSBundle bundleForClass:[self class]], @""):STATUS_TYPE_FAN];
    NSView* optNet = [self getOptionView:@"stat_net":NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_1553049563_15", nil, [NSBundle bundleForClass:[self class]], @""):STATUS_TYPE_NET];
    
    NSView* optCpuUsed = [self getOptionView:@"stat_cpu_usage":NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_1553049563_16", nil, [NSBundle bundleForClass:[self class]], @""):STATUS_TYPE_CPU];
    
    NSView* optGpuUsed = [self getOptionView:@"stat_gpu_usage":NSLocalizedStringFromTableInBundle(@"PreferenceViewController_setupViews_1553049563_17", nil, [NSBundle bundleForClass:[self class]], @""):STATUS_TYPE_GPU];
    
    // 监听状态栏选中变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStatusOptionsChanged:) name:kLemonStatusOptionsChanged object:nil];
    
    
    [self.view addSubview:showStatusBarIconText];
    [self.view addSubview:bootMonitorSwitch];
    [self.view addSubview:bootMonitorLineView];
    
    [self.view addSubview:tfMonitorTitle];
    [self.view addSubview:monitorImageView];
    [self.view addSubview:tfMonitorWarningTips];
    [self.view addSubview:optLogo];
    [self.view addSubview:optMem];
    [self.view addSubview:optDisk];
    [self.view addSubview:optCpuTem];
    [self.view addSubview:optCpuFan];
    [self.view addSubview:optNet];
    [self.view addSubview:optCpuUsed];
    [self.view addSubview:optGpuUsed];
    
    NSView *cView = self.view;
    
       // 状态栏自启设置
    [showStatusBarIconText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cView).offset(20);
        make.leading.equalTo(cView).offset(29);
    }];

    [bootMonitorSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(showStatusBarIconText.mas_centerY);
        make.right.equalTo(cView).offset(-30);
        make.width.equalTo(@(40));
        make.height.equalTo(@(19));
    }];

    [bootMonitorLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(showStatusBarIconText.mas_bottom).offset(20);
        make.centerX.equalTo(cView);
        make.width.equalTo(cView);
        make.height.equalTo(@(1));
    }];

    // 状态栏图标显示
    [tfMonitorTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(bootMonitorLineView.mas_bottom).offset(16);
        make.leading.equalTo(cView).offset(29);
    }];

    [tfMonitorWarningTips mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(tfMonitorTitle.mas_right);
        make.centerY.equalTo(tfMonitorTitle.mas_centerY);
    }];

    [monitorImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tfMonitorTitle.mas_bottom).offset(14);
        make.leading.equalTo(cView).offset(30);
    }];
    //    [tfMonitorTips mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.top.equalTo(tfMonitorTitleDes.mas_bottom).offset(12);
    //        make.leading.equalTo(cView).offset(33);
    //    }];
    
    
    NSInteger itemHeight = 0;
    if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
        itemHeight = 70;
    }else{
        itemHeight = 90;
    }
    
    
     //状态栏选项
    [optLogo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(cView.mas_left).offset(30);
        make.top.equalTo(monitorImageView.mas_bottom).offset(10);
        make.width.equalTo(@(70));
        make.height.equalTo(@(itemHeight));
    }];
    [optMem mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(optLogo.mas_right).offset(10);
        make.top.equalTo(optLogo);
        make.width.equalTo(@(70));
        make.height.equalTo(@(itemHeight));
    }];
    [optDisk mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(optMem.mas_right).offset(10);
        make.top.equalTo(optLogo);
        make.width.equalTo(@(70));
        make.height.equalTo(@(itemHeight));
    }];
    [optCpuTem mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(optDisk.mas_right).offset(10);
        make.top.equalTo(optLogo);
        make.width.equalTo(@(70));
        make.height.equalTo(@(itemHeight));
    }];
    [optCpuFan mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(optCpuTem.mas_right).offset(10);
        make.top.equalTo(optLogo);
        make.width.equalTo(@(70));
        make.height.equalTo(@(itemHeight));
    }];
    [optNet mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(optCpuFan.mas_right).offset(10);
        make.top.equalTo(optLogo);
        make.width.equalTo(@(70));
        make.height.equalTo(@(itemHeight));
    }];
    [optCpuUsed mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(optLogo.mas_bottom).offset(10);
        make.left.equalTo(optLogo.mas_left);
        make.width.equalTo(@(70));
        make.height.equalTo(@(itemHeight));
    }];
    
    [optGpuUsed mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(optLogo.mas_bottom).offset(10);
        make.left.equalTo(optMem.mas_left);
        make.width.equalTo(@(70));
        make.height.equalTo(@(itemHeight));
    }];
    
    // 第一次，统一改变状态
    [[NSNotificationCenter defaultCenter] postNotificationName:kLemonStatusOptionsChanged object:[[NSNumber alloc] initWithInteger:_myStatusType]];
    
}

-(NSView*)getOptionView:(NSString*)image :(NSString*)tittle :(NSInteger)type
{
    //
    NSView* container = [[NSView alloc] init];
    container.wantsLayer = true;
    [self.iconContainerViews addObject:container];
    container.layer.backgroundColor = [NSColor colorWithHex:0xF2F4F8].CGColor;
    
    //
    NSImageView* logo = [[NSImageView alloc] init];
    logo.image = [[NSBundle mainBundle] imageForResource:image];
    
    //
    NSTextField* tips = [NSTextField labelWithStringCompat:tittle];
    [tips setTextColor:[LMAppThemeHelper getTitleColor]];
    tips.alignment = NSTextAlignmentCenter;
    if (@available(macOS 10.11, *)) {
        tips.maximumNumberOfLines = 2;
    }
    
    //
    NSButton* optChecked = [[LMCheckboxButton alloc] init];
    [optChecked setButtonType:NSButtonTypeSwitch];
    optChecked.allowsMixedState = NO;
    [optChecked setBordered:NO];
    optChecked.tag = type;
    optChecked.title=@"";
    optChecked.target = self;
    optChecked.action  = @selector(doCheckChanged:);
    
    //
    [container addSubview:logo];
    [container addSubview:tips];
    [container addSubview:optChecked];
    
    //
    [logo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(container).offset(20);
        make.centerX.equalTo(container);
    }];
    [tips mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(container.mas_centerX);
        make.bottom.equalTo(container.mas_bottom).offset(-6);
    }];
    
    if ([self isMacOS11]) {
        [optChecked mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(container.mas_top);
            make.right.equalTo(container.mas_right).offset(0);
        }];
    } else {
        [optChecked mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(container.mas_top);
            make.right.equalTo(container.mas_right).offset(3);
        }];
    }
    [_myStatusControls setObject:optChecked forKey:[[NSNumber alloc] initWithInteger:type]];
    return container;
}

- (BOOL)isMacOS11 {
    NSLog(@"NSAppKitVersionNumber: %f",NSAppKitVersionNumber);
    if (NSAppKitVersionNumber > 1900) {
        NSLog(@"VersionNumber is 11");
        return YES;
    }
    NSLog(@"VersionNumber is less than 11");
    return NO;
}

-(NSColor *)getIconContainerBgColor{
    if (@available(macOS 10.14, *)) {
        if([self isDarkMode]){
            return [NSColor colorWithHex:0x353743];
        }else{
            return [NSColor colorWithHex:0xF2F4F8];
        }
    } else {
        return [NSColor colorWithHex:0xF2F4F8];
    }
}




- (void)doCheckChanged:(id)sender
{
    NSLog(@"preference:doCheckChanged");
    NSButton* optChecked = (NSButton*)sender;
    NSInteger tag = optChecked.tag;
    if (optChecked.state == NSControlStateValueOn )
    {
        _myStatusType |= tag;
        
        
        // 容错处理，至少拷贝选择一项
        [self.tfMonitorWarningTips setHidden:YES];
    }
    else if(optChecked.state == NSControlStateValueOff)
    {
        
        _myStatusType &= ~tag;
        
        // 容错处理，至少拷贝选择一项
        if ((_myStatusType & ~STATUS_TYPE_BOOTSHOW) == 0)
        {
            [self.tfMonitorWarningTips setHidden:NO];
            _myStatusType |= tag;
            optChecked.state = NSControlStateValueOn;
            return;
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kLemonStatusOptionsChanged object:[[NSNumber alloc] initWithInteger:_myStatusType]];
}

-(void) onStatusOptionsChanged:(NSNotification*)notification
{
    //
    NSInteger type = ((NSNumber*)notification.object).integerValue;
    
    //
    ((NSButton*)_myStatusControls[[NSNumber numberWithInteger:STATUS_TYPE_LOGO]]).state = type & STATUS_TYPE_LOGO ? NSControlStateValueOn : NSControlStateValueOff;
    ((NSButton*)_myStatusControls[[NSNumber numberWithInteger:STATUS_TYPE_MEM]]).state = type & STATUS_TYPE_MEM ? NSControlStateValueOn : NSControlStateValueOff;
    ((NSButton*)_myStatusControls[[NSNumber numberWithInteger:STATUS_TYPE_DISK]]).state = type & STATUS_TYPE_DISK ? NSControlStateValueOn : NSControlStateValueOff;
    ((NSButton*)_myStatusControls[[NSNumber numberWithInteger:STATUS_TYPE_TEP]]).state = type & STATUS_TYPE_TEP ? NSControlStateValueOn : NSControlStateValueOff;
    ((NSButton*)_myStatusControls[[NSNumber numberWithInteger:STATUS_TYPE_FAN]]).state = type & STATUS_TYPE_FAN ? NSControlStateValueOn : NSControlStateValueOff;
    ((NSButton*)_myStatusControls[[NSNumber numberWithInteger:STATUS_TYPE_NET]]).state = type & STATUS_TYPE_NET ? NSControlStateValueOn : NSControlStateValueOff;
    ((NSButton*)_myStatusControls[[NSNumber numberWithInteger:STATUS_TYPE_CPU]]).state = type & STATUS_TYPE_CPU ? NSControlStateValueOn : NSControlStateValueOff;
    ((NSButton*)_myStatusControls[[NSNumber numberWithInteger:STATUS_TYPE_GPU]]).state = type & STATUS_TYPE_GPU ? NSControlStateValueOn : NSControlStateValueOff;

    
    // save config
    [[NSUserDefaults standardUserDefaults] setObject:(NSNumber*)notification.object forKey:kLemonShowMonitorCfg];
    
    // send to monitor process
    NSDictionary* dict = @{@"type":[NSNumber numberWithInteger:type]};
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:kStatusChangedNotification object:nil userInfo:dict deliverImmediately:YES];
    
    
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

- (void)dealloc
{
    
}

@end
