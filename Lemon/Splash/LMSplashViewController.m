//
//  LMSplashViewController.m
//  Lemon
//

//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMSplashViewController.h"
#import "BFPageControl.h"
#import "LMSplashMenuBarViewController.h"
#import "LMSplashMainAppViewController.h"
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/LMImageButton.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/LMAppThemeHelper.h>

typedef enum {
    LMSplashTypeMenubar,
    LMSplashTypeMainApp
} LMSplashType;

@interface LMSplashViewController () <BFPageControlDelegate>{
    LMSplashMenuBarViewController *menubarViewController;
    LMSplashMainAppViewController *mainAppViewController;
    LMSplashType curSplashType;
    NSButton *_leftArrowButton;
    NSButton *_rightArrowButton;
    BFPageControl *_pageControl;
}

@end

@implementation LMSplashViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
    NSLog(@"%s :stacktrace: %@", __FUNCTION__, [NSThread callStackSymbols]);
}

- (void)viewWillAppear{
    [super viewWillAppear];
    NSLog(@"%s", __FUNCTION__);
}
// viewController
// window.contentViewController -> [NSWindow _contentViewControllerChanged] ->[NSViewController _loadViewIfRequired]  -> [NSViewController loadView] loadView 会自动调用.
// 自动调用 loadView 方法会触发调用 viewDidLoad 方法.

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 780, 482)];
    view.wantsLayer = true;
   
//    view.layer.backgroundColor = [NSColor whiteColor].CGColor;
    self.view = view;
}

- (void)viewWillLayout{
    self.view.wantsLayer = YES;
    if([self isDarkMode]){
        self.view.layer.backgroundColor = [NSColor colorWithHex:0x242633 alpha:0.2].CGColor;
    }else{
        self.view.layer.backgroundColor = [NSColor whiteColor].CGColor;
    }
}

- (void)initView {
    [self setupBkgView];
    [self setupPageControl];
    [self setupChildViewControllers];
    [self setupArrowButtons];

}

- (void)setupChildViewControllers{
    menubarViewController = [[LMSplashMenuBarViewController alloc]init];
    [self addChildViewController:menubarViewController];
    [self.view addSubview:menubarViewController.view];
//    [menubarViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {   //使用transitionFromViewController动画时不能使用约束,不然第一次动画效果不对.
//        make.centerX.equalTo(self.view);
//        make.top.equalTo(self.view);
//        make.width.equalTo(@580);
//        make.height.equalTo(@432);
//    }];
//
    menubarViewController.view.frame = NSMakeRect(100,  50, 580, 432);
    self->curSplashType = LMSplashTypeMenubar;

    
    mainAppViewController = [[LMSplashMainAppViewController alloc]init];
    [self addChildViewController:mainAppViewController];
//    [self.view addSubview:mainAppViewController.view];   // transition动画时会自动 add,这里不需要 add这个 view.  view 的大小也同 page1 相同.
}

-(void)setupBkgView{
//    NSImageView *bkgImageView = [LMViewHelper createNormalImageView];
//    bkgImageView.image = [NSImage imageNamed:@"splash_bkg"];
//    [self.view addSubview:bkgImageView];
//    [bkgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.width.equalTo(@666);
//        make.height.equalTo(@482);
//        make.centerX.equalTo(self.view);
//        make.top.equalTo(self.view);
//    }];
}

- (void)setupArrowButtons{
    NSButton *leftArrowButton =  [LMViewHelper createNormalButton];
    _leftArrowButton = leftArrowButton;
    [self.view addSubview:leftArrowButton];
    
    [leftArrowButton setButtonType:NSButtonTypeMomentaryChange];
    [leftArrowButton setBezelStyle:NSRecessedBezelStyle];
    [leftArrowButton setFocusRingType:NSFocusRingTypeNone];
    leftArrowButton.bordered = NO;
    [leftArrowButton setTitle:@""];
    leftArrowButton.image = [NSImage imageNamed:@"splash_left_arrow" withClass:self.class];
    leftArrowButton.alternateImage = [NSImage imageNamed:@"splash_left_arrow" withClass:self.class];
    leftArrowButton.target = self;
    leftArrowButton.action = @selector(onLeftButtonClick);

    
    NSButton *rightArrowButton = [LMViewHelper createNormalButton];
    _rightArrowButton = rightArrowButton;
    [_rightArrowButton setImagePosition:NSImageOnly];
    [self.view addSubview:rightArrowButton];
    rightArrowButton.image = [NSImage imageNamed:@"splash_right_arrow" withClass:self.class];
    rightArrowButton.alternateImage = [NSImage imageNamed:@"splash_right_arrow" withClass:self.class];
    rightArrowButton.target = self;
    rightArrowButton.action = @selector(onRightButtonClick);
    
    [leftArrowButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.width.equalTo(@28);
        make.centerY.equalTo(self.view);
        make.left.equalTo(self.view).offset(28);
    }];
    
    [rightArrowButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.width.equalTo(@28);
        make.centerY.equalTo(self.view);
        make.right.equalTo(self.view).offset(-28);
    }];
}

- (void)setupPageControl{
    NSRect frame = self.view.frame;
    BFPageControl *control = [[BFPageControl alloc] init];
    _pageControl = control;
    control.focusRingType = NSFocusRingTypeNone;
    [control setDelegate: self];
    [control setNumberOfPages: 2];
    [control setIndicatorDiameterSize: 10];
    [control setIndicatorMargin: 12];
    [control setCurrentPage: 0];
    [control setDrawingBlock: ^(NSRect frame, NSView *aView, BOOL isSelected, BOOL isHighlighted){
        //TODO: 为什么以前是frame.origin.y + 1.5？？？
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect: CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height)];
        [[NSColor whiteColor] set];
        [path fill];
        
        path = [NSBezierPath bezierPathWithOvalInRect: frame];
        NSColor *color = isSelected ? [NSColor colorWithHex:0xF19A3B] :
        [NSColor colorWithHex:0xEBEBEB];
        
        [color set];
        [path fill];

    }];
    [self.view addSubview: control];
    CGSize size = [control intrinsicContentSize];
    [control setFrame: CGRectMake((frame.size.width - size.width)/2, 27, size.width, size.height)];
}

- (void)pageControl:(BFPageControl *)pageControl didSelectPageAtIndex:(NSInteger)index{
    NSLog(@"%@: Selected page at index: %li", pageControl, index);
    
    if(index == curSplashType){
        NSLog(@"pageControl can't change, because current index same");
        return;
    }
    [self pageChange];
}

-(void)pageChange{
    switch (curSplashType) {
        case LMSplashTypeMainApp:{
            [self page2Topage1];
            break;
        }
            
        case LMSplashTypeMenubar:{
            [self page1Topage2];
            break;
        }
        default:
            break;
    }
}


-(void)page1Topage2{
    [self disableTransitionButton];
    self->_pageControl.currentPage = 1;
    [self transitionFromViewController:menubarViewController toViewController:mainAppViewController   options:NSViewControllerTransitionSlideForward completionHandler:^{
        self->curSplashType = LMSplashTypeMainApp;
        [self enableTransitionButton];
    }];
    
}

-(void)page2Topage1{
    [self disableTransitionButton];
    self->_pageControl.currentPage = 0;
    [self transitionFromViewController:mainAppViewController toViewController:menubarViewController   options:NSViewControllerTransitionSlideBackward completionHandler:^{
        self->curSplashType = LMSplashTypeMenubar;
        [self enableTransitionButton];
    }];
}

-(void) onRightButtonClick{
    if(curSplashType == LMSplashTypeMainApp){
        NSLog(@"onRightButtonClick  can't onclick, because current index same");
        return;
    }
    [self pageChange];
}

-(void) onLeftButtonClick{
    if(curSplashType == LMSplashTypeMenubar){
        NSLog(@"onLeftButtonClick  can't onclick, because current index same");
        return;
    }
    [self pageChange];
}

-(void) enableTransitionButton{
    [_rightArrowButton setEnabled:YES];
    [_leftArrowButton setEnabled:YES];
}

-(void) disableTransitionButton{
    [_rightArrowButton setEnabled:NO];
    [_leftArrowButton setEnabled:NO];

    
}
@end


