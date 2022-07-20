//
//  McUninstallViewController.m
//  LemonUninstaller
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "McUninstallViewController.h"
#import "McUninstallSoftManager.h"
#import "McTableCellView.h"
#import "NSString+Extension.h"
#import "NSColor+Extension.h"
#import "NSButton+Extension.h"
#import "LMLoadingView.h"
#import "LMRowView.h"
#import "QMUICommon/NSFontHelper.h"
#import <QMUICommon/LMSortableButton.h>
#import "NSImage+Extension.h"
#import <QMUICommon/MMScroller.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMCoreFunction/McCoreFunction.h>
#import "LMLocalAppListManager.h"
#import "QMCircleLoadingButton.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMBigLoadingView.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/FullDiskAccessPermissionViewController.h>
#import <QMUICommon/SharedPrefrenceManager.h>
#import <QMCoreFunction/QMFullDiskAccessManager.h>
#import <QMCoreFunction/LanguageHelper.h>
#import "LemonDaemonConst.h"
#import <QMUICommon/LMPermissionGuideWndController.h>
#import "AppTrashDel.h"
#import "LMUninstallXMLParseManager.h"
#define LOADING_VIEW_SIZE       160

//monitor 卸载残留检测
#define IS_ENABLE_TRASH_WATCH @"enable_trash_watch"

//是否已经打开过弹窗提示”是否打开卸载残留功能“
#define K_HAS_OPEN_UNINSTALL_TRASH_CHECK_WINDOW @"has_open_uninstall_trash_check_window"




@interface McUninstallViewController ()<NSTableViewDelegate, NSTableViewDataSource> {
    NSBundle *_myBundle;
    NSMutableArray<McUninstallSoft *> *installedAppArrayOld;
    NSArray<LMLocalApp *> *showAppList;
    NSArray<LMLocalApp *> *filterAppList;
    __weak IBOutlet NSTableView *tableView;
    LMBigLoadingView *loadingView;
    __weak IBOutlet NSTextField *windowTitle;
    __weak IBOutlet LMSortableButton *headerButtonLastOpen;
    __weak IBOutlet LMSortableButton *headerButtonName;
    __weak IBOutlet LMSortableButton *headerButtonSize;
    __weak IBOutlet NSView *headerView;
    __weak IBOutlet NSSearchField *searchField;
    
    LMSortType sortType;
    SortOrderType sortOrderType;

    __weak IBOutlet QMCircleLoadingButton *btnRefresh;
    
    __weak IBOutlet NSTextField *noAppText;
    __weak IBOutlet NSImageView *noAppIcon;
    
    __weak IBOutlet NSTextField *loadingText;
    __weak IBOutlet NSScrollView *scrollView;
    __weak IBOutlet NSView *line1;
    __weak IBOutlet NSView *line2;
    
    NSTextField *scanPhaseLabel; // debug for scan phase
    BOOL isUninstalling;
    
    NSString *_filterKeyword;
   
    
}

@property (strong,nonatomic) LMPermissionGuideWndController *permissionGuideWndController;


@end

@implementation McUninstallViewController

// [tableView makeViewWithIdentifier:identifier owner:self] owner为self时，每调一次awakeFromNib都会被回调一次
// 可以将owner设为nil, 这样awakeFromNib只会调用一次。
- (void)awakeFromNib {
    //NSLog(@"awakeFromNib");
}

- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        _myBundle = [NSBundle bundleForClass:[self class]];
        sortType = McLocalSortName;
        sortOrderType = Ascending;
    }
    return self;
}



- (void)addLoadingViews {
    NSRect bounds = tableView.bounds;
    bounds.origin.x = (tableView.bounds.size.width - LOADING_VIEW_SIZE) / 2;
    bounds.origin.y = 184;
    bounds.size.width = LOADING_VIEW_SIZE;
    bounds.size.height = LOADING_VIEW_SIZE;
    loadingView = [[LMBigLoadingView alloc] initWithFrame:bounds];
    [self.view addSubview:loadingView];
    [loadingText setTextColor:[NSColor colorWithHex:0x94979B]];
    [loadingText setBackgroundColor:[NSColor whiteColor]];
    [loadingText setFont:[NSFontHelper getMediumSystemFont:12]];
    [loadingText setHidden:NO];
    [self setHeaderViewHidden:YES];
    [tableView setHidden:YES];
    [btnRefresh setHidden:NO];
    [btnRefresh startAnimation:nil];
    [self setNoAppViewsHidden:YES];
    [self enableHeaderCol:NO];
    
    #ifdef DebugAppUninstallScanBySerial
    // 显示扫描哪款 app
    NSTextField *scanPhaseLabel = [LMViewHelper createNormalLabel:10 fontColor:[NSColor blueColor]];
    self->windowTitle.stringValue = @"";
    self->scanPhaseLabel = scanPhaseLabel;
    [self.view addSubview:scanPhaseLabel];
    [scanPhaseLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(12);
        make.left.equalTo(self.view).offset(20);
    }];
    #endif
}

- (void)removeLoadingViews {
    NSLog(@"%s", __FUNCTION__);
    if (loadingView) {
        [loadingView invalidate];
        [loadingView removeFromSuperview];
        loadingView = nil;
    }
    [self setHeaderViewHidden:NO];
    [tableView setHidden:NO];
    [loadingText setHidden:YES];
}

-(void)loaddingEnd{
    [self setHeaderViewHidden:NO];
    [tableView setHidden:NO];
    [self enableHeaderCol:YES];
    [searchField setHidden:NO];
    [btnRefresh setHidden:NO];
    [btnRefresh setEnabled:YES];
    [btnRefresh stopAnimation:nil];
    [loadingText setHidden:YES];
}

- (void)initLoadingViews {
    [self setHeaderViewHidden:NO];
    [loadingText setHidden:YES];
}

-(void)initViewText{
    [windowTitle setStringValue:NSLocalizedStringFromTableInBundle(@"McUninstallViewController_initViewText_windowTitle_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [headerButtonName setTitle:NSLocalizedStringFromTableInBundle(@"McUninstallViewController_initViewText_headerButtonName_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    [headerButtonName setFontColor:[LMAppThemeHelper getTitleColor]];
    [headerButtonSize setTitle:NSLocalizedStringFromTableInBundle(@"McUninstallViewController_initViewText_headerButtonSize_3", nil, [NSBundle bundleForClass:[self class]], @"")];
    [headerButtonSize setFontColor:[LMAppThemeHelper getTitleColor]];
    [headerButtonLastOpen setTitle:NSLocalizedStringFromTableInBundle(@"McUninstallViewController_initViewText_headerButtonLastOpen_4", nil, [NSBundle bundleForClass:[self class]], @"")];
    [headerButtonLastOpen setFontColor:[LMAppThemeHelper getTitleColor]];
    [searchField setPlaceholderString:NSLocalizedStringFromTableInBundle(@"McUninstallViewController_initViewText_searchField_5", nil, [NSBundle bundleForClass:[self class]], @"")];
    [loadingText setStringValue:NSLocalizedStringFromTableInBundle(@"McUninstallViewController_initViewText_loadingText_6", nil, [NSBundle bundleForClass:[self class]], @"")];
    [noAppText setStringValue:NSLocalizedStringFromTableInBundle(@"McUninstallViewController_initViewText_noAppText_7", nil, [NSBundle bundleForClass:[self class]], @"")];
}

- (void)viewDidLoad {
    NSLog(@"viewDidLoad");
    [super viewDidLoad];
    showAppList = [[NSArray alloc] init];

    [self initViewText];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onScanProgress:)
                                                 name:LMNotificationScanProgress
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppListChanged:)
                                                 name:LMNotificationListChanged
                                               object:nil];
    
#ifdef DebugAppUninstallScanBySerial
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppItemScanProcess:)
                                                 name:LMNotificationScanInnerProgress
                                               object:nil];
#endif
    
    [self initSearchField];
    [self initNoAppViews];
    [self initLoadingViews];
    [self setNoAppViewsHidden:YES];
    
    windowTitle.font = [NSFontHelper getMediumSystemFont:16];
    [self setTitleColorForTextField:windowTitle];
    [self initHeader];
    [btnRefresh setEnabled:YES];

   
    [tableView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
    if (@available(macOS 11.0, *)) {
        tableView.style = NSTableViewStyleFullWidth;
    } else {
        // Fallback on earlier versions
    }
    
    if (@available(macOS 11.0,*)) {
        NSTableColumn *column = tableView.tableColumns[0];
        column.width = 320;
    }

    MMScroller *scroller = [[MMScroller alloc] init];
    [self->scrollView setVerticalScroller:scroller];
    [self->scrollView setHasHorizontalScroller:NO];
    
    // 需要全量扫描的时候, 排序策略不能使用记忆策略.(因为还未获取到大小)
    // 增量扫描时, 如果app列表有改变, 这里也无法使用记忆策略.(因为部分 app还未获取到大小).
    showAppList = [[LMLocalAppListManager defaultManager] appsListSortByType:self->sortType byAscendingOrder:self->sortOrderType];
    BOOL isNeedFullScan = [[LMLocalAppListManager defaultManager] isNeedFullScanBecauseOvertime];
    NSLog(@"%s isNeedFullScan :%hhd",__FUNCTION__, isNeedFullScan);
    
    [searchField setHidden:YES];
    [btnRefresh setHidden:YES];
    if (!isNeedFullScan && showAppList) {
        // 快速加载， 只扫描有变动的item
        [self fastReload];
    } else {
        [self loadData];
        [self initHeaderState];
    }

    // Do view setup here.
}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:line1];
    [LMAppThemeHelper setDivideLineColorFor:line2];
}

- (void)initHeader {
    NSDictionary *tdic_off = @{NSForegroundColorAttributeName: [LMAppThemeHelper getTitleColor], NSFontAttributeName:[NSFontHelper getMediumSystemFont:14]};
    NSDictionary *tdic_on = @{NSForegroundColorAttributeName: [LMAppThemeHelper getTitleColor], NSFontAttributeName:[NSFontHelper getMediumSystemFont:14]};
//    NSDictionary *tdic_on = @{NSForegroundColorAttributeName: [NSColor redColor], NSFontAttributeName:[NSFontHelper getRegularSystemFont:14]};
    NSAttributedString *titleAttribute_off = [[NSAttributedString alloc] initWithString:headerButtonLastOpen.title
                                                                             attributes:tdic_off];
    NSAttributedString *titleAttribute_on = [[NSAttributedString alloc] initWithString:headerButtonLastOpen.title
                                                                            attributes:tdic_on];
    headerButtonLastOpen.attributedTitle = titleAttribute_off;
    headerButtonLastOpen.focusRingType = NSFocusRingTypeNone;
    headerButtonLastOpen.attributedAlternateTitle  = titleAttribute_on;
    
    titleAttribute_off = [[NSAttributedString alloc] initWithString:headerButtonName.title
                                                                             attributes:tdic_off];
    titleAttribute_on = [[NSAttributedString alloc] initWithString:headerButtonName.title
                                                                            attributes:tdic_on];
    
    headerButtonName.attributedTitle = titleAttribute_off;
    headerButtonName.focusRingType = NSFocusRingTypeNone;
    headerButtonName.attributedAlternateTitle = titleAttribute_on;
    
    titleAttribute_off = [[NSAttributedString alloc] initWithString:headerButtonSize.title
                                                                             attributes:tdic_off];
    titleAttribute_on = [[NSAttributedString alloc] initWithString:headerButtonSize.title
                                                                            attributes:tdic_on];
    headerButtonSize.attributedTitle = titleAttribute_off;
    headerButtonSize.focusRingType = NSFocusRingTypeNone;
    headerButtonSize.attributedAlternateTitle = titleAttribute_on;
    
   
    [headerButtonName setSortOrderType:Ascending];
    [headerButtonSize setSortOrderType:Ascending];
    [headerButtonLastOpen setSortOrderType:Ascending];
    
    headerButtonName.state = NSControlStateValueOn;
    headerButtonSize.state = NSControlStateValueOff;
    headerButtonLastOpen.state = NSControlStateValueOff;
}


- (void) initNoAppViews {
    [noAppIcon setImage:[NSImage imageNamed:@"no_app_icon" withClass:self.class]];
    [noAppText setTextColor:[NSColor colorWithHex:0x94979B]];
    [noAppText setBackgroundColor:[NSColor whiteColor]];
    [noAppText setFont:[NSFontHelper getMediumSystemFont:12]];
}

- (void) setNoAppViewsHidden:(BOOL) isHidden {
    [noAppText setHidden:isHidden];
    [noAppIcon setHidden:isHidden];
}

- (void) setHeaderViewHidden:(BOOL) isHidden {
    [line1 setHidden:isHidden];
    [line2 setHidden:isHidden];
    [headerView setHidden:isHidden];
}

- (void) loadData {
    NSLog(@"%s", __FUNCTION__);
    [self addLoadingViews];
    [searchField setEnabled:NO];
    [btnRefresh setEnabled:NO];
    [[LMLocalAppListManager defaultManager] scanAllAppsItemAsync:sortType byAscendingOrder:sortOrderType];
}

- (void) fastReload {
    NSLog(@"%s", __FUNCTION__);
    [self addLoadingViews];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL isReady =  [[LMLocalAppListManager defaultManager] fastScan:self->sortType byAscendingOrder:self->sortOrderType];
        
        NSLog(@"%s fastReload isReady: %hhd", __FUNCTION__, isReady);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            if (!strongSelf) {
                NSLog(@" stop execute, strongSelf is nil");
                return ;
            }
            
            if (isReady) {
                
                [strongSelf refreshUI];
            } else {
                self->sortType = LMSortTypeName;// 如果需要增量扫描,则sortType在fastRefresh()内部已经重置为LMSortTypeName
                
            }
            
            [strongSelf initHeaderState];
            [strongSelf removeLoadingViews]; // 页面没扫描完就关闭了,下次打开页面直接等待
            [strongSelf loaddingEnd];
        });
      
    });
}
    
    
//    [[McUninstallSoftManager sharedManager] setSortFlag:self->sortType];
//    [[McUninstallSoftManager sharedManager] setAscending:self->sortOrderType == Ascending];
//    [[McUninstallSoftManager sharedManager] refresh];
//}

- (void)refreshUI {
    NSLog(@"refreshUI");
    showAppList =  [[LMLocalAppListManager defaultManager] appsListSortByType:self->sortType byAscendingOrder:self->sortOrderType];
    filterAppList = [self filterAppList:_filterKeyword];
    
    if ([filterAppList count] == 0) {
        [self setNoAppViewsHidden:NO];
    } else {
        [self setNoAppViewsHidden:YES];
    }
    [self->tableView reloadData];
    NSLog(@"%s, count:%ld", __FUNCTION__,  [showAppList count]);
    NSLog(@"%s, after filter count:%ld", __FUNCTION__,  [filterAppList count]);
}

- (void)onAppListChanged:(NSNotification *)notify {
    NSDictionary *info = [notify userInfo];
    NSInteger changedReason = [[info objectForKey:LMNotificationKeyListChangedReason] integerValue];
    NSLog(@"%s, reason:%ld", __FUNCTION__, changedReason);
    switch (changedReason) {
        case LMChangedReasonScanInit:{
            [self removeLoadingViews];
            [searchField setHidden:NO];
            [searchField setEnabled:YES];
            [btnRefresh setHidden:NO];
            [btnRefresh setEnabled:NO];
            [self enableHeaderCol:NO];
            [self refreshUI];
            break;
        }
        case LMChangedReasonDel: {
            LMLocalApp *item = [info objectForKey:LMNotificationKeyDelItem];
            NSInteger index = [filterAppList indexOfObject:item];
            NSLog(@"%s, removeItem:%@, atIndex:%ld", __FUNCTION__, item, index);
            if (index >= 0 && index < tableView.numberOfRows) {
                showAppList =  [[LMLocalAppListManager defaultManager] appsListSortByType:self->sortType byAscendingOrder:self->sortOrderType];
                filterAppList = [self filterAppList:_filterKeyword];
                [tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationEffectGap];
                isUninstalling = NO;
                if ([filterAppList count] == 0) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self setNoAppViewsHidden:NO];
                    });
                }
            }
            // 删除结束,使按钮可用
            [self enableHeaderCol:YES];
            [self openUninstalTrashCheckTips];
            break;
        }
        case LMChangedReasonPartialDel: {
            LMLocalApp *item = [info objectForKey:LMNotificationKeyDelItem];
            NSInteger index = [filterAppList indexOfObject:item];
            if (index >= 0 && index < tableView.numberOfRows) {
                NSLog(@"%s, reloadItem:%@, atIndex:%ld", __FUNCTION__, item, index);
                [tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndex:1]];
                isUninstalling = NO;
            }
            [self openUninstalTrashCheckTips];
            break;
        }
        case LMChangedReasonScanEnd:{
            NSInteger scanType = [[info objectForKey:LMKeyScanType] integerValue];
            NSLog(@"%s, scan end ,type:%ld", __FUNCTION__, (long)scanType);

//            [self removeLoadingViews]; // 页面没扫描完就关闭了,下次打开页面直接等待
            [self loaddingEnd];
            [self refreshUI];

            break;
        }
        default:
            [self refreshUI];
            break;
    }

}

-(void)openUninstalTrashCheckTips{
    //如果没有开启卸载残留功能 && 没有授权 && 没有提示过
//    [SharedPrefrenceManager putBool:NO withKey:K_HAS_OPEN_UNINSTALL_TRASH_CHECK_WINDOW];
    BOOL hasOpenWindow = [SharedPrefrenceManager getBool:K_HAS_OPEN_UNINSTALL_TRASH_CHECK_WINDOW];
    NSLog(@"%s, hash open window: %hhd",__FUNCTION__,hasOpenWindow);
//    hasOpenWindow = NO;
    if(![self checkFullDiskAuthorizationStatus] && !hasOpenWindow)
    {
        //如果状态栏在,提示打开权限
        if(isAppRunningBundleId(MONITOR_APP_BUNDLEID)){
            [FullDiskAccessPermissionViewController showFullDiskAccessRequestWithParentController:self title:NSLocalizedStringFromTableInBundle(@"McUninstallWindowController_open_uninstall_trash_check_tips", nil, [NSBundle bundleForClass:[self class]], @"") description:NSLocalizedStringFromTableInBundle(@"McUninstallWindowController_open_uninstall_trash_check_sub_tips", nil, [NSBundle bundleForClass:[self class]], @"") windowHeight:158 windowCloseBlock:^{
                [SharedPrefrenceManager putBool:YES withKey:K_HAS_OPEN_UNINSTALL_TRASH_CHECK_WINDOW];
            } okButtonBlock:^{
                [SharedPrefrenceManager putBool:YES withKey:K_HAS_OPEN_UNINSTALL_TRASH_CHECK_WINDOW];
                [self openFullDiskPermissinGuideWindow];
            } cancelButtonBlock:^{
            }];
            
        }else{
            //如果状态栏不在，提示授权并打开状态栏
            [FullDiskAccessPermissionViewController showFullDiskAccessRequestWithParentController:self title:NSLocalizedStringFromTableInBundle(@"McUninstallWindowController_open_uninstall_trash_check_tips", nil, [NSBundle bundleForClass:[self class]], @"") description:NSLocalizedStringFromTableInBundle(@"McUninstallWindowController_open_minotor_and_uninstall_trash_check_sub_tips", nil, [NSBundle bundleForClass:[self class]], @"") okBtnTitle:NSLocalizedStringFromTableInBundle(@"McUninstallWindowController_open_minotor_and_uninstall_trash_check_btn_title", nil, [NSBundle bundleForClass:[self class]], @"")  windowHeight:165 windowCloseBlock:^{
                [SharedPrefrenceManager putBool:YES withKey:K_HAS_OPEN_UNINSTALL_TRASH_CHECK_WINDOW];
            } okButtonBlock:^{
                [SharedPrefrenceManager putBool:YES withKey:K_HAS_OPEN_UNINSTALL_TRASH_CHECK_WINDOW];
                [self openMonitor];
                [self openFullDiskPermissinGuideWindow];
            } cancelButtonBlock:^{
            }];
            
//            [FullDiskAccessPermissionViewController showFullDiskAccessRequestWithParentController:self title:title description:desc okBtnTitle:nil windowHeight:height windowCloseBlock:windowCloseblock okButtonBlock:okBtnBlock cancelButtonBlock:nil];
        }
        
    }
        
}

-(void)openMonitor{
    NSLog(@"%s, open monitor", __FUNCTION__);
    NSError *error = NULL;
    NSRunningApplication *app = [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:MONITOR_APP_PATH]
                                                                              options:NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation
                                                                        configuration:@{NSWorkspaceLaunchConfigurationArguments: @[[NSString stringWithFormat:@"%lu", LemonMonitorRunningMenu]]}
                                                                                error:&error];
    NSLog(@"%s, open lemon monitor: %@, %@",__FUNCTION__, app, error);
}

-(void)openFullDiskPermissinGuideWindow{
    CGPoint centerPoint = [self getCenterPoint];
    if(!self.permissionGuideWndController){
        NSString *imageName = @"setstep_ch";
        if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
            imageName = @"setstep_en";
        }
        NSString *title = NSLocalizedStringFromTableInBundle(@"McUninstallWindowController_monitor_full_disk_access_guide_window_title", nil, [NSBundle bundleForClass:[self class]], @"");
        NSString *descText = NSLocalizedStringFromTableInBundle(@"McUninstallWindowController_monitor_full_disk_access_guide_window_desc", nil, [NSBundle bundleForClass:[self class]], @"");
        self.permissionGuideWndController = [[LMPermissionGuideWndController alloc] initWithParaentCenterPos:centerPoint title:title descText:descText image:[NSImage imageNamed:imageName withClass:self.class] guideImageViewHeight:680];
        self.permissionGuideWndController.needCheckMonitorFullDiskAuthorizationStatus = YES;
        self.permissionGuideWndController.settingButtonEvent = ^{
            [QMFullDiskAccessManager openFullDiskAuthPrefreence];
        };
        __weak McUninstallViewController *weakSelf = self;
        self.permissionGuideWndController.finishButtonEvent = ^{
            NSLog(@"finishButtonEvent----");
            if(!isAppRunningBundleId(MONITOR_APP_BUNDLEID)){
                [weakSelf openMonitor];
            }
            if([weakSelf checkFullDiskAuthorizationStatus]){
                [SharedPrefrenceManager putBool:YES withKey:IS_ENABLE_TRASH_WATCH];
                [AppTrashDel enableTrashWatch:YES];
            }
           
        };
        self.permissionGuideWndController.cancelButtonEvent = ^{
        };
    }
     [self.permissionGuideWndController loadWindow];
     [self.permissionGuideWndController.window makeKeyAndOrderFront:nil];
//    [self.permissionGuideWndController.window makeKeyAndOrderFront:nil];
//     [[NSApplication sharedApplication] runModalForWindow:self.permissionGuideWndController.window];

}
//
//-(void)updateUninstallTrashCheckStatus{
//    if(![self checkMonitorFullDiskAuthorizationStatus]){
//        [SharedPrefrenceManager putBool:NO withKey:IS_ENABLE_TRASH_WATCH];
//        return;
//    }
//    if(self.isGetPermission && [self checkMonitorFullDiskAuthorizationStatus]){
//        self.isGetPermission = NO;
//        [SharedPrefrenceManager putBool:YES withKey:IS_ENABLE_TRASH_WATCH];
//        #ifndef APPSTORE_VERSION
//        [AppTrashDel enableTrashWatch:YES];
//        #endif
//    }
//
//}
//
BOOL isAppRunningBundleId(NSString *bundelId){
    NSArray *runnings= [NSRunningApplication runningApplicationsWithBundleIdentifier:bundelId];
    NSLog(@"[TrashDel, running%@:%@", bundelId, runnings);
    return [runnings count] > 0;
}

-(BOOL)checkFullDiskAuthorizationStatus{
     if (@available(macOS 10.15, *))
     {
        return [QMFullDiskAccessManager getFullDiskAuthorationStatus] == QMFullDiskAuthorationStatusAuthorized;
     }
    return YES;
}

-(void)onAppItemScanProcess:(NSNotification *)notify{
    
    NSDictionary *info = notify.userInfo;
    id curObject = [info objectForKey:LMKeyScanProgressCurObject];
    if(!curObject || ![curObject isKindOfClass:LMLocalApp.class]){
        NSLog(@"warning, %s, can't get scan progress item", __FUNCTION__);
        return;
    }
    
    LMLocalApp* app = curObject;
    NSString *phrase = [info objectForKey:LMKeyScanProgressCurPhrase];
    self->scanPhaseLabel.stringValue = [NSString stringWithFormat:@"正在扫描app:%@, phrase is %@", app.appName, phrase];
}

- (void)onScanProgress:(NSNotification *)notify {
    NSDictionary *info = notify.userInfo;
   
    id curObject = [info objectForKey:LMKeyScanProgressCurObject];
    if(!curObject || ![curObject isKindOfClass:LMLocalApp.class]){
        NSLog(@"warning, %s, can't get scan progress item", __FUNCTION__);
        return;
    }
    
    NSArray<LMLocalApp *> *apps = self->filterAppList; //filterAppList是真正关联 tableView 的 list.
    
    // 必须计算需要更新的 app 在tableView 中的 index. 而不能拿 manager.appList的curIndex.
    // 1. curIndex 只是代表哪个扫描完了,不能代表扫描了多少个.(多线程并发)
    // 2. curIndex 无法标识showAppList中哪个扫描完了. 因为showAppList是由 controller 持有的. 而 curIndex是 manager的扫描List的index. controller持有的showAppList和manager的扫描List两者可能不同. (这里针对增量扫描的时候,当全量扫描时,两个list内容相同, 增量扫描时,showAppList包含所有app,而manager的扫描list只包含增量的app), 另外 tablview 显示的数据源是filterAppList而不是showAppList,两者也可能不同.
    NSInteger itemInTableViewIndex = 0;

    BOOL isFind = FALSE;

    LMLocalApp* app = curObject;
    self->scanPhaseLabel.stringValue = [NSString stringWithFormat:@"正在扫描%@, path is %@", app.appName, app.bundlePath];

    for(LMLocalApp* app in apps ){
        if(app == curObject){
            itemInTableViewIndex = [apps indexOfObject:app];
            isFind = YES;
            break;
        }
    }
    
    if(!isFind){
        NSLog(@"warning, %s, can't get scan progress index, app is %@", __FUNCTION__, curObject);
    }
    
    // 只有在view存在的情况下才更新view
    NSInteger rowNum = [self->tableView numberOfRows];
    if(rowNum == 0 || rowNum <= itemInTableViewIndex){
        NSLog(@"tableView row Num is %ld, curIdex is %ld, apps is %@",(long)rowNum, (long)itemInTableViewIndex, apps == nil? @"nil" : [NSString stringWithFormat:@"%lu", (unsigned long)[apps count]]);
        return;
    }


    
    NSView * itemView = [self->tableView viewAtColumn:0 row:itemInTableViewIndex makeIfNecessary:NO];
    if(itemView){
        [self->tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:itemInTableViewIndex]
                             columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 3)]];
    }
}

// for table view
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return filterAppList.count;
}

- (void)initHeaderState{
    NSButton *curOnHeader = headerButtonName;
    switch (self->sortType) {
        case LMSortTypeName:
            [headerButtonName setSortOrderType:self->sortOrderType];
            curOnHeader = headerButtonName;
            break;
        case LMSortTypeSize:
            [headerButtonSize setSortOrderType:self->sortOrderType];
            curOnHeader = headerButtonSize;
            break;
        case LMSortTypeLastUsedDate:
            [headerButtonLastOpen setSortOrderType:self->sortOrderType];
            curOnHeader = headerButtonLastOpen;
            break;
        default:
            break;
    }
    [self setHeaderState:headerButtonName onButton:curOnHeader];
    [self setHeaderState:headerButtonSize onButton:curOnHeader];
    [self setHeaderState:headerButtonLastOpen onButton:curOnHeader];
}

- (IBAction)headerColClicked:(id)sender {
    NSLog(@"headerColClicked %@", sender);
    [self setHeaderState:headerButtonName onButton:sender];
    [self setHeaderState:headerButtonSize onButton:sender];
    [self setHeaderState:headerButtonLastOpen onButton:sender];
    
    if (sender == headerButtonName) {
        if (self->sortType == LMSortTypeName) {
            // 点击的排列方式和现在的一样，改变排列顺序
            [((LMSortableButton *)sender) toggleSortType];
        } else {
            self->sortType = LMSortTypeName;
        }
    } else if (sender == headerButtonSize) {
        if (self->sortType == LMSortTypeSize) {
            [((LMSortableButton *)sender) toggleSortType];
        } else {
            self->sortType = LMSortTypeSize;
        }
    } else {
        if (self->sortType == LMSortTypeLastUsedDate) {
            [((LMSortableButton *)sender) toggleSortType];
        } else {
            self->sortType = LMSortTypeLastUsedDate;
        }
    }
    self->sortOrderType = ((LMSortableButton *)sender).sortOrderType;
    [self refreshUI];
}

- (void)enableHeaderCol:(BOOL)enable {
    [headerButtonName setEnabled:enable];
    [headerButtonName setRefreshType:!enable];
    [headerButtonSize setEnabled:enable];
    [headerButtonSize setRefreshType:!enable];
    [headerButtonLastOpen setEnabled:enable];
    [headerButtonLastOpen setRefreshType:!enable];
}

- (void) setHeaderButton:(NSButton *)button withText:(NSString *)text withColor:(NSColor *)color {
    NSDictionary *tdic_off = @{NSForegroundColorAttributeName: color, NSFontAttributeName:[NSFontHelper getMediumSystemFont:14]};
    NSDictionary *tdic_on = @{NSForegroundColorAttributeName: color, NSFontAttributeName:[NSFontHelper getMediumSystemFont:14]};
    //    NSDictionary *tdic_on = @{NSForegroundColorAttributeName: [NSColor redColor], NSFontAttributeName:[NSFontHelper getRegularSystemFont:14]};
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
        [self setHeaderButton:button withText:button.title withColor:[LMAppThemeHelper getTitleColor]];
    } else {
        button.state = NSControlStateValueOff;
        [self setHeaderButton:button withText:button.title withColor:[NSColor colorWithHex:0x94979B]];
    }
}

- (void)sortDataByType:(McLocalSort)sortType withOrder:(SortOrderType) sortOrderType {
//    [[McUninstallSoftManager sharedManager] sortby:sortType isAscending:(sortOrderType == Ascending)];
}

- (void) btnClick {
    NSLog(@"btn clicked");
}


- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    return [[LMRowView alloc] init];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *identifier = tableColumn.identifier;
    LMLocalApp *app = [filterAppList objectAtIndex:row];
    
    McTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
    cellView.soft = app;
//    [cellView.progressView setHidden:YES];
//    cellView.progressView.value = 0;
    [cellView.btnRemove setHidden:NO];
    if ([identifier isEqualToString:@"BasicInfo"])
    {
        cellView.appName.stringValue = app.showName;
        cellView.appName.textColor = [LMAppThemeHelper getTitleColor];
        [cellView.appIcon setImage:app.icon];
    }
    else if ([identifier isEqualToString:@"Size"])
    {
        if(app.isScanComplete){
            [cellView.sizeProgressView setHidden:YES];
            [cellView.sizeLabel setHidden:NO];
            cellView.sizeLabel.stringValue = [NSString stringFromDiskSize:app.totalSize];
            cellView.sizeLabel.textColor = [LMAppThemeHelper getTitleColor];
        }else{
            [cellView.sizeProgressView setHidden:NO];
            [cellView.sizeProgressView startAnimation:nil];
            [cellView.sizeLabel setHidden:YES];
        }

    }
    else if ([identifier isEqualToString:@"LastOpen"])
    {
        if(app.isScanComplete){
            [cellView.lastOpen setHidden:NO];
            [cellView.timeprogressView setHidden:YES];

            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:NSLocalizedStringFromTableInBundle(@"McUninstallViewController_tableView_1553153166_1", nil, [NSBundle bundleForClass:[self class]], @"")];
            if (app.lastUsedDate){
                cellView.lastOpen.stringValue = [df stringFromDate:app.lastUsedDate];
            } else {
                cellView.lastOpen.stringValue = NSLocalizedStringFromTableInBundle(@"McUninstallViewController_tableView_lastOpen_2", nil, [NSBundle bundleForClass:[self class]], @"");
            }
            cellView.lastOpen.textColor = [LMAppThemeHelper getTitleColor];
        }else{
            [cellView.timeprogressView setHidden:NO];
            [cellView.timeprogressView startAnimation:nil];
            [cellView.lastOpen setHidden:YES];

        }
        
    }
    else if ([identifier isEqualToString:@"Remove"])
    {
        
        if(app.isScanComplete){
            [cellView.btnRemove setEnabled:YES];
            [cellView.btnRemove setAlphaValue:1.0];
            [cellView.btnRemove setTarget:cellView];
            [cellView.btnRemove setAction:@selector(uninstallClick:)];
            __weak McUninstallViewController *weakSelf = self; //block里使用weak self避免强引用循环。
            cellView.actionHandler = ^{
                McUninstallViewController *innerSelf = weakSelf;
                //有其他项在删除时，不响应
                if (innerSelf->isUninstalling) {
                    return;
                }
                [innerSelf showDetailItemView:app];
                
            };
        }else{
            [cellView.btnRemove setEnabled:NO];
            [cellView.btnRemove setAlphaValue:0.6];
        }
    }
    return cellView;
}

- (void)showDetailItemView:(LMLocalApp *) software{
     [self.view.window.windowController showUninstallDetailViewWithSoft:software];
}

- (BOOL)showIsKillingAppAlert:(NSString *)appName appPath:(NSString *)appPath{
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSWarningAlertStyle;
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"McUninstallViewController_showIsKillingAppAlert_alert_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"McUninstallViewController_showIsKillingAppAlert_alert_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    alert.messageText= [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"McUninstallViewController_showIsKillingAppAlert_NSString_3", nil, [NSBundle bundleForClass:[self class]], @""), appName];
    alert.informativeText=NSLocalizedStringFromTableInBundle(@"McUninstallViewController_showIsKillingAppAlert_alert_4", nil, [NSBundle bundleForClass:[self class]], @"");
    NSImage *iconImage = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
    if (iconImage) {
        alert.icon = iconImage;
    }
    NSInteger responseTag = [alert runModal];
    if (responseTag == NSAlertFirstButtonReturn) {
        return NO;
    } else {
        return YES;
    }
}

// uninstall
- (void)uninstallSoft:(LMLocalApp *)software
{
    BOOL lemonLiteCheck = false;
    NSString *lemonLiteMonitorBundleId = @"88L2Q4487U.com.tencent.LemonASMonitor";
    //TOOD 兼容 TencentLemonLite 的卸载
    if(software.bundleID && [software.bundleID isEqualToString:@"com.tencent.LemonLite"]){
        lemonLiteCheck = [self checkIsAppRunningWithBundleId:lemonLiteMonitorBundleId hostApp:software];
    }
    
    NSLog(@"%s, %@", __FUNCTION__, software);
    if ( (software.bundleID && [self checkIsAppRunning:software]) || lemonLiteCheck) {
        BOOL isContinue = [self showIsKillingAppAlert:software.showName appPath:software.bundlePath];
        if (!isContinue) {
            return;
        }        
    }
    //get selectedItems
    isUninstalling = true;
    [self enableHeaderCol:NO];
    [[LMLocalAppListManager defaultManager] uninstall:software];
//    [[McUninstallSoftManager sharedManager] uninstall:software];
//    {
//        sheetController = [[QMUninstallSheetController alloc] init];
//    }
//    sheetController.soft = software;
//
//
//    [sheetController setWindowCenterPositon:[self getCenterPoint]];
//    NSModalResponse code = [[NSApplication sharedApplication] runModalForWindow:sheetController.window];
//    if (code == NSModalResponseOK) {
//        [self enableHeaderCol:NO];
//        NSArray *selectedArray = [sheetController selectedItems];
//        [[McUninstallSoftManager sharedManager] uninstall:sheetController.soft fileItems:selectedArray];
//    }
}

// 会判断 bundle 删除是否勾选.
- (BOOL) checkIsAppRunning:(LMLocalApp *)soft {
    
    NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:soft.bundleID];
    if ([apps count] > 0) {
        LMFileGroup *bundleGroup = [soft groupByType:LMFileTypeBundle];
        for (NSRunningApplication *app in apps) {
            for (LMFileItem *bundleItem in bundleGroup.filePaths) {
                if (!bundleItem.isSelected)
                    continue;
                if ([app.bundleURL.path isEqualToString:bundleItem.path]) {
                    return YES;
                }
            }
        }

        // VMware需要判断是否勾选了虚拟机文件
        if ([soft.bundleID isEqualToString:@"com.vmware.fusion"]) {
            LMFileGroup *otherGroup = [soft groupByType:LMFileTypeOther];
            for (NSRunningApplication *app in apps) {
                for (LMFileItem *item in otherGroup.filePaths) {
                    if (!item.isSelected)
                        continue;
                    if ([app.bundleIdentifier isEqualToString:soft.bundleID]) {
                        return YES;
                    }
                }
            }
        }
    }
    
    return NO;
}

- (BOOL) checkIsAppRunningWithBundleId:(NSString *)bundleId hostApp:(LMLocalApp *)hostSoft{
    
    if(!bundleId){
        return NO;
    }
    NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleId];
    
    if ([apps count] > 0) {
        for (NSRunningApplication *app in apps) {
            LMFileGroup *bundleGroup = [hostSoft groupByType:LMFileTypeBundle];
            for (LMFileItem *bundleItem in bundleGroup.filePaths) {
                if (!bundleItem.isSelected)
                    continue;
                if ([app.bundleURL.path containsString:bundleItem.path]) {
                    return YES;
                }
            }
        }
    }
    
    return NO;
}

- (void)killAppOfBundle:(NSString *)bundleID {
    NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleID];
    for (NSRunningApplication *app in apps) {
        NSString *executePath = [app.executableURL path];
        [[McCoreFunction shareCoreFuction] killProcessByID:app.processIdentifier ifMatch:executePath];
    }
}


- (void)killItemProcess:(LMFileItem *)fileItem {
    NSLog(@"%s, %@", __FUNCTION__, fileItem);
    NSBundle *bundle = [NSBundle bundleWithPath:fileItem.path];
    if (!bundle)
        return;
    
    NSString *bundleIdentifier = [bundle bundleIdentifier];
    if (!bundleIdentifier)
        return;
    
    NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier];
    for (NSRunningApplication *runningApp in apps) {
        if ([runningApp.bundleURL.path isEqualToString:fileItem.path]) {
#ifndef DEBUG
            [[McCoreFunction shareCoreFuction] killProcessByID:runningApp.processIdentifier];
#endif
        }
    }
}


-(CGPoint)getCenterPoint{
    CGPoint origin = self.view.window.frame.origin;
    CGSize size = self.view.window.frame.size;
    return CGPointMake(origin.x + size.width / 2, origin.y + size.height / 2);
}

- (NSArray *)filterAppList:(NSString *)keyword {
    if ([keyword length] == 0) {
        return [showAppList copy];
    }
    NSMutableArray *array = [showAppList mutableCopy];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(showName contains[cd] %@) OR (appName contains[cd] %@)",
                              keyword,keyword];
    [array filterUsingPredicate:predicate];

    return [array copy];
}

- (void)initSearchField {
    //只有当敲回车才会触发Action方法
//    [searchField.cell sendActionOn:NSMouseEnteredMask];
    [searchField setTextColor:[LMAppThemeHelper getTitleColor]];
    [searchField setFont:[NSFontHelper getLightSystemFont:11]];
//searchField
//    NSTextField *test;
//    loadingText color
    
//    test.appearance
//    test.tint
//    [searchField setBackgroundColor:[NSColor whiteColor]];
//    [searchField setWantsLayer:YES];
//    [[searchField layer] setBorderColor:[NSColor colorWithHex:0xEDEDED].CGColor];
//    [searchField setBordered:NO];
//    [[searchField layer] setBorderColor:[NSColor blackColor].CGColor];
//    [[searchField layer] setBorderWidth:1];
   // NSDictionary *attr_text = @{NSForegroundColorAttributeName: [NSColor colorWithHex:0x515151], NSFontAttributeName:[NSFontHelper getMediumSystemFont:10]};
    NSDictionary *atrr_placeholder = @{NSForegroundColorAttributeName: [NSColor colorWithHex:0xc2c2c2], NSFontAttributeName:[NSFontHelper getLightSystemFont:11]};
    [searchField setPlaceholderAttributedString:[[NSAttributedString alloc] initWithString:searchField.placeholderString attributes:atrr_placeholder]];
    NSImage *searchImage = [NSImage imageNamed:@"filter_normal" withClass:self.class];
    [[searchField.cell searchButtonCell] setImage:searchImage];
    [[searchField.cell searchButtonCell] setAlternateImage:searchImage];
}

// MARK: button action
- (IBAction)onSearchFieldEnter:(id)sender {
    _filterKeyword = [searchField stringValue];
    filterAppList = [self filterAppList:_filterKeyword];
    if ([filterAppList count] == 0) {
        [self setNoAppViewsHidden:NO];
    } else {
        [self setNoAppViewsHidden:YES];
    }
    [tableView reloadData];
    
}

- (IBAction)onRefreshBtnClicked:(id)sender {
    NSLog(@"%s", __FUNCTION__);
    showAppList = [NSArray array];
    filterAppList = [NSArray array];
    
    // 刷新是全量扫描 需要重置排序为按名称排序.
    sortType = McLocalSortName;
    sortOrderType = [headerButtonName sortOrderType];
    NSButton *curOnHeader = headerButtonName;
    [self setHeaderState:headerButtonName onButton:curOnHeader];
    [self setHeaderState:headerButtonSize onButton:curOnHeader];
    [self setHeaderState:headerButtonLastOpen onButton:curOnHeader];
    
    [tableView reloadData];
    [self loadData];
}


- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
