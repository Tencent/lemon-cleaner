//
//  ResultViewController.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "PrivacyCleanResultViewController.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/LMAppThemeHelper.h>

@interface PrivacyCleanResultViewController ()
@property(strong, nonatomic) NSImageView *scanProgressCircleView;
@property(strong, nonatomic) NSTextField *cleanTitleLabel;
@property(strong, nonatomic) NSTextField *cleanSubTitleLabel;

@end

@implementation PrivacyCleanResultViewController

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
    self.scanProgressCircleView = [[NSImageView alloc] init];
    [self.view addSubview:self.scanProgressCircleView];
    NSImage *processImage = [NSImage imageNamed:@"privacy_clean_complete" withClass:self.class];
    self.scanProgressCircleView.image = processImage;
    self.scanProgressCircleView.imageScaling = NSImageScaleProportionallyUpOrDown;

    
    NSTextField *cleanTitleLabel = [LMViewHelper createNormalLabel:32 fontColor:[LMAppThemeHelper getTitleColor]];
    cleanTitleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"PrivacyCleanResultViewController_setupViews_cleanTitleLabel_1", nil, [NSBundle bundleForClass:[self class]], @"");
    self.cleanTitleLabel = cleanTitleLabel;
    [self.view addSubview:cleanTitleLabel];

    
    NSTextField *cleanSubTitleLabel = [LMViewHelper createNormalLabel:14 fontColor:[NSColor colorWithHex:0x515151]];
    cleanSubTitleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"PrivacyCleanResultViewController_setupViews_cleanSubTitleLabel_2", nil, [NSBundle bundleForClass:[self class]], @"");
    self.cleanSubTitleLabel = cleanSubTitleLabel;
    [self.view addSubview:cleanSubTitleLabel];

    NSButton *cleanButton = [LMViewHelper createNormalGreenButton:20 title:NSLocalizedStringFromTableInBundle(@"PrivacyCleanResultViewController_setupViews_cleanButton _3", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.view addSubview:cleanButton];
    cleanButton.target = self;
    cleanButton.action = @selector(cleanButtonClicked);

    [self.scanProgressCircleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(180);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-211);
    }];

    [cleanTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-156);
        make.centerX.equalTo(self.scanProgressCircleView);
    }];
    
    [cleanSubTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-131);
        make.centerX.equalTo(self.scanProgressCircleView);
    }];


    [cleanButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(148);
        make.height.mas_equalTo(48);
        make.bottom.equalTo(self.view).offset(-58);
        make.centerX.equalTo(self.scanProgressCircleView);
    }];
}

- (void)viewWillAppear{
    if(_cleanNum > 0){
        NSDictionary *normalAttributes = @{ NSForegroundColorAttributeName:[NSColor colorWithHex:0x94979B],  NSFontAttributeName: [NSFontHelper getLightSystemFont:14]};
        
        NSDictionary *colorAttributes = @{NSForegroundColorAttributeName:[NSColor colorWithHex:0x04D999],
                                          NSFontAttributeName: [NSFontHelper getLightSystemFont:14]
                                          };
        
        NSString *numberString = [NSString stringWithFormat:@"%ld",(long)_cleanNum];
        NSString *totalString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"PrivacyCleanResultViewController_viewWillAppear_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""),numberString];
        
        NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc]initWithString:totalString attributes:normalAttributes];
        [attributeString addAttributes:colorAttributes range:NSMakeRange(0, numberString.length)];
        self.cleanSubTitleLabel.attributedStringValue = attributeString;
        
    }else{
        self.cleanSubTitleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"PrivacyCleanResultViewController_viewWillAppear_cleanSubTitleLabel_2", nil, [NSBundle bundleForClass:[self class]], @"");
    }
}

// MARK: button action
- (void)cleanButtonClicked {
    [self.view.window.windowController close];
}


@end
