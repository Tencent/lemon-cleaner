//
//  LMFloderAddViewController.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMFloderAddViewController.h"
#import <QMUICommon/LMSelectorDropView.h>
#import "LMPhotoFileScanManager.h"
#import "LMPhotoCleanerWndController.h"
#import <QMUICommon/LMViewHelper.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/LMiCloudPathHelper.h>
#import <QMUICommon/LMGradientTitleButton.h>
#import <QMCoreFunction/NSString+Extension.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/NSFontHelper.h>
#import <Photos/Photos.h>
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import <QMCoreFunction/NSString+Extension.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMUICommon/GetFullAccessWndController.h>
#import <QMCoreFunction/LMAuthorizationManager.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/LMPermissionGuideWndController.h>
#import <FMDB/FMDB.h>
#import <QMCoreFunction/McCoreFunction.h>
#import "FileMangerHelper.h"
#import <QMUICommon/PathSelectViewController.h>
#import <QMCoreFunction/NSBezierPath+Extension.h>
#import <QMUICommon/QMUICommon-umbrella.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/FullDiskAccessPermissionViewController.h>

@interface LMFloderAddViewController ()<LMFolderSelectorDelegate, NSDraggingDestination>{
    NSBundle *myBundle;
    LMSelectorDropView *selectorDropView;
    NSTimeInterval addActionClickTimeInterval;
    PathSelectViewController *pathSelectViewController;
    CAShapeLayer *dragShadowViewlayer;
}
//@property (nonatomic,nonnull) IBOutlet LMGradientTitleButton *addPath;

@property (weak) IBOutlet NSTextField *titleTextFileld;
@property (weak) IBOutlet NSTextField *descTextField;
@property (strong, nonatomic) LMGradientTitleButton *ok;
@property (nonatomic,nonnull) NSButton *operateButton;
@property(weak) NSView* dragShadowView;
@property(weak) NSImageView* mainBgImageView;

@property (strong,nonatomic) LMPermissionGuideWndController *permissionGuideWndController;

@end


@implementation LMFloderAddViewController

- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        myBundle = [NSBundle bundleForClass:[self class]];
    }
    return self;
}

-(void)initViewText{
    [self.titleTextFileld setStringValue:NSLocalizedStringFromTableInBundle(@"LMFloderAddViewController_initViewText_titleTextFileld_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self setTitleColorForTextField:self.titleTextFileld];
}

-(void)setupViews{
    [self.descTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleTextFileld.mas_bottom);
        make.left.equalTo(self.titleTextFileld.mas_left);
    }];
    
    [self initPathSelectViewController];
    [self.operateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(148);
        make.height.mas_equalTo(48);
        make.top.equalTo(self->pathSelectViewController.view.mas_bottom).offset(32);
        make.left.equalTo(self.descTextField);
    }];
    
//    self.view.layer
    //设置插画背景图
    NSImageView *imageView = [[NSImageView alloc]init];
    self.mainBgImageView = imageView;
    NSImage *image = [NSImage imageNamed:@"photo_clean_main_bg" withClass:self.class];
    [imageView setImage:image];
    [self.view addSubview:imageView];
//    [self.mainBgImageView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,nil]];
//    [self.mainBgImageView ap_forwardDraggingDestinationTo:self];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view);
        make.right.equalTo(self.view).offset(10);
    }];
}

-(void)initPathSelectViewController{
    pathSelectViewController = [[PathSelectViewController alloc]init];
    pathSelectViewController.sourceType = 1;    //重复文件
    pathSelectViewController.delegate = self;
    [self addChildViewController:pathSelectViewController];
    [self.view addSubview:pathSelectViewController.view];
    [pathSelectViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@400);
        make.height.equalTo(@80);
        make.left.equalTo(self.descTextField.mas_left);
        make.top.equalTo(self.descTextField.mas_bottom).offset(30);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self.view setWantsLayer:YES];
//    [self.view.layer setBackgroundColor:[[NSColor whiteColor] CGColor]];
    
    self.operateButton = [LMViewHelper createNormalGreenButton:20 title:NSLocalizedStringFromTableInBundle(@"LMFloderAddViewController_viewDidLoad_1553065843_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.view addSubview:self.operateButton];
    self.operateButton.target = self;
    self.operateButton.action = @selector(actionStartScan);
    [self.operateButton setEnabled:NO];
    
    LMSelectorDropView *dropView = [[LMSelectorDropView alloc] initWithFrame:NSMakeRect(79, 131, 220, 220)];
    dropView.addFilesTipString = NSLocalizedStringFromTableInBundle(@"LMFloderAddViewController_viewDidLoad_1553065843_2", nil, [NSBundle bundleForClass:[self class]], @"");
    [dropView awakeFromNib];
    
    NSString *photoPath = [NSString stringWithFormat:@"%@/Pictures/Photos Library.photoslibrary", [NSString getUserHomePath]];
    
    BOOL isDirectory;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:photoPath isDirectory:&isDirectory];
    if(!isExist){
        photoPath = [NSString stringWithFormat:@"%@/Pictures/照片图库.photoslibrary", [NSString getUserHomePath]];
        isExist = [fileManager fileExistsAtPath:photoPath isDirectory:&isDirectory];
    }
    
    self.descTextField.font = [NSFontHelper getLightSystemFont:16];
        [self.descTextField setStringValue:[NSString stringWithFormat:@"%@",NSLocalizedStringFromTableInBundle(@"LMFloderAddViewController_initViewText_descTextField_2", nil, [NSBundle bundleForClass:[self class]], @"")]];
    [self setupViews];
    [self initViewText];
    [self initShadowView];
}

/// 创建拖拽的蒙层 响应拖拽效果，拖拽时响应蒙层
-(void)initShadowView{
    NSView *dragShadowView = [[NSView alloc]init];
    dragShadowView.wantsLayer = YES;
    self.dragShadowView = dragShadowView;
    
    [self.view registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,nil]];
    [self.view ap_forwardDraggingDestinationTo:self];
    [self.view addSubview:dragShadowView];
    [self.dragShadowView setHidden:YES];
    [self.dragShadowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(28);
        make.left.equalTo(self.view).offset(28);
        make.right.equalTo(self.view).offset(-28);
        make.bottom.equalTo(self.view).offset(-28);
    }];
    
    NSImageView *imageView = [[NSImageView alloc]init];
    [imageView setImage:[NSImage imageNamed:@"add_folder_drag_view_btn_bg" withClass:self.class]];
    
    [self.dragShadowView addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.dragShadowView.mas_bottom).offset(-30);
        make.centerX.equalTo(self.dragShadowView);
    }];
    
    NSTextField *textField = [LMViewHelper createNormalLabel:12 fontColor:[NSColor whiteColor] fonttype:LMFontTypeLight];
    textField.stringValue = NSLocalizedStringFromTableInBundle(@"add_folder_drag_folder_tips", nil, [NSBundle mainBundle], @"");
    [self.dragShadowView addSubview:textField];
    [textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(imageView);
        make.centerX.equalTo(self.dragShadowView);
    }];
    
}

- (void)viewDidLayout{
    //设置拖拽view的边框和背景
    if(!dragShadowViewlayer){
        dragShadowViewlayer = [CAShapeLayer layer];
    }
    dragShadowViewlayer.strokeColor = [NSColor colorWithHex:0x027BFF].CGColor;
    dragShadowViewlayer.path = [[NSBezierPath bezierPathWithRect:self.dragShadowView.bounds] copyQuartzPath];
    dragShadowViewlayer.frame = self.dragShadowView.bounds;
    dragShadowViewlayer.lineWidth = 1;
    dragShadowViewlayer.cornerRadius = 10;
    dragShadowViewlayer.lineCap = @"kCALineCapRound";
    dragShadowViewlayer.lineDashPattern = @[@10,@10];
    dragShadowViewlayer.fillColor = [LMAppThemeHelper getDragShadowViewBgColor].CGColor;
    [self.dragShadowView.layer addSublayer:dragShadowViewlayer];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender{
    NSLog(@"draggingEntered");
    [self.dragShadowView setHidden: NO];
    return NSDragOperationCopy;//添加时会有“+”号
}

- (void)draggingExited:(id<NSDraggingInfo>)sender{
    NSLog(@"draggingExited");
    [self.dragShadowView setHidden: YES];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender{
    NSLog(@"performDragOperation");
    [self.dragShadowView setHidden: YES];
    NSArray *files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    if([pathSelectViewController addFilePath:files])
        return YES;
    return NO;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender{
    NSLog(@"draggingEnded");
    [self.dragShadowView setHidden: YES];
}

- (void)viewDidAppear{
    [super viewDidAppear];
    [selectorDropView showDefatulsState:NO];
}

- (void)duplicateChoosePathChanged:(NSString *)path isRemove:(BOOL)remove
{
    NSString *photoPath = [NSString stringWithFormat:@"%@/Pictures", [NSString getUserHomePath]];
    NSString *photoslibraryPath = @"photoslibrary";

    [self.operateButton setEnabled:[[selectorDropView duplicateChoosePaths] count] > 0];
    [self.operateButton setEnabled:[[pathSelectViewController getChoosePaths] count] > 0];
}

- (NSArray *)duplicateViewAllowFilePaths:(NSArray *)filePaths
{
    //    infoTextField.stringValue = @"";
    NSMutableArray * retArray = [NSMutableArray array];
    NSArray * array = [LMPhotoFileScanManager systemProtectPath];
    for (__strong NSString *path in filePaths)
    {
        
        //兼容 10.15 beta4, 用户的磁盘可能挂载到 "/" 也会挂载到 "/System/Volumes/Data"
        NSString *dataSystemPath = @"/System/Volumes/Data";
        if([path hasPrefix: dataSystemPath]){
            path = [path substringFromIndex:dataSystemPath.length];
        }
        
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:path];
        if(!isExist){
            NSLog(@"%s path not exist :%@",__FUNCTION__, path);
            continue;
        }
        
        if([LMiCloudPathHelper isICloudPath:path]){
            path = [LMiCloudPathHelper getICloudContainerPath];
        }
   
        for (NSString * protectPath in array)
        {
            if ([path hasPrefix:protectPath] && ![LMiCloudPathHelper isICloudSubPath:path])
            {
                NSLog(@"你选择了系统保护文档");
                return nil;
            }
        }
        
        if ([path containsString:@"Pictures/Photos Library"]) {
            [retArray addObject:path];
            continue;
        }
       
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir&&![path containsString:@".app"]){
            [retArray addObject:path];
        }
    }
    
    if ([retArray count] > 0)
    {
        //        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kFirstDragDropFiles];
        //        [dropTipsImageView removeFromSuperview];
    }
    return retArray;
}


- (void)removeAllChoosePath
{
    [self.operateButton setEnabled:NO];
}

- (void)addFloderAction{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self->addActionClickTimeInterval = [[NSDate date] timeIntervalSince1970];
    });
}

- (void)cancelAddAction{
    
}

- (void)addFolderAction {
    
}

//
//- (void)addFolderAction {
//
//}



- (void)addSystemPhotoLibraryPathAction{
    double startTime = [[NSDate date] timeIntervalSince1970];
    NSString *photoPath = [NSString stringWithFormat:@"%@/Pictures/Photos Library.photoslibrary", [NSString getUserHomePath]];
    
    BOOL isDirectory;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:photoPath isDirectory:&isDirectory];
    if(!isExist){
        photoPath = [NSString stringWithFormat:@"%@/Pictures/照片图库.photoslibrary", [NSString getUserHomePath]];
        isExist = [fileManager fileExistsAtPath:photoPath isDirectory:&isDirectory];
    }
    double endTime = [[NSDate date] timeIntervalSince1970];
    double getPathTime = endTime - startTime;
    NSLog(@"AddSystemPath---getTime:%f",getPathTime);
    NSLog(@"AddSystemPath---startAddTime:%f",endTime);
    
    [pathSelectViewController addFilePathToView:photoPath];
    
}

#pragma mark action
- (IBAction)actionStartScan{
    NSLog(@"LMPhotoCleaner--->actionStartScan");
    //    NSArray *choosePaths = [selectorDropView duplicateChoosePaths];
    NSArray *choosePaths = [pathSelectViewController getChoosePaths];
    if (choosePaths == nil ||choosePaths.count == 0) {
        return;
    }
    
    //如果没有涉及系统相册不需要访问相册权限
    if([FileMangerHelper isContainPhotoLibraryWithPathArray:choosePaths] && [LMAuthorizationManager checkAuthorizationForAccessAlbum] == PhotoDenied){
        [self popAlertDialogForNeedPermission];
        return;
    };
    
    NSString *reportPathString = @"";
    for (NSString *path in choosePaths) {
        reportPathString = [reportPathString stringByAppendingString:path];
        reportPathString = [reportPathString stringByAppendingString:@","];
    }
    NSLog(@"LMPhotoCleaner--->actionStartScan--getSelectedPath:%@",reportPathString);
    
    LMPhotoCleanerWndController *mainWndController = (LMPhotoCleanerWndController*)self.view.window.windowController;
    [mainWndController showScanView:choosePaths];
}

/**
 判断照片图库是否存在，如果不存在不需要检查访问相册的权限
 
 @return YES：存在
 */
-(Boolean)checkPhotoLibraryExist{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *photoHomePath = [NSString stringWithFormat:@"%@/Pictures/",[NSString getUserHomePath]];
    NSString *phtotPath = [photoHomePath stringByAppendingString:@"照片图库.photoslibrary"];
    Boolean isPhotoLibraryExist = YES;
    if(![fileManager fileExistsAtPath:phtotPath]){
        isPhotoLibraryExist = NO;
    }
    if(!isPhotoLibraryExist){
        phtotPath = [photoHomePath stringByAppendingString:@"Photos Library.photoslibrary"];
        if([fileManager fileExistsAtPath:phtotPath]){
            isPhotoLibraryExist = YES;
        }else{
            isPhotoLibraryExist = NO;
            NSLog(@"照片图库.photoslibrary is not exist");
        }
    }
    return isPhotoLibraryExist;
}

//- (void)viewWillLayout{
//    NSLog(@"LMFolderAddViewController---viewWillLayout");
//}


//-(Boolean)isContainPhotoLibraryWithPathArray:(NSArray*)rootPath{
//    for (NSString *path in rootPath) {
//        if ([path containsString:@".photoslibrary"]) {
//            return YES;
//        }
//    }
//    return NO;
//}


/**
 提示用户需要权限
 */
-(void)popAlertDialogForNeedPermission{
    NSString *title = NSLocalizedStringFromTableInBundle(@"LMFloderAddViewController_alertDialog_content_needPermission", nil, [NSBundle bundleForClass:[self class]], @"");
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMFloderAddViewController_alertDialog_okButton_getPermission", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"LMFloderAddViewController_alertDialog_cancelButton", nil, [NSBundle bundleForClass:[self class]], @"")];
    [alert setMessageText:title];
    [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
        if(returnCode == NSAlertFirstButtonReturn){
            [self openPermissinGuideWindow];
        }
    }];
}

-(CGPoint)getCenterPoint
{
    CGPoint origin = self.view.window.frame.origin;
    CGSize size = self.view.window.frame.size;
    return CGPointMake(origin.x + size.width / 2, origin.y + size.height / 2);
}

-(void)openPermissinGuideWindow{
    CGPoint centerPoint = [self getCenterPoint];
    if(!self.permissionGuideWndController){
        
        NSString *imageName = @"access_photo_permission_guide_ch";
        if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
            imageName = @"access_photo_permission_guide_en";
        }
        NSString *title = NSLocalizedStringFromTableInBundle(@"LMFloderAddViewController_accessPhoto_permissionGuide_title", nil, [NSBundle bundleForClass:[self class]], @"");
        NSString *descText = NSLocalizedStringFromTableInBundle(@"LMFloderAddViewController_accessPhoto_permissionGuide_descText", nil, [NSBundle bundleForClass:[self class]], @"");
        self.permissionGuideWndController = [[LMPermissionGuideWndController alloc] initWithParaentCenterPos:centerPoint title:title descText:descText image:[NSImage imageNamed:imageName withClass:self.class]];
        self.permissionGuideWndController.settingButtonEvent = ^{
            [LMAuthorizationManager openPrivacyPhotoPreference];
        };
    }
    [self.permissionGuideWndController loadWindow];
    [self presentViewControllerAsModalWindow:self.permissionGuideWndController.contentViewController];
//    [self.permissionGuideWndController.window makeKeyAndOrderFront:nil];
}

-(void)dealloc{
    NSLog(@"Super Dealloc _______________________ ，%@",[self className]);
}

@end
