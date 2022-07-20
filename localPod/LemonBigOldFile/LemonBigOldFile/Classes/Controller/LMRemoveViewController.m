//
//  LMCleanViewController.m
//  LemonBigOldFile
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMRemoveViewController.h"
#import "McBigFileWndController.h"
#import "QMProgressView.h"
#import "QMLargeOldManager.h"
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMRectangleButton.h>
#import <QMUICommon/RatingUtils.h>
#import "NSColor+Extension.h"
#import "NSString+Extension.h"
#import "NSFont+Extension.h"
@interface LMRemoveViewController ()<BigFileWndEvent>

@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet QMProgressView *scanProgressView;
@property (weak) IBOutlet NSTextField *doneTitleTextView;
@property (weak) IBOutlet LMRectangleButton *doneBtn;

@end

@implementation LMRemoveViewController
{
    UInt64 _removedSize;
}

- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [_titleLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMRemoveViewController_viewDidLoad_titleLabel_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self setTitleColorForTextField:_titleLabel];
    [_doneTitleTextView setStringValue:NSLocalizedStringFromTableInBundle(@"LMRemoveViewController_viewDidLoad_doneTitleTextView_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self setTitleColorForTextField:_doneTitleTextView];
    [removedDescText setStringValue:NSLocalizedStringFromTableInBundle(@"LMRemoveViewController_viewDidLoad_removedDescText_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    [_doneBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMRemoveViewController_viewDidLoad_doneBtn_3", nil, [NSBundle bundleForClass:[self class]], @"")];
    
    [self initView];
    [self initData];
}


- (void)initData {
    [RatingUtils recordCleanFinishAction];
}

- (void)initView {
    [self setProgressViewStyle];
    [self.view addSubview:doneView];
    
    [pathText setFont:[NSFontHelper getLightSystemFont:12]];
    [removedDescText setFont:[NSFontHelper getLightSystemFont:14]];
    [removedDescText setTextColor:[NSColor colorWithHex:0x94979b]];
}

-(void)setProgressViewStyle{
    self.scanProgressView.backColor = [NSColor colorWithSRGBRed:230/255.0 green:236/255.0 blue:241/255.0 alpha:1.0];
    self.scanProgressView.fillColor = [NSColor colorWithSRGBRed:123/255.0 green:207/255.0 blue:140/255.0 alpha:1.0];
    self.scanProgressView.borderColor = [NSColor clearColor];
    self.scanProgressView.minValue = 0.0;
    self.scanProgressView.maxValue = 1.0;
    self.scanProgressView.value = 0.0;
    [self.scanProgressView setWantsLayer:YES];
}

- (void)showCleaningView {
    QMLargeOldManager * itemManager = [QMLargeOldManager sharedManager];
    NSLog(@"showCleaningView itemManager:%@", itemManager);
    NSArray * array = [itemManager needRemoveItem];
    if ([array count] == 0)
        return;
    
//    [cleaningView setHidden:NO];
//    [doneView setHidden:YES];
    //直接显示完成页面。
    [cleaningView setHidden:YES];
    [doneView setHidden:NO];
    
    [self startRemoveResult:YES];
}

-(void)showDoneView {
    [cleaningView setHidden:YES];
    [doneView setHidden:NO];
    NSString * removedSizeStr = [NSString stringFromDiskSize:_removedSize];
    
    NSString *sizeString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMRemoveViewController_viewDidLoad_removedDescText_2", nil, [NSBundle bundleForClass:[self class]], @""), removedSizeStr];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:sizeString];
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x04D999] range:NSMakeRange(0, removedSizeStr.length)];
    
    //段落样式
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc]init];
    //对齐方式
    paragraph.alignment = NSTextAlignmentCenter;
    [attrString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, sizeString.length)];
    [removedDescText setAttributedStringValue:attrString];
}

- (void)startRemoveResult:(BOOL)toTrash
{
    _removedSize = 0;
    QMLargeOldManager * itemManager = [QMLargeOldManager sharedManager];
    NSArray * array = [itemManager needRemoveItem];
    if ([array count] == 0)
        return;
    for(QMLargeOldResultItem* item in array) {
        _removedSize += item.fileSize;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 删除文件
        [itemManager removeResultItem:array toTrash:toTrash block:^(float value, NSString* path) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if(strongSelf) {
                if (value >= strongSelf.scanProgressView.value) {
                    strongSelf.scanProgressView.value = value;
                    strongSelf->pathText.stringValue = path;
                    NSLog(@"clean file:%@, progress:%f", path, value);
                }
            }
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([itemManager resultItemArray].count == 0)
            {
                // 全部删除完成
            }
            else
            {
                // 还有剩余文件
            }
            [weakSelf showDoneView];
        });
    });
}

#pragma mark-
#pragma mark user action

- (IBAction)doneAction:(id)sender {
    [self.view.window.windowController showMainView];
}

#pragma mark-
#pragma mark window event

- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"windowWillClose remove view controller");
    QMLargeOldManager * itemManager = [QMLargeOldManager sharedManager];
    [itemManager stopRemove];
}

@end
