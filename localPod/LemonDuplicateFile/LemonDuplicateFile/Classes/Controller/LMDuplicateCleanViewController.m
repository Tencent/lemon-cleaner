//
//  LMDuplicateCleanViewController.m
//  LemonDuplicateFile
//
//  Created by tencent on 2024/3/11.
//

#import "LMDuplicateCleanViewController.h"
#import <Masonry/Masonry.h>
#import "QMDuplicateFiles.h"
#import <QMUICommon/QMProgressView.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMBorderButton.h>
#import <QMCoreFunction/QMFileClassification.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import "QMDuplicateItemManager.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import "LMDuplicateCleanResultViewController.h"


@interface LMDuplicateCleanViewController ()

@property(strong, nonatomic) QMProgressView *cleanProgressView;
@property(strong, nonatomic) NSImageView *cleanProgressCircleView;
@property(strong, nonatomic) NSTextField *cleanProgressTextField;

@end

@implementation LMDuplicateCleanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setProgressViews];
    [self setupTextViews];
    [self.cleanProgressView setValue:0.0];
}

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 780, 482)];
    self.view = view;
}

- (void)setupTextViews {
    NSTextField *titleLabel = [LMViewHelper createNormalLabel:32 fontColor:[LMAppThemeHelper getTitleColor]];
    [self.view addSubview:titleLabel];
    titleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMDuplicateCleanViewController_setupTextViews_titleLabel_1", nil, [NSBundle bundleForClass:[self class]], @"");

    NSTextField *progressLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979B]];
    self.cleanProgressTextField = progressLabel;
    [self.view addSubview:progressLabel];
    progressLabel.font = [NSFontHelper getLightSystemFont:12];
    progressLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    
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
    
    [cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@60);
        make.height.equalTo(@24);
        make.centerY.equalTo(titleLabel).offset(2);
        make.left.equalTo(titleLabel.mas_right).offset(16);
    }];
}

- (void)setProgressViews {
    self.cleanProgressCircleView = [[NSImageView alloc] init];
    [self.view addSubview:self.cleanProgressCircleView];
    NSImage *processImage = [NSImage imageNamed:@"duplicate_main" withClass:self.class];
    self.cleanProgressCircleView.image = processImage;

    self.cleanProgressView = [[QMProgressView alloc] initWithFrame:NSMakeRect(61, 192, 300, 5)];
    [self.view addSubview:self.cleanProgressView];
    self.cleanProgressView.minValue = 0.0;
    self.cleanProgressView.maxValue = 1.0;
    self.cleanProgressView.value = 0.0;
    [self.cleanProgressView setWantsLayer:YES];

    [self.cleanProgressCircleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(180);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-200);
    }];

    [self.cleanProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(300);
        make.height.mas_equalTo(5);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-77);
    }];
}

#pragma mark - cancel button

- (void)cancelButtonClick {
    LMDuplicateWindowController *windowController = self.view.window.windowController;
    [windowController.itemManager cancelCleaning];
}

#pragma mark - QMDuplicateItemManagerDelegate

- (void)cleanDuplicateItemBegin {
    NSLog(@"%s", __func__);
}

- (void)cleanDuplicateItem:(NSString *)path currentIndex:(NSInteger)index totalItemCounts:(NSInteger)total {
    dispatch_async(dispatch_get_main_queue(), ^{
        float progressValue = (index + 1)/fmax(total, 1.0);
        progressValue = fmax(0, progressValue);
        progressValue = fmin(1.0, progressValue);
        [self.cleanProgressView setValue:(progressValue)];

        self.cleanProgressTextField.stringValue = path ? path : @"";
    });
}

- (void)cleanDuplicateItemEnd:(uint64)cleanSize {
    NSLog(@"%s", __func__);
    dispatch_async(dispatch_get_main_queue(), ^{
        LMDuplicateCleanResultViewController *controller = [[LMDuplicateCleanResultViewController alloc] init];
        controller.cleanSize = cleanSize;
        self.view.window.contentViewController = controller;
    });
}

@end
