//
//  ScanViewController.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "PrivacyScanViewController.h"
#import <QMUICommon/QMProgressView.h>
#import <Masonry/Masonry.h>
#import "PrivacyWindowController.h"
#import "PrivacyDataManager.h"
#import "RunningAppPopViewController.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/NSFontHelper.h>

#define Max_Process_Time 1.0


@interface PrivacyScanViewController () <ScanDelegate>


@property(strong, nonatomic) QMProgressView *scanProgressView;
@property(strong, nonatomic) NSImageView *scanProgressImageView;
@property(strong, nonatomic) NSTextField *scanProgressTextField;
@property(strong, nonatomic) PrivacyDataManager *manager;
@property(readwrite, assign) ScanType scanType;
@property(readwrite, assign) float process;

@end

@implementation PrivacyScanViewController{
    CFAbsoluteTime lastUpdateTime;
    NSTimer *timer;
    CFAbsoluteTime startTime;
    PrivacyData *resultData;
}


- (instancetype)init:(ScanType)type {
    self = [super init];
    if (self) {
        self.scanType = type;
        [self loadView];
    }

    return self;
}

- (void)loadView {
    NSRect rect = NSMakeRect(0, 0, 780, 482);
    NSView *view = [[NSView alloc] initWithFrame:rect];
    self.view = view;
    [self viewDidLoad];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
}

- (void)viewWillDisappear{
    [self resetDataAndStopTimer];
}

- (void)setupViews {
    [self setProgressViews];
    [self setupTextViews];
}

// 开始扫描
- (void)startToScan {
    self.manager = [[PrivacyDataManager alloc] init];
    self.manager.delegate = self;

    NSArray *array = [PrivacyDataManager getInstalledAndRunningBrowserApps];
    if (!array) {
        array = [NSMutableArray alloc];
    }

    NSInteger appRunningNum = 0;
    for (BrowserApp *app in array) {
        if (app.isRunning) {
            appRunningNum++;
        }
    }

    [self startTimer];
    [self startToInnerScan:array needKill:NO];

}

- (void)startToInnerScan:(NSArray *)apps needKill:(BOOL)killFlag {
    [self.manager killAppsAndToScan:apps needKill:killFlag];
}

// 开始清理
- (void)startToCleanWithData:(PrivacyData *)data runningApps:(NSArray *)apps needKill:(BOOL)killFlag {
    
    [self startTimer];
    self.manager = [[PrivacyDataManager alloc] init];
    self.manager.delegate = self;
    [self.manager killAppAndCleanWithData:data runningApps:apps needKill:killFlag];
}


-(void)resetDataAndStopTimer{
    self.manager = nil;
    self.process = 0.0;
    self->resultData = nil;
    [self cancelTimerIfNeeed];
}

- (void)startTimer{
    [self cancelTimerIfNeeed];
    startTime = CFAbsoluteTimeGetCurrent();
    timer = [NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(showProcess) userInfo:nil repeats:YES];
}

-(void)cancelTimerIfNeeed{
    
    NSLog(@"cancelTimerIfNeeed...");
    
    if (timer && timer.isValid) {
        [timer invalidate];  // 从运行循环中移除， 对运行循环的引用进行一次 release
        timer=nil;            // 将销毁定时器
    }
    
}

-(void)showProcess{
    
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime deltaTime = now - startTime;
    //采用保证扫描时间大于Max_Process_Time
    if(deltaTime < Max_Process_Time){
        [self.scanProgressView setValue:(float) self.process];
        return;
    }
    
    [self.scanProgressView setValue:(float) self.process];
    if(self.process >= 1.0 && self->resultData){
        [self cancelTimerIfNeeed];
        [self turnToNextController];
    }
   
}

- (void)cancelScanPrivateData {
    [self resetDataAndStopTimer];
    [self.view.window close];
}


- (void)setupTextViews {
    NSTextField *titleLabel = [LMViewHelper createNormalLabel:32 fontColor:[LMAppThemeHelper getTitleColor]];
    [self.view addSubview:titleLabel];

    switch (self.scanType) {
        case ScanTypeGet:
            titleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"PrivacyScanViewController_setupTextViews_titleLabel_1", nil, [NSBundle bundleForClass:[self class]], @"");
            break;
        case ScanTypeClean:
            titleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"PrivacyScanViewController_setupTextViews_titleLabel_2", nil, [NSBundle bundleForClass:[self class]], @"");
            break;
    }


    NSTextField *progressLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979B]];
    progressLabel.font = [NSFontHelper getLightSystemFont:12];
    [self.view addSubview:progressLabel];
    self.scanProgressTextField = progressLabel;


    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-128);
    }];

    [progressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-96);
    }];

}

- (void)setProgressViews {
    self.scanProgressImageView = [[NSImageView alloc] init];
    [self.view addSubview:self.scanProgressImageView];
    NSImage *processImage = [NSImage imageNamed:@"privacy_clean" withClass:self.class];
    self.scanProgressImageView.image = processImage;
    self.scanProgressImageView.imageScaling = NSImageScaleProportionallyUpOrDown;

    self.scanProgressView = [[QMProgressView alloc] initWithFrame:NSMakeRect(61, 192, 300, 5)];
    [self.view addSubview:self.scanProgressView];
    self.scanProgressView.minValue = 0.0;
    self.scanProgressView.maxValue = 1.0;
    self.scanProgressView.value = 0.0;
    [self.scanProgressView setWantsLayer:YES];


    [self.scanProgressImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(180);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-200);
    }];

    [self.scanProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(300);
        make.height.mas_equalTo(5);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-77);
    }];

}


- (void)scanStart {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.scanProgressView.value = 0;
    });
}


- (void)scanEnd:(PrivacyData *)privacyData {
    NSDate *now = [NSDate date];
    NSLog(@"scanEnd : time %f" , now.timeIntervalSince1970);
    dispatch_async(dispatch_get_main_queue(), ^{ //
        self.process = 1.0;
        self->resultData = privacyData;
        
    });

}


- (void)scanProcess:(double)processValue text:(NSString *)progressText {
    NSDate *now = [NSDate date];

    NSLog(@"scanProcess : processValue :%f , time %f", processValue , now.timeIntervalSince1970);
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.process = processValue;
        if (progressText) {
            self.scanProgressTextField.stringValue = progressText;
        }
     
    });
}

-(void)turnToNextController{
    self.process = 1.0;
    self.scanProgressView.value = 1;
    
    PrivacyWindowController *windowController = self.view.window.windowController;
    if (windowController) {
        
        switch (self.scanType) {
            case ScanTypeGet:
                [windowController showDataResultViewController:self->resultData];
                break;
            case ScanTypeClean:
                [windowController showCleanResultViewController:self->resultData];
                break;
        }
    }
}

@end
