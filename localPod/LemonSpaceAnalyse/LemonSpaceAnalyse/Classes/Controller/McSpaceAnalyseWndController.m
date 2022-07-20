//
//  McSpaceAnalyseWndController.m
//  LemonSpaceAnalyse
//
//  
//

#import "McSpaceAnalyseWndController.h"
#import "LMSpaceMainViewController.h"
#import "LMSpaceResultViewController.h"
#import "LMItem.h"
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/NSBundle+LMLanguage.h>

@interface McSpaceAnalyseWndController ()<LMSpaceMainViewControllerDelegate>
@property (weak) IBOutlet NSView *mainView;

@property(nonatomic, strong) LMSpaceMainViewController* mainVC;
@property(nonatomic, strong) LMSpaceResultViewController* resultVC;

@end

@implementation McSpaceAnalyseWndController

- (instancetype)init
{
    self = [super  initWithWindowNibName:@"McSpaceAnalyseWndController"];
    if (self) {
        [self hookMulitLanguage];
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
        [NSBundle setLanguage:language bundle:[NSBundle bundleForClass:[LMSpaceMainViewController class]]];
        [NSBundle setLanguage:language bundle:[NSBundle bundleForClass:[LMSpaceResultViewController class]]];
    }
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    self.mainVC = [[LMSpaceMainViewController alloc] init];
    self.mainVC.delegete = self;
    self.resultVC = [[LMSpaceResultViewController alloc] init];
    
    [self.window setBackgroundColor:[NSColor whiteColor]];
    self.window.movableByWindowBackground = YES;
    //不用contentViewController，主要是fix rdq上面的crash：60002005、60002206
  
    [self.mainView addSubview:self.mainVC.view];
    [self.mainView addSubview:self.resultVC.view];
    self.mainVC.view.hidden = NO;
    self.resultVC.view.hidden = YES;
}

- (void)showMainView {
    self.mainVC.view.hidden = NO;
    self.resultVC.view.hidden = YES;
    [self.mainVC showStartView];
}

- (void)restartScanView {
    self.mainVC.view.hidden = NO;
    self.resultVC.view.hidden = YES;
    [self.mainVC restartScan];
}

- (void)showResultView {
    self.mainVC.view.hidden = YES;
    self.resultVC.view.hidden = NO;
}

#pragma mark - LMSpaceMainViewControllerDelegate

-(void)spaceMainViewControllerEnd:(LMItem *)topItem {
    [self.resultVC initItemData:topItem];
}

#pragma mark - over

- (void)windowWillClose:(NSNotification *)notification {
//    NSLog(@"windowWillClose: %@, className:%@", notification, [self className]);
    LMSpaceBaseViewController* vc = nil;
    if (self.mainVC.view.isHidden == NO) {
        vc = self.mainVC;
    }
    if (self.resultVC.view.isHidden == NO) {
        vc = self.resultVC;
    }
    
    [vc windowWillClose:notification];

    if ([self.delegate respondsToSelector:@selector(windowWillDismiss:)]) {
        [self.delegate windowWillDismiss:[self className]];
    }
}

-(void)dealloc{
//    NSLog(@"__%s__",__FUNCTION__);
}
- (BOOL)windowShouldClose:(NSWindow *)sender {
    if (self.mainVC.view.isHidden == NO) {
        if (self.mainVC.scanView.isHidden == NO) {
            [self.mainVC SpaceMainWindowShouldClose];
            return NO;
        }
        return YES;
    }
    return YES;
}

@end
