//
//  LMFileMoveAlertViewController.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveAlertViewController.h"
#import "LMFileMoveCommonDefines.h"
#import <QMUICommon/LMBorderButton.h>
#import <QMUICommon/LMRectangleButton.h>
#import "LMFileMoveAlertViewController.h"
#import "LMFileMoveCommonDefines.h"

@interface LMFileMoveAlertViewController ()

@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong) LMRectangleButton *continueButton;
@property (nonatomic, strong) LMBorderButton *cancelButton;

@property (nonatomic, strong) NSImage *alertImage;
@property (nonatomic, strong) NSString *alertTitle;
@property (nonatomic, strong) NSString *continueButtonTitle;
@property (nonatomic, strong) NSString *stopButtonTitle;
@property (nonatomic, strong) dispatch_block_t continueHandler;
@property (nonatomic, strong) dispatch_block_t stopHandler;

@end

@implementation LMFileMoveAlertViewController

- (instancetype)initWithImage:(NSImage *)image title:(NSString *)title continueButtonTitle:(NSString *)continueButtonTitle stopButtonTitle:(NSString *)stopButtonTitle continueHandler:(dispatch_block_t)continueHandler stopHandler:(dispatch_block_t)stopHandler {
    if (self = [super init]) {
        self.alertImage = image;
        self.alertTitle = title;
        self.continueButtonTitle = continueButtonTitle;
        self.stopButtonTitle = stopButtonTitle;
        self.continueHandler = continueHandler;
        self.stopHandler = stopHandler;
    }
    return self;
}

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:CGRectMake(0, 0, LM_FILE_MOVE_ALERT_WINDOW_SIZE.width, LM_FILE_MOVE_ALERT_WINDOW_SIZE.height)];
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = lm_backgroundColor().CGColor;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self _setupSubviews];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    [self _setupWindow];
}

- (void)_setupWindow {
    NSWindow *window = self.view.window;
    window.titlebarAppearsTransparent = YES;
    window.movableByWindowBackground = YES;
    window.titleVisibility = NSWindowTitleHidden;
    window.styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskFullSizeContentView;
}

- (void)_setupSubviews {
    self.imageView = [[NSImageView alloc] init];
    self.imageView.image = self.alertImage;
    [self.view addSubview:self.imageView];

    self.titleLabel = [NSTextField labelWithStringCompat:self.alertTitle];
    self.titleLabel.font = [NSFont systemFontOfSize:16];
    [LMAppThemeHelper setTitleColorForTextField:self.titleLabel];
    [self.view addSubview:self.titleLabel];
     
    self.cancelButton = [[LMBorderButton alloc] init];
    [self.view addSubview:self.cancelButton];
    self.cancelButton.title = self.stopButtonTitle;
    self.cancelButton.target = self;
    self.cancelButton.action = @selector(cancelButtonOnClick:);
    self.cancelButton.fontSize = 12;
    self.cancelButton.font = [NSFont systemFontOfSize:12];
    
    self.continueButton = [[LMRectangleButton alloc] init];
    [self.view addSubview:self.continueButton];
    self.continueButton.title = self.continueButtonTitle;
    self.continueButton.target = self;
    self.continueButton.action = @selector(continueButtonOnClick:);
    self.continueButton.font = [NSFont systemFontOfSize:12];

    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(48);
        make.left.equalTo(self.view).offset(24);
        make.size.mas_equalTo(CGSizeMake(40, 40));
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.imageView.mas_right).offset(16);
        make.top.equalTo(self.imageView);
    }];
    
    [self.continueButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-20);
        make.bottom.equalTo(self.view).offset(-16);
        make.height.mas_equalTo(24);
        make.width.mas_equalTo(lm_localizedCGFloat(72, 76));
    }];
    
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.continueButton.mas_left).offset(-10);
        make.bottom.height.equalTo(self.continueButton);
        make.width.mas_equalTo(lm_localizedCGFloat(48, 56));
    }];
}

- (void)cancelButtonOnClick:(id)sender {
    !self.stopHandler ?: self.stopHandler();
    [self.view.window close];
}

- (void)continueButtonOnClick:(id)sender {
    !self.continueHandler ?: self.continueHandler();
    [self.view.window close];
}

@end
