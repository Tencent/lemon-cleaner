//
//  LMSpaceMainViewController.m
//  LemonSpaceAnalyse
//
//  
//

#import "LMSpaceMainViewController.h"
#import <QMUICommon/LMRectangleButton.h>
#import <Masonry/Masonry.h>
#import "LMFileScanManager.h"
#import "McSpaceAnalyseWndController.h"
#import "QMProgressView.h"
#import "LMItem.h"
#import <QMUICommon/LMBigLoadingView.h>
#import <QMUICommon/LMBorderButton.h>
#import <QMCoreFunction/QMEnvironmentInfo.h>
#import "NSColor+Extension.h"
#import "LMThemeManager.h"
#import <QMCoreFunction/LMBookMark.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMCoreFunction/NSString+Extension.h>
#import <QMCoreFunction/QMFullDiskAccessManager.h>

#define kSpaceStartPath @"/"///Users/lemon/Downloads

@interface LMSpaceMainViewController ()<LMFileScanManagerDelegate,NSOpenSavePanelDelegate>


@property (weak) IBOutlet NSTextField *mainViewTitle;
@property (weak) IBOutlet NSTextField *mainViewDesc;
@property (weak) IBOutlet LMRectangleButton *mainViewStartButton;


@property (weak) IBOutlet NSTextField *scanViewTitle;
@property (weak) IBOutlet NSTextField *scanViewDesc;
@property (weak) IBOutlet NSImageView *scanViewImageView;
@property (weak) IBOutlet QMProgressView *scanViewProgressView;
@property (weak) IBOutlet LMBorderButton *scanViewCancelButton;

@property(nonatomic, strong) LMFileScanManager *scanManager;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, strong) NSTimer *finishTimer;
@property(nonatomic, assign) int animateCount;
@property(nonatomic, assign) long timerNum;
@property(nonatomic, strong) NSImageView *mainBgImageView;
@property(nonatomic, assign) BOOL isRestart;

@end

@implementation LMSpaceMainViewController

- (instancetype)init {
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        _scanManager = [[LMFileScanManager alloc] init];
        _scanManager.delegate = self;
        _timerNum = 0;
        _animateCount = 0;
        _isRestart = NO;

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self initView];
}

-(void)viewWillLayout{
    [super viewWillLayout];
    if([LMThemeManager cureentTheme] == YES){
        self.scanViewTitle.textColor = [NSColor whiteColor];
    }else{
        self.scanViewTitle.textColor = [NSColor colorWithHex:0x515151 alpha:1];
    }
}
    
- (void)setupViews {
    
    if([LMThemeManager cureentTheme] == YES){
        self.scanViewTitle.textColor = [NSColor whiteColor];
    }else{
        self.scanViewTitle.textColor = [NSColor colorWithHex:0x515151 alpha:1];
    }
    
    NSImageView *imageView = [[NSImageView alloc]init];
    self.mainBgImageView = imageView;
    NSImage *image = [NSImage imageNamed:@"img_disk_space" withClass:[self class]] ;

    [imageView setImage:image];
    imageView.imageScaling = NSImageScaleAxesIndependently;
    [self.view addSubview:imageView];
    
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view);
        make.right.equalTo(self.view);
        make.width.equalTo(@(720.7));
        make.height.equalTo(@(406));
    }];
}

- (void)initView {
    
    
    self.mainViewTitle.stringValue = NSLocalizedStringFromTableInBundle(@"Disk Analyzer", nil, [NSBundle bundleForClass:[self class]], @"");

    self.mainViewDesc.stringValue = NSLocalizedStringFromTableInBundle(@"Visually analyze file occupancy and explore storage conditions", nil, [NSBundle bundleForClass:[self class]], @"");
    
    self.mainViewStartButton.title = NSLocalizedStringFromTableInBundle(@"Start", nil, [NSBundle bundleForClass:[self class]], @"");
    
    self.scanViewTitle.stringValue = NSLocalizedStringFromTableInBundle(@"Scanning Macintosh HD", nil, [NSBundle bundleForClass:[self class]], @"");
    self.scanViewCancelButton.title =NSLocalizedStringFromTableInBundle(@"Cancel", nil, [NSBundle bundleForClass:[self class]], @"");
    
    [self.view addSubview:self.scanView];
    self.scanViewProgressView.value = 0.0;
    [self showStartView];
}

- (void)showStartView {
    [self.startView setHidden:NO];
    [self.scanView setHidden:YES];
    self.mainBgImageView.hidden = NO;

    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
        self.timerNum = 0;
    }
}

- (void)restartScan {
    self.isRestart = YES;
    [self.scanManager startWithRootPath:kSpaceStartPath];///Users/lemon/Downloads
    [self showScanView];
}

- (void)showScanView {
    [self.startView setHidden:YES];
    [self.scanView setHidden:NO];
    self.mainBgImageView.hidden = YES;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0/25 target:self selector:@selector(startLoadView) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    [self.timer fire];
}

- (void)startLoadView{
    self.timerNum ++;
    NSString *loadImage = [NSString stringWithFormat:@"ani_scanning_000%02ld",self.timerNum%30];
    NSImage *image = [NSImage imageNamed:loadImage withClass:[self class]] ;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.scanViewImageView.image = image;
    });
}

- (void)startFinishAni {
    
    [self scanViewsIsHidden:YES];
    self.finishTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/25
                                                   target:self
                                                 selector:@selector(_refreshAnimateState)
                                                 userInfo:nil
                                                  repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.finishTimer forMode:NSRunLoopCommonModes];
    [self.finishTimer fire];
}

- (void)_refreshAnimateState {

    if(_animateCount > 49) {
        
        [_finishTimer invalidate];
        _finishTimer = nil;
        [self enterResultView];
        _animateCount = 0;
        
        return;
    }
    NSString* picName =[NSString stringWithFormat:@"ani_scan_finish_000%02d",self.animateCount];
    NSImage* image = [NSImage imageNamed:picName withClass:[self class]];
    [self.scanViewImageView setImage:image];
    self.animateCount++;
}


- (void)scanViewsIsHidden:(BOOL)result {
    self.scanViewTitle.hidden = result;
    self.scanViewDesc.hidden = result;
    self.scanViewCancelButton.hidden = result;
    self.scanViewProgressView.hidden = result;
}

- (void)enterResultView {
    LMItem *topItem = self.scanManager.topItem;
    self.scanManager.topItem = nil;

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof(self) strongSelf = weakSelf;
        if(strongSelf) {
            [strongSelf.view.window.windowController showResultView];
            [strongSelf scanViewsIsHidden:NO];
            [strongSelf.scanViewImageView setImage:[NSImage imageNamed:@"ani_scanning_00000" withClass:[self class]]];
            if ([strongSelf.delegete respondsToSelector:@selector(spaceMainViewControllerEnd:)]) {
                [strongSelf.delegete spaceMainViewControllerEnd:topItem];
            }
        }
    });
}

- (void)SpaceMainWindowShouldClose{
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Continue", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Stop", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert setMessageText:NSLocalizedStringFromTableInBundle(@"Stop the scanning？", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert setInformativeText:NSLocalizedStringFromTableInBundle(@"It will discard all current progress.", nil, [NSBundle bundleForClass:[self class]], @"")];

    [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == 1001) {
            [self.scanManager cancel];
            if (self.timer) {
                [self.timer invalidate];
                self.timer = nil;
                self.timerNum = 0;
            }
            [[self.view window] close];
        }
    }];
}

#pragma mark - Action

#pragma mark -- panel delegate
-(void)showOpenPanelGetPermission{
    NSString *userPath = @"/";
    
    NSLog(@"userpath = %@", userPath);
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    openDlg.allowsMultipleSelection = YES;
    openDlg.canChooseDirectories = YES;
    openDlg.canChooseFiles = YES;
    [openDlg setPrompt:NSLocalizedStringFromTableInBundle(@"Grant access", nil, [NSBundle bundleForClass:[self class]], @"")];
    openDlg.delegate = self;
    openDlg.message = NSLocalizedStringFromTableInBundle(@"Please authorize access to Macintosh HD to continue", nil, [NSBundle bundleForClass:[self class]], @"");
    openDlg.directoryURL = [NSURL URLWithString:userPath];
    __weak __typeof(self) weakSelf = self;
    [openDlg beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if(result == NSModalResponseOK){
            NSLog(@"click ok");
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                NSArray *urls = [openDlg URLs];
                NSURL *url = [urls objectAtIndex:0];
                NSString *path = [url path];
                NSLog(@"user select complate path = %@ and userPath = %@", path, userPath);
                if ([path isEqualToString:userPath] || [path hasSuffix:userPath]) {
                    NSLog(@"start to save bookmark to defaults");
                    [[LMBookMark defaultShareBookmark] saveBookmarkWithFilePath:userPath];
                }
            }
        }else{
            NSLog(@"click cancel");
        }
    }];
}

#pragma mark -- NSOpenSavePanelDelegate
#pragma mark -- - 获取权限选择方法回调
- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url NS_AVAILABLE_MAC(10_6){
    NSLog(@"user select shouldEnableURL = %@", [url path]);
    NSString *userPath = @"/";
    if([[url path] isEqualToString:userPath] || [[url path] hasSuffix:userPath])
        return YES;
    return NO;
}

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError NS_AVAILABLE_MAC(10_6){
    NSLog(@"user select validateURL = %@", [url path]);
    NSString *userPath = @"/";
    if([[url path] isEqualToString:userPath] || [[url path] hasSuffix:userPath])
        return YES;
    return NO;
}
- (IBAction)startScanBtn:(id)sender {
    
    NSString *userPath = @"/";
    BOOL isUserGiveFullPathPermission = [[LMBookMark defaultShareBookmark] accessingSecurityScopedResourceWithFilePath:userPath];
    BOOL fullDiskAccess = [QMFullDiskAccessManager getFullDiskAuthorationStatus] == QMFullDiskAuthorationStatusAuthorized;
    if (isUserGiveFullPathPermission == NO && fullDiskAccess == NO) {
        [self showOpenPanelGetPermission];
        return;
    }
    
    [self.scanManager startWithRootPath:kSpaceStartPath];////Users/lemon/Downloads
    [self showScanView];
}

- (IBAction)cancelScanBtn:(id)sender {
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Continue", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Stop", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert setMessageText:NSLocalizedStringFromTableInBundle(@"Stop the scanning？", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert setInformativeText:NSLocalizedStringFromTableInBundle(@"It will discard all current progress.", nil, [NSBundle bundleForClass:[self class]], @"")];
      
    [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == 1001) {
            [self.scanManager cancel];
            if (self.timer) {
                [self.timer invalidate];
                self.timer = nil;
                self.timerNum = 0;
            }
        }
    }];
}

#pragma mark - LMFileScanManagerDelegate

- (void)progressRate:(float)value progressStr:(NSString *)path {
    float valueNew = value;
    if (value > 1) {
        valueNew = 1;
    }
    value = 0;
    if(path == nil){
        path = @"";
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.scanViewProgressView.value = valueNew;
        strongSelf.scanViewDesc.stringValue = path;
    });
}

- (void)end {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
        self.timerNum = 0;
    }
    
    if ([self.scanManager isCancel]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            [strongSelf showStartView];
            strongSelf.scanManager.topItem = nil;
            strongSelf.scanManager.isCancel = NO;
        });
        return;
    }
    //计算各文件大小
    self.scanManager.topItem.sizeInBytes = [self.scanManager.topItem calculateSizeInBytesRecursively];
    [self.scanManager.topItem compareChild];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [strongSelf startFinishAni];
    });
}

#pragma mark - over

- (void)windowWillClose:(NSNotification *)notification {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
        self.timerNum = 0;
    }
    if (self.finishTimer) {
        [self.finishTimer invalidate];
        self.finishTimer = nil;
        self.animateCount = 0;
    }
}

- (void)dealloc {
//    NSLog(@"__%s__",__FUNCTION__);
}

@end
