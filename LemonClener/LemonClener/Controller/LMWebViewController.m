//
//  LMWebViewController.m
//  LemonClener
//

//  Copyright © 2021 Tencent. All rights reserved.
//

#import "LMWebViewController.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>

@interface LMWebViewController () <WKNavigationDelegate, WKUIDelegate>

@property(nonatomic, strong) WKWebView *webView;

@end

@implementation LMWebViewController

- (instancetype)init {
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {

    }
    return self;
}

- (void)initWebView {
    
    NSString *jScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";
    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    [wkUController addUserScript:wkUScript];
    WKWebViewConfiguration *wkWebConfig = [[WKWebViewConfiguration alloc] init];
    wkWebConfig.userContentController = wkUController;
    
    self.webView = [[WKWebView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100) configuration:wkWebConfig];
    [self.view addSubview:self.webView];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.view).offset(28);
    }];
    
    //_currentNewGuid
    NSString *guid = [[NSUserDefaults standardUserDefaults] objectForKey:@"kLemonCurrentGuid"]?:@"";
    NSString *url = [NSString stringWithFormat:@"https://sdi.3g.qq.com/v/2021111811411711422?guid=%@", guid];
    // 代理
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    // 是否允许手势左滑返回上一级, 类似导航控制的左滑返回
    self.webView.allowsBackForwardNavigationGestures = YES;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self.webView loadRequest:request];
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initWebView];
    // Do view setup here.
}

- (void)viewDidLayout {
    [super viewDidLayout];
    self.view.window.title = @"";
}

-(void)dealloc {
    NSLog(@"___%s__",__FUNCTION__);
}

- (void)windowWillClose {
    [self.webView stopLoading];
    self.webView = nil;
}

@end
