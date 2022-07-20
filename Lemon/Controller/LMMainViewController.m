//
//  LMMainViewController.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMMainViewController.h"
#import "LemonMainWndController.h"


@interface LMMainViewController ()


@end

@implementation LMMainViewController

-(id)init{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [self initData];
    [self initView];
}

- (void)viewDidAppear{
    [super viewDidAppear];
    
}

- (void)viewWillLayout{
    [super viewWillLayout];
    self.view.layer.backgroundColor = [NSColor clearColor].CGColor;
}

-(void)initView{
    [self.view addSubview:self.scanViewContoller.view];
//    self.view.wantsLayer = YES;
//    self.view.layer.backgroundColor = [NSColor clearColor].CGColor;
}

-(void)initData{
    self.scanViewContoller = [[LMCleanScanViewController alloc] init];
}

- (void)showAnimate {
    [self.scanViewContoller showAnimate];
}


@end
