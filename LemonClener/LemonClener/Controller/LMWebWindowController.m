//
//  LMWebWindowController.m
//  Lemon
//

//  Copyright © 2021 Tencent. All rights reserved.
//

#import "LMWebWindowController.h"
#import "LMWebViewController.h"
#import <Masonry/Masonry.h>

@interface LMWebWindowController ()

@property(nonatomic, strong) LMWebViewController *webVC;
@property (weak) IBOutlet NSView *mainView;

@end

@implementation LMWebWindowController

- (instancetype)init
{
    self = [super  initWithWindowNibName:@"LMWebWindowController"];
    if (self) {

    }
    return self;
}

- (void)awakeFromNib {
    self.window.titlebarAppearsTransparent = YES;
    self.window.styleMask |= NSWindowStyleMaskFullSizeContentView;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    //不用contentViewController，主要是fix rdq上面的crash：60002005、60002206
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    self.webVC = [[LMWebViewController alloc] init];
    [self.mainView addSubview:self.webVC.view];
    self.window.movableByWindowBackground = YES;
    [self.webVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.right.left.equalTo(self.mainView);
    }];
}

-(void)dealloc {
    NSLog(@"___%s__",__FUNCTION__);
}

- (void)windowWillClose:(NSNotification *)notification {
    
    [self.webVC windowWillClose];
    
    if ([self.delegate respondsToSelector:@selector(windowWillDismiss:)]) {
        [self.delegate windowWillDismiss:[self className]];
    }
}

- (BOOL)windowShouldClose:(NSWindow *)sender {
    return YES;
}

@end
