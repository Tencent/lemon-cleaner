//
//  LMAlertViewController.m
//  Lemon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMAlertViewController.h"
#import "LMViewHelper.h"
#import "LMBorderButton.h"
#import <Masonry/Masonry.h>
#import "LMAppThemeHelper.h"
#import "LMCommonHelper.h"

@interface LMAlertViewController ()

@end

@implementation LMAlertViewController

- (void)loadView {
    NSRect rect = NSMakeRect(0, 0, 420, _windowHeigh);
    NSView *view = [[NSView alloc] initWithFrame:rect];
    
    view.wantsLayer = YES;
//    view.layer.backgroundColor = [NSColor whiteColor].CGColor;
    if ([LMCommonHelper isMacOS11]) {
        view.layer.cornerRadius = 10;
    } else {
        view.layer.cornerRadius = 5;
    }
    
    view.layer.masksToBounds = YES;
    self.view = view;
    //    [self viewDidLoad];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupWindow];
    [self setupViews];
}

- (void)viewWillAppear {
    NSWindow *window = self.view.window;
    if (window) {
        window.titleVisibility = NSWindowTitleHidden;
        window.titlebarAppearsTransparent = YES;
        window.styleMask = NSWindowStyleMaskFullSizeContentView ;
        
        
        window.opaque = NO;
        window.showsToolbarButton = NO;
        //        window.movableByWindowBackground = YES; //window 可随拖动移动
        [window setBackgroundColor:[NSColor clearColor]];
        
        CGFloat xPos = NSWidth([[window screen] frame])/2 - NSWidth([window frame])/2;
        CGFloat yPos = NSHeight([[window screen] frame])/2 - NSHeight([window frame])/2;
        if(_parentViewController){
            NSWindow *parentWindow = _parentViewController.view.window;
            if (parentWindow) {
                xPos = NSWidth([parentWindow frame])/2 - NSWidth([window frame])/2 + parentWindow.frame.origin.x;
                yPos = NSHeight([parentWindow frame])/2 - NSHeight([window frame])/2 + parentWindow.frame.origin.y;
            }
        }
        
        [window setFrame:NSMakeRect(xPos, yPos, NSWidth([window frame]), NSHeight([window frame])) display:YES];
    }
}

- (void)setupWindow {
//    self.view.window.delegate = self;
    self.view.window.title = @"";
    self.title = @"";
}

- (void)setupViews{
    
    NSTextField *titleLabel = [LMViewHelper createNormalLabel:14 fontColor:[LMAppThemeHelper getTitleColor]];
    [self.view addSubview:titleLabel];

    if (@available(macOS 10.11, *)) {
        titleLabel.maximumNumberOfLines = 3;
    }
    self.titleLabel = titleLabel;
    
    
    //副标题
     NSTextField *descLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979b]];
     [self.view addSubview:descLabel];
//    [descLabel setHidden:YES];
    self.descLabel = descLabel;


    NSButton *okButton  = [LMViewHelper createSmallGreenButton:12 title:@""];
    [self.view addSubview:okButton];
    okButton.wantsLayer = YES;
    okButton.layer.cornerRadius = 2;
    okButton.target = self;
    okButton.action = @selector(onOkButtonClicked);
    self.okButton = okButton;
    

    LMBorderButton *cancelButton = [[LMBorderButton alloc] init];
    [self.view addSubview:cancelButton];
    cancelButton.target = self;
    cancelButton.action = @selector(onCancelButtonClicked);
    cancelButton.font = [NSFont systemFontOfSize:12];
    _cancelButton = cancelButton;
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(18);
        make.left.equalTo(self.view).offset(24);
        make.width.lessThanOrEqualTo(@387);
    }];
    
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
         make.top.equalTo(titleLabel.mas_bottom).offset(7);
         make.left.equalTo(self.view).offset(24);
         make.width.lessThanOrEqualTo(@387);
     }];
    
    [okButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(68);
        make.height.mas_equalTo(24);
        make.right.equalTo(self.view).offset(-20);
        make.bottom.equalTo(self.view).offset(-21);
    }];
    
    [cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(68);
        make.height.mas_equalTo(24);
        make.right.equalTo(okButton.mas_left).offset(-12);
        make.centerY.equalTo(okButton);
    }];
//    [cancelButton sizeToFit];
}

- (void)updateViewConstraints{
    [super updateViewConstraints];
    [self widenButtonWidth:_okButton];
    [self widenButtonWidth:_cancelButton];

}

-(void)widenButtonWidth:(NSButton*)button{ // 加宽 button 宽度.
    if(button.title && button.title.length > 0){
        CGFloat textWidth = [self widthOfString:button.title withFont:button.font];
        CGFloat buttonWidth = textWidth + 15;
        if(buttonWidth > 68){
            NSLog(@"reset button width is %f", buttonWidth);
            [button mas_updateConstraints:^(MASConstraintMaker *make) {
                make.width.equalTo(@(buttonWidth));
            }];
        }else{
            [button mas_updateConstraints:^(MASConstraintMaker *make) {
                make.width.equalTo(@(68));
            }];
        }
    }
}


- (CGFloat)widthOfString:(NSString *)string withFont:(NSFont *)font {
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:string attributes:attributes] size].width;
}

- (void)showAlertViewAsModalStypeAt:(NSViewController *)viewController{
    if(viewController){
        [viewController presentViewControllerAsModalWindow:self];
    }
    if(_windowShowCallback){
        _windowShowCallback();
    }
}


// MARK: user action
-(void)onOkButtonClicked{
    if(_okButtonCallback){
        _okButtonCallback();
    }

    [self _closeWindow];
}


-(void)onCancelButtonClicked{
    if(_cancelButtonCallback){
        _cancelButtonCallback();
    }
    
  [self _closeWindow];
}

-(void)_closeWindow{
    [self.view.window close];
      if(_windowCloseCallback){
          _windowCloseCallback();
      }
}


@end
