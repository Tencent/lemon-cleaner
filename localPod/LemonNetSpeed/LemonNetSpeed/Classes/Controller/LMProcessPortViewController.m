//
//  LMProcessPortViewController.m
//  LemonNetSpeed
//
//  
//  Copyright © 2019年 tencent. All rights reserved.
//

#import "LMProcessPortViewController.h"
#import "LMProcessPortModel.h"
#import "LMProcessPortRowView.h"
#import "LMNetProcRowView.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import <QMCoreFunction/McStatMonitor.h>
#import <QMCoreFunction/McProcessInfoData.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <QMUICommon/MMScroller.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMSortableButton.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSColor+Extension.h>

enum
{
    LMPortSortByName = 0,
    LMPortSortBySocketType,
    LMPortSortByConnectState
};
typedef NSInteger LMPortSortType;
@interface LMProcessPortViewController (){
    
    LMPortSortType sortType;
    SortOrderType sortOrderType;
}
@property (nonatomic, strong) NSMutableArray *portModelArray;
@property (nonatomic, strong) NSMutableDictionary *iconArray;
@property (nonatomic, strong) NSTimer *statPortTimer;

@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet NSTableView *tableView;

@property (weak) IBOutlet NSTextField *tfTitle;
@property (weak) IBOutlet NSTextField *tfPortInfo;

//@property (weak) IBOutlet NSTextField *tfHeadProtocol;
//@property (weak) IBOutlet NSTextField *tfHeadSrcIpPort;
//@property (weak) IBOutlet NSTextField *tfHeadDestIpPort;
//@property (weak) IBOutlet NSTextField *tfHeadOp;

@property (weak) IBOutlet LMSortableButton *tfHeadProtocol;
@property (weak) IBOutlet LMSortableButton *tfHeadSrcIpPort;
@property (weak) IBOutlet LMSortableButton *tfHeadDestIpPort;
@property (weak) IBOutlet LMSortableButton *tfHeadOp;
@property (weak) IBOutlet LMSortableButton *sortNameBtn;
@property (weak) IBOutlet LMSortableButton *sortSocketTypeBtn;
@property (weak) IBOutlet LMSortableButton *sortConnectStateBtn;

@property (weak) IBOutlet NSView *headView;
@property (weak) IBOutlet NSView *lineView;

@property (nonatomic, strong) NSProgressIndicator *indicator;
@end

@implementation LMProcessPortViewController

- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        [[McStatMonitor shareMonitor] setProcessPortStat:YES];
        sortType = LMPortSortByName;
        sortOrderType = Ascending;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.

    _tfTitle.font = [NSFontHelper getMediumSystemFont:15];
    _tfTitle.stringValue = NSLocalizedStringFromTableInBundle(@"LMPortStatViewController_viewDidLoad_tfTitle_1", nil, [NSBundle bundleForClass:[self class]], @"");
     [self setTitleColorForTextField:_tfTitle];
    _tfPortInfo.font = [NSFontHelper getRegularSystemFont:12];
    _tfPortInfo.stringValue = NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_viewDidLoad__tfPortInfo_1", nil, [NSBundle bundleForClass:[self class]], @"");
    _tfPortInfo.textColor = [NSColor colorWithHex:0x94979B];
    
    int fontSize = 11;
    _tfHeadProtocol.font = [NSFontHelper getMediumSystemFont:fontSize];
    
    NSDictionary *tdic = @{NSForegroundColorAttributeName: [LMAppThemeHelper getTitleColor], NSFontAttributeName:[NSFontHelper getMediumSystemFont:fontSize]};
    NSAttributedString *titleAttribute = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_viewDidLoad__tfHeadProtocol_2", nil, [NSBundle bundleForClass:[self class]], @"")
                                                                             attributes:tdic];
    _tfHeadProtocol.attributedTitle = titleAttribute;
    _tfHeadProtocol.image = nil;
    
    titleAttribute = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_viewDidLoad__tfHeadSrcIpPort_3", nil, [NSBundle bundleForClass:[self class]], @"")
                                                     attributes:tdic];
    _tfHeadSrcIpPort.attributedTitle = titleAttribute;
    _tfHeadSrcIpPort.image = nil;
    titleAttribute = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_viewDidLoad__tfHeadDestIpPort_4", nil, [NSBundle bundleForClass:[self class]], @"")
                                                     attributes:tdic];
    _tfHeadDestIpPort.attributedTitle = titleAttribute;
    _tfHeadDestIpPort.image = nil;
    titleAttribute = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_viewDidLoad__tfHeadOp_5", nil, [NSBundle bundleForClass:[self class]], @"")
                                                     attributes:tdic];
    _tfHeadOp.attributedTitle = titleAttribute;
    _tfHeadOp.image = nil;
    [self initHeader];
    
    CALayer *lineLayer = [[CALayer alloc] init];
    lineLayer.backgroundColor = [NSColor colorWithWhite:0.96 alpha:1].CGColor;
    _lineView.layer = lineLayer;
    
    MMScroller *scroller = [[MMScroller alloc] init];
    [self.scrollView setBackgroundColor:[NSColor whiteColor]];
    [self.scrollView setVerticalScroller:scroller];
    [self.scrollView setHasHorizontalScroller:NO];
    [self.tableView setBackgroundColor:[NSColor whiteColor]];
    if (@available(macOS 11.0, *)) {
        self.tableView.style = NSTableViewStyleFullWidth;
    } else {
        // Fallback on earlier versions
    }
   
    self.indicator = [[NSProgressIndicator alloc] init];
    self.indicator.style = NSProgressIndicatorStyleSpinning;
    [self.view addSubview:self.indicator];
    [self.indicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view).offset(0);
        make.width.height.equalTo(@100);
    }];
    [self.tfPortInfo setHidden:YES];
    [self.headView setHidden:YES];
    [self.lineView setHidden:YES];
    [self.scrollView setHidden:YES];
    [self.indicator startAnimation:nil];
    
    self.portModelArray = [NSMutableArray array];
    self.iconArray = [NSMutableDictionary dictionary];
    [self startPortTimer];

}

- (void)dealloc{
    [[McStatMonitor shareMonitor] setProcessPortStat:NO];
    [self stopPortTimer];
}

- (void)initHeader {
    int fontSize = 11;
    [self.sortNameBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_initHeader_sortNameBtn_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.sortSocketTypeBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_initHeader_sortSocketTypeBtn_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.sortConnectStateBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_initHeader_sortConnectStateBtn_3", nil, [NSBundle bundleForClass:[self class]], @"")];
    NSDictionary *tdic_off = @{NSForegroundColorAttributeName: [LMAppThemeHelper getTitleColor], NSFontAttributeName:[NSFontHelper getMediumSystemFont:fontSize]};
    NSDictionary *tdic_on = @{NSForegroundColorAttributeName: [LMAppThemeHelper getTitleColor], NSFontAttributeName:[NSFontHelper getMediumSystemFont:fontSize]};
    NSAttributedString *titleAttribute_off = [[NSAttributedString alloc] initWithString:self.sortNameBtn.title
                                                                             attributes:tdic_off];
    NSAttributedString *titleAttribute_on = [[NSAttributedString alloc] initWithString:self.sortNameBtn.title
                                                                            attributes:tdic_on];
    self.sortNameBtn.attributedTitle = titleAttribute_off;
    self.sortNameBtn.focusRingType = NSFocusRingTypeNone;
    self.sortNameBtn.attributedAlternateTitle  = titleAttribute_on;
    
    titleAttribute_off = [[NSAttributedString alloc] initWithString:self.sortSocketTypeBtn.title
                                                         attributes:tdic_off];
    titleAttribute_on = [[NSAttributedString alloc] initWithString:self.sortSocketTypeBtn.title
                                                        attributes:tdic_on];
    
    self.sortSocketTypeBtn.attributedTitle = titleAttribute_off;
    self.sortSocketTypeBtn.focusRingType = NSFocusRingTypeNone;
    self.sortSocketTypeBtn.attributedAlternateTitle = titleAttribute_on;
    
    titleAttribute_off = [[NSAttributedString alloc] initWithString:self.sortConnectStateBtn.title
                                                         attributes:tdic_off];
    titleAttribute_on = [[NSAttributedString alloc] initWithString:self.sortConnectStateBtn.title
                                                        attributes:tdic_on];
    self.sortConnectStateBtn.attributedTitle = titleAttribute_off;
    self.sortConnectStateBtn.focusRingType = NSFocusRingTypeNone;
    self.sortConnectStateBtn.attributedAlternateTitle = titleAttribute_on;
    
    
    [self.sortNameBtn setSortOrderType:Ascending];
    [self.sortSocketTypeBtn setSortOrderType:Ascending];
    [self.sortConnectStateBtn setSortOrderType:Ascending];
    
    self.sortNameBtn.state = NSControlStateValueOn;
    self.sortSocketTypeBtn.state = NSControlStateValueOff;
    self.sortConnectStateBtn.state = NSControlStateValueOff;
}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:self.lineView];
}

- (void) setHeaderButton:(NSButton *)button withText:(NSString *)text withColor:(NSColor *)color {
    NSDictionary *tdic_off = @{NSForegroundColorAttributeName: color, NSFontAttributeName:[NSFontHelper getMediumSystemFont:11]};
    NSDictionary *tdic_on = @{NSForegroundColorAttributeName: color, NSFontAttributeName:[NSFontHelper getMediumSystemFont:11]};
    NSAttributedString *titleAttribute_off = [[NSAttributedString alloc] initWithString:text
                                                                             attributes:tdic_off];
    NSAttributedString *titleAttribute_on = [[NSAttributedString alloc] initWithString:text
                                                                            attributes:tdic_on];
    button.attributedTitle = titleAttribute_off;
    button.attributedAlternateTitle  = titleAttribute_on;
}
- (void)setHeaderState:(NSButton *)button onButton:(NSButton *)onButton {
    if (button == onButton){
        button.state = NSControlStateValueOn;
        //[self setHeaderButton:button withText:button.title withColor:[NSColor colorWithHex:0x515151]];
    } else {
        button.state = NSControlStateValueOff;
        //[self setHeaderButton:button withText:button.title withColor:[NSColor colorWithHex:0x515151]];
    }
}

- (IBAction)headerColClicked:(id)sender {
    NSLog(@"headerColClicked %@", sender);
    [self setHeaderState:self.sortNameBtn onButton:sender];
    [self setHeaderState:self.sortSocketTypeBtn onButton:sender];
    [self setHeaderState:self.sortConnectStateBtn onButton:sender];
    
    if (sender == self.sortNameBtn) {
        if (self->sortType == LMPortSortByName) {
            [((LMSortableButton *)sender) toggleSortType];
        } else {
            self->sortType = LMPortSortByName;
        }
    } else if (sender == self.sortSocketTypeBtn) {
        if (self->sortType == LMPortSortBySocketType) {
            [((LMSortableButton *)sender) toggleSortType];
        } else {
            self->sortType = LMPortSortBySocketType;
        }
    } else {
        if (self->sortType == LMPortSortByConnectState) {
            [((LMSortableButton *)sender) toggleSortType];
        } else {
            self->sortType = LMPortSortByConnectState;
        }
    }
    self->sortOrderType = ((LMSortableButton *)sender).sortOrderType;
    [self refreshUI];
}
- (void)refreshUI {
    //NSLog(@"%s", __FUNCTION__);
    NSMutableArray<LMProcessPortModel *> *unsortedArray = [self.portModelArray mutableCopy];
    [unsortedArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        LMProcessPortModel *item1 = (LMProcessPortModel *)obj1;
        LMProcessPortModel *item2 = (LMProcessPortModel *)obj2;
        
        NSComparisonResult result = NSOrderedAscending;
        if (self->sortType == LMPortSortByName)
        {
            result = [item1.appName localizedCompare:item2.appName];
        }
        else if (self->sortType == LMPortSortBySocketType)
        {
            result = [item1.socketType localizedCompare:item2.socketType];
        }
        else if (self->sortType == LMPortSortByConnectState)
        {
            result = [item1.connectState localizedCompare:item2.connectState];
        }
        return self->sortOrderType ? result:(0 - result);
    }];
    self.portModelArray = unsortedArray;
    
    [self.tableView reloadData];
}

- (void)startPortTimer{
    if (!self.statPortTimer) {
        self.statPortTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(statProcessPort) userInfo:nil repeats:YES];
        __weak LMProcessPortViewController *weakSelf = self;
        if ([[McStatMonitor shareMonitor] fetchCacheProcessInfo].count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[McStatMonitor shareMonitor] processInfo];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf statProcessPort];
                });
            });
        } else {
            [weakSelf statProcessPort];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf statProcessPort];
            });
        }
    }
}
- (void)stopPortTimer{
    if (self.statPortTimer) {
        [self.statPortTimer invalidate];
        self.statPortTimer = nil;
    }
}
- (NSImage *)icon:(NSString*)bundlePath {
    //获取图标
    NSImage *_icon;
    if (bundlePath) {
        @try
        {
            NSImage * iconImage = nil;
            iconImage = [[NSWorkspace sharedWorkspace] iconForFile:bundlePath];
            
            if (iconImage != nil)
            {
                [iconImage setSize:NSMakeSize(32, 32)];
                _icon = iconImage;
            }
        }
        @catch (NSException *exception)
        {
            _icon = nil;
        }
    }
    
    //设置默认的图标
    if (!_icon)
    {
        // 单例,只执行一次
        static NSImage *defaultIcon = nil;
        static dispatch_once_t onceToken;
        __weak LMProcessPortViewController *weakSelf = self;
        dispatch_once(&onceToken, ^{
            //defaultIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
            //[defaultIcon setSize:NSMakeSize(32, 32)];
            defaultIcon = [[NSBundle bundleForClass:weakSelf.class] imageForResource:@"defaultTeminate"];
        });
        _icon = defaultIcon;
    }
    return _icon;
}
- (void)statProcessPort{
    int processTotal = 0, tcpLocal = 0, tcpRemote = 0;
    @autoreleasepool{
        NSArray *processInfo = [[McStatMonitor shareMonitor] fetchCacheProcessInfo];
//        if (processInfo.count == 0) {
//            return;
//        }
        NSString *outputStr = [QMShellExcuteHelper excuteCmd:@"netstat -vatn |grep -E 'tcp4|tcp6|tcp46|udp4|udp6|udp46'"];
        [self.portModelArray removeAllObjects];
        NSArray *portArr = [outputStr componentsSeparatedByString:@"\n"];
        for (NSString *portItem in portArr) {
            //if ([portItem containsString:@"*.*                    *.*"]) {
            //    continue;
            //}
            //NSLog(@"portItem: %@", portItem);
            
            NSError* error;
            NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[^ ]+" options:0 error:&error];
            NSArray *tempArr = [regex matchesInString:portItem options:0 range:NSMakeRange(0, [portItem length])];
            NSMutableArray *reArr = [NSMutableArray arrayWithArray:tempArr];
            //netstat -f inet -n
            //tcp4       0      0  192.168.141.1.59960    192.168.141.128.445    ESTABLISHED
            //netstat -vatn |grep -E 'tcp4|tcp6|tcp46|udp4|udp6|udp46'
            //tcp4       0      0  10.68.56.61.53315      10.14.36.100.8080      ESTABLISHED 131072 131376  32971      0
            NSMutableArray *pis = [NSMutableArray array];
            for (NSTextCheckingResult *res in reArr) {
                [pis addObject:[portItem substringWithRange:res.range]];
            }
            NSInteger minLength = 9;
            if (@available(macOS 15.0, *)) {
                minLength = 11;
            }
            if (pis.count < minLength) {
                continue;
            }
            if ([[pis objectAtIndex:3] isEqualToString:@"*.*"] &&
                [[pis objectAtIndex:4] isEqualToString:@"*.*"]) {
                //continue;
            }
//            if ([[pis objectAtIndex:5] isEqualToString:@"CLOSE_WAIT"] ||
//                [[pis objectAtIndex:5] isEqualToString:@"FIN_WAIT_2"] ||
//                [[pis objectAtIndex:5] isEqualToString:@"FIN_WAIT"]) {
//                continue;
//            }
            BOOL isTcp = NO;
            if ([[pis objectAtIndex:0] hasPrefix:@"tcp"]) {
                isTcp = YES;
            }
            LMProcessPortModel *model = [[LMProcessPortModel alloc] init];
            McProcessInfoData* findInfo = NULL;
            for (McProcessInfoData* info in processInfo) {
                pid_t pid = info.pid;
                if (isTcp) {
                    if (pis.count > minLength && [[pis objectAtIndex:(minLength - 1)] integerValue] == pid) {
                        findInfo = info;
                        break;
                    }
                } else {
                    if (pis.count > (minLength - 1) && [[pis objectAtIndex:(minLength - 2)] integerValue] == pid) {
                        findInfo = info;
                        break;
                    }
                }
            }
            if (!findInfo) {
                continue;
            }
            model.pid = findInfo.pid;
            model.appName = findInfo.pName;
            NSImage *cacheIcon = [self.iconArray objectForKey:model.appName];
            if (cacheIcon) {
                model.appIcon = cacheIcon;
            } else {
                NSString *bundlePath = [[[findInfo.pExecutePath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent ]stringByDeletingLastPathComponent];
                NSImage *icon = nil;
                if ([[bundlePath pathExtension] isEqualToString:@"app"]) {
                    icon = [self icon:bundlePath];
                } else {
                    icon = [self icon:nil];
                }
                if (icon) {
                    model.appIcon = icon;
                    [self.iconArray setObject:model.appIcon forKey:model.appName];
                }
            }
            if (isTcp) {
                model.protocol = @"TCP";
                model.connectState = @"--";
                if ([[pis objectAtIndex:5] hasSuffix:@"ESTABLISHED"]) {
                    model.connectState = NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_statProcessPort_1558009676_1", nil, [NSBundle bundleForClass:[self class]], @"");
                } else if ([[pis objectAtIndex:5] hasSuffix:@"LISTEN"]) {
                    model.connectState = NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_statProcessPort_1558009676_2", nil, [NSBundle bundleForClass:[self class]], @"");
                } else {
                    model.connectState = @"--";
                }
//            if ([[pis objectAtIndex:5] isEqualToString:@"CLOSE_WAIT"] ||
//                [[pis objectAtIndex:5] isEqualToString:@"FIN_WAIT_2"] ||
//                [[pis objectAtIndex:5] isEqualToString:@"FIN_WAIT"]) {
//                continue;
//            }
//                if ([[pis objectAtIndex:5] length] > 0) {
//                    model.connectState = [pis objectAtIndex:5];
//                }
                if ([[pis objectAtIndex:4] hasPrefix:@"127.0.0.1"] ||
                    [[pis objectAtIndex:4] isEqualToString:@"*.*"]) {
                    model.socketType = NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_statProcessPort_1558009676_3", nil, [NSBundle bundleForClass:[self class]], @"");
                    tcpLocal++;
                } else {
                    model.socketType = NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_statProcessPort_1558009676_4", nil, [NSBundle bundleForClass:[self class]], @"");
                    tcpRemote++;
                }
            } else {
                model.protocol = @"UDP";
                model.connectState = @"--";
                model.socketType = @"--";
            }
            model.srcIpPort = [pis objectAtIndex:3];
            model.destIpPort = [pis objectAtIndex:4];
            [self.portModelArray addObject:model];
            processTotal++;
        }
        
        //NSLog(@"%lu", (unsigned long)self.portModelArray.count);
    }
    if (self.portModelArray.count > 0) {
        [self.tfPortInfo setHidden:NO];
        [self.headView setHidden:NO];
        [self.lineView setHidden:NO];
        [self.scrollView setHidden:NO];
        [self.indicator stopAnimation:nil];
        [self.indicator setHidden:YES];
    }
    [self refreshUI];
    
    //processTotal = tcpLocal + tcpRemote;
    NSString *strPort = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_statProcessPort_NSString_5", nil, [NSBundle bundleForClass:[self class]], @""), processTotal, tcpLocal, tcpRemote];
    NSString *strPortTemp = strPort;
    
    NSString *strNumber = [NSString stringWithFormat:@"%d", processTotal];
    int pos = (int)[strPortTemp rangeOfString:strNumber].location;
    NSRange range1 = NSMakeRange(pos, strNumber.length);
    
    strPortTemp = [strPortTemp substringWithRange:NSMakeRange(pos+strNumber.length, [strPortTemp length]-(pos+strNumber.length))];
    strNumber = [NSString stringWithFormat:@"%d", tcpLocal];
    pos = (int)[strPortTemp rangeOfString:strNumber].location;
    NSRange range2 = NSMakeRange(pos+range1.location+range1.length, strNumber.length);
    
    strPortTemp = [strPortTemp substringWithRange:NSMakeRange(pos+strNumber.length, [strPortTemp length]-(pos+strNumber.length))];
    strNumber = [NSString stringWithFormat:@"%d", tcpRemote];
    pos = (int)[strPortTemp rangeOfString:strNumber].location;
    NSRange range3 = NSMakeRange(pos+range2.location+range2.length, strNumber.length);
    
    NSFont *font = [NSFontHelper getLightSystemFont:12];
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:strPort];
    [attrStr addAttributes:@{NSFontAttributeName:font,
                             NSForegroundColorAttributeName: [NSColor colorWithHex:0x94979B]}
                     range:NSMakeRange(0, strPort.length)];
    NSRange allRange = [strPort rangeOfString:strPort];
    if (NSLocationInRange(range1.location, allRange) && NSLocationInRange(range1.location+range1.length, allRange)) {
        [attrStr addAttributes:@{NSFontAttributeName:font,
                                 NSForegroundColorAttributeName: [NSColor colorWithHex:0x04D999]}
                         range:range1];
    }
    if (NSLocationInRange(range2.location, allRange) && NSLocationInRange(range2.location+range2.length, allRange)) {
        [attrStr addAttributes:@{NSFontAttributeName:font,
                                 NSForegroundColorAttributeName: [NSColor colorWithHex:0x04D999]}
                         range:range2];
    }
    if (NSLocationInRange(range3.location, allRange) && NSLocationInRange(range3.location+range3.length, allRange)) {
        [attrStr addAttributes:@{NSFontAttributeName:font,
                                 NSForegroundColorAttributeName: [NSColor colorWithHex:0x04D999]}
                         range:range3];
    }
    self.tfPortInfo.attributedStringValue = attrStr;
}


// for table view
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.portModelArray.count;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    return [[LMNetProcRowView alloc] init];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *identifier = tableColumn.identifier;
    LMProcessPortRowView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
    if (self.portModelArray.count < row) {
        NSLog(@"self.portModelArray.count < row");
        return cellView;
    }
    LMProcessPortModel *model = [self.portModelArray objectAtIndex:row];
    cellView.portModel = model;
    if ([identifier isEqualToString:@"AppInfo"])
    {
        cellView.appName.stringValue = model.appName;
        [cellView.appName setToolTip:model.appName];
        cellView.appName.textColor = [LMAppThemeHelper getTitleColor];
        [cellView.appIcon setImage:model.appIcon];
    }
    else if ([identifier isEqualToString:@"protocol"])
    {
        cellView.protocol.stringValue = model.protocol;
    }
    else if ([identifier isEqualToString:@"socketType"])
    {
        cellView.socketType.stringValue = model.socketType;
    }
    else if ([identifier isEqualToString:@"srcIpPort"])
    {
        cellView.srcIpPort.stringValue = model.srcIpPort;
    }
    else if ([identifier isEqualToString:@"destIpPort"])
    {
        cellView.destIpPort.stringValue = model.destIpPort;
    }
    else if ([identifier isEqualToString:@"connectState"])
    {
        cellView.connectState.stringValue = model.connectState;
    }
    else if ([identifier isEqualToString:@"killProcess"])
    {
        __weak LMProcessPortViewController *weakSelf = self; //block里使用weak self避免强引用循环。
        cellView.actionHandler = ^(LMProcessPortModel *portModel){
            NSAlert *alert = [[NSAlert alloc] init];
            alert.alertStyle = NSAlertStyleInformational;
            alert.messageText = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_tableView_NSString_1", nil, [NSBundle bundleForClass:[weakSelf class]], @""), portModel.appName];
            alert.informativeText = NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_tableView_alert_2", nil, [NSBundle bundleForClass:[weakSelf class]], @"");
            [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_tableView_alert_3", nil, [NSBundle bundleForClass:[weakSelf class]], @"")];
            [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMProcessPortViewController_tableView_alert_4", nil, [NSBundle bundleForClass:[weakSelf class]], @"")];
            alert.window.backgroundColor = [LMAppThemeHelper getMainBgColor];
            NSInteger responseTag = [alert runModal];
            if (responseTag == NSAlertFirstButtonReturn) {
                [weakSelf.view.window orderFront:nil];
                int pid = portModel.pid;
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    [[McCoreFunction shareCoreFuction] killProcessByID: pid];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf statProcessPort];
                    });
                });
            }
        };
    }
    return cellView;
}

@end
