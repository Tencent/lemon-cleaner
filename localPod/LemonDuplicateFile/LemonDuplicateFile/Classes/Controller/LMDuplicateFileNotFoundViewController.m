//
//  LMDuplicateFileNotFoundViewController.m
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/28.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "LMDuplicateFileNotFoundViewController.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import "LMDuplicateWindowController.h"
#import <QMUICommon/LMAppThemeHelper.h>
@implementation LMDuplicateFileNotFoundViewController

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 780, 482)];
    self.view = view;
    self.title = @"";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadView];
    [self initView];
}


- (void)initView {
    NSImageView *imageView = [[NSImageView alloc] init];
    self.imageView = imageView;
    imageView.image = [NSImage imageNamed:@"duplicate_main" withClass:self.class];
    [self.view addSubview:imageView];

    NSTextField *textField = [LMViewHelper createNormalLabel:32 fontColor:[LMAppThemeHelper getTitleColor]];
    [self.view addSubview:textField];
    self.descLabel = textField;


    NSButton *button = [LMViewHelper createNormalGreenButton:20 title:NSLocalizedStringFromTableInBundle(@"LMDuplicateFileNotFoundViewController_initView_button _1", nil, [NSBundle bundleForClass:[self class]], @"")];
    button.target = self;
    button.action = @selector(turnToSelectFileController);
    [self.view addSubview:button];

    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(180);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-211);
    }];

    [textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-131);
        make.centerX.equalTo(self.view);
    }];

    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@148);
        make.height.equalTo(@48);
        make.bottom.equalTo(self.view).offset(-58);
        make.centerX.equalTo(self.view);
    }];
}

- (void)viewWillAppear{
    if(_isScanCancel){
        self.descLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMDuplicateFileNotFoundViewController_viewWillAppear_descLabel_1", nil, [NSBundle bundleForClass:[self class]], @"");
    }else{
        self.descLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMDuplicateFileNotFoundViewController_viewWillAppear_descLabel_2", nil, [NSBundle bundleForClass:[self class]], @"");
    }
}

- (void)turnToSelectFileController {
    LMDuplicateWindowController *windowController = self.view.window.windowController;
    if(windowController){
        [windowController showBaseViewController];
    }
}

@end
