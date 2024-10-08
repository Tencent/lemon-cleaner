//
//  LMDuplicateScanViewController.m
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/21.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "LMDuplicateScanViewController.h"
#import "LMDuplicateWindowController.h"
#import <Masonry/Masonry.h>
#import "QMDuplicateFiles.h"
#import "LMDuplicateScanResultViewController.h"
#import "LMDuplicateFileNotFoundViewController.h"
#import <QMUICommon/QMProgressView.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMBorderButton.h>
#import <QMCoreFunction/QMFileClassification.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import "McDuplicateFilesDelegate.h"
#import "QMDuplicateItemManager.h"
#import <QMUICommon/LMAppThemeHelper.h>

@interface LMDuplicateScanViewController () <McDuplicateFilesDelegate> {
    QMDuplicateFiles *_duplicateFilesScan;
//    LMDuplicateResultViewController *resultViewController;
    NSArray *_resultArray;
    BOOL _interrupt;
    CFAbsoluteTime lastUpdateTime;
    CFAbsoluteTime scanStartTime;
    
    NSString *compareString;   //为了保证做动画的三个点保持不动
    BOOL     compareReMargin;  // 重新做一次布局

}

@property(strong, nonatomic) QMProgressView *scanProgressView;
@property(strong, nonatomic) NSImageView *scanProgressCircleView;
@property(strong, nonatomic) NSTextField *scanProgressTextField;
@property(strong, nonatomic) NSTextField *scanProgressDotTextField;


@end

@implementation LMDuplicateScanViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setProgressViews];
    [self setupTextViews];
    [self startScan];
    scanStartTime = CFAbsoluteTimeGetCurrent();
}

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 780, 482)];
    self.view = view;
}

- (void)setupTextViews {
    NSTextField *titleLabel = [LMViewHelper createNormalLabel:32 fontColor:[LMAppThemeHelper getTitleColor]];
    [self.view addSubview:titleLabel];
    titleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMDuplicateScanViewController_setupTextViews_titleLabel_1", nil, [NSBundle bundleForClass:[self class]], @"");

    NSTextField *progressLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979B]];
    self.scanProgressTextField = progressLabel;
    [self.view addSubview:progressLabel];
    progressLabel.font = [NSFontHelper getLightSystemFont:12];
    progressLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;

    NSTextField *progressDotSuffixLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979B]];
    self.scanProgressDotTextField = progressDotSuffixLabel;
    [self.view addSubview:progressDotSuffixLabel];
    progressDotSuffixLabel.font = [NSFontHelper getLightSystemFont:12];
    
    LMBorderButton *cancelButton = [[LMBorderButton alloc] init];

    [self.view addSubview:cancelButton];
    cancelButton.title = NSLocalizedStringFromTableInBundle(@"LMDuplicateScanViewController_setupTextViews_cancelButton_2", nil, [NSBundle bundleForClass:[self class]], @"");
    cancelButton.target = self;
    cancelButton.action = @selector(cancelButtonClick);
    cancelButton.font = [NSFont systemFontOfSize:12];

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-128);
    }];

    [progressLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-96);
        make.centerX.equalTo(self.view);
        make.width.lessThanOrEqualTo(@380);
    }];
    
    [progressDotSuffixLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(progressLabel);
        make.left.equalTo(progressLabel.mas_right);
    }];

    [cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@60);
        make.height.equalTo(@24);
        make.centerY.equalTo(titleLabel).offset(2);
        make.left.equalTo(titleLabel.mas_right).offset(16);
    }];
}

- (void)setProgressViews {

    self.scanProgressCircleView = [[NSImageView alloc] init];
    [self.view addSubview:self.scanProgressCircleView];
    NSImage *processImage = [NSImage imageNamed:@"duplicate_main" withClass:self.class];
    self.scanProgressCircleView.image = processImage;

    self.scanProgressView = [[QMProgressView alloc] initWithFrame:NSMakeRect(61, 192, 300, 5)];
    [self.view addSubview:self.scanProgressView];
    self.scanProgressView.minValue = 0.0;
    self.scanProgressView.maxValue = 1.0;
    self.scanProgressView.value = 0.0;
    [self.scanProgressView setWantsLayer:YES];


    [self.scanProgressCircleView mas_makeConstraints:^(MASConstraintMaker *make) {
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


- (void)startScan {
    _duplicateFilesScan = [[QMDuplicateFiles alloc] init];
    [_duplicateFilesScan start:self path:_pathArray excludeArray:nil];
    [self.scanProgressView setValue:0.0];

}

// 外部调用停止 scan
- (void)stopScan{
    _interrupt = YES;
}

// MARK: button action
- (void)cancelButtonClick {
    _interrupt = YES;
    
    CFTimeInterval now = CFAbsoluteTimeGetCurrent();
    CFTimeInterval timeOffset = now - scanStartTime;
    if(timeOffset > 1 * 60 * 60 ){ // 1小时
        timeOffset = -1;
    }
}

//设置进度显示 BOOL 表示是否中断 特别注意
- (BOOL)progressRate:(float)value progressStr:(NSString *)path {

//    NSLog(@"DuplicateFile progressRate->rate : %f, path:%@", value, path);
    dispatch_async(dispatch_get_main_queue(), ^{
    

        if (path) {
            
            NSString *tempPath = path;
            NSString *tempPathSuffix = nil;
            //含有 "正在比对中"时, 保证只有扫描后面的三个点...动 
            if([path containsString:NSLocalizedStringFromTableInBundle(@"LMDuplicateScanViewController_progressRate_1553072147_1", nil, [NSBundle bundleForClass:[self class]], @"")]){
                
                if([path containsString:@"..."]){
                    tempPath = [path stringByReplacingOccurrencesOfString:@"..." withString:@""];
                    tempPathSuffix = @"...";
                }else if ([path containsString:@".."]){
                    tempPath = [path stringByReplacingOccurrencesOfString:@".." withString:@""];
                    tempPathSuffix = @"..";
                }else {
                    tempPath = [path substringToIndex:path.length -1];
                    tempPathSuffix = @".";
                }
                self.scanProgressDotTextField.stringValue = tempPathSuffix;
            }else{
                self.scanProgressDotTextField.stringValue = @"";
            }
            if ([tempPath isKindOfClass:NSString.class] && tempPath.length > 0) {
                self.scanProgressTextField.stringValue = tempPath;
            }
        }
    
        //防止进度条更新频率过高
        CFAbsoluteTime timeInSeconds = CFAbsoluteTimeGetCurrent();
        if(timeInSeconds - self->lastUpdateTime > 0.10){
            [self.scanProgressView setValue:(value)];
            self->lastUpdateTime = timeInSeconds;
        }
        
     
    });
    return _interrupt;
}

- (void)addDuplicateFileRecord:(NSArray *)pathArray totalSize:(uint64_t)size {

    if(self.windowController){
        [self.windowController.itemManager addDuplicateItem:pathArray
                                              fileSize:size];
    }

}

- (void)duplicateFileSearchEnd {

    dispatch_async(dispatch_get_main_queue(), ^{
        
        LMDuplicateWindowController *windowController = self.view.window.windowController;
        if(windowController){
            self->_resultArray = [windowController.itemManager duplicateArrayWithType:QMFileTypeAll];
        }
        [self toResultViewController];
    });
}

- (void)toResultViewController {
    if (_resultArray.count == 0) {
        LMDuplicateFileNotFoundViewController *controller = [[LMDuplicateFileNotFoundViewController alloc] init];
        controller.isScanCancel = _interrupt;
        self.view.window.contentViewController = controller;
    } else {
        LMDuplicateScanResultViewController *resultViewController = [[LMDuplicateScanResultViewController alloc] init];
        resultViewController.resultArray = _resultArray;
        self.view.window.contentViewController = resultViewController;
    }
}

- (BOOL)cancelScan{
    return _interrupt;
}


@end
