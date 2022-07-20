//
//  CheckDeleteSystemPhotoViewController.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "CheckDeleteSystemPhotoViewController.h"
#import "LMPhotoItem.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMViewHelper.h>
#import "LMPhotoCleanerWndController.h"
#import <QMCoreFunction/NSString+Extension.h>
#import <Masonry/Masonry.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/RatingUtils.h>
#import <QMCoreFunction/NSButton+Extension.h>
#import <QMUICommon/GetFullAccessWndController.h>
#import <QMCoreFunction/LMAuthorizationManager.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/LMPermissionGuideWndController.h>
#import "LMSystemPhotoCleanerHelper.h"
#import <QMUICommon/LMBigLoadingView.h>
#import <QMUICommon/LMAppThemeHelper.h>

#define LOADING_VIEW_SIZE       160

typedef enum{
    GetPermissionState, //用户未授权 -- “获取权限”
    ScanPhotoState,     //再次扫描 --  “更新” （已取消该状态）
    OpenPhotoAppState,       //打开相册应用 -- “立即清理”
}OperateButtonState;

@interface CheckDeleteSystemPhotoViewController ()
@property (weak) IBOutlet NSImageView *hudColorView;
@property (weak) IBOutlet NSImageView *picView;
@property (nonatomic,nonnull) NSButton *operateButton;
@property (weak) IBOutlet NSTextField *alreadyClean;
@property (weak) IBOutlet NSTextField *needToCleanBySelf;
@property (weak) IBOutlet NSTextField *picDeleteTip;
@property (weak) IBOutlet NSTextField *descTitleTextFileld;
@property (weak) IBOutlet NSButton *noUseButton;
@property (weak) NSTextField *extraText;//由于英文提示文字过长，分两行显示，extraText显示第二行
@property (atomic) NSInteger selfDefineFloderSize;
@property (atomic) NSInteger photoFloderSize;

@property OperateButtonState operateButtonState;
@property (strong,nonatomic) LMPermissionGuideWndController *permissionGuideWndController;

@property LMBigLoadingView *loadingView;
@property NSTextField *loadingText;

@end

@implementation CheckDeleteSystemPhotoViewController

- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        //myBundle = [NSBundle bundleForClass:[self class]];
    }
    return self;
}

-(void)initViewText{
    [self.picDeleteTip setStringValue:NSLocalizedStringFromTableInBundle(@"CheckDeleteSystemPhotoViewController_initViewText_picDeleteTip_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.descTitleTextFileld setStringValue:NSLocalizedStringFromTableInBundle(@"CheckDeleteSystemPhotoViewController_initViewText_descTitleTextFileld_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    if ([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese) {
        self.descTitleTextFileld.alignment = NSTextAlignmentLeft;
        if (@available(macOS 10.11, *)) {
            self.descTitleTextFileld.maximumNumberOfLines = 2;
        }
    }
}

-(void)setupViews{
    [self.noUseButton setWantsLayer:YES];
    self.noUseButton.layer.borderWidth = 1;
    self.noUseButton.layer.borderColor = [NSColor colorWithHex:0xd4d4d4].CGColor;
    self.noUseButton.layer.cornerRadius = 5;
    
    [self.descTitleTextFileld mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.needToCleanBySelf.mas_bottom).offset(5);
        make.width.lessThanOrEqualTo(@640);
    }];
    
    [self.picDeleteTip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.alreadyClean.mas_bottom).offset(5);
        make.centerX.equalTo(self.hudColorView.mas_centerX).offset(10);
    }];
    
    [self.picView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.picDeleteTip.mas_left);
        make.centerY.equalTo(self.picDeleteTip);
        make.width.equalTo(@21);
        make.height.equalTo(@20);
    }];
}

-(void)initExtraTextField{
    if(self.extraText) return;
    NSTextField *textField = [[NSTextField alloc]init];
    textField.backgroundColor = [NSColor clearColor];
    self.extraText = textField;
    self.extraText.textColor = [LMAppThemeHelper getTitleColor];
    self.extraText.font = [NSFontHelper getRegularSystemFont:22];
    self.extraText.stringValue = NSLocalizedStringFromTableInBundle(@"CheckDeleteSystemPhotoViewController_automation_needPermission_extraTips", nil, [NSBundle bundleForClass:[self class]], @"");
    [self.extraText setEditable:false];
    [self.extraText setBordered:false];
    [self.extraText setAlignment:NSCenterTextAlignment];
    [self.view addSubview:self.extraText];
    [self.extraText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.needToCleanBySelf.mas_bottom).offset(0);
        make.centerX.equalTo(self.needToCleanBySelf);
        make.width.equalTo(@500);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupViews];
    [self initViewText];
    [self.noUseButton setTitle:NSLocalizedStringFromTableInBundle(@"CheckDeleteSystemPhotoViewController_initViewText_noUseButton_3", nil, [NSBundle bundleForClass:[self class]], @"")];
    self.noUseButton.wantsLayer = true;
    [self.noUseButton.layer setBorderWidth:0.5];
    [self.noUseButton.layer setBorderColor:[NSColor colorWithHex:0x94979b].CGColor];
    [self.noUseButton.layer setCornerRadius:3];
    self.operateButtonState = OpenPhotoAppState;
    if(!self.authorizedForCreateAlbum){
        self.operateButtonState = GetPermissionState;
        //如果没有权限，添加监听
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(receiveNotifactionAfterPermissionSetted) name:LM_NOTIFACTION_SCAN_SYSTEM_PHOTO object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(permissionGuideWindowWillClose) name:NSWindowWillCloseNotification object:nil];
    }
    self.operateButton = [LMViewHelper createNormalGreenButton:20 title:NSLocalizedStringFromTableInBundle(@"CheckDeleteSystemPhotoViewController_viewDidLoad_1553065843_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self resetView];
    [self.view addSubview:self.operateButton];
    self.operateButton.target = self;
    [self.operateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(148);
        make.height.mas_equalTo(48);
        make.bottom.equalTo(self.view).offset(-69);
        make.left.equalTo(self.view).offset(415);
    }];
    [self.operateButton setEnabled:YES];
   
    [self getSelfDefineFolderSize];
    NSString *alreadyStr = [NSString stringWithFormat:@"%@",[self getDeletePictureSizeDescription:self.selfDefineFloderSize]];
    NSMutableParagraphStyle *paragStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragStyle setAlignment:NSTextAlignmentCenter];
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:alreadyStr
                                                                                      attributes:@{NSForegroundColorAttributeName: [LMAppThemeHelper getTitleColor],
                                                                                                   NSParagraphStyleAttributeName:paragStyle,
                                                                                                   NSFontAttributeName: [NSFont systemFontOfSize:24.0]}];
    [attributedStr addAttribute:NSForegroundColorAttributeName value:[LMAppThemeHelper getTitleColor] range:NSMakeRange(alreadyStr.length - 2, 2)];
    [attributedStr addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:14.0] range:NSMakeRange(alreadyStr.length - 2, 2)];
    
    [self.needToCleanBySelf setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"CheckDeleteSystemPhotoViewController_viewDidLoad_needToCleanBySelf_2", nil, [NSBundle bundleForClass:[self class]], @""),[self getDeletePictureSizeDescription:self.photoFloderSize]]];
    [self setTitleColorForTextField:self.needToCleanBySelf];
    
    self.alreadyClean.attributedStringValue = attributedStr;
    
    if ([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese) {
        self.needToCleanBySelf.font = [NSFontHelper getRegularSystemFont:22];
    }
    
    // 清理完成
    [RatingUtils recordCleanFinishAction];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(receiveNotificationAfterCreateAlbum:) name:LM_NOTIFCATION_CREAT_ALBUM_FINISHED object:nil];
    
}

-(void)initLoadingView{
   
    if(!self.loadingView){
        NSRect bounds = self.view.bounds;
        bounds.origin.x = (self.view.bounds.size.width - LOADING_VIEW_SIZE) / 2;
        bounds.origin.y = 184;
        bounds.size.width = LOADING_VIEW_SIZE;
        bounds.size.height = LOADING_VIEW_SIZE;
        self.loadingView = [[LMBigLoadingView alloc] initWithFrame:bounds];
        [self.view addSubview:self.loadingView];
        self.loadingText = [[NSTextField alloc]init];
        [self.loadingText setBezeled:NO];
        [self.loadingText setDrawsBackground:NO];
        [self.loadingText setEditable:NO];
        [self.loadingText setSelectable:NO];
        self.loadingText.stringValue = NSLocalizedStringFromTableInBundle(@"CheckDeleteSystemPhotoViewController_cleaning_loadingText", nil, [NSBundle bundleForClass:[self class]], @"");
        [self.loadingText setTextColor:[NSColor colorWithHex:0x94979B]];
//        [self.loadingText setBackgroundColor:[NSColor whiteColor]];
        [self.loadingText setFont:[NSFontHelper getLightSystemFont:18]];
        [self.view addSubview:self.loadingText];
        [self.loadingText mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.loadingView.mas_bottom).offset(20);
            make.height.mas_equalTo(100);
            make.width.mas_equalTo(300);
            make.centerX.equalTo(self.loadingView.mas_centerX);
        }];
        [self.loadingText setAlignment:NSCenterTextAlignment];
    }
    [self setViewHidden:YES];
    
}

-(void)setViewHidden:(Boolean)hidden{
    /*
     NSImageView *hudColorView;
     @property (weak) IBOutlet NSImageView *picView;
     @property (nonatomic,nonnull) NSButton *operateButton;
     @property (weak) IBOutlet NSTextField *alreadyClean;
     @property (weak) IBOutlet NSTextField *needToCleanBySelf;
     @property (weak) IBOutlet NSTextField *picDeleteTip;
     @property (weak) IBOutlet NSTextField *descTitleTextFileld;
     @property (weak) IBOutlet NSButton *noUseButton;
     @property (weak) NSTextField *extraText;//由于英文提示文字过长，分两行显示，extraText显示第二行
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.noUseButton setHidden:hidden];
        [self.operateButton setHidden:hidden];
        [self.alreadyClean setHidden:hidden];
        [self.needToCleanBySelf setHidden:hidden];
        [self.picDeleteTip setHidden:hidden];
        [self.descTitleTextFileld setHidden:hidden];
        [self.picView setHidden:hidden];
        [self.extraText setHidden:hidden];
        [self.hudColorView setHidden:hidden];
        [self.loadingView setHidden:!hidden];
        [self.loadingText setHidden:!hidden];
        if(!hidden){
            [self.loadingView invalidate];
        }
    });
}

-(void)receiveNotificationAfterCreateAlbum: (NSNotification *)notification{
    NSNumber *number = [notification object];
    Boolean authorizedForCreateAlbum = [number boolValue];
    if(authorizedForCreateAlbum){
        self.operateButtonState = OpenPhotoAppState;
        [self removeNotification];
    }else{
        self.operateButtonState = GetPermissionState;
    }
    [self setViewHidden:NO];
    [self resetView];
}

-(void)receiveNotifactionAfterPermissionSetted{
    if(![LMAuthorizationManager checkAuthorizationForCreateAlbum]){
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initLoadingView];
        //当窗口显示在前台，再次尝试清理
        [self scanSystemPhoto];
    });
    
}

/**
 更新按钮和提示信息
 */
-(void)resetView{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self resetButton];
        [self resetTipsView];
    });
}

/**
 根据operateButtonState更新按钮状态
 */
- (void)resetButton{
        NSString *operateButtonTitleKey = @"CheckDeleteSystemPhotoViewController_viewDidLoad_1553065843_1";
        NSString *cancelButtonTitleKey = @"CheckDeleteSystemPhotoViewController_initViewText_noUseButton_3";
        switch (self.operateButtonState) {
            case GetPermissionState:
                operateButtonTitleKey = @"CheckDeleteSystemPhotoViewController_button_get_permission";
                cancelButtonTitleKey = @"CheckDeleteSystemPhotoViewController_initViewText_noUseButton_cancel";
                self.operateButton.action = @selector(openPermissinGuideWindow:);
                break;
            case ScanPhotoState://该中间状态已取消
//                operateButtonTitleKey = @"CheckDeleteSystemPhotoViewController_operateButton_scanAgain";
//                cancelButtonTitleKey = @"CheckDeleteSystemPhotoViewController_initViewText_noUseButton_cancel";
//                self.operateButton.action = @selector(scanSystemPhoto);
                break;
            case OpenPhotoAppState:
                [self getSelfDefineFolderSize];
                self.operateButton.action = @selector(openPhotoAppAction);
                break;
            default:
                break;
        }
        [self.operateButton setTitle:NSLocalizedStringFromTableInBundle(operateButtonTitleKey, nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.noUseButton setTitle:NSLocalizedStringFromTableInBundle(cancelButtonTitleKey, nil, [NSBundle bundleForClass:[self class]], @"")];
    
}

/**
 设置文本提示信息
 */
-(void)resetTipsView{
    NSString *titleTips = nil;
    switch (self.operateButtonState) {
        case GetPermissionState:
            titleTips = NSLocalizedStringFromTableInBundle(@"CheckDeleteSystemPhotoViewController_automation_needPermissionTips", nil, [NSBundle bundleForClass:[self class]],@"");
            [self.descTitleTextFileld setStringValue:@""];
            //由于英文提示信息过长，需要分两行显示
            if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
                 [self initExtraTextField];
                 [self.extraText setHidden:NO];
            }
            break;
        case ScanPhotoState:
            break;
        case OpenPhotoAppState:
            titleTips = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"CheckDeleteSystemPhotoViewController_viewDidLoad_needToCleanBySelf_2", nil, [NSBundle bundleForClass:[self class]], @""),[self getDeletePictureSizeDescription:self.photoFloderSize]] ;
            [self.descTitleTextFileld setStringValue:NSLocalizedStringFromTableInBundle(@"CheckDeleteSystemPhotoViewController_initViewText_descTitleTextFileld_2", nil, [NSBundle bundleForClass:[self class]], @"")];
                [self.extraText setHidden:YES];
            break;
        default:
            break;
    }
    [self.needToCleanBySelf setStringValue:titleTips];
    
}

-(void)scanSystemPhoto{
    LMSystemPhotoCleanerHelper *helper = [[LMSystemPhotoCleanerHelper alloc]init];
    [helper addPhotoToAlbumWith:self.systemPhotoArray];
}

- (void)getSelfDefineFolderSize{
    NSString *photoPath = [NSString stringWithFormat:@"%@/Pictures", [NSString getUserHomePath]];
    NSString *photoslibraryPath = @"photoslibrary";
    self.selfDefineFloderSize = 0;
    self.photoFloderSize = 0;
    
    for (NSInteger index = 0;index < self.result.count;index ++) {
        LMSimilarPhotoGroup *group  = [self.result objectAtIndex: index];
        for (LMPhotoItem *item in group.items) {
            if(NO == item.isSelected){
                continue;
            }
            
            if([item.path containsString:photoPath]&&[item.path containsString:photoslibraryPath]){
                self.photoFloderSize += item.imageSize;
            } else {
                self.selfDefineFloderSize += item.imageSize;
            }
        }
    }
}

- (IBAction)giveUpClean:(id)sender {
    [self removeNotification];
    [self.view.window.windowController showAddView];
}

/**
 macOS 10.14 photos.app 路径是/Applications/Photos.app
 macOS 10.15 photos.app 路径是/System/Applications/Photos.app
 */
- (IBAction)openPhotoAppAction {
    [self removeNotification];
//    NSString *appPath = @"/Applications/Photos.app";
//    [[NSWorkspace sharedWorkspace]openFile:appPath];
    NSString *appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Photos"];
    NSLog(@"LMPhotoCleaner--->openPhotoAppAction--appPath:%@",appPath);
    [[NSWorkspace sharedWorkspace] launchApplication:appPath];
    [self.view.window.windowController showAddView];
}

-(void)openPermissinGuideWindow: (NSButton *)sender{
    CGPoint centerPoint = [self getCenterPoint];
    if(!self.permissionGuideWndController){
        NSString *imageName = @"automation_permission_guide_ch";
        if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
            imageName = @"automation_permission_guide_en";
        }
        NSString *title = NSLocalizedStringFromTableInBundle(@"CheckDeleteSystemPhotoViewController_automation_permissionGuide_title", nil, [NSBundle bundleForClass:[self class]], @"");
        NSString *descText = NSLocalizedStringFromTableInBundle(@"CheckDeleteSystemPhotoViewController_automation_permissionGuide_descText", nil, [NSBundle bundleForClass:[self class]], @"");
        self.permissionGuideWndController = [[LMPermissionGuideWndController alloc] initWithParaentCenterPos:centerPoint title:title descText:descText image:[NSImage imageNamed:imageName withClass:self.class]];
        self.permissionGuideWndController.settingButtonEvent = ^{
             [LMAuthorizationManager openPrivacyAutomationPreference];
        };
        self.permissionGuideWndController.finishButtonEvent = ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:LM_NOTIFACTION_SCAN_SYSTEM_PHOTO object:nil];
        };
    }
    [self.permissionGuideWndController loadWindow];
    [[NSApplication sharedApplication] runModalForWindow:self.permissionGuideWndController.window];
    
}

-(void)permissionGuideWindowWillClose{
    [[NSApplication sharedApplication]stopModal];
}

-(CGPoint)getCenterPoint
{
    CGPoint origin = self.view.window.frame.origin;
    CGSize size = self.view.window.frame.size;
    return CGPointMake(origin.x + size.width / 2, origin.y + size.height / 2);
}

- (NSString*)getDeletePictureSizeDescription:(NSInteger)fileSize{
    NSString *deletePictureSizeDescription = @"";
    fileSize /= 1000;
    if (fileSize > 1000*1000*1000) {
        deletePictureSizeDescription = [NSString stringWithFormat:@"%.1f TB",fileSize*1.0/(1000*1000*1000)];
    }else if (fileSize > 1000*1000) {
        deletePictureSizeDescription = [NSString stringWithFormat:@"%.1f GB",fileSize*1.0/(1000*1000)];
    } else {
        deletePictureSizeDescription = [NSString stringWithFormat:@"%.1f MB",fileSize*1.0/(1000)];
    }
    return deletePictureSizeDescription;
}

-(void)removeNotification{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:LM_NOTIFACTION_SCAN_SYSTEM_PHOTO object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:LM_NOTIFCATION_CREAT_ALBUM_FINISHED object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:NSWindowWillCloseNotification object:nil];
}

@end
