//
//  LMToolViewController.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMToolViewController.h"
#import "ToolTableCellView.h"
#import <Masonry/Masonry.h>
#import "UIHelper.h"
#import <LemonClener/ToolModel.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <QMCoreFunction/NSColor+Extension.h>
//#import <LemonBigOldFile/McBigFileWndController.h>
#import <LemonDuplicateFile/LMDuplicateWindowController.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/QMBaseWindowController.h>
#import <LemonClener/CleanerCantant.h>
#import <QMCoreFunction/NSView+Extension.h>
#import <LemonClener/LMCleanerTableView.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/NSBundle+LMLanguage.h>
#import "LemonMainWndController.h"
#import <QMUICommon/NSFontHelper.h>
#import <QMCoreFunction/NSButton+Extension.h>
#import <QMUICommon/LMResultButton.h>
#import <QMUICommon/FullDiskAccessPermissionViewController.h>
#import <LemonSpaceAnalyse/McSpaceAnalyseWndController.h>
#import <LemonClener/LemonVCModel.h>

#define LEMON_SPACE_ENTER_REPORT_TWO          12002 //磁盘入口2

@interface LMToolViewController ()<NSTableViewDelegate, NSTableViewDataSource, QMWindowDelegate>
{
    BOOL isDidAppear;
}
//@property (nonatomic, strong) NSMutableDictionary *toolConMap;
//@property (nonatomic, strong) NSTextField *titleLabel;
//@property (nonatomic, strong) NSTextField *descLabel;
@property (weak) IBOutlet NSImageView *backImageView;
@property (nonatomic, strong) LMCleanerTableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, assign) CGFloat wWidth;
@property (nonatomic, assign) CGFloat wHeight;
@property (weak) IBOutlet NSTextField *moreAppTitle;
@property (weak) IBOutlet LMResultButton *moreAppLink;

@property(nonatomic, strong) NSButton *communityButton;
@end

@implementation LMToolViewController

-(id)init{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        
    }
    
    return self;
}

- (void)viewWillAppear{
    [super viewWillAppear];
    
#warning why需要这样
    if (_tableView) {
        [_tableView reloadData];
    }
}

-(void)viewDidAppear{
    [super viewDidAppear];
    isDidAppear = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [self initData];
    [self initView];
}

-(void)initData{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showExperienceTool:) name:SHOW_EXPERIENCE_TOOL object:nil];

    self.dataSource = [[NSMutableArray alloc] init];
//    self.toolConMap = [[NSMutableDictionary alloc] init];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
#ifndef APPSTORE_VERSION
    NSString *toolConfigPath = [mainBundle pathForResource:@"ToolConfig" ofType:@"plist"];
    NSString *language = [LanguageHelper getCurrentUserLanguage];
    if(language != nil){
        toolConfigPath = [mainBundle pathForResource:@"ToolConfig" ofType:@"plist" inDirectory:@"" forLocalization:language];
    }
#else
    NSString *toolConfigPath = [mainBundle pathForResource:@"ToolConfigAppStore" ofType:@"plist"];
#endif
    NSDictionary *toolConfigDic = [NSDictionary dictionaryWithContentsOfFile:toolConfigPath];
    for (NSDictionary *toolItemKey in toolConfigDic.allKeys) {
         if ([[toolConfigDic objectForKey:toolItemKey] isKindOfClass:[NSDictionary class]]) {
             NSDictionary *toolItemDic =[toolConfigDic objectForKey:toolItemKey];
             
             NSString *toolId = toolItemDic[@"toolId"];
             NSString *toolPicName = toolItemDic[@"toolPicName"];
             NSString *className = toolItemDic[@"className"];
             NSString *toolName = toolItemDic[@"toolName"];
             NSString *toolDesc = toolItemDic[@"toolDesc"];
             NSInteger reportId = [toolItemDic[@"reportId"] integerValue];
             
             ToolModel *toolModel = [[ToolModel alloc] initWithToolId:toolId toolPicName:toolPicName className:className toolName:toolName toolDesc:toolDesc reportId:reportId];
             [self.dataSource addObject:toolModel];
         }
    }
    
    [self.dataSource sortUsingComparator:^NSComparisonResult(ToolModel *obj1, ToolModel *obj2) {
        NSInteger obj1Integer = [obj1.toolId integerValue];
        NSInteger obj2Integer = [obj2.toolId integerValue];
        
        if (obj1Integer < obj2Integer) {
            return NSOrderedAscending;
        }else{
            return NSOrderedDescending;
        }
        
    }];
}

-(void)communityBtn {
    
    if([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese){
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.facebook.com/groups/2270176446528228/"]];
        return;
    }
    
    //app版本号
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    //系统版本号
    NSOperatingSystemVersion osVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSString *os_Version = [NSString stringWithFormat:@"%ld.%ld.%ld",osVersion.majorVersion,osVersion.minorVersion,osVersion.patchVersion];

    NSString *URLStr = [NSString stringWithFormat:@"https://txc.qq.com/products/36664?clientVersion=%@&os=macOS&osVersion=%@",app_Version,os_Version];

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:URLStr]];
}

-(void)initView{
    NSImage *image = [NSImage imageNamed:@"icon_tool_view_community"];
    
    if (@available(macOS 10.12, *)) {
        self.communityButton = [NSButton buttonWithTitle:@"" image:image target:self action:@selector(communityBtn)];
    } else {
        self.communityButton = [[NSButton alloc] init];
        self.communityButton.image = image;
        [self.communityButton setTarget:self];
        [self.communityButton setAction:@selector(communityBtn)];
    }
    
    NSMutableAttributedString *linkAttrStr = [[NSMutableAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"Share valuable suggestions", nil, [NSBundle bundleForClass:[self class]], @"")];
        [linkAttrStr addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(0, linkAttrStr.length)];
        [self.communityButton setAttributedTitle:linkAttrStr];
    
    self.communityButton.font = [NSFont systemFontOfSize:12.0f];
    self.communityButton.bordered = NO;
    self.communityButton.imagePosition = NSImageLeft;
    [self.view addSubview:self.communityButton];
    
    [self.communityButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@20);
        make.trailing.equalTo(self.view.mas_trailing).offset(-24);
        make.bottom.equalTo(self.view.mas_bottom).offset(-16);
    }];
    
//    [self.view setWantsLayer:YES];
//    [self.view.layer setBackgroundColor:[NSColor whiteColor].CGColor];
//    [self.backImageView setAlphaValue:0.7];
    [self.backImageView setHidden:YES];
    
    self.moreAppLink.image = [NSImage imageNamed:@"icon_tc_robot"];
    [self.moreAppTitle setFont:[NSFontHelper getLightSystemFont:12]];
    [self.moreAppTitle setTextColor:[NSColor colorWithHex:0xC9C9C9]];
    [self.moreAppTitle setStringValue:NSLocalizedStringFromTableInBundle(@"LMToolViewController_initView_moreAppTitle_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    NSClickGestureRecognizer *recognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(gotoMacqqCom:)];
    [self.moreAppTitle addGestureRecognizer:recognizer];
//    [self.moreAppLink setFont:[NSFontHelper getLightSystemFont:12]];
//    [self.moreAppLink setTitle:@"mac.qq.com" withColor:[NSColor colorWithHex:0x057cff]];
//    [self.moreAppLink setDefaultTitleColor:[NSColor colorWithHex:0x05CFF]];
//    [self.moreAppLink setHoverTitleColor:[NSColor colorWithHex:0x00A0FF]];
//    [self.moreAppLink setDownTitleColor:[NSColor colorWithHex:0x0381DE]];
    [self.moreAppLink setWantsLayer:YES];
    [self.moreAppLink setFocusRingType:NSFocusRingTypeNone];
//    self.moreAppLink.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    self.moreAppLink.layer.borderWidth = 0;
    self.moreAppLink.layer.borderColor = [NSColor clearColor].CGColor;
#ifndef APPSTORE_VERSION
    self.wWidth = self.view.bounds.size.width - 50;
    self.wHeight = 530;
    _tableView = [[LMCleanerTableView alloc]initWithFrame:CGRectMake(0, 50, self.wWidth, self.wHeight)];
#else
    self.wWidth = LMToolWidth - LMToolTopSpace * 2;
    self.wHeight = LMToolHeight - LMToolTopSpace * 4;
    _tableView = [[LMCleanerTableView alloc]initWithFrame:CGRectMake(LMToolTopSpace, LMToolTopSpace*2, self.wWidth, self.wHeight)];
#endif
    NSLog(@"view size = %@", NSStringFromSize(self.view.frame.size));
    [_tableView setBackgroundColor:[NSColor clearColor]];
    [_tableView setFocusRingType:NSFocusRingTypeNone];
    NSTableColumn * column = [[NSTableColumn alloc]initWithIdentifier:@"column1"];
    NSTableColumn * column2 = [[NSTableColumn alloc]initWithIdentifier:@"column2"];
#ifndef APPSTORE_VERSION
    column.width = 274;
    column2.width = 300;
#else
    column.width = self.wWidth/2 - LMToolTopSpace/2;
    column2.width = self.wWidth/2 - LMToolTopSpace/2;
#endif
    column.resizingMask =NSTableColumnUserResizingMask;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.headerView = nil;
    _tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    [_tableView addTableColumn:column];
    [_tableView addTableColumn:column2];
    if (@available(macOS 11.0, *)) {
        _tableView.style = NSTableViewStyleFullWidth;
    } else {
        // Fallback on earlier versions
    }
    [self.view addSubview:_tableView];
    
//    [_tableView reloadData];
    
#ifdef APPSTORE_VERSION
    [self.moreAppLink setHidden:YES];
    [self.moreAppTitle setHidden:YES];
#endif
    
}

- (IBAction)gotoMacqqCom:(id)sender {
    
    if([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese){
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.facebook.com/groups/2270176446528228/"]];
        return;
    }
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.qq.com/products/36664"]];
    return;
}

-(CGPoint)getCenterPoint{
    CGPoint origin = self.view.window.frame.origin;
    CGSize size = self.view.window.frame.size;
    return CGPointMake(origin.x + size.width / 2, origin.y + size.height / 2);
}

-(QMBaseWindowController *)getWindowControllerByClassname:(NSString *)className{
    QMBaseWindowController *controller = nil;
    
    controller = [[LemonVCModel shareInstance].toolConMap objectForKey:className];
    if (controller == nil) {
        controller = [[NSClassFromString(className) alloc] init];
        if ([controller isKindOfClass:[QMBaseWindowController class]]) {
            ((QMBaseWindowController*)controller).delegate = self;
        }
        [[LemonVCModel shareInstance].toolConMap setValue:controller forKey:className];
    }
    return controller;
}

-(void)showExperienceTool:(NSNotification *)noti{
    if (noti != nil) {
        NSDictionary *userInfo = noti.userInfo;
        NSString *className = userInfo[EXPERIENCE_TOOL_CLASS_NAME];
        if ([className isEqualToString:MORE_FUNCTION]) {
            
            if ([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese) {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.facebook.com/groups/2270176446528228/"]];
                return;
            }
#ifndef APPSTORE_VERSION
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.qq.com/products/36664"]];
#else
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.qq.com/products/52728"]];
#endif
            return;
        }
        NSString *language = [LanguageHelper getCurrentUserLanguage];
        if(language != nil){
            //hook 小工具多语言
            [NSBundle setLanguage:language bundle:[NSBundle bundleForClass:NSClassFromString(className)]];
        }
        
        QMBaseWindowController *controller = [self getWindowControllerByClassname:className];
        [controller showWindow:self];
        [controller setWindowCenterPositon:[self getCenterPoint]];
    }
}

//设置行数 通用
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    int row = (int)(self.dataSource.count / 2) + (self.dataSource.count % 2);
    return row;
}
//View-base
//设置某个元素的具体视图
- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row{
    //根据ID取视图
    ToolTableCellView * view = [tableView makeViewWithIdentifier:@"cellId" owner:self];
    view.tagImage.hidden = YES;
    if (view==nil) {
#ifndef APPSTORE_VERSION
        view = [[ToolTableCellView alloc]initWithFrame:CGRectMake(0, 0, 284, self.wHeight/4)];
#else
        view = [[ToolTableCellView alloc]initWithFrame:CGRectMake(0, 0, 284, self.wHeight/2)];
#endif
        view.identifier = @"cellId";
    }
    
    NSInteger columnRow;
    if ([tableColumn.identifier isEqualToString:@"column1"]) {
        columnRow = 0;
    }else{
        columnRow = 1;
    }
    NSInteger index = [self getIndexByColumn:columnRow withRow:row];
    if (index >= self.dataSource.count) {
        return nil;
    }
    ToolModel *toolModel = [self.dataSource objectAtIndex:index];
    
    __weak LMToolViewController *weakSelf = self;
    [view setCellWithToolModel:toolModel toolBlock:^(NSString *className) {
        if (@available(macOS 10.11 ,*)) {
        } else {
            if ([className isEqualToString:@"LMPhotoCleanerWndController"]) {
                [weakSelf showNotSupportToast];
                return ;
            }
        }
        if ([className isEqualToString:MORE_FUNCTION] || className == nil) {
            
            if ([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese) {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.facebook.com/groups/2270176446528228/"]];
                return;
            }
#ifndef APPSTORE_VERSION
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.qq.com/products/36664"]];
#else
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.qq.com/products/52728"]];
#endif

            return;
        } else if ([className isEqualToString:LEMON_LAB] || className == nil) {
            
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://lemon.qq.com/lab/"]];
                    return;
        } else {
            NSString *language = [LanguageHelper getCurrentUserLanguage];
            if(language != nil){
                //hook 小工具多语言
                [NSBundle setLanguage:language bundle:[NSBundle bundleForClass:NSClassFromString(className)]];
            }
            if([self isNeedCheckFullDiskAccessWithClassName:className]){
                //检查完全磁盘访问权限
                if([FullDiskAccessPermissionViewController showFullDiskAccessRequestIfNeededWithParentController:self title:NSLocalizedStringFromTableInBundle(@"LMToolViewController_checkFullDiskAccess_need_permission_window_title", nil, [NSBundle bundleForClass:[self class]], @"") sourceType:SMALL_TOOLS_VIEW]) return;
            }
            
            QMBaseWindowController *controller = [weakSelf getWindowControllerByClassname:className];
            [controller showWindow:weakSelf];
            [controller setWindowCenterPositon:[weakSelf getCenterPoint]];
        }
        
    }];
    return view;
}

-(BOOL)isNeedCheckFullDiskAccessWithClassName: (NSString *)className{
    NSArray *classNames = @[@"McSpaceAnalyseWndController",@"McBigFileWndController",@"LMDuplicateWindowController",@"LMPhotoCleanerWndController",@"McUninstallWindowController",@"LMLoginItemManageWindowController"];
    for (NSString* temp in classNames) {
        if([className isEqualToString:temp]){
            return YES;
        }
    }
    return NO;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
#ifndef APPSTORE_VERSION
    return self.wHeight/4;
#else
    return self.wHeight/2;
#endif
}

-(NSInteger)getIndexByColumn:(NSInteger) column withRow:(NSInteger) row{
    return row * 2 + column;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    return NSDragOperationNone;
}

#pragma mark -- QMWindowDelegate
-(void)windowWillDismiss:(NSString *)clsName{
//    NSLog(@"class name is %@", clsName);
    [[LemonVCModel shareInstance].toolConMap setValue:nil forKey:clsName];
}

- (void)showNotSupportToast{
    
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleWarning;
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMToolViewController_showNotSupportToast_alert_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMToolViewController_showNotSupportToast_alert_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    alert.messageText = NSLocalizedStringFromTableInBundle(@"LMToolViewController_showNotSupportToast_alert_3", nil, [NSBundle bundleForClass:[self class]], @"");
    alert.informativeText = NSLocalizedStringFromTableInBundle(@"LMToolViewController_showNotSupportToast_alert_4", nil, [NSBundle bundleForClass:[self class]], @"");
    [alert beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:^(NSModalResponse returnCode) {
    
    }];
  
}

@end
