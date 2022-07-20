//
//  McTableCellView.m
//  LemonUninstaller
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "McTableCellView.h"
//#import "McUninstallSoftManager.h"
#import "LMLocalApp.h"

@implementation McTableCellView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDelectProgress:)
                                                     name:LMNotificationDelectProgress
                                                   object:nil];

    }
    return self;
}


-(void)awakeFromNib{
    [super awakeFromNib];
    [_btnRemove setTitle:NSLocalizedStringFromTableInBundle(@"McTableCellView_awakeFromNib_btnRemove_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    
    if(self.timeprogressView){
        self.timeprogressView.indeterminate = YES;
        self.timeprogressView.displayedWhenStopped = YES;
        [self.timeprogressView setUsesThreadedAnimation:YES];
//        self.timeprogressView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    }

    if(self.sizeProgressView){
        self.sizeProgressView.indeterminate = YES;
        self.sizeProgressView.displayedWhenStopped = YES;
        [self.sizeProgressView setUsesThreadedAnimation:YES];
//        self.sizeProgressView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    }
    
    //11.0 系统和
    if (@available(macOS 11.0,*)) {
        NSRect appIconRect = self.appIcon.frame;
        self.appIcon.frame = NSMakeRect(appIconRect.origin.x - 7, appIconRect.origin.y, appIconRect.size.width, appIconRect.size.height);
        
        NSRect appNameRect = self.appName.frame;
        self.appName.frame = NSMakeRect(appNameRect.origin.x - 7, appNameRect.origin.y, appNameRect.size.width, appNameRect.size.height);
        
    }
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}
- (IBAction)labelSeize:(id)sender {
}

- (void)uninstallClick:(id)sender
{
    NSLog(@"uninstallClick %@", sender);
    if (_actionHandler) _actionHandler();
}


// 会接收到多次, 一个软件卸载有十几个项, 每一项卸载完成都会回调
- (void)onDelectProgress:(NSNotification *)notify
{
   
    
    if (self.soft != notify.object)
        return;
    
    //
    if (!self.window || (!self.timeprogressView && !self.sizeProgressView))
        return;
    
    [self.btnRemove setHidden:YES];
    [self.lastOpen setHidden:YES];
    [self.sizeLabel setHidden:YES];
    [self.timeprogressView setHidden:NO];
    [self.sizeProgressView setHidden:NO];

    
//    double progress = [[notify.userInfo objectForKey:LMNotificationKeyDelProgress] doubleValue];
    BOOL isFinish = [[notify.userInfo objectForKey:LMNotificationKeyIsDelFinished] boolValue];
//    NSLog(@"%s, uninstall progress %f", __FUNCTION__, progress);
//    self.progressView.value = progress;
    LMLocalApp *app = notify.object;
    //卸载时如果没有移选择xxx.app，这时把progressView隐藏，btnRemove显示出来
    if (isFinish && ![app isBundleItemDelected]) {
        NSLog(@"uninstall end, soft:%@", app.showName);
        [self.timeprogressView setHidden:YES];
        [self.sizeProgressView setHidden:YES];
        [self.sizeLabel setHidden:NO];
        [self.lastOpen setHidden:NO];
        [self.btnRemove setHidden:NO];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
