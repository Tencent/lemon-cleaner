//
//  StartViewController.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2018 tencent. All rights reserved.
//

#import "PrivacyStartViewController.h"
#import <QMUICommon/LMViewHelper.h>
#import "PrivacyWindowController.h"
#import <Masonry/Masonry.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>

@interface PrivacyStartViewController (){
    NSImageView *mainbgImagaView;
}

@end

@implementation PrivacyStartViewController

- (instancetype)init {
    self = [super init];
    if (self) {
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


- (void)setupViews {
    NSImageView *imageView = [LMViewHelper createNormalImageView];
    imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    imageView.image = [NSImage imageNamed:@"privacy_clean" withClass:self.class];
//    [self.view addSubview:imageView];


    NSTextField *titleView = [LMViewHelper createNormalLabel:32 fontColor:[LMAppThemeHelper getTitleColor]];
    [self.view addSubview:titleView];
    titleView.stringValue = NSLocalizedStringFromTableInBundle(@"PrivacyStartViewController_setupViews_titleView_1", nil, [NSBundle bundleForClass:[self class]], @"");

    NSTextField *subTitleView = [LMViewHelper createNormalLabel:16 fontColor:[NSColor colorWithHex:0x94979B]];
    [self.view addSubview:subTitleView];
    subTitleView.font = [NSFontHelper getLightSystemFont:16];
    subTitleView.stringValue = NSLocalizedStringFromTableInBundle(@"PrivacyStartViewController_setupViews_subTitleView_2", nil, [NSBundle bundleForClass:[self class]], @"");

    NSButton *startScanButton = [LMViewHelper createNormalGreenButton:20 title:NSLocalizedStringFromTableInBundle(@"PrivacyStartViewController_setupViews_startScanButton _3", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.view addSubview:startScanButton];
    startScanButton.target = self;
    startScanButton.action = @selector(scanButtonClicked);

//    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.width.height.mas_equalTo(180);
//        make.centerY.equalTo(self.view);
//        make.left.equalTo(self.view).offset(100);
//    }];

    [titleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(72);
        make.top.equalTo(self.view).offset(87);
    }];

    [subTitleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleView);
        make.top.equalTo(titleView.mas_bottom).offset(8);
    }];
    
    [startScanButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(148);
        make.height.mas_equalTo(48);
        make.top.equalTo(subTitleView.mas_bottom).offset(62);
        make.left.equalTo(titleView);
    }];
    
    NSImageView *bgImagaView = [[NSImageView alloc]init];
    bgImagaView.imageScaling = NSImageScaleAxesIndependently;
    NSImage *image = [NSImage imageNamed:@"privacy_clean_main_bg" withClass:self.class];
    [bgImagaView setImage:image];
    [self.view addSubview:bgImagaView];
    [bgImagaView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view);
        make.right.equalTo(self.view);
       }];

}

// MARK: button action
- (void)scanButtonClicked {
    PrivacyWindowController *windowController = self.view.window.windowController;
    if(windowController){
        [windowController showScanViewController];
    }
}

@end
