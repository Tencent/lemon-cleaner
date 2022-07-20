//
//  LMNetProcViewController.m
//  LemonNetSpeed
//
//  
//  Copyright © 2019年 tencent. All rights reserved.
//

#import "LMNetProcViewController.h"
#import "LMProcNetCellView.h"
#import <QMCoreFunction/McStatMonitor.h>
#import "McStatInfoConst.h"
#import <QMCoreFunction/McProcessInfoData.h>
#import "QMNetworkSpeedFormatter.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import "LMNetProcRowView.h"
#import <QMUICommon/MMScroller.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import "QMNetworkStatus.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSArray+Extension.h>
#import <QMCoreFunction/NSString+Extension.h>

static const NSUInteger kMaxCount = 10;
static NSString * const kImageKey = @"image";
static NSString * const kTitleKey = @"title";
static NSString * const kSpeedKey = @"speed";
static NSString * const kDownloadSpeedKey = @"downloadSpeed";
static NSString * const kUploadSpeedKey = @"uploadSpeed";
static NSString * const kPidKey = @"pid";

@interface LMNetProcViewController ()<NSOutlineViewDataSource, NSOutlineViewDelegate>
{
    QMNetworkSpeedFormatter *_speedFormatter;
    BOOL _isNetConnect;
}
@property (strong, nonatomic) NSArray *speedByProcess;
@property (nonatomic, assign) float upSpeed;
@property (nonatomic, assign) float downSpeed;


@property (weak) IBOutlet NSImageView *noProcImageView;
@property (weak) IBOutlet NSTextField *noNetTips;
@property(nonatomic, weak) IBOutlet NSOutlineView *outlineView;
@property (weak) IBOutlet NSScrollView *scroolView;
@property (weak) IBOutlet NSView *seprateLineView;
//@property(nonatomic, weak) IBOutlet NSTextField *procCountTextField;
@property(nonatomic, weak) IBOutlet NSTextField *downloadTotalTextField;
@property(nonatomic, weak) IBOutlet NSTextField *uploadTotalTextField;
@property (weak) IBOutlet NSTextField *flowMonitor;
@property (weak) IBOutlet NSTextField *currentUploadSpeed;
@property (weak) IBOutlet NSTextField *currentDownloadSpeed;
@property (weak) IBOutlet NSTextField *appName;
@property (weak) IBOutlet NSTextField *uploadSpeed;
@property (weak) IBOutlet NSTextField *downloadSpeed;


@end

@implementation LMNetProcViewController

+ (NSDictionary *)networkInfoItemWithPid:(id)pid name:(NSString *)processName icon:(NSImage *)image upSpeed:(NSNumber *)upSpeed downSpeed:(NSNumber *)downSpeed
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    if (pid) {
        dict[kPidKey] = pid;
    }
    if (processName) {
        dict[kTitleKey] = processName;
    }
    if (image) {
        dict[kImageKey] = image;
    }
    if (upSpeed && downSpeed) {
        dict[kSpeedKey] = @([upSpeed unsignedLongLongValue]  + [downSpeed unsignedLongLongValue]);
        dict[kUploadSpeedKey] = @([upSpeed unsignedLongLongValue]);
        dict[kDownloadSpeedKey] = @([downSpeed unsignedLongLongValue]);
    }
    return dict;
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
    [self initView];
    [self initViewText];
    [self initData];
}

-(void)initViewText{
    [self.flowMonitor setStringValue:NSLocalizedStringFromTableInBundle(@"LMNetProcViewController_initViewText_flowMonitor_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.currentUploadSpeed setStringValue:NSLocalizedStringFromTableInBundle(@"LMNetProcViewController_initViewText_currentUploadSpeed_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.currentDownloadSpeed setStringValue:NSLocalizedStringFromTableInBundle(@"LMNetProcViewController_initViewText_currentDownloadSpeed_3", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.appName setStringValue:NSLocalizedStringFromTableInBundle(@"LMNetProcViewController_initViewText_appName_4", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.appName setTextColor:[NSColor colorWithHex:0x94979B]];
    [self.downloadSpeed setStringValue:NSLocalizedStringFromTableInBundle(@"LMNetProcViewController_initViewText_downloadSpeed_5", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.downloadSpeed setTextColor:[NSColor colorWithHex:0x94979B]];
    [self.uploadSpeed setStringValue:NSLocalizedStringFromTableInBundle(@"LMNetProcViewController_initViewText_uploadSpeed_6", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.uploadSpeed setTextColor:[NSColor colorWithHex:0x94979B]];
    [self.noNetTips setStringValue:NSLocalizedStringFromTableInBundle(@"LMNetProcViewController_initViewText_noNetTips_7", nil, [NSBundle bundleForClass:[self class]], @"")];
    
    [self setTitleColorForTextField:self.flowMonitor];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)networkChange:(BOOL)isReachable{
    if (!isReachable) {
        [self noConnectionState];
    } else {
        [self connectionState];
    }
}

- (void)connectionState
{
    _isNetConnect = YES;
    [self.outlineView setHidden:NO];
//    [self.noProcImageView setHidden:YES];
    [self.noNetTips setHidden:YES];
    [self.noProcImageView setImage:[NSImage imageNamed:@"no_proc_icon" withClass:[self class]]];
}

- (void)noConnectionState
{
    [self.noProcImageView setImage:[NSImage imageNamed:@"no_net_icon" withClass:[self class]]];
    [self.noProcImageView setHidden:NO];
    [self.outlineView setHidden:YES];
    [self.noNetTips setHidden:NO];
    _isNetConnect = NO;
}

- (void)initView {
    [self.view setWantsLayer:YES];
    [self.view.layer setBackgroundColor:[NSColor whiteColor].CGColor];
    [_seprateLineView setWantsLayer:YES];
//    [self.noProcImageView setHidden:YES];
    [self.noNetTips setHidden:YES];
    [_seprateLineView.layer setBackgroundColor:[NSColor colorWithHex:0xe8e8e8].CGColor];
    [_downloadTotalTextField setTextColor:[NSColor colorWithHex:0x06D99A]];
    [_uploadTotalTextField setTextColor:[NSColor colorWithHex:0x1A83F7]];
    MMScroller *scroller = [[MMScroller alloc] init];
    [self.scroolView setVerticalScroller:scroller];
    [self.scroolView setBackgroundColor:[NSColor whiteColor]];
    [self.outlineView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
//    [_procCountTextField setTextColor:[NSColor colorWithHex:0x04D999]];
    
    [self.currentUploadSpeed mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(18);
        make.bottom.equalTo(self.seprateLineView.mas_top).offset(-8);
    }];
    
    [self.uploadTotalTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.currentUploadSpeed.mas_right);
        make.centerY.equalTo(self.currentUploadSpeed);
    }];
    
    [self.currentDownloadSpeed mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.uploadTotalTextField.mas_right).offset(10);
        make.centerY.equalTo(self.uploadTotalTextField);
    }];
    
    [self.downloadTotalTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.currentDownloadSpeed.mas_right);
        make.centerY.equalTo(self.currentDownloadSpeed);;
    }];
    
    BOOL isConnect = [QMNetworkStatus connectedToNetworkStatus];
    if (!isConnect) {
        [self noConnectionState];
    }
}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:self.seprateLineView];
}

- (void)initData {
    _speedFormatter = [[QMNetworkSpeedFormatter alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNetworkInfoChanged:)
                                                 name:kNetworkInfoNotification
                                               object:nil];
    [self.downloadTotalTextField setStringValue:@"0.0KB/s"];
    [self.uploadTotalTextField setStringValue:@"0.0KB/s"];
//    [[McStatMonitor shareMonitor] startRunMonitor];
}

- (void)receivedNetworkInfoChanged:(NSNotification *)notification {
    NSArray *flowSpeedArray = nil;
//    if (popover.networkViewController.isWindowVisible) {
    if (YES) {
        NSArray *processInfo = [[McStatMonitor shareMonitor].processInfo filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"upSpeed > 0 OR downSpeed > 0"]];
        flowSpeedArray = [processInfo map:^id(McProcessInfoData *obj, NSUInteger index) {
            NSRunningApplication *runningApp = [NSRunningApplication runningApplicationWithProcessIdentifier:obj.pid];
            return [LMNetProcViewController
                    networkInfoItemWithPid:[NSString stringWithFormat:@"%d", obj.pid]
                    name:runningApp.localizedName ?: obj.pName
                    icon:runningApp.icon ?: [[NSWorkspace sharedWorkspace] iconForFile:obj.pExecutePath]
                    upSpeed: @(obj.upSpeed)
                    downSpeed: @(obj.downSpeed)];
        }];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        float upSpeed = [[notification.object objectForKey:@"UpSpeed"] floatValue];
        float downSpeed = [[notification.object objectForKey:@"DownSpeed"] floatValue];
        self.upSpeed = upSpeed;
        self.downSpeed = downSpeed;
        
        self.downloadTotalTextField.stringValue = [NSString stringFromNetSpeedWithoutSpacing:downSpeed/1024.f];
        self.uploadTotalTextField.stringValue = [NSString stringFromNetSpeedWithoutSpacing:upSpeed/1024.f];
        
        [self addSpeedByProcessFromArray:flowSpeedArray];
    });
}

- (void)dismiss
{
//    [[McStatMonitor shareMonitor] stopRunMonitor];
}

- (void)addSpeedByProcessFromArray:(NSArray *)objects
{
    if (!_isNetConnect) {
        return;
    }
    NSComparator comparator = ^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [obj1[kPidKey] compare:obj2[kPidKey]];
    };
    NSArray *sortedObjects = [objects sortedArrayUsingComparator:comparator];
    NSMutableArray *currentObjects = [NSMutableArray arrayWithArray: [self.speedByProcess sortedArrayUsingComparator:comparator]];
    
    NSUInteger currentCount = currentObjects.count;
    NSUInteger objectCount = objects.count;
    NSUInteger i = 0, j = 0;
    while(i < currentCount && j < objectCount) {
        NSDictionary *cur = currentObjects[i];
        NSDictionary *obj = sortedObjects[j];
        switch (comparator(cur, obj)) {
            case NSOrderedSame:
                currentObjects[i] = obj;
                ++i;
                ++j;
                break;
            case NSOrderedAscending: {
                if ([self isItemLive:cur]) {
                    NSMutableDictionary *newObj = [cur mutableCopy];
                    newObj[kSpeedKey] = @0;
                    newObj[kDownloadSpeedKey] = @0;
                    newObj[kUploadSpeedKey] = @0;
                    currentObjects[i] = newObj;
                    ++i;
                } else {
                    [currentObjects removeObjectAtIndex:i];
                    -- currentCount;
                }
            }break;
            case NSOrderedDescending:
                [currentObjects insertObject:obj atIndex:i];
                currentCount += 1;
                ++i;
                ++j;
                break;
        }
    }
    
    for (; i < currentCount; ++i) {
        NSDictionary *item = currentObjects[i];
        if ([self isItemLive:item]) {
            NSMutableDictionary *newObj = [currentObjects[i] mutableCopy];
            newObj[kSpeedKey] = @0;
            newObj[kDownloadSpeedKey] = @0;
            newObj[kUploadSpeedKey] = @0;
            currentObjects[i] = newObj;
        } else {
            [currentObjects removeObjectAtIndex:i];
            --currentCount;
        }
    }
    
    for (; j < objectCount; ++j) {
        [currentObjects addObject:sortedObjects[j]];
    }
    
    if (currentObjects.count > kMaxCount) {
        [currentObjects sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            NSComparisonResult result = [obj1[kSpeedKey] compare:obj2[kSpeedKey]];
            switch (result) {
                case NSOrderedSame:
                    return NSOrderedSame;
                    break;
                case NSOrderedAscending:
                    return NSOrderedDescending;
                case NSOrderedDescending:
                    return NSOrderedAscending;
            };
        }];
        [currentObjects removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(kMaxCount, currentObjects.count - kMaxCount)]];
    }
    NSComparator speedComparator = ^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        NSComparisonResult result = [obj1[kSpeedKey] compare:obj2[kSpeedKey]];
        switch (result) {
            case NSOrderedSame:
                return NSOrderedSame;
                break;
            case NSOrderedAscending:
                return NSOrderedDescending;
            case NSOrderedDescending:
                return NSOrderedAscending;
        };
    };
    self.speedByProcess = [currentObjects sortedArrayUsingComparator:speedComparator];
//    self.procCountTextField.stringValue = [NSString stringWithFormat:@"%lu", [currentObjects count]];
    [self.noProcImageView setHidden:[currentObjects count] == 0 ? NO : YES];
    [self.outlineView reloadData];
}

- (BOOL)isItemLive:(NSDictionary *)item
{
    pid_t pid = (pid_t)[item[kPidKey] integerValue];
    NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
    return app && [[app localizedName] isEqualToString:item[kTitleKey]];
}

#pragma mark-
#pragma mark outline View Delegate

-(NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item{
    LMNetProcRowView *rowView = [[LMNetProcRowView alloc] initWithFrame:NSZeroRect];
    return rowView;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item)
    {
        return [self.speedByProcess count];
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item)
    {
        return self.speedByProcess[index];
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return nil;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(NSDictionary *)item
{
    // 如果owner是self, awakerFromNib会被调用
    LMProcNetCellView *view = [outlineView makeViewWithIdentifier:@"LMProcNetCellView" owner:self];
    [view.iconView setImage: item[kImageKey]];
    [view.nameLabel setStringValue:item[kTitleKey]];
    [view.downloadLabel setStringValue: [_speedFormatter stringForObjectValue: item[kDownloadSpeedKey]]];
    [view.uploadLabel setStringValue: [_speedFormatter stringForObjectValue: item[kUploadSpeedKey]]];
    return view;
}

@end
