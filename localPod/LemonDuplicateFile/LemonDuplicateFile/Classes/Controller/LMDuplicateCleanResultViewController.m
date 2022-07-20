//
//  LMDuplicateCleanedViewController.m
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/26.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "LMDuplicateCleanResultViewController.h"
#import <QMCoreFunction/NSImage+Extension.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import "LMDuplicateWindowController.h"
#import "SizeHelper.h"
#import <QMUICommon/RatingUtils.h>
#import <QMUICommon/LMAppThemeHelper.h>

@implementation LMDuplicateCleanResultViewController

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 780, 482)];
    self.view = view;
    self.title = @"";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadView];
    [self initView];
    [self initData];
}


- (void)initData {
    [RatingUtils recordCleanFinishAction];
}

- (void)initView {

    self.imageView = [[NSImageView alloc] init];
    [self.view addSubview:self.imageView];
    NSImage *processImage = [NSImage imageNamed:@"icon_duplicate_clean_complete" withClass:self.class];
    self.imageView.image = processImage;
    self.imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    
    
    NSTextField *cleanTitleLabel = [LMViewHelper createNormalLabel:32 fontColor:[LMAppThemeHelper getTitleColor]];
    cleanTitleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMDuplicateCleanResultViewController_initView_cleanTitleLabel_1", nil, [NSBundle bundleForClass:[self class]], @"");
    self.cleanTitleLabel = cleanTitleLabel;
    [self.view addSubview:cleanTitleLabel];
    
    
    NSTextField *cleanSubTitleLabel = [LMViewHelper createNormalLabel:14 fontColor:[NSColor colorWithHex:0x94979b] fonttype:LMFontTypeLight];
    cleanSubTitleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMDuplicateCleanResultViewController_initView_cleanSubTitleLabel_2", nil, [NSBundle bundleForClass:[self class]], @"");
    self.cleanSubTitleLabel = cleanSubTitleLabel;
    [self.view addSubview:cleanSubTitleLabel];
    
    NSButton *cleanButton = [LMViewHelper createNormalGreenButton:20 title:NSLocalizedStringFromTableInBundle(@"LMDuplicateCleanResultViewController_initView_cleanButton _3", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.view addSubview:cleanButton];
    cleanButton.target = self;
    cleanButton.action = @selector(turnToSelectFileController);
    
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(180);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-211);
    }];
    
    [cleanTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-156);
        make.centerX.equalTo(self.imageView);
    }];
    
    [cleanSubTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-131);
        make.centerX.equalTo(self.imageView);
    }];
    
    
    [cleanButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(148);
        make.height.mas_equalTo(48);
        make.bottom.equalTo(self.view).offset(-58);
        make.centerX.equalTo(self.imageView);
    }];
}

- (void)viewWillAppear{
    if(self.cleanSize > 0){
        NSDictionary *normalAttributes = @{ NSForegroundColorAttributeName:[NSColor colorWithHex:0x94979B],  NSFontAttributeName: [NSFontHelper getLightSystemFont:14]};
        
        NSDictionary *colorAttributes = @{NSForegroundColorAttributeName:[NSColor colorWithHex:0x04D999] };
        
        NSString *numberString = [NSString stringWithFormat:@"%@",[SizeHelper getFileSizeStringBySize:self.cleanSize] ];
        NSString *totalString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMDuplicateCleanResultViewController_viewWillAppear_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""),numberString];
        
        NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc]initWithString:totalString attributes:normalAttributes];
        [attributeString addAttributes:colorAttributes range:NSMakeRange(0, numberString.length)];
        self.cleanSubTitleLabel.attributedStringValue = attributeString;
        
    }else{
        self.cleanSubTitleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMDuplicateCleanResultViewController_viewWillAppear_cleanSubTitleLabel_2", nil, [NSBundle bundleForClass:[self class]], @"");
    }
}

- (void)turnToSelectFileController {
    LMDuplicateWindowController *windowController = self.view.window.windowController;
    if(windowController){
        [windowController showBaseViewController];
    }
}

- (void)windowClose {
    [self.view.window close];
}
@end
