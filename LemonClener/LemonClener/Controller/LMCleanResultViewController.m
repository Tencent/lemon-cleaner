//
//  LMCleanResultViewController.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMCleanResultViewController.h"
#import "CleanerCantant.h"
#import "LMResultButton.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import "LMLineChartView.h"
#import <QMCoreFunction/NSString+Extension.h>
#import "LMCleanerDataCenter.h"
#import <QMUICommon/LMRectangleButton.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/NSFontHelper.h>
#import "MacDeviceHelper.h"
#import "AnimationHelper.h"
#import <QMUICommon/LMAppThemeHelper.h>

@interface LMCleanResultViewController ()<NSTableViewDelegate, NSTableViewDataSource, LineCharViewMouseOnLineEvent, CAAnimationDelegate>
{
    __weak IBOutlet NSTextField *mainTitle;
    __weak IBOutlet NSTextField *mainText;
    __weak IBOutlet NSTextField *fileNumText;
    __weak IBOutlet NSTextField *timeText;
    __weak IBOutlet NSTextField *recent7DaysTitle;
    __weak IBOutlet NSTextField *recent7DaysSize;
    __weak IBOutlet NSView *contentView;
    __weak IBOutlet NSView *tipCleanSizeView;
//    __weak IBOutlet NSTextField *theDayTitleLabel;
    __weak IBOutlet NSTextField *theDaySizeLabel;
    __weak IBOutlet NSImageView *fileNumIcon;
    __weak IBOutlet NSImageView *timeIcon;
    LMLineChartView *chartView;
    
    __weak IBOutlet NSView *lineView;
    //added by levey
    __weak IBOutlet NSView *resultUpAnimateView;
    NSInteger _isAnimating;                     //动画计数，用于屏蔽动画中点击事件或跳转逻辑（切换动画同一时间只有一套，可以用一个计数简单处理）
}

@end

@implementation LMCleanResultViewController

-(id)init{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initView];
    _isAnimating = 0;
}

-(void)viewWillAppear{
    [super viewWillAppear];
    
    NSLog(@"LMCleanResultViewController view will appear");
    CleanStatus status = [[LMCleanerDataCenter shareInstance] getCurrentCleanerStatus];
    if (status == CleanStatusCleanResult) {
        NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];
        [chartView clear];
        NSArray *values = [[LMCleanerDataCenter shareInstance] getSevenDaysTotalCleanSizeArrByTimeInterval:nowTimeInterval];
        
        LMDataSet *dataSet = [[LMDataSet alloc] initWithValues:values
                                                     withColor:[NSColor colorWithRed:0xff/255.0 green:0xb7/255.0 blue:0x59/255.0 alpha:1]
                                                  withColorEnd:[NSColor colorWithRed:0xff/255.0 green:0xd2/255.0 blue:0x30/255.0 alpha:1]
                                             andFillColorStart:[NSColor colorWithRed:0xfd/255.0 green:0xef/255.0 blue:0xce/255.0 alpha:0.3]
                                               andFillColorEnd:[NSColor colorWithRed:0xff/255.0 green:0xff/255.0 blue:0xff/255.0 alpha:0]
                                                  andLineWidth:4];
        
        [chartView addDataSet:dataSet];
        
        [chartView setDoesDrawXAxisTicks:YES];
        NSArray *labels = [[LMCleanerDataCenter shareInstance] getSevenDaysDateStrlByTimeInterval:nowTimeInterval];
        [chartView setXAxisLabels:labels];
        chartView.axisLabelAttributes = @{NSFontAttributeName: [NSFont systemFontOfSize:10], NSForegroundColorAttributeName: [NSColor lightGrayColor]};
        
        [chartView setDoesDrawGrid:YES];
        [chartView setGridLineStyle:@[@1,@1]];
        
        UInt64 totalSize = [[LMCleanerDataCenter shareInstance] getSevenDaysTotalCleanSizeByTimeInterval:nowTimeInterval];
        NSString *sizeString = [NSString stringFromDiskSize:totalSize];
        [recent7DaysSize setStringValue:sizeString];
    }
}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:lineView];
}
-(void)initView{
    [self.view becomeFirstResponder];
    [self.view setAcceptsTouchEvents:YES];
    outlineView.headerView = nil;
    
//    [mainTitle setTextColor:[NSColor colorWithHex:0x515151]];
    [LMAppThemeHelper setTitleColorForTextField:mainTitle];
    [mainText setTextColor:[NSColor colorWithHex:0x00DB99]];
    [fileNumText setTextColor:[NSColor colorWithHex:0x94979b]];
    [timeText setTextColor:[NSColor colorWithHex:0x94979b]];
    [LMAppThemeHelper setTitleColorForTextField:recent7DaysTitle];
    [recent7DaysSize setTextColor:[NSColor colorWithHex:0x00DB99]];
    
    [recent7DaysTitle mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->contentView).offset(64);
        make.top.equalTo(self->contentView).offset(35);
    }];
    
    [recent7DaysSize mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->recent7DaysTitle.mas_right).offset(2);
        make.centerY.equalTo(self->recent7DaysTitle);
    }];
    
    [fileNumText mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self->fileNumIcon);
        make.left.equalTo(self->fileNumIcon.mas_right).offset(9);
        make.height.equalTo(@19);
    }];
    
    [timeIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self->fileNumIcon);
        make.left.equalTo(self->fileNumText.mas_right).offset(36);
        make.height.equalTo(@18);
        make.width.equalTo(@18);
    }];
    
    [timeText mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self->fileNumIcon);
        make.left.equalTo(self->timeIcon.mas_right).offset(9);
        make.height.equalTo(@19);
        make.width.equalTo(@173);
    }];
    
    chartView = [[LMLineChartView alloc] initWithFrame:CGRectMake(49, 45, 912, 331)];
    
    
    chartView.mouseOnLineEventDelegate = self;
    [contentView addSubview:chartView];
    
    [tipCleanSizeView setWantsLayer:YES];
    [tipCleanSizeView.layer setBackgroundColor:[NSColor clearColor].CGColor];
    [tipCleanSizeView setHidden:YES];
    [self.view addSubview:tipCleanSizeView];
//    [theDayTitleLabel setTextColor:[NSColor colorWithHex:0x515151]];
    [theDaySizeLabel setTextColor:[NSColor whiteColor]];
    
    [self initViewText];
    [self setLabelFont];
}

-(void)initViewText{
//    theDayTitleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanResultViewController_initViewText_theDayTitleLabel_1", nil, [NSBundle bundleForClass:[self class]], @"");
    mainTitle.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanResultViewController_initViewText_mainTitle_2", nil, [NSBundle bundleForClass:[self class]], @"");
    recent7DaysTitle.stringValue = NSLocalizedStringFromTableInBundle(@"LMCleanResultViewController_initViewText_recent7DaysTitle_3", nil, [NSBundle bundleForClass:[self class]], @"");
    [doneButton setTitle:NSLocalizedStringFromTableInBundle(@"LMCleanResultViewController_initViewText_doneButton_4", nil, [NSBundle bundleForClass:[self class]], @"") withColor:[NSColor whiteColor]];
}

-(void)setLabelFont{
    [fileNumText setFont:[NSFontHelper getLightSystemFont:14]];
    [timeText setFont:[NSFontHelper getLightSystemFont:14]];
    [recent7DaysTitle setFont:[NSFontHelper getLightSystemFont:16]];
    [recent7DaysSize setFont:[NSFontHelper getLightSystemFont:16]];
//    [theDayTitleLabel setFont:[NSFontHelper getLightSystemFont:12]];
    [theDaySizeLabel setFont:[NSFontHelper getLightSystemFont:12]];
}

//有垃圾的初始化
-(void)setResultViewWithCleanFileSize:(NSUInteger)fileSize fileNum:(NSUInteger) fileNum cleanTime:(NSUInteger) cleanTime{
    NSString *fileSizeString = [NSString stringFromDiskSize:fileSize];
    [[LMCleanerDataCenter shareInstance] setIsBigPage:YES];
    [mainText setStringValue:fileSizeString];
    [fileNumText setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanResultViewController_setResultViewWithCleanFileSize_fileNumText_1", nil, [NSBundle bundleForClass:[self class]], @""), fileNum]];
    if (cleanTime > 0) {
        [timeText setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanResultViewController_setResultViewWithCleanFileSize_timeText_2", nil, [NSBundle bundleForClass:[self class]], @""), cleanTime]];
    }else{
        [timeText setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMCleanResultViewController_setResultViewWithCleanFileSize_timeText_3", nil, [NSBundle bundleForClass:[self class]], @"")]];
    }
    
    [self initResultView];
    [self initResultView];
}

-(void)initResultData{
    
}

-(void)initResultView{
    
}

- (void)showAnimate {
    //reset animate view state
    [resultUpAnimateView.layer removeAllAnimations];
    [contentView.layer removeAllAnimations];
    
    [self showAnimateReverse:YES];
}

#pragma mark-
#pragma mark animation

- (void)showAnimateReverse:(BOOL)isReverse {
    if(isReverse) {
        _isAnimating = 2;
        [AnimationHelper TransOpacityAnimate:resultUpAnimateView reverse:isReverse offsetTyep:NO offsetValue:80 opacity:0 durationT:0.16 durationO:0.24 delay:0.08 type:kCAMediaTimingFunctionEaseOut delegate:self];
        [AnimationHelper TransOpacityAnimate:contentView reverse:isReverse offsetTyep:YES offsetValue:40 opacity:0 durationT:0.2 durationO:0.2 delay:0.28 type:kCAMediaTimingFunctionEaseOut delegate:self];
    } else {
        _isAnimating = 2;
        [AnimationHelper TransOpacityAnimate:resultUpAnimateView reverse:isReverse offsetTyep:NO offsetValue:80 opacity:0 durationT:0.16 durationO:0.24 delay:0.28 type:kCAMediaTimingFunctionEaseIn delegate:self];
        [AnimationHelper TransOpacityAnimate:contentView reverse:isReverse offsetTyep:YES offsetValue:40 opacity:0 durationT:0.2 durationO:0.2 delay:0.08 type:kCAMediaTimingFunctionEaseIn delegate:self];
    }
}


#pragma mark-
#pragma mark animation delegate

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    if(_isAnimating > 0)
    _isAnimating--;
}

#pragma mark-
#pragma mark user action

- (IBAction)completeAction:(id)sender {
    if(_isAnimating) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:REPARSE_CLEAN_XML object:nil];
    NSLog(@"completeAction");
    //先执行窗口移动动画（added by levey）
    CGPoint oldOrigin = self.view.window.frame.origin;
    CGPoint newOrigin = [MacDeviceHelper getScreenOriginSmall:oldOrigin];
    CGSize size = self.view.window.frame.size;
    if(oldOrigin.x != newOrigin.x) {
        __weak NSViewController* weakSelf = self;
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [context setDuration:0.3];
            [[weakSelf.view.window animator] setFrame:NSMakeRect(newOrigin.x, newOrigin.y, size.width, size.height) display:YES];
        } completionHandler:^{
            [self completeActionLogic];
        }];
    } else {
        [self completeActionLogic];
    }
}
//completeAction原本逻辑，等窗口移动后再执行（added by levey）
- (void)completeActionLogic {
    [[LMCleanerDataCenter shareInstance] setIsBigPage:NO];
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setValue:CLOSE_BIG_RESULT_VIEW forKey:@"flag"];
    [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_OR_CLOSE_BIG_CLEAN_VIEW object:nil userInfo:userInfo];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:START_JUMP_MAINPAGE object:nil];
    
    //展示切换动画，大界面动画跟窗口变化一起，不需要等动画完成再调用（added by levey）
    [self showAnimateReverse:NO];
}

#pragma mark -- LineChartView Delegate
- (void) mouseMoveOutSamplePoint:(NSPoint)point atIndex:(NSInteger)i{
//    NSLog(@"i =========== %ld", i);
//    NSLog(@"point is = %@", NSStringFromPoint(point));
    NSPoint selfPoint = [chartView convertPoint:point toView:self.view];
//    NSLog(@"selfPoint is = %@", NSStringFromPoint(selfPoint));
    CGPoint newPoint  = CGPointMake(selfPoint.x - tipCleanSizeView.frame.size.width / 2 + 16, selfPoint.y + 20);
//    NSLog(@"newPoint is = %@", NSStringFromPoint(newPoint));
    [tipCleanSizeView setFrameOrigin:newPoint];
    NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];
    NSArray *sizeArr = [[LMCleanerDataCenter shareInstance] getSevenDaysShowModelByTimeInterval:nowTimeInterval];
    if ((sizeArr == nil) || ([sizeArr count] < i + 1)) {
        [theDaySizeLabel setStringValue:@"0 M"];
    }else{
        LMCleanShowModel *showModel = [sizeArr objectAtIndex:i];
        NSString *sizeString = [NSString stringFromDiskSize:showModel.totalSize];
        [theDaySizeLabel setStringValue:sizeString];
    }
    [tipCleanSizeView setHidden:NO];
}

- (void) mouseMoveOutSamplePoint{
    NSLog(@"mouseMoveOutSamplePoint");
    [tipCleanSizeView setHidden:YES];
}

@end

