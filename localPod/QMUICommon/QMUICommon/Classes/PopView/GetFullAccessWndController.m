//
//  GetFullAccessWndController.m
//  LemonClener
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "GetFullAccessWndController.h"
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/NSBundle+LMLanguage.h>

@interface GetFullAccessWndController ()<NSWindowDelegate>

@property (nonatomic, copy) SuccessSettingBlock successSettingBlock;
@property (nonatomic, assign) CGPoint centerPoint;
@property (nonatomic, assign) BOOL isSettingSuccess;

@end

@implementation GetFullAccessWndController

- (instancetype)init {
    self = [super init];
    if (self) {
        _style = GetFullDiskPopVCStyleDefault;
        [self hookMulitLanguage];
    }
    return self;
}

+(GetFullAccessWndController *)shareInstance {
    static GetFullAccessWndController *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GetFullAccessWndController alloc] init];
    });
    return instance;
}

-(void)setParaentCenterPos:(CGPoint)centerPos suceessSeting:(SuccessSettingBlock) successSettingBlock{
    self.centerPoint = centerPos;
    self.successSettingBlock = successSettingBlock;
    if(![self.window isVisible])
    {
        [self loadWindow];
    }
}

-(void)closeWindow{
    [self.window close];
}

- (void)hookMulitLanguage {
    NSString *languageString = [LanguageHelper getCurrentUserLanguageByReadFile];
    if(languageString != nil) {
        [NSBundle setLanguage:languageString bundle:[NSBundle bundleForClass:[GetFullAccessWndController class]]];
    }
}

-(void)loadWindow{
    NSRect frame;
    if (self.style == GetFullDiskPopVCStyleMonitor) {
        frame = NSMakeRect(0, 0, 610, 524);
    } else {
        frame = NSMakeRect(0, 0, 610, 476);
    }
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
    [self windowDidLoad];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    __weak GetFullAccessWndController *weakSelf = self;
    GetFullDiskPopViewController *viewCon = [[GetFullDiskPopViewController alloc] initWithCLoseSetting:^{
        [weakSelf.window close];
    }];
    viewCon.style = self.style;
    self.contentViewController = viewCon;
}


-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
