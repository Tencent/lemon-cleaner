//
//  LMPhotoCleanFinishedViewController.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMPhotoCleanFinishedViewController.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMViewHelper.h>
#import "LMPhotoCleanerWndController.h"
#import <QMUICommon/RatingUtils.h>

@interface LMPhotoCleanFinishedViewController ()
@property (nonatomic,nonnull) NSButton *operateButton;
@property (weak) IBOutlet NSTextField *descriptionTextField;

@end

@implementation LMPhotoCleanFinishedViewController

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

    [self.descriptionTextField setStringValue:NSLocalizedStringFromTableInBundle(@"LMPhotoCleanFinishedViewController_viewDidLoad_descriptionTextField_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    self.operateButton = [LMViewHelper createNormalGreenButton:20 title:NSLocalizedStringFromTableInBundle(@"LMPhotoCleanFinishedViewController_viewDidLoad_1553065843_2", nil, [NSBundle bundleForClass:[self class]], @"")];
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
    
    NSString *description = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMPhotoCleanFinishedViewController_viewDidLoad_description _3", nil, [NSBundle bundleForClass:[self class]], @""),(long)self.deleteCount];
    [self.descriptionTextField setStringValue:description];
    [self setTitleColorForTextField:self.descriptionTextField];
    
    // 完成扫描
    [RatingUtils recordCleanFinishAction];

}


- (IBAction)actionFinish {
    [self.view.window.windowController showAddView];

}

@end
