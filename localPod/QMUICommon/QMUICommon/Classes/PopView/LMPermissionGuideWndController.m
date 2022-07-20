//
//  LMPermissionGuideWndController.m
//  QMUICommon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMPermissionGuideWndController.h"
#import "LMPermissionGuideViewController.h"
@interface LMPermissionGuideWndController ()
@property (nonatomic, assign) CGPoint centerPoint;
@property (nonatomic) LMPermissionType permissionType;
@property NSInteger guideImageViewHeight;

@end

@implementation LMPermissionGuideWndController


-(id)initWithParaentCenterPos:(CGPoint)centerPos title:(NSString *)title descText:(NSString *) desc image:(NSImage *) image{
    return [self initWithParaentCenterPos:centerPos title:title descText:desc image:image guideImageViewHeight:410];
}

-(id)initWithParaentCenterPos:(CGPoint)centerPos title:(NSString *)title descText:(NSString *) desc image:(NSImage *) image guideImageViewHeight: (NSInteger) height{
    self = [super init];
    if (self) {
        self.centerPoint = centerPos;
        self.tipsTitle = title;
        self.descText = desc;
        self.image = image;
        self.guideImageViewHeight = height;
        self.needCheckMonitorFullDiskAuthorizationStatus = NO;
//        [self loadWindow];
    }
    
    return self;
}

-(void)closeWindow{
    [self.window close];
}

-(void)loadWindow{
    NSRect frame = NSMakeRect(0, 0, 610, 476);
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:NSWindowStyleMaskTitled
                   | NSWindowStyleMaskFullSizeContentView
                                                backing:NSBackingStoreBuffered defer:YES];
    
    
    self.window.titleVisibility = NSWindowTitleHidden;
    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES; //window 可随拖动移动
    [self.window setBackgroundColor:[NSColor clearColor]];
    
    CGFloat xPos = self.centerPoint.x - NSWidth(frame)/2;
    CGFloat yPos = self.centerPoint.y - NSHeight(frame)/2;
    
    [self.window setFrame:NSMakeRect(xPos, yPos, NSWidth(frame), NSHeight(frame)) display:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(permissionGuideWindowWillClose) name:NSWindowWillCloseNotification object:nil];
    [self windowDidLoad];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    LMPermissionGuideViewController *viewController = [[LMPermissionGuideViewController alloc]init];
    viewController.tipsTitle = self.tipsTitle;
    viewController.descText = self.descText;
    viewController.image = self.image;
    viewController.okButtonEvent = self.settingButtonEvent;
    viewController.finishButtonEvent = self.finishButtonEvent;
    viewController.guidImageViewHeight = self.guideImageViewHeight;
    viewController.cancelButtonEvent = self.cancelButtonEvent;
    viewController.cancelButtonTitle = self.cancelButtonTitle;
    viewController.settingButtonTitle = self.settingButtonTitle;
    viewController.confirmTitle = self.confirmTitle;
    viewController.needCheckMonitorFullDiskAuthorizationStatus = self.needCheckMonitorFullDiskAuthorizationStatus;
    self.contentViewController = viewController;
}

-(void)permissionGuideWindowWillClose{
    [[NSApplication sharedApplication]stopModal];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
