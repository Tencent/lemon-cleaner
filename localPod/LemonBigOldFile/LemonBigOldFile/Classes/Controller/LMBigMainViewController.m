//
//  LMBigMainViewController.m
//  LemonBigOldFile
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMBigMainViewController.h"
#import "QMLargeOldScanner.h"
#import "QMLargeOldManager.h"
#import "McBigFileWndController.h"
#import "QMProgressView.h"
#import <QMUICommon/LMRectangleButton.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMCoreFunction/NSString+Extension.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <Masonry/Masonry.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/FullDiskAccessPermissionViewController.h>
#import <QMCoreFunction/QMShellExcuteHelper.h>

#ifdef DEBUG
//#define kScanPath   [NSString stringWithFormat:@"/Users/%@/Downloads", NSUserName()]
//#define kScanPath   [NSString stringWithFormat:@"%@/Desktop", NSHomeDirectory()]
#else
#endif

@interface LMBigMainViewController ()<QMLargeOldScannerDelegate>
{
    BOOL _isStopScan;
    BOOL _scanEnd;
    CFAbsoluteTime _startScanTime;
    
    NSInteger _loopCount;
    NSTimer * _scanProgressTime;
    NSTimer * _scanPathTime;
    NSString * _scanPath;
    QMLargeOldScanner * _largeOldScanner;
}

@property (weak) IBOutlet NSView *startView;
@property (weak) IBOutlet NSView *noResultView;
@property (weak) IBOutlet NSView *scanView;
@property (weak) IBOutlet NSTextField *scanTitleLabel;
@property (weak) IBOutlet QMProgressView *scanProgressView;
@property (weak) IBOutlet NSTextField *scanPathLabel;
@property (weak) IBOutlet NSTextField *mainVIewTitleLabel;

@property (weak) IBOutlet NSImageView *picView;
@property (weak) IBOutlet NSTextField *mainViewDescLabel;
@property (weak) IBOutlet LMRectangleButton *mainViewBtn;
@property (weak) IBOutlet NSTextField *noResultTitleLabel;
@property (weak) IBOutlet NSTextField *noResultDescLabel;
@property (weak) IBOutlet LMRectangleButton *scanDoneBtn;
@property (weak) NSImageView *mainBgImageView;
@property (weak) IBOutlet NSButton *cancelBtn;

@end

@implementation LMBigMainViewController

- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        
    }
    return self;
}

-(void)initViewText{ 
    [self.mainVIewTitleLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMBigMainViewController_initViewText_mainVIewTitleLabel_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self setTitleColorForTextField:self.mainVIewTitleLabel];
    [self.mainViewDescLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMBigMainViewController_initViewText_mainViewDescLabel_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.mainViewBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMBigMainViewController_initViewText_mainViewBtn_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.scanTitleLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMBigMainViewController_initViewText_scanTitleLabel_3", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self setTitleColorForTextField:self.scanTitleLabel];
    [self.cancelBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMBigMainViewController_initViewText_cancelBtn_4", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.noResultDescLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMBigMainViewController_initViewText_noResultDescLabel_5", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.scanDoneBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMBigMainViewController_initViewText_scanDoneBtn_6", nil, [NSBundle bundleForClass:[self class]], @"")];
}

-(void)setupViews{
    [self.scanTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.scanView);
        make.top.equalTo(self.picView.mas_bottom).offset(35);
    }];
    
    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.scanTitleLabel.mas_centerY);
        make.left.equalTo(self.scanTitleLabel.mas_right).offset(20);
        make.width.equalTo(@60);
        make.height.equalTo(@24);
    }];
    
    NSImageView *imageView = [[NSImageView alloc]init];
    self.mainBgImageView = imageView;
    NSImage *image = [NSImage imageNamed:@"big_file_main_bg" withClass:self.class];
    [imageView setImage:image];
    [self.view addSubview:imageView];
//    imageView.imageScaling = NSImageScaleProportionallyDown;
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view);
        make.right.equalTo(self.view);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self initViewText];
    [self initView];
}

- (void)initView {
    [self.view addSubview:self.scanView];
    [self.view addSubview:self.noResultView];
    [self showStartView];
    
    //fix 10.10 system font light unavailable
    [self.mainViewDescLabel setFont:[NSFontHelper getLightSystemFont:16]];
    [self.noResultDescLabel setFont:[NSFontHelper getLightSystemFont:14]];
    [self.scanPathLabel setFont:[NSFontHelper getLightSystemFont:12]];
    [self.cancelBtn setFont:[NSFontHelper getLightSystemFont:12]];
}

- (void)showStartView {
    _loopCount = 0;
    [self.scanProgressView setValue:0];
    
    [self.startView setHidden:NO];
    [self.scanView setHidden:YES];
    [self.noResultView setHidden:YES];
    [self.mainBgImageView setHidden:NO];
}

- (void)showScanningView {
    [self.startView setHidden:YES];
    [self.scanView setHidden:NO];
    [self.noResultView setHidden:YES];
    [self.mainBgImageView setHidden:YES];
}

- (void)showNoResultView {
    [self.startView setHidden:YES];
    [self.scanView setHidden:YES];
    [self.noResultView setHidden:NO];
    [self.mainBgImageView setHidden:YES];
    if(_isStopScan) {
        _noResultTitleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMBigMainViewController_showNoResultView__noResultTitleLabel_1", nil, [NSBundle bundleForClass:[self class]], @"");
    } else {
        _noResultTitleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMBigMainViewController_showNoResultView__noResultTitleLabel_2", nil, [NSBundle bundleForClass:[self class]], @"");
    }
    [self setTitleColorForTextField:_noResultTitleLabel];
}

- (void)_updateProgressValue
{
    if (_loopCount > 50 || self.scanProgressView.value > 0.5)
    {
        [_scanProgressTime invalidate];
        _scanProgressTime = nil;
        return;
    }
    
    if (_loopCount % 10 == 0 && _loopCount != 0)
    {
        [_scanProgressTime setFireDate:[NSDate dateWithTimeIntervalSinceNow:5]];
    }
    
    float value = 0.01 * _loopCount;
    if (self.scanProgressView.value < value)
    {
        self.scanProgressView.value = value;
    }
    _loopCount++;
}

- (void)_updateScanPath
{
    if (!_scanPath)
        return;
    [self.scanPathLabel setStringValue:_scanPath];
}

#pragma mark-
#pragma mark user action

- (IBAction)startScanAction:(id)sender {
    
    
    [self showScanningView];
    _isStopScan = NO;
    _scanEnd = NO;
    _startScanTime = CFAbsoluteTimeGetCurrent();
    if ([McCoreFunction isAppStoreVersion]) {
        _scanPath = [NSString stringWithFormat:@"%@", [NSString getUserHomePath]];
    } else {
        _scanPath = [NSString stringWithFormat:@"%@", NSHomeDirectory()];
    }

    [[QMLargeOldManager sharedManager] removeAllResult];
    _largeOldScanner = [[QMLargeOldScanner alloc] init];
    [_largeOldScanner start:self
                       path:_scanPath
               excludeArray:nil];

    _scanProgressTime = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                         target:self
                                                       selector:@selector(_updateProgressValue)
                                                       userInfo:nil
                                                        repeats:YES];
    _scanPathTime = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                     target:self
                                                   selector:@selector(_updateScanPath)
                                                   userInfo:nil
                                                    repeats:YES];
}

- (IBAction)cancelScanAction:(id)sender {
    _isStopScan = YES;
    CFAbsoluteTime curTime = CFAbsoluteTimeGetCurrent();
    int costTimeSeconds = curTime - _startScanTime;
    
    [_largeOldScanner stopScan];
    NSRunLoop *curLoop = [NSRunLoop currentRunLoop];
    while (!_scanEnd)
    {
        [curLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        usleep(1000 * 10);
    }
}

- (IBAction)doneAction:(id)sender {
    [self showStartView];
}

#pragma mark-
#pragma mark Big File delegate

- (void)largeOldFileSearchEnd {
    NSLog(@"largeOldFileSearchEnd");
    _scanEnd = YES;
    
//    CFAbsoluteTime curTime = CFAbsoluteTimeGetCurrent();
//    if (curTime - _startScanTime < 1.5 && !_isStopScan)
//    {
//        [NSThread sleepForTimeInterval:(1.5 - (curTime - _startScanTime))];
//    }
    QMLargeOldManager * largeOldManager = [QMLargeOldManager sharedManager];
    NSArray * array = [_largeOldScanner resultWithType:QMLargeOldOnlyFile fileSize:0];
    for (QMLargeOldItem * item in array)
    {
        //保存在云盘上的文件可能本地不占用磁盘空间，需要根据磁盘空间大小过滤一下
        if ([item.filePath containsString:@"OneDrive"] || [item.filePath containsString:@"Dropbox"]) {
            NSString *path = [self stringEscapeCharacterWith:item.filePath];
            NSString *cmdString = [NSString stringWithFormat:@"du -m %@",path];
            NSString *result = [QMShellExcuteHelper excuteCmd:cmdString];
            NSLog(@"%s, filePath = %@,result = %@", __FUNCTION__, path, result);
            NSArray<NSString *> *array = [result componentsSeparatedByString:@"\t"];
            if (array.count > 0) {
                if(array[0].intValue < 50) {
                    continue;
                }
            }

        }
        [largeOldManager addLargeOldItem:item.filePath
                                fileSize:item.fileSize
                              accessTime:item.lastAccessTime];
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof(self) strongSelf = weakSelf;
        if(strongSelf) {
            [strongSelf->_scanPathTime invalidate];
            strongSelf->_scanPathTime = nil;
            [strongSelf->_scanProgressTime invalidate];
            strongSelf->_scanProgressTime = nil;
            
            // 关闭动画
            //[_scanAnimationView stopAnimation];
            if ([array count] == 0)
            {
                [strongSelf showNoResultView];
            }
            else
            {
                [strongSelf.view.window.windowController showResultView];
            }
        }
    });
}

- (BOOL)progressRate:(float)value path:(NSString *)path {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof(self) strongSelf = weakSelf;
        if(strongSelf) {
            if (value != 0)
            {
                strongSelf.scanProgressView.value = value;
            }
            if (path)
                strongSelf->_scanPath = path;
        }
    });
    return _isStopScan;
}

#pragma mark-
#pragma mark window event

- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"windowWillClose main view controller");
    [_largeOldScanner stopScan];
}

- (NSString *)stringEscapeCharacterWith:(NSString *)string {
    NSString *fileName = [string lastPathComponent];
    NSString *directoryPath = [string stringByDeletingLastPathComponent];
    fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"\\/"];
    string = [directoryPath stringByAppendingPathComponent:fileName];
    string = [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
    string = [string stringByReplacingOccurrencesOfString:@"|" withString:@"\\|"];
    return string;
}



@end
