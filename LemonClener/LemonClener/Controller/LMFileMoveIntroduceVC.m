//
//  LMFileMoveIntroduceVC.m
//  LemonClener
//

//  Copyright © 2022 Tencent. All rights reserved.
//

#import "LMFileMoveIntroduceVC.h"
#import <QMUICommon/LMRectangleButton.h>
#import <Masonry/Masonry.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <LemonFileMove/LMFileMoveFeatureDefines.h>

@interface LMFileMoveIntroduceVC ()

@property (weak) IBOutlet NSTextField *titleField;
@property (weak) IBOutlet NSTextField *descFiled;
@property (weak) IBOutlet NSTextField *egField;
@property (weak) IBOutlet LMRectangleButton *startButton;

@end

@implementation LMFileMoveIntroduceVC

- (instancetype)init {
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {

    }
    return self;
}

- (void)viewWillAppear {
    self.view.window.titleVisibility = NSWindowTitleHidden;
    self.view.window.titlebarAppearsTransparent = YES;
    self.view.window.styleMask = NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskTitled | NSFullSizeContentViewWindowMask;
    [[self.view.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do view setup here.
    self.view.window.title = @"1";
    [self.view.window setTitleVisibility:NSWindowTitleHidden];
    [self.view.window setTitlebarAppearsTransparent:YES];
    self.view.window.styleMask = NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskTitled | NSFullSizeContentViewWindowMask;
    [[self.view.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    self.titleField.stringValue = NSLocalizedStringFromTableInBundle(@"Hey, dear users", nil, [NSBundle bundleForClass:[self class]], @"");
    self.titleField.textColor = [LMAppThemeHelper getTitleColor];
    [self.titleField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(85);
        make.left.equalTo(self.view).offset(72);
        make.height.mas_equalTo(45);
        make.width.mas_equalTo(208);
    }];
    
    NSMutableParagraphStyle *textParagraph = [[NSMutableParagraphStyle alloc] init];
    [textParagraph setLineSpacing:4.0];
    NSDictionary *attrDic = [NSDictionary dictionaryWithObjectsAndKeys:textParagraph,NSParagraphStyleAttributeName, nil];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"We have launched \"File Moving\" to help you\nclean up the files you are not sure to clean.", nil, [NSBundle bundleForClass:[self class]], @"") attributes:attrDic];
    // 这个需要在设置属性之前设置
    [self.descFiled setAttributedStringValue:attrString];
    [self.descFiled mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleField.mas_bottom).offset(10);
        make.left.equalTo(self.view).offset(72);
        make.width.mas_equalTo(400);
        make.height.mas_equalTo(52);
    }];
    self.descFiled.textColor = [LMAppThemeHelper getTitleColor];
    NSMutableParagraphStyle *textParagraphEg = [[NSMutableParagraphStyle alloc] init];
    [textParagraphEg setLineSpacing:4.0];
    NSDictionary *attrDicEg = [NSDictionary dictionaryWithObjectsAndKeys:textParagraphEg,NSParagraphStyleAttributeName, nil];
    NSAttributedString *attrStringEg = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"Videos, pictures, documents and other content of IM tools, we help you organize and move them to external storage or cloud disks with just one click in order to free up your spaces.", nil, [NSBundle bundleForClass:[self class]], @"") attributes:attrDicEg];
    [self.egField setAttributedStringValue:attrStringEg];
    [self.egField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descFiled.mas_bottom).offset(8);
        make.left.equalTo(self.view).offset(72);
        make.width.mas_equalTo(360);
        make.height.mas_lessThanOrEqualTo(64);
    }];
    
    
    self.startButton.title = NSLocalizedStringFromTableInBundle(@"Start", nil, [NSBundle bundleForClass:[self class]], @"");
    [self.startButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.egField.mas_bottom).offset(48);
        make.left.equalTo(self.view).offset(72);
        make.height.mas_equalTo(48);
        make.width.mas_equalTo(148);
    }];
}

- (IBAction)startScan:(id)sender {
    [self dismissViewController:self];
    if ([self.delegate respondsToSelector:@selector(fileMoveIntroduceVCDidStart)]) {
        [self.delegate fileMoveIntroduceVCDidStart];
        
    }
}

@end
