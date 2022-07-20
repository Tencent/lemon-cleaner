//
//  LMNoSimilarPhotoResultViewController.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMNoSimilarPhotoResultViewController.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMViewHelper.h>
#import "LMPhotoCleanerWndController.h"

@interface LMNoSimilarPhotoResultViewController ()
@property (nonatomic,nonnull) NSButton *operateButton;
@property (weak) IBOutlet NSTextField *descriptionTextField;

@end

@implementation LMNoSimilarPhotoResultViewController

- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        //myBundle = [NSBundle bundleForClass:[self class]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.descriptionTextField setStringValue:NSLocalizedStringFromTableInBundle(@"LMNoSimilarPhotoResultViewController_viewDidLoad_descriptionTextField_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self setTitleColorForTextField:self.descriptionTextField];
    
    self.operateButton = [LMViewHelper createNormalGreenButton:20 title:NSLocalizedStringFromTableInBundle(@"LMNoSimilarPhotoResultViewController_viewDidLoad_1553065843_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.view addSubview:self.operateButton];
    self.operateButton.target = self;
    self.operateButton.action = @selector(actionFinish);
    [self.operateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(148);
        make.height.mas_equalTo(48);
        make.bottom.equalTo(self.view).offset(-77);
        make.left.equalTo(self.view).offset(316);
    }];
    [self.operateButton setEnabled:YES]; 
    
}

- (void)viewDidAppear{
    [super viewDidAppear];
    [self.descriptionTextField setStringValue:self.descriptionString];
}

- (IBAction)actionFinish {
    [self.view.window.windowController showAddView];
}

@end
