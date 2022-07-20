//
//  RegisterViewController.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "RegisterViewController.h"
#import <QMUICommon/LMViewHelper.h>
#import <Masonry/Masonry.h>
#import "RegisterWindowController.h"
#import "ParagraphTextFieldCell.h"
#import <QMCoreFunction/NSImage+Extension.h>
#import "RegisterUtil.h"

@interface RegisterViewController () <NSTextFieldDelegate>

@property(nonatomic) NSTextField *warningLabel;
@property(nonatomic) NSTextField *registerCodeTextField;
@property(nonatomic) NSTextField *placeholderTextField;
@property(nonatomic) NSButton *registerButton;
@property(nonatomic) NSProgressIndicator *progressIndicator;
@end

@implementation RegisterViewController


- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadView];
    }

    return self;
}

- (void)loadView {
    NSRect rect = NSMakeRect(0, 0, 348, 344);
    NSView *view = [[NSView alloc] initWithFrame:rect];
    view.wantsLayer = YES;
//    view.layer.backgroundColor = [NSColor whiteColor].CGColor;
    view.layer = [[CALayer alloc] init];
    NSImage *bgImage = [NSImage imageNamed:@"register_bg"];
    view.layer.contentsGravity = kCAGravityResizeAspectFill;
    view.layer.contents = bgImage;
    self.view = view;
    [self viewDidLoad];

}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self setupViews];
    [self setupProgressView];
}



- (void)setupViews {

    NSImageView *iconImageView = [[NSImageView alloc] init];
    [self.view addSubview:iconImageView];
    iconImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    iconImageView.image = [NSImage imageNamed:@"lemon_normal_icon" withClass:self.class];

    NSTextField *appNameLabel = [LMViewHelper createNormalLabel:16 fontColor:[NSColor colorWithHex:0x515151]];
    [self.view addSubview:appNameLabel];
    appNameLabel.stringValue = @"Lemon Cleaner";


    
    NSTextField *registerCodeTextField = [[NSTextField alloc] init];
    // 不知道为什么 textField 设置 cell 后,会出现2个 view 展示 text
//    ParagraphTextFieldCell *textCell = [[ParagraphTextFieldCell alloc]initTextCell:@""];
//    [registerCodeTextField setCell: textCell];
    registerCodeTextField.bordered = NO; //默认的 border 不能更改颜色, 需要更改 layer 的颜色.
    registerCodeTextField.wantsLayer = YES;
    registerCodeTextField.editable = YES;
    registerCodeTextField.drawsBackground = NO;
    registerCodeTextField.focusRingType = NSFocusRingTypeNone;
    registerCodeTextField.font = [NSFont systemFontOfSize:12];
    registerCodeTextField.textColor = [NSColor colorWithHex:0x515151];
    registerCodeTextField.delegate = self;
    registerCodeTextField.preferredMaxLayoutWidth = 180;
    registerCodeTextField.allowsEditingTextAttributes = NO;  // 这个相当于 textfield xib 的 allowRichText
    registerCodeTextField.usesSingleLineMode = YES;

    
//    registerCodeTextField.cell.truncatesLastVisibleLine = YES;
    registerCodeTextField.cell.wraps = YES;
    registerCodeTextField.cell.scrollable = YES;  // 这个是横向滚动,变成单行.

    [self.view addSubview:registerCodeTextField];
    self.registerCodeTextField = registerCodeTextField;
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSCenterTextAlignment;
    
    NSColor *placeholderColor = [NSColor colorWithHex:0x93979B];
    NSAttributedString *placeholderAttrStr = [[NSMutableAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"RegisterViewController_setupViews_placeholderAttrStr _1", nil, [NSBundle bundleForClass:[self class]], @"") attributes:@{NSForegroundColorAttributeName: placeholderColor , NSParagraphStyleAttributeName:style}]; //前面添加空格 为了对齐效果.
    registerCodeTextField.placeholderAttributedString = placeholderAttrStr;

    
    NSView *bottomLineView = [[NSView alloc] init];
    [self.view addSubview:bottomLineView];
    bottomLineView.wantsLayer = YES;
    bottomLineView.layer.backgroundColor = [NSColor colorWithHex:0xE0E0E0].CGColor;
    
    
    NSButton *registerButton = [[NSButton alloc] init];
    [self.view addSubview:registerButton];
    self.registerButton = registerButton;
    [registerButton setButtonType:NSButtonTypeMomentaryChange];
    [registerButton setBezelStyle:NSBezelStyleRounded];
    registerButton.bordered = NO;
    registerButton.imageScaling = NSImageScaleProportionallyUpOrDown;
    registerButton.target = self;
    registerButton.action = @selector(registerButtonClick);
    registerButton.image = [NSImage imageNamed:@"register_enable" withClass:self.class];
    registerButton.alternateImage = [NSImage imageNamed:@"regiser_unable" withClass:self.class];
    [registerButton setEnabled:NO];


    NSTextField *warningLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0xE6704C]];
    [self.view addSubview:warningLabel];
    self.warningLabel = warningLabel;
    warningLabel.stringValue = NSLocalizedStringFromTableInBundle(@"RegisterViewController__WarningRegisterCodeError_1", nil, [NSBundle bundleForClass:[self class]], @"");
    warningLabel.preferredMaxLayoutWidth = 300;
    warningLabel.alignment = NSCenterTextAlignment;
    if (@available(macOS 10.11, *)) {
        warningLabel.maximumNumberOfLines = 2;
    } else {
        // Fallback on earlier versions
    }
    [warningLabel setHidden:YES];

    [iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@160);
        make.width.equalTo(@160);
        make.top.equalTo(self.view).offset(36);
        make.centerX.equalTo(self.view);
    }];

    [appNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(iconImageView.mas_bottom).offset(15);
    }];

    [bottomLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@1);
        make.width.equalTo(@298);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-56);
    }];
    
    [registerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@20);
        make.right.equalTo(bottomLineView).offset(-12);
        make.bottom.equalTo(bottomLineView).offset(-6);
    }];
    
    [registerCodeTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(bottomLineView);
        make.left.equalTo(bottomLineView).offset(5);
        make.right.equalTo(registerButton.mas_left).offset(-10);
        make.height.centerY.equalTo(registerButton);
    }];
    

    [warningLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(bottomLineView.mas_bottom).offset(12);
    }];
}

- (void)setupProgressView {
    NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] init];
    [self.view addSubview:progressIndicator];
    self.progressIndicator = progressIndicator;
    //设置是精准的进度条还是模糊的指示器
    progressIndicator.indeterminate = YES;
    progressIndicator.bezeled = YES;
    progressIndicator.controlSize = NSControlSizeRegular;
    progressIndicator.style = NSProgressIndicatorSpinningStyle;
    progressIndicator.displayedWhenStopped = YES;
    [progressIndicator setHidden:YES];
    [progressIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.lessThanOrEqualTo(@40);
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.registerCodeTextField);
    }];

}

- (BOOL)simpleVerifyRegisterCodeFormat:(NSString *)registerCode {
    if (!registerCode) {
        return NO;
    }
    return YES;
}

- (void)registerButtonClick {
    NSString *registerCode = _registerCodeTextField.stringValue;
    registerCode = [registerCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSLog(@"input registerCode is [%@]", registerCode);
    BOOL formatValidate = [self simpleVerifyRegisterCodeFormat:registerCode];
    if (!formatValidate) {
        [_warningLabel setHidden:NO];
        _warningLabel.stringValue = NSLocalizedStringFromTableInBundle(@"RegisterViewController__WarningRegisterCodeFormatInValidate _2", nil, [NSBundle bundleForClass:[self class]], @"");
        return;
    }
}

// MARK: textField delegate

- (void)controlTextDidChange:(NSNotification *)notification {
    if (!_warningLabel.hidden) {
        _warningLabel.hidden = YES;
    }

    NSTextField *textField = [notification object];
    if (textField && textField.stringValue && textField.stringValue.length > 0) {
        [self.registerButton setEnabled:YES];
        [self.placeholderTextField setHidden:YES];
    } else {
        [self.registerButton setEnabled:NO];
        [self.placeholderTextField setHidden:NO];
    }
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector{
    NSLog(@"Selector method is (%@)", NSStringFromSelector( commandSelector ) );
    if (commandSelector == @selector(insertNewline:)) {
        if(textView.string != nil && textView.string.length > 0){
            [_registerButton performClick:_registerButton];
        }
        
        return YES;
        
    } else if (commandSelector == @selector(deleteForward:)) {
        //Do something against DELETE key
        
    } else if (commandSelector == @selector(deleteBackward:)) {
        //Do something against BACKSPACE key
        
    } else if (commandSelector == @selector(insertTab:)) {
        //Do something against TAB key
    }
    
    return NO;
}

- (void)showProgressView {
    [self.progressIndicator setHidden:NO];
    [self.progressIndicator startAnimation:self];
    self.registerCodeTextField.enabled = NO;
    self.registerButton.enabled = NO;
}

- (void)hideProgressView {
    [self.progressIndicator setHidden:YES];
    [self.progressIndicator stopAnimation:self];
    self.registerCodeTextField.enabled = YES;
    self.registerButton.enabled = YES;

}

@end


