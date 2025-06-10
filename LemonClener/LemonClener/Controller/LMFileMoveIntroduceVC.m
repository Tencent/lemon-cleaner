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
    self.titleField.stringValue = LMLocalizedSelfBundleString(@"Hey, 柠檬用户", nil);
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
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:LMLocalizedSelfBundleString(@"针对扫描出来很多文件不敢清理的情况\n我们推出了文件搬家功能", nil) attributes:attrDic];
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
    NSAttributedString *attrStringEg = [[NSAttributedString alloc] initWithString:LMLocalizedSelfBundleString(@"例如聊天过程接收的视频、图片、文档等内容，一键整理转移到外设、云盘等，帮助你更好的释放磁盘空间。", nil) attributes:attrDicEg];
    [self.egField setAttributedStringValue:attrStringEg];
    [self.egField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descFiled.mas_bottom).offset(8);
        make.left.equalTo(self.view).offset(72);
        make.width.mas_equalTo(360);
        make.height.mas_lessThanOrEqualTo(64);
    }];
    
    
    self.startButton.title = LMLocalizedSelfBundleString(@"去使用", nil);
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
