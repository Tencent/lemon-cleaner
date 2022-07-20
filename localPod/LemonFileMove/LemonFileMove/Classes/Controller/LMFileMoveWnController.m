//
//  LMFileMoveWnController.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveWnController.h"
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/NSBundle+LMLanguage.h>
#import "LMFileMoveMainVC.h"
#import "LMFileMoveProcessViewController.h"
#import "LMFileMoveManger.h"
#import "LMFileMoveResultViewController.h"
#import "DiskArbitrationPrivateFunctions.h"
#import "LMFileMoveAlertViewController.h"
#import "LMFileMoveCommonDefines.h"

@interface LMFileMoveWnController () <NSWindowDelegate>

@property (weak) IBOutlet NSView *mainView;
@property (nonatomic, strong) LMFileMoveMainVC *mainVC;
@property (nonatomic, strong) LMFileMoveProcessViewController *processVC;
@property (nonatomic, strong) LMFileMoveResultViewController *resultVC;

@end

@implementation LMFileMoveWnController

- (instancetype)init
{
    self = [super  initWithWindowNibName:@"LMFileMoveWnController"];
    if (self) {
        [self hookMulitLanguage];
        InitializeDiskArbitration();
    }
    return self;
}

- (void)awakeFromNib {
    self.window.titlebarAppearsTransparent = YES;
    self.window.styleMask |= NSWindowStyleMaskFullSizeContentView;
}

- (void)hookMulitLanguage {
    NSString *language = [LanguageHelper getCurrentUserLanguage];
    if(language != nil){
        [NSBundle setLanguage:language bundle:[NSBundle bundleForClass:[LMFileMoveWnController class]]];
//        [NSBundle setLanguage:language bundle:[NSBundle bundleForClass:[LMSpaceResultViewController class]]];
    }
}

- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.title = NSLocalizedStringFromTableInBundle(@"Files Transfer", nil, [NSBundle bundleForClass:[self class]], @"");
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    self.mainVC = [[LMFileMoveMainVC alloc] init];
    self.processVC = [[LMFileMoveProcessViewController alloc] init];
    self.resultVC = [[LMFileMoveResultViewController alloc] init];
    [self.window setBackgroundColor:[NSColor whiteColor]];
    self.window.movableByWindowBackground = YES;
    //不用contentViewController，主要是fix rdq上面的crash：60002005、60002206
    [self.mainView addSubview:self.mainVC.view];
    [self.mainView addSubview:self.processVC.view];
    [self.mainView addSubview:self.resultVC.view];

    [self showMainView];
}

#pragma mark - Private

- (void)showMainView {
    self.mainVC.view.hidden = NO;
    self.processVC.view.hidden = YES;
    self.resultVC.view.hidden = YES;
    [self.mainVC showStartView];
}

- (void)showProcessView {
    self.mainVC.view.hidden = YES;
    self.processVC.view.hidden = NO;
    self.resultVC.view.hidden = YES;
    [self.processVC startMoveFile];
}

- (void)showResultViewWithSuccessStatus:(BOOL)isSucceed {
    self.mainVC.view.hidden = YES;
    self.processVC.view.hidden = YES;
    self.resultVC.view.hidden = NO;
    if (isSucceed) {
        [self.resultVC showSuccessView];
    } else {
        [self.resultVC showFailureView];
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    [[LMFileMoveManger shareInstance] stopScan];
    UnregisterDiskCallback();
    if ([self.delegate respondsToSelector:@selector(windowWillDismiss:)]) {
        [self.delegate windowWillDismiss:[self className]];
    }
}

- (BOOL)windowShouldClose:(NSWindow *)sender {
    if (!self.processVC.view.hidden) {
        [self.processVC showCloseWindowAlert];
        return NO;
    }
    return YES;
}

@end
