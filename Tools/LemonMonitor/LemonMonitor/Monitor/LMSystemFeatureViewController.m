//
//  LMSystemFeatureViewController.m
//  LemonMonitor
//

//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "LMSystemFeatureViewController.h"
#import "QMNetworkSpeedFormatter.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/ClickableView.h>
#import <QMUICommon/ClickableImageView.h>

#import "QMDataConst.h"
#import "LemonDaemonConst.h"
#import <PrivacyProtect/OwlManager.h>
#import "McStatInfoConst.h"

#import <LemonStat/McDiskInfo.h>
#import <PrivacyProtect/OwlManager.h>
#import <PrivacyProtect/OwlWindowController.h>
#import <LemonHardware/LemonHardwareWindowController.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/NSBundle+LMLanguage.h>
#import <QMCoreFunction/McStatMonitor.h>
#import <LemonStat/McDiskInfo.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import "LMHardWareDataUtil.h"


static const NSUInteger kMaxCount = 5;
static NSString * const kImageKey = @"image";
static NSString * const kTitleKey = @"title";
static NSString * const kSpeedKey = @"speed";
static NSString * const kPidKey = @"pid";

@interface LMSystemFeatureViewController ()
{
    struct {
        int upHistory : 1;
        int downHistory : 1;
    } _observingFlags;
    
    QMNetworkSpeedFormatter *_speedFormatter;
    
    NSBundle *myBundle;
    
    NSView* miscContainerView;
    NSTextField *_fanSpeedText;
    NSTextField *_cpuTemperatureText;
    NSTextField *_diskUsageText;

    
    NSImageView *_imageCamera;
    NSImageView *_imageMicrophone;
    NSTextField *_privacyCameraLabel;
    NSTextField *_privacyMicrophoneLabel;
    
    NSView *_divideView;

}
@property (nonatomic, weak) OwlWindowController *owlController;
@property (nonatomic, weak) LemonHardwareWindowController *hardwareController;
@property (nonatomic, weak) NSTextField *diskSizeLabel;
@property (nonatomic, strong) NSString *mainDiskName;

@end

@implementation LMSystemFeatureViewController

+ (NSDictionary *)networkInfoItemWithPid:(id)pid name:(NSString *)processName icon:(NSImage *)image upSpeed:(NSNumber *)upSpeed downSpeed:(NSNumber *)downSpeed
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    if (pid) {
        dict[kPidKey] = pid;
    }
    if (processName) {
        dict[kTitleKey] = processName;
    }
    if (image) {
        dict[kImageKey] = image;
    }
    if (upSpeed && downSpeed) {
        dict[kSpeedKey] = @([upSpeed unsignedLongLongValue]  + [downSpeed unsignedLongLongValue]);
    }
    return dict;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNetworkView];
    [self setupMiscView];
#ifndef APPSTORE_VERSION
    [self setupOwlViews];
    
#endif
    [self initNetworkData];
}

- (void)viewWillAppear
{
    NSLog(@"%s", __FUNCTION__);
    [self initDiskInfo];
    [super viewWillAppear];
    [self updateVedioState];
    [self updateAudioState];
}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:_divideView];
    
}

-(void)updateVedioState
{
#ifndef APPSTORE_VERSION
    BOOL isWatchVedio = [[OwlManager shareInstance] isWatchVedio];
    NSLog(@"receivedVedioStateChanged isWatchVedio=%d\n", isWatchVedio);
    //LMSystemFeatureViewController_updateAudioState__privacyMicrophoneLabel__not_work
    if (isWatchVedio)
    {
        [_imageCamera setImage:[myBundle imageForResource:@"lemon_camera_down"]];
    }
    else
    {
        [_imageCamera setImage:[myBundle imageForResource:@"lemon_camera_normal"]];
    }
    
    if ( isWatchVedio)
    {
        _privacyCameraLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMSystemFeatureViewController_updateVedioState__privacyCameraLabel_1", nil, [NSBundle bundleForClass:[self class]], @"");
        _privacyCameraLabel.textColor = [NSColor colorWithHex:0x1A83F7];
    }
    else
    {
        _privacyCameraLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMSystemFeatureViewController_updateVedioState__privacyCameraLabel_2", nil, [NSBundle bundleForClass:[self class]], @"");
        _privacyCameraLabel.textColor = [NSColor colorWithHex:0x94979b];
    }
    if ([self isMacOS11_3]) {
        _privacyCameraLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMSystemFeatureViewController_updateVedioState__privacyCameraLabel_not_work", nil, [NSBundle bundleForClass:[self class]], @"");
        _privacyCameraLabel.textColor = [NSColor colorWithHex:0x94979b];
        [_imageCamera setImage:[myBundle imageForResource:@"lemon_camera_normal"]];
    }
#endif
}

-(void)updateAudioState
{
#ifndef APPSTORE_VERSION
    BOOL isWatchAudio = [[OwlManager shareInstance] isWatchAudio];
    NSLog(@"receivedAudioStateChanged isWatchAudio=%d\n", isWatchAudio);
    if (isWatchAudio)
    {
        [_imageMicrophone setImage:[myBundle imageForResource:@"lemon_microphone"]];
    }
    else
    {
        [_imageMicrophone setImage:[myBundle imageForResource:@"lemon_microphone_gray"]];
    }
    
    if (isWatchAudio)
    {
        _privacyMicrophoneLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMSystemFeatureViewController_updateAudioState__privacyMicrophoneLabel_1", nil, [NSBundle bundleForClass:[self class]], @"");
        _privacyMicrophoneLabel.textColor = [NSColor colorWithHex:0x1A83F7];
    }
    else
    {
        _privacyMicrophoneLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMSystemFeatureViewController_updateAudioState__privacyMicrophoneLabel_2", nil, [NSBundle bundleForClass:[self class]], @"");
        _privacyMicrophoneLabel.textColor = [NSColor colorWithHex:0x94979b];
    }
    if ([self isMacOS11_3]) {
        _privacyMicrophoneLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMSystemFeatureViewController_updateAudioState__privacyMicrophoneLabel__not_work", nil, [NSBundle bundleForClass:[self class]], @"");
        _privacyMicrophoneLabel.textColor = [NSColor colorWithHex:0x94979b];
        [_imageMicrophone setImage:[myBundle imageForResource:@"lemon_microphone_gray"]];
    }

#endif
}

- (void)loadView{
    myBundle = [NSBundle bundleForClass:[self class]];

    NSRect rect = NSMakeRect(0, 0, 340, 330);
    NSView *view = [[NSView alloc] initWithFrame:rect];
    self.view = view;
}

-(void)setupNetworkView{

    [self setupNetworkInfoView];
    [self setupNetwrokTrendImageView];
}

- (void)startMonitor
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedCPUInfoChanged:)
                                                 name:kStatCPUInfoNotification
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNetworkInfoChanged:)
                                                 name:kNetworkInfoNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedTempCpuInfoChanged:)
                                                 name:kTempCpuInfoNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedDiskInfoChanged:)
                                                 name:NOTIFICATION_UPDATE_DISK_INFO
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedFanCpuInfoChanged:)
                                                 name:kFanCpuInfoNotification
                                               object:nil];
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(receivedVedioStateChanged:)
    //                                                 name:OwlWatchVedioStateChange
    //                                               object:nil];
    //
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(receivedAudioStateChanged:)
    //                                                 name:OwlWatchAudioStateChange
    //                                               object:nil];
}

- (void)stopMonitor
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kStatCPUInfoNotification
                                                  object:nil];
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kNetworkInfoNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kTempCpuInfoNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:kDiskInfoNotification
                                               object:nil];
    //    [[NSNotificationCenter defaultCenter] removeObserver:self
    //                                                    name:OwlWatchVedioStateChange
    //                                                  object:nil];
    //
    //    [[NSNotificationCenter defaultCenter] removeObserver:self
    //                                                    name:OwlWatchAudioStateChange
    //                                                  object:nil];
}

-(void)initDiskInfo{
    if(!self.diskModel){
        NSLog(@"%s, diskModel is nil", __FUNCTION__);
        self.diskModel = [[DiskModel alloc]init];
        [self.diskModel getHardWareInfo];
    }
    NSLog(@"%s, diskModel info: %@", __FUNCTION__, self.diskModel);
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
        NSArray *diskInfo = self.diskModel.diskZoneArr;
        for (DiskZoneModel *zoneModel in diskInfo) {
            NSLog(@"%s, zoneMode Info : %@", __FUNCTION__, zoneModel);
            if(zoneModel.isMainDisk){
                uint64_t usedBytes = zoneModel.maxSize - zoneModel.leftSize;
                if (zoneModel.maxSize > 0)
                {
                    double useRate = usedBytes*1.0/zoneModel.maxSize;
                    [dict setObject:@(usedBytes) forKey:@"used"];
                    [dict setObject:@(zoneModel.maxSize) forKey:@"total"];
                    NSLog(@"%s, useRate : %f", __FUNCTION__, useRate);
                    [self updateDiskInfoWith:dict];
                    break;
                }
            }
        }
}

-(void)setupNetworkInfoView{
    NSView *diskContainerView = [[NSView alloc] init];
    [self.view addSubview:diskContainerView];
    
    NSImageView *diskImageView = [LMViewHelper createNormalImageView];
    diskImageView.image = [NSImage imageNamed:@"maindisk"];
    [diskContainerView addSubview:diskImageView];
    
    NSTextField *diskSizeLabel = [LMViewHelper createNormalLabel:14 fontColor:[LMAppThemeHelper getTitleColor]];
    [diskContainerView addSubview:diskSizeLabel];
    self.diskSizeLabel = diskSizeLabel;
    
    NSButton *diskButton = [LMViewHelper createNormalTextButton:12 title:NSLocalizedStringFromTableInBundle(@"LemonHardwareViewController_initView_diskButton_1", nil, [NSBundle bundleForClass:[self class]], @"") textColor:[NSColor colorWithHex:0x1A83F7]];
    diskButton.target = self;
    diskButton.action = @selector(clickDiskCheckButton);
    [diskContainerView addSubview:diskButton];
    
    //
    NSView *infoContainerView = [[NSView alloc]init];
    [self.view addSubview:infoContainerView];
    
    NSImageView *iconImageView = [LMViewHelper createNormalImageView];
    [infoContainerView addSubview:iconImageView];
    iconImageView.image = [myBundle imageForResource:@"lemon_network_info"];
    
    NSImageView *upSpeedImageView = [LMViewHelper createNormalImageView];
    [upSpeedImageView setImage:[myBundle imageForResource:@"float_arrow_up"]];
    [infoContainerView addSubview:upSpeedImageView];
    
    NSImageView *downSpeedImageView = [LMViewHelper createNormalImageView];
    [downSpeedImageView setImage:[myBundle imageForResource:@"float_arrow_down"]];
    [infoContainerView addSubview:downSpeedImageView];
    
    NSTextField *upSpeedLabel = [LMViewHelper createNormalLabel:14 fontColor:[LMAppThemeHelper getTitleColor]];
    [infoContainerView addSubview:upSpeedLabel];
    self.upSpeedLabel = upSpeedLabel;

    NSTextField *upSpeedKbLable = [LMViewHelper createNormalLabel:14 fontColor:[NSColor colorWithHex:0x94979b] fonttype:LMFontTypeLight];
    upSpeedKbLable.stringValue = @"KB/s";
    [infoContainerView addSubview:upSpeedKbLable];
    self.upSpeedKbLabel = upSpeedKbLable;


    NSTextField *downSpeedLabel = [LMViewHelper createNormalLabel:14 fontColor:[LMAppThemeHelper getTitleColor]];
    [infoContainerView addSubview:downSpeedLabel];
    self.downSpeedLabel = downSpeedLabel;
    
    NSTextField *downSpeedKbLable = [LMViewHelper createNormalLabel:14 fontColor:[NSColor colorWithHex:0x94979b] fonttype:LMFontTypeLight];
    downSpeedKbLable.stringValue = @"KB/s";
    [infoContainerView addSubview:downSpeedKbLable];
    self.downSpeedKbLabel = downSpeedKbLable;
    
    [diskContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(105);
        make.height.equalTo(@32);
        make.left.width.equalTo(self.view);
    }];
    
    [diskImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(32);
        make.centerY.equalTo(diskContainerView);
        make.left.equalTo(diskContainerView).offset(13);
    }];
    
    [diskSizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(diskImageView.mas_right).offset(3);
        make.centerY.equalTo(diskContainerView);
    }];
    
    [diskButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(diskContainerView);
        make.right.equalTo(diskContainerView).offset(-20);
    }];
    
    [infoContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(138);
        make.height.equalTo(@32);
        make.left.width.equalTo(self.view);
    }];
    
    [iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(16);
        make.centerY.equalTo(infoContainerView);
        make.left.equalTo(self.view).offset(21);
    }];
    
    [upSpeedImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(11);
        make.centerY.equalTo(iconImageView);
        make.left.equalTo(self.view).offset(47);
    }];
    
    [upSpeedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(upSpeedImageView).offset(-1);
        make.left.equalTo(upSpeedImageView.mas_right).offset(5);
    }];
    
    [upSpeedKbLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(upSpeedLabel);
        make.left.equalTo(upSpeedLabel.mas_right).offset(3);
    }];
    
    [downSpeedImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(11);
        make.centerY.equalTo(iconImageView);
        make.left.equalTo(self.view).offset(133);
    }];
    
    [downSpeedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(downSpeedImageView).offset(-1);
        make.left.equalTo(downSpeedImageView.mas_right).offset(5);
    }];
    
     [downSpeedKbLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(downSpeedLabel);
        make.left.equalTo(downSpeedLabel.mas_right).offset(3);
    }];
}



-(void)setupNetwrokTrendImageView{
    
    ClickableView *clickableView = [[ClickableView alloc]init];
    [self.view addSubview:clickableView];
    
    CGFloat plotViewHeight = 50;
    _upSpeedPlotView = [[QMNetworkPlotView alloc] initWithFrame:NSMakeRect(0, 0, 300, plotViewHeight)];
    [clickableView addSubview:_upSpeedPlotView];
    _downSpeedPlotView = [[QMNetworkPlotView alloc] initWithFrame:NSMakeRect(0, 0, 300, plotViewHeight)];
    _downSpeedPlotView.upsideDown = YES;
    [clickableView addSubview:_downSpeedPlotView];
    
    [_upSpeedPlotView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view).offset(-40);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(plotViewHeight);
        make.top.equalTo(self.view).offset(170);
    }];
    
    [_downSpeedPlotView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view).offset(-40);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(plotViewHeight);
        make.top.equalTo(_upSpeedPlotView.mas_bottom);
    }];
    
    [clickableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.centerX.equalTo(self.view);
        make.top.equalTo(_upSpeedPlotView);
        make.bottom.equalTo(_downSpeedPlotView);
    }];
}

///macOS 11.3系统以上
- (BOOL)isMacOS11_3 {
#if DISABLED_PRIVACY_MAX1103
    if (@available(macOS 11.3, *)) {
        return YES;
    }
#endif
    return NO;
}

-(void)setupOwlViews
{
    ClickableView *owlContainerView = [[ClickableView alloc]init];
    [self.view addSubview:owlContainerView];
    //11.3及以上系统暂时屏蔽隐私防护功能入口
    if (![self isMacOS11_3]) {
        NSClickGestureRecognizer *recognizer = [[NSClickGestureRecognizer alloc]init];
        recognizer.target = self;
        recognizer.action = @selector(clickOwlView);
        [owlContainerView addGestureRecognizer:recognizer];
    }
    // 摄像头
    NSImageView* imageCamera = [LMViewHelper createNormalImageView];
    imageCamera.imageScaling = NSImageScaleProportionallyDown;
    _imageCamera = imageCamera;
    [owlContainerView addSubview:imageCamera];

    NSTextField *cameraLabel = [LMViewHelper createNormalLabel:12 fontColor:[LMAppThemeHelper getTitleColor]];
    [owlContainerView addSubview:cameraLabel];
    cameraLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMSystemFeatureViewController_setupOwlViews_cameraLabel_1", nil, [NSBundle bundleForClass:[self class]], @"");
    
    NSTextField *cameraStateLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979b]];
    _privacyCameraLabel = cameraStateLabel;
    [owlContainerView addSubview:cameraStateLabel];
    
    // 麦克风
    NSImageView* imageMicrophone = [LMViewHelper createNormalImageView];
    imageMicrophone.imageScaling = NSImageScaleProportionallyDown;
    _imageMicrophone = imageMicrophone;
    [owlContainerView addSubview:imageMicrophone];
    _imageMicrophone = imageMicrophone;
    
    NSTextField *microphoneLabel = [LMViewHelper createNormalLabel:12 fontColor:[LMAppThemeHelper getTitleColor]];
    [owlContainerView addSubview:microphoneLabel];
    microphoneLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMSystemFeatureViewController_setupOwlViews_microphoneLabel_2", nil, [NSBundle bundleForClass:[self class]], @"");
    
    NSTextField *microhoneStateLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979b]];
    _privacyMicrophoneLabel = microhoneStateLabel;

    [owlContainerView addSubview:microhoneStateLabel];
    

    
    
    [owlContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@71);
        make.bottom.equalTo(self.view);
        make.width.equalTo(self.view).offset(-26);
        make.centerX.equalTo(self.view);
    }];
    
    
    [imageCamera mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(owlContainerView);
        make.top.equalTo(owlContainerView.mas_top);
        make.width.equalTo(@32);
        make.height.equalTo(@32);
    }];
    
    [cameraLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(imageCamera.mas_right).offset(3);
        make.centerY.equalTo(imageCamera);
    }];
    
    [cameraStateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(owlContainerView).offset(-7); //container -13
        make.centerY.equalTo(imageCamera);
    }];
    
    [imageMicrophone mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(imageCamera);
        make.top.equalTo(imageCamera.mas_bottom).offset(7);
        make.width.equalTo(@32);
        make.height.equalTo(@20);
    }];
    
    [microphoneLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(imageMicrophone.mas_right).offset(3);
        make.centerY.equalTo(imageMicrophone);
    }];
    
    [microhoneStateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(owlContainerView).offset(-7); //container -13
        make.centerY.equalTo(imageMicrophone);
    }];
    
}


- (void)viewDidAppear
{
    if (!_observingFlags.downHistory) {
        _observingFlags.downHistory = YES;
        [self.downSpeedHistory addObserver:self forKeyPath:@"items" options:NSKeyValueObservingOptionNew context:NULL];
    }
    [self.downSpeedPlotView replaceDataWithHistory:[self.downSpeedHistory valueArray]];
    
    if (!_observingFlags.upHistory) {
        _observingFlags.upHistory = YES;
        [self.upSpeedHistory addObserver:self forKeyPath:@"items" options:NSKeyValueObservingOptionNew context:NULL];
    }
    [self.upSpeedPlotView replaceDataWithHistory:[self.upSpeedHistory valueArray]];
}

- (void)viewDidDisappear
{
    if (!_windowVisible) return;
    if (_observingFlags.downHistory) {
        _observingFlags.downHistory = NO;
        [self.downSpeedHistory removeObserver:self forKeyPath:@"items"];
    }
    if (_observingFlags.upHistory) {
        _observingFlags.upHistory = NO;
        [self.upSpeedHistory removeObserver:self forKeyPath:@"items"];
    }
}

-(void)initNetworkData{
    _speedFormatter = [[QMNetworkSpeedFormatter alloc] init];
    [self.upSpeedPlotView addObserver:self forKeyPath:@"maxValue" options:NSKeyValueObservingOptionNew context:NULL];
    [self.downSpeedPlotView addObserver:self forKeyPath:@"maxValue" options:NSKeyValueObservingOptionNew context:NULL];
    
    [self.upSpeedPlotView replaceDataWithHistory:[self.upSpeedHistory valueArray]];
    [self.downSpeedPlotView replaceDataWithHistory:[self.downSpeedHistory valueArray]];
}

// mark: 根据数值的改变,更改

- (void)setUpSpeedHistory:(QMValueHistory *)upSpeedHistory
{
    if (_upSpeedHistory && _observingFlags.upHistory) {
        [_upSpeedHistory removeObserver:self forKeyPath:@"items"];
    }
    _upSpeedHistory = upSpeedHistory;
    if (_windowVisible) {
        _observingFlags.upHistory = YES;
        [upSpeedHistory addObserver:self forKeyPath:@"items" options:NSKeyValueObservingOptionNew context:NULL];
        [self.upSpeedPlotView replaceDataWithHistory:[upSpeedHistory valueArray]];
    }
}

- (void)setDownSpeedHistory:(QMValueHistory *)downSpeedHistory
{
    if (_downSpeedHistory && _observingFlags.downHistory) {
        [_downSpeedHistory removeObserver:self forKeyPath:@"items"];
    }
    _downSpeedHistory = downSpeedHistory;
    if (_windowVisible) {
        _observingFlags.downHistory = YES;
        [downSpeedHistory addObserver:self forKeyPath:@"items" options:NSKeyValueObservingOptionNew context:NULL];
        [self.downSpeedPlotView replaceDataWithHistory:[downSpeedHistory valueArray]];
    }
}

- (void) setUpSpeed:(float)upSpeed{
    float _upSpeedNumber = upSpeed / 1024;
    NSArray *stringArr = [self stringArrayFromNetSpeedWithoutSpacing:_upSpeedNumber];
    dispatch_async(dispatch_get_main_queue(), ^{
        if(stringArr.count == 2){
            float speed = [[stringArr objectAtIndex:0]floatValue];
            self.upSpeedLabel.stringValue = [NSString stringWithFormat:@"%0.1f", speed];
            self.upSpeedKbLabel.stringValue = (NSString *)[stringArr objectAtIndex:1];
        }
    });
   
}

- (void) setDownSpeed:(float)downSpeed{
    float _downSpeedNumber = downSpeed / 1024;
    NSArray *stringArr = [self stringArrayFromNetSpeedWithoutSpacing:_downSpeedNumber];

    dispatch_async(dispatch_get_main_queue(), ^{
        if(stringArr.count == 2){
            float speed = [[stringArr objectAtIndex:0]floatValue];
            self.downSpeedLabel.stringValue = [NSString stringWithFormat:@"%0.1f", speed] ;
            self.downSpeedKbLabel.stringValue = (NSString *)[stringArr objectAtIndex:1];
        }
    });
}

- (void)setWindowVisible:(BOOL)windowVisible
{
    if (_windowVisible == windowVisible) return;
    if (windowVisible) {
        [self viewDidAppear];
    } else {
        [self viewDidDisappear];
    }
    _windowVisible = windowVisible;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.downSpeedHistory || object == self.upSpeedHistory) {
        NSKeyValueChange changeKind = [change[NSKeyValueChangeKindKey] integerValue];
        if (changeKind == NSKeyValueChangeInsertion) {
            if (object == self.downSpeedHistory) {
                [self.downSpeedPlotView feed:[(NSNumber*)[self.downSpeedHistory lastObject].value unsignedLongLongValue]];
            } else if (object == self.upSpeedHistory) {
                [self.upSpeedPlotView feed:[(NSNumber*)[self.upSpeedHistory lastObject].value unsignedLongLongValue]];
            }
        }
    } else if (object == self.upSpeedPlotView || object == self.downSpeedPlotView) {
        PointType displayMax = MAX(self.upSpeedPlotView.maxValue, self.downSpeedPlotView.maxValue);
        self.downSpeedPlotView.displayMax = displayMax;
        self.upSpeedPlotView.displayMax = displayMax;
    }
}

- (void)dealloc
{
    if (_observingFlags.upHistory) {
        [self.upSpeedHistory removeObserver:self forKeyPath:@"items"];
    }
    if (_observingFlags.downHistory) {
        [self.downSpeedHistory removeObserver:self forKeyPath:@"items"];
    }
    
    [self.upSpeedPlotView removeObserver:self forKeyPath:@"maxValue"];
    [self.downSpeedPlotView removeObserver:self forKeyPath:@"maxValue"];
}


- (BOOL)isItemLive:(NSDictionary *)item
{
    pid_t pid = (pid_t)[item[kPidKey] integerValue];
    NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
    return app && [[app localizedName] isEqualToString:item[kTitleKey]];
}

// mark : 系统情形
- (void) setupMiscView
{
    NSView* containerView = [[NSView alloc] init];
    miscContainerView = containerView;
    [self.view addSubview:containerView];
    [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.height.equalTo(@103);
        make.top.mas_equalTo(self.view);
    }];
    
    // cpu container
    NSView* colCpuContainerView = [[NSView alloc] init];
    colCpuContainerView.wantsLayer = true;
    [containerView addSubview:colCpuContainerView];
    [colCpuContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(containerView).offset(21);
        make.width.equalTo(@62);
        make.height.equalTo(@80);
        make.top.mas_equalTo(containerView.mas_top);
    }];
    
    NSTextField *cpuTemperatureText = [LMViewHelper createNormalLabel:20 fontColor:[LMAppThemeHelper getTitleColor] fonttype:LMFontTypeRegular];
    cpuTemperatureText.stringValue = @"30°C";
    [colCpuContainerView addSubview:cpuTemperatureText];
    [cpuTemperatureText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(colCpuContainerView.mas_top).offset(28);
        make.centerX.equalTo(colCpuContainerView);
    }];
    _cpuTemperatureText = cpuTemperatureText;
    
    NSTextField* cpuText = [LMViewHelper createNormalLabel:13 fontColor:[NSColor colorWithHex:0x94979B] fonttype:LMFontTypeLight];
    cpuText.stringValue = NSLocalizedStringFromTableInBundle(@"LMSystemFeatureViewController_setupMiscView_cpuText_1", nil, [NSBundle bundleForClass:[self class]], @"");
    [colCpuContainerView addSubview:cpuText];
    [cpuText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cpuTemperatureText.mas_bottom).offset(8);
        make.centerX.equalTo(colCpuContainerView);
    }];
    
    
    // fan container
    NSView* colFanContainerView = [[NSView alloc] init];
    colFanContainerView.wantsLayer = true;
    [containerView addSubview:colFanContainerView];
    [colFanContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@82);
        make.height.equalTo(@80);
        make.centerX.equalTo(containerView);
        make.top.mas_equalTo(containerView.mas_top);
    }];
    
    NSTextField* fanSpeedText = [LMViewHelper createNormalLabel:20 fontColor:[LMAppThemeHelper getTitleColor] fonttype:LMFontTypeRegular];
    fanSpeedText.stringValue = @"30 R";
    [colFanContainerView addSubview:fanSpeedText];
    [fanSpeedText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(colFanContainerView.mas_top).offset(28);
        make.centerX.equalTo(colFanContainerView);
    }];
    _fanSpeedText = fanSpeedText;
    
    NSTextField* fanText = [LMViewHelper createNormalLabel:13 fontColor:[NSColor colorWithHex:0x94979B] fonttype:LMFontTypeLight];
    fanText.stringValue = NSLocalizedStringFromTableInBundle(@"LMSystemFeatureViewController_setupMiscView_fanText_2", nil, [NSBundle bundleForClass:[self class]], @"");
    [colFanContainerView addSubview:fanText];
    [fanText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(fanSpeedText.mas_bottom).offset(8);
        make.centerX.equalTo(colFanContainerView);
    }];
    
  
    
    // system hard disk container
    NSView* hardDiskContainerView = [[NSView alloc] init];
    [containerView addSubview:hardDiskContainerView];
    
    NSTextField *diskUsageLabel = [LMViewHelper createNormalLabel:20 fontColor:[LMAppThemeHelper getTitleColor]];
    diskUsageLabel.font = [NSFontHelper getRegularSystemFont:20];
    [hardDiskContainerView addSubview:diskUsageLabel];
    _diskUsageText = diskUsageLabel;
    
    NSTextField *diskInfoLabel = [LMViewHelper createNormalLabel:13 fontColor:[NSColor colorWithHex:0x94979B]];
    [hardDiskContainerView addSubview:diskInfoLabel];
    diskInfoLabel.font = [NSFontHelper getLightSystemFont:12];
    diskInfoLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMSystemFeatureViewController_setupMiscView_diskInfoLabel_3", nil, [NSBundle bundleForClass:[self class]], @"");
    
    [hardDiskContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.height.equalTo(containerView);
        make.width.equalTo(@65);
        make.right.equalTo(containerView).offset(-28);
    }];
    [diskUsageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(hardDiskContainerView).offset(28);
        make.centerX.equalTo(hardDiskContainerView);
    }];
    
    [diskInfoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(diskUsageLabel.mas_bottom).offset(8);
        make.centerX.equalTo(hardDiskContainerView);
    }];
    
    
    // divide line
    _divideView = [[NSView alloc] init];
    [self.view addSubview:_divideView];
    [_divideView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@1);
        make.bottom.equalTo(containerView);
        make.width.equalTo(containerView).offset(-20);
        make.centerX.equalTo(containerView);
    }];
}


-(void)receivedCPUInfoChanged:(NSNotification *)notification
{
//    double cpuUsage = [[(NSDictionary *)notification.object objectForKey:@"CpuUsage"] doubleValue];
    
}

-(void)receivedNetworkInfoChanged:(NSNotification *)notification
{
    self.upSpeed = [[notification.object objectForKey:@"UpSpeed"] floatValue];
    self.downSpeed = [[notification.object objectForKey:@"DownSpeed"] floatValue];

}

- (NSArray *)stringArrayFromNetSpeedWithoutSpacing:(CGFloat)value
{
    const float oneMB = 1000;
    float _value = 0;
    NSString * formatStr = nil;
    if (value > 1000)
    {
        _value = value / oneMB;
        formatStr = @"MB/s";
    }
    else
    {
        _value = value;
        formatStr = @"KB/s";
    }
    NSMutableArray *netInfoArray = [[NSMutableArray alloc]init];
    [netInfoArray addObject:@(_value)];
    [netInfoArray addObject:formatStr];
    
    return netInfoArray;
}

-(void)receivedTempCpuInfoChanged:(NSNotification *)notification
{
    const long tempCpuThreshold = 70;
    NSDictionary* dict = notification.object;
    double tempCpu = [[dict objectForKey:@"CpuTemp"] doubleValue];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (tempCpu < tempCpuThreshold)
        {
            _cpuTemperatureText.textColor = [LMAppThemeHelper getTitleColor];
        }
        else
        {
            _cpuTemperatureText.textColor = [NSColor colorWithHex:0xE6704C  alpha:1.0];
        }
        _cpuTemperatureText.stringValue = [NSString stringWithFormat:@"%d°C", (int)(tempCpu)];
    });
}

-(void)receivedFanCpuInfoChanged:(NSNotification *)notification{
    const long fanSpeedThreshold = 3000;
    NSDictionary* dict = notification.object;
    float fanSpeed = 0;
    
    NSArray* arrayFans = [dict objectForKey:@"fanArray"];
    if (arrayFans && arrayFans.count > 0)
    {
        for (NSDictionary*dictFan in arrayFans)
        {
            float speed = [[dictFan objectForKey:@"fanSpeed"] floatValue];
            if (speed > fanSpeed)
            {
                fanSpeed = speed;
            }
        }
        //        NSDictionary* dictFan1 = arrayFans[0];
        //        fanSpeed = [[dictFan1 objectForKey:@"fanSpeed"] floatValue];
    }
    else
    {
        NSLog(@"receivedTempCpuInfoChanged:arrayFans=%@", arrayFans);
    }
    //    NSLog(@"receivedTempCpuIn foChanged:cpuTemp=%f,fanSpeed=%f", tempCpu, fanSpeed);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (fanSpeed < fanSpeedThreshold)
        {
            _fanSpeedText.textColor = [LMAppThemeHelper getTitleColor];
        }
        else
        {
            _fanSpeedText.textColor = [NSColor colorWithHex:0xE6704C  alpha:1.0];
        }
        _fanSpeedText.stringValue = [NSString stringWithFormat:@"%d R", (int)(fanSpeed)];
    });
}

// disk info
-(void)receivedDiskInfoChanged:(NSNotification *)notification
{
    NSDictionary* dict = notification.object;
    [self updateDiskInfoWith:dict];
}

-(NSDictionary *)getDiskInfoDict{

    McDiskInfo *diskInfo = [[McDiskInfo alloc] init];
    
    NSArray * volumnesArray = [diskInfo GetVolumesInformation];
    
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    if (volumnesArray)
        [dict setObject:volumnesArray forKey:@"Volumnes"];
    return dict;
}

-(void)updateDiskInfoWith:(NSDictionary*)dict{
    if (dict)
    {
        NSNumber *total = dict[@"total"];
        uint64_t totalBytes = total.unsignedLongLongValue;
        NSNumber *used = dict[@"used"];
        uint64_t usedBytes = used.unsignedLongLongValue;
        uint64_t leftBytes = totalBytes - usedBytes;
//        NSLog(@"%s, usedBytes : %llu", __FUNCTION__, usedBytes);
//        uint64_t freeBytes = 0;
//        uint64_t usedBytes = dict[@"used"];
//        NSArray * volumnesArray = dict[@"Volumnes"];
//        [LMHardWareDataUtil calculateDiskUsageInfoWithMainDiskName:self.mainDiskName volumeArray:volumnesArray freeBytes:&freeBytes totalBytes:&totalBytes];
        //设置磁盘占用百分比
        if (totalBytes > 0){
            double useRate = usedBytes * 1.0/totalBytes;
            dispatch_async(dispatch_get_main_queue(), ^{
                _diskUsageText.stringValue = [NSString stringWithFormat:@"%d%%",(int)round(useRate*100)];
            });
        }
        
        if (totalBytes > 0) {
            NSString *diskSize = [NSString stringWithFormat:@"%@ %@ / %@ %@", NSLocalizedStringFromTableInBundle(@"LMSystemFeatureViewController_initNetworkData_diskSize_1", nil, [NSBundle bundleForClass:[self class]], @""), [NSString stringFromDiskSize:leftBytes], NSLocalizedStringFromTableInBundle(@"LMSystemFeatureViewController_initNetworkData_diskSize_2", nil, [NSBundle bundleForClass:[self class]], @""), [NSString stringFromDiskSize:totalBytes]];
            //从前往后拿单位range
            NSString *firstUnit = [NSString unitStringFromSize:leftBytes diskMode:YES];
            NSRange firstRange = [diskSize rangeOfString:firstUnit];
            NSString *secondUnit = [NSString unitStringFromSize:totalBytes diskMode:YES];
            NSRange secondRange = [diskSize rangeOfString:secondUnit options:NSBackwardsSearch];
            NSRange thirdRange = [diskSize rangeOfString:@"/"];
            NSRange fourthRange = [diskSize rangeOfString:NSLocalizedStringFromTableInBundle(@"LMSystemFeatureViewController_initNetworkData_diskSize_1", nil, [NSBundle bundleForClass:[self class]], @"")];
            NSRange fifthRange = [diskSize rangeOfString:NSLocalizedStringFromTableInBundle(@"LMSystemFeatureViewController_initNetworkData_diskSize_2", nil, [NSBundle bundleForClass:[self class]], @"")];
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:diskSize];
            [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x93979B] range:firstRange];
            [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x93979B] range:secondRange];
            [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x93979B] range:thirdRange];
            [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x93979B] range:fourthRange];
            [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x93979B] range:fifthRange];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.diskSizeLabel setAttributedStringValue:attrString];
            });
        }
    }
}

-(float)getAllUsableBytes{
    if (@available(macOS 10.13, *)) {
        NSError *error = nil;
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:NSHomeDirectory()];
         //TODO: 拿到有效的剩余空间
        NSDictionary *results = [fileURL resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForImportantUsageKey] error:&error];
        if (!results) {
            NSLog(@"Error retrieving resource keys");
            return 0;
        }
        //    NSLog(@"float Available capacity for important usage: %lf",[[results objectForKey:NSURLVolumeAvailableCapacityForImportantUsageKey] floatValue]);
        return [[results objectForKey:NSURLVolumeAvailableCapacityForImportantUsageKey] floatValue];
    }else{
        return 0;
    }
}

-(void)clickDiskCheckButton{
    self.hardwareController = (LemonHardwareWindowController *)[self.delegate getControllerByClassName:[LemonHardwareWindowController className]];
    if(self.hardwareController == nil){
        return;
    }
    //hook 硬件详情多语言
    NSString *languageString = [LanguageHelper getCurrentUserLanguageByReadFile];
    if(languageString != nil){
        [NSBundle setLanguage:languageString bundle:[NSBundle bundleForClass:[LemonHardwareWindowController class]]];
    }
    [self.hardwareController.window makeKeyAndOrderFront:nil];
    [self.hardwareController.window center];
    [[NSNotificationCenter defaultCenter] postNotificationName:QMPopoverDismiss object:nil];
}

-(void)clickOwlView{
    NSLog(@"clickOwlView for click privacy!");
    self.owlController = (OwlWindowController *)[self.delegate getControllerByClassName:[OwlWindowController className]];
    if(self.owlController == nil){
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:QMPopoverDismiss object:nil];
    [self.owlController showWindow:self];
    [self.owlController.window makeKeyWindow];
    [self.owlController.window center];
//    if ([NSRunningApplication runningApplicationsWithBundleIdentifier:MAIN_APP_BUNDLEID].count == 0) {
//        NSArray *arguments = @[[NSString stringWithFormat:@"1"]];
//        [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:DEFAULT_APP_PATH]
//                                                      options:NSWorkspaceLaunchWithoutAddingToRecents
//                                                configuration:@{NSWorkspaceLaunchConfigurationArguments: arguments}
//                                                        error:NULL];
//    } else {
//        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:kShowOwlWindowFromMonitor
//                                                                       object:nil
//                                                                     userInfo:nil
//                                                           deliverImmediately:YES];
//    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:QMPopoverDismiss object:nil];
}

@end
