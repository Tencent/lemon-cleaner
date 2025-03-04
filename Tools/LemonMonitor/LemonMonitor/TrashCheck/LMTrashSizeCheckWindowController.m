//
//  LMTrashSizeCheckWindowController.m
//  LemonMonitor
//

//  Copyright © 2020 Tencent. All rights reserved.
//

#import "LMTrashSizeCheckWindowController.h"
#import <QMUICommon/LMRectangleButton.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/QMProgressView.h>
#import <QMUICommon/LMBorderButton.h>
#import <QMUICommon/SharedPrefrenceManager.h>
#import "LemonDaemonConst.h"
#import <QMCoreFunction/NSString+Extension.h>
#import <QMCoreFunction/McFunCleanFile.h>
#import <QMUICommon/LMCommonHelper.h>
#import <QMUICommon/GetFullAccessWndController.h>
#import <QMCoreFunction/QMFullDiskAccessManager.h>

@interface LMTrashSizeCheckWindowController ()
@property (weak) IBOutlet NSView *containerView;

//提示需要清理
@property (strong) IBOutlet NSView *needCleanView;
@property (weak) IBOutlet LMBorderButton *nextRemindButton;
@property (weak) IBOutlet LMRectangleButton *cleanButton;
@property (weak) IBOutlet NSTextField *needCleanTipsFirst;
@property (weak) IBOutlet NSTextField *needCleanTipsSecond;

//清理中...
@property (weak) IBOutlet NSTextField *progressTitle;
@property (strong) IBOutlet NSView *cleaningView;

//清理完成
@property (strong) IBOutlet NSView *cleanResultView;
@property (weak) IBOutlet QMProgressView *progressView;
@property (weak) IBOutlet LMRectangleButton *cancelButton;
@property (weak) IBOutlet NSTextField *cleanCompleteTips;

@property (weak) IBOutlet LMRectangleButton *completeBtn;

@property BOOL isCanceled;
@property NSInteger deleteCount;
@property NSInteger totalCount;
@property NSTimer *timer;
@property (strong,nonatomic) GetFullAccessWndController *getFullAccessWndController;

@end

@implementation LMTrashSizeCheckWindowController

- (instancetype)init
{
    self = [super initWithWindowNibName:NSStringFromClass([self class])];
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self.window setMovableByWindowBackground:YES];
    [self.window setLevel:kCGDockWindowLevel];
        //TODO:没有考虑在窗口打开时切换主题样式的情况，此时切换主题，窗口样式不会变化
    [self.window setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
    [self.window setOpaque:NO];
    
}

-(void)show{
    //直接设置contentView的圆角没有效果，contentView的父View是N
    NSView *view = self.window.contentView.superview;
    view.wantsLayer = YES;
    if ([LMCommonHelper isMacOS11]) {
        view.layer.cornerRadius = 10;
    } else {
        view.layer.cornerRadius = 5;
    }
    
    if([self.window isVisible]){
        NSLog(@"%s, window has show", __FUNCTION__);
        [self resetContentView];
        [self.needCleanView setHidden:NO];
        [self initView];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(closeWindow) object:nil];
        return;
    }
    NSLog(@"%s, window has not show", __FUNCTION__);
    [self window];
    [self resetContentView];
    [self.needCleanView setHidden:NO];
    [self initView];
    NSRect frame;
    frame.size = self.needCleanView.frame.size;
    frame.origin.x = NSMaxX([[NSScreen mainScreen] visibleFrame])-NSWidth(frame)-20;
    frame.origin.y = NSMaxY([[NSScreen mainScreen] visibleFrame])-NSHeight(frame)-20;
//
    [self.window setAlphaValue:0];
//    [self.window setContentView:self.needCleanView];
    [self.window setFrame:frame display:YES];
    [self.window makeKeyAndOrderFront:nil];
    [[self.window animator] setAlphaValue:1.0];
    NSLog(@"%s, window controller : %@", __FUNCTION__, self);
}

-(void)resetContentView{
    [self.needCleanView setHidden:YES];
    [self.cleaningView setHidden:YES];
    [self.cleanResultView setHidden:YES];
}

-(void)initView{
    //init clean view
    NSString *sizeString = @"";
    NSString *sourceString = @"";
    NSInteger watchStatus = CFPreferencesGetAppIntegerValue((__bridge CFStringRef)(K_TRASH_SIZE_WATCH_STATUS), (__bridge CFStringRef)(MAIN_APP_BUNDLEID), nil);
    if(watchStatus == V_TRASH_SIZE_WATCH_WHEN_OVER_SIZE || watchStatus == 0){
        NSInteger threshold = CFPreferencesGetAppIntegerValue((__bridge CFStringRef)TRASH_SIZE_WATCH_THRESHOLD, (__bridge CFStringRef)(MAIN_APP_BUNDLEID), nil);
        if(threshold == 0){
            threshold = 1024;
        }
        sizeString = [self getTrashSizeStringWithThreshold:threshold];
        sourceString =  [self getStringByKey:@"LMTrashSizeCheckWindowController_need_clean_size_tips_content_for_over_threshold"];
    }else {
        sizeString = [NSString stringFromDiskSize:self.trashSize];
        sourceString =  [self getStringByKey:@"LMTrashSizeCheckWindowController_need_clean_size_tips_content_for_delete_file"];
    }
    sourceString = [NSString stringWithFormat:sourceString,sizeString];
    NSAttributedString *attributeString = [self attributedWithString:sourceString keywordsRange:[sourceString rangeOfString:sizeString]];
//    [self.needCleanTipsFirst setAttributedStringValue:attributeString];
    
    [self.needCleanTipsSecond setAttributedStringValue:attributeString];
    self.needCleanTipsFirst.stringValue = [self getStringByKey:@"LMTrashSizeCheckWindowController_need_clean_size_tips_content_second"];
    self.nextRemindButton.title = [self getStringByKey:@"LMTrashSizeCheckWindowController_cleaning_next_remind_btn"];
    self.cleanButton.title = [self getStringByKey:@"LMTrashSizeCheckWindowController_cleaning_clean_btn"];
    
    //init cleaning view
    self.progressTitle.stringValue = [self getStringByKey:@"LMTrashSizeCheckWindowController_cleaning_tips"];
    self.cancelButton.title = [self getStringByKey:@"LMTrashSizeCheckWindowController_cleaning_cancel_btn"];
    
    //init result view
    self.cleanCompleteTips.stringValue = [self getStringByKey:@"LMTrashSizeCheckWindowController_cleaning_complete_tips"];
    self.completeBtn.title = [self getStringByKey:@"LMTrashSizeCheckWindowController_cleaning_complete_btn"];
}

-(NSString *)getTrashSizeStringWithThreshold: (NSInteger)threshold {
    if(threshold == 1024) return @"1 GB";
    if(threshold == 2048) return @"2 GB";
    return @"500 MB";
}


NSErrorDomain kNSFontValueNilDomain  = @"kNSFontValueNilDomain";
NSErrorDomain kNSFontKeyNilDomain    = @"kNSFontKeyNilDomain";
NSErrorDomain kNSColorValueNilDomain = @"kNSColorValueNilDomain";
NSErrorDomain kNSColorKeyNilDomain   = @"kNSColorKeyNilDomain";

NSInteger kNSFontValueNilCode        =  -1001;
NSInteger kNSFontKeyNilCode          =  -1002;
NSInteger kNSColorValueNilCode       =  -1003;
NSInteger kNSColorKeyNilCode         =  -1004;

- (NSAttributedString *)attributedWithString:(NSString *)string keywordsRange:(NSRange)range
{
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12.0], NSFontAttributeName?:@"NSFont", [LMAppThemeHelper getTitleColor], NSForegroundColorAttributeName?:@"NSColor", nil];
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:string
                                                                                      attributes:attributes];
    [attributedStr addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x64DFA7] range:range];
    return attributedStr;
}

- (IBAction)cleanAction:(id)sender {
    NSLog(@"%s, window controller : %@", __FUNCTION__, self);
    
    [[NSUserDefaults standardUserDefaults] setDouble:0.0 forKey:@"kTrashSizeNextRemindTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if ([QMFullDiskAccessManager getFullDiskAuthorationStatus] != QMFullDiskAuthorationStatusAuthorized) {
        [self openFullDiskAccessSettingGuidePage];
        return;
    };
    
    [self resetContentView];
    [self.cleaningView setHidden: NO];
    self.progressView.maxValue = 1;
    self.progressView.value = 0;

    [self startClean];
}

-(void)startClean{
    self.isCanceled = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        NSString *trashPath = [@"~/.Trash" stringByExpandingTildeInPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        NSArray *pathArray = [fileManager contentsOfDirectoryAtPath:trashPath error:&error];
        self.deleteCount = 0;
        self.totalCount = pathArray.count;
//        self.totalCount = 20;
//        [self startTimer];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startTimer];
        });
        
        if(self.totalCount == 0){
            self.deleteCount = self.totalCount;
            return;
        }
        McFunCleanFile * funCleanFile = [[McFunCleanFile alloc]init];
        NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
        for (NSString *path in pathArray) {
            NSString *filePath = [[trashPath stringByAppendingString:@"/"] stringByAppendingString:path];
            NSLog(@"filePath : %@", filePath);
            BOOL status = [fileManager removeItemAtPath:filePath error:&error];
            if(!status){
                NSLog(@"%s, error : %@", __FUNCTION__, error);
                [funCleanFile removeFileByDaemonWithPath:filePath];
            }
            self.deleteCount++;
            if(self.isCanceled){
                self.deleteCount = self.totalCount;
                break;
            }
        }
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        double runTime = endTime - startTime;
        NSLog(@"runTime: %f", runTime);
    });
    
}

-(void)startTimer{
    self.timer = [NSTimer timerWithTimeInterval:0.3 target:self selector:@selector(udpateProgress) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

-(void)udpateProgress{
    NSLog(@"deleteCount : %ld", (long)self.deleteCount);
    self.progressView.value = (float)self.deleteCount/self.totalCount;
    if(self.deleteCount >= self.totalCount){
        [self resetContentView];
        [self.cleanResultView setHidden:NO];
        [self performSelector:@selector(closeWindow) withObject:nil afterDelay:1.5];
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (IBAction)nextRemindAction:(id)sender {
    NSLog(@"%s, window controller : %@", __FUNCTION__, self);
    NSTimeInterval datenow = [[NSDate date] timeIntervalSince1970];
    [[NSUserDefaults standardUserDefaults] setDouble:datenow forKey:@"kTrashSizeNextRemindTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self.window close];
}

- (IBAction)cancelCleanAction:(id)sender {
    NSLog(@"%s, window controller : %@", __FUNCTION__, self);
    self.isCanceled = YES;
    [self.window close];
}

-(void)closeWindow{
    if(self.window){
        [self.window close];
    }
}

- (IBAction)completeAction:(id)sender {
    NSLog(@"%s, window controller : %@", __FUNCTION__, self);
    [self.window close];
}

-(NSString *)getStringByKey: (NSString *)key{
    return NSLocalizedStringFromTableInBundle(key, nil, [NSBundle bundleForClass:[self class]], @"");
}

- (void)openFullDiskAccessSettingGuidePage {
    if (!self.getFullAccessWndController) {
        self.getFullAccessWndController = [GetFullAccessWndController shareInstance];
        if (@available(macOS 13.0, *)) {
            self.getFullAccessWndController.style = GetFullDiskPopVCStyleDefault;
        } else {
            self.getFullAccessWndController.style = GetFullDiskPopVCStyleMonitor;
        }
        [self.getFullAccessWndController setParaentCenterPos:[self getCenterPoint] suceessSeting:nil];
    }
    
    [self.getFullAccessWndController.window makeKeyAndOrderFront:nil];
}

- (CGPoint)getCenterPoint {
    CGPoint origin = [NSScreen mainScreen].frame.origin;
    CGSize size = [NSScreen mainScreen].frame.size;
    return CGPointMake(origin.x + size.width / 2, origin.y + size.height / 2);
}

@end
