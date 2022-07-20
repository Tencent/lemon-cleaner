//
//  LMDuplicateFileViewController.m
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/16.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "LMDuplicateSelectFoldersViewController.h"
#import <Masonry/Masonry.h>
#import "LMDuplicateScanViewController.h"
#import "QMDuplicateFileScanManager.h"
#import <QMUICommon/QMUICommon-umbrella.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSBezierPath+Extension.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/FullDiskAccessPermissionViewController.h>
#import <QMCoreFunction/QMFullDiskAccessManager.h>
//#import "NSBe"
//#import <QMUICommon/PathSelectViewController.h>

@interface LMDuplicateSelectFoldersViewController () <LMFolderSelectorDelegate, NSDraggingDestination> {
    NSTextField *_titleLabel;
    NSTextField *_descLabel;
    NSButton *_startScanBtn;
    CAShapeLayer *dragShadowViewlayer;
    
    PathSelectViewController *pathSelectViewController;
}

@property(weak) NSView* dragShadowView;
@property  FullDiskAccessPermissionViewController *requestFullDiskAccessViewController;


@end

@implementation LMDuplicateSelectFoldersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];

}



// viewController
// window.contentViewController -> [NSWindow _contentViewControllerChanged] ->[NSViewController _loadViewIfRequired]  -> [NSViewController loadView] loadView 会自动调用.
// 自动调用 loadView 方法会触发调用 viewDidLoad 方法.


- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 780, 482)];
    view.wantsLayer = true;
    view.layer.backgroundColor = [NSColor whiteColor].CGColor;
    self.view = view;
}

- (void)initView {
    [self initBgImageView];
    pathSelectViewController = [[PathSelectViewController alloc]init];
    pathSelectViewController.sourceType = 2;    //重复文件
    pathSelectViewController.delegate = self;
    [self addChildViewController:pathSelectViewController];
    [self.view addSubview:pathSelectViewController.view];
   
    _titleLabel = [LMViewHelper createNormalLabel:32 fontColor:[LMAppThemeHelper getTitleColor]];
    [self.view addSubview:_titleLabel];
    _titleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMDuplicateSelectFoldersViewController_initView__titleLabel_2", nil, [NSBundle bundleForClass:[self class]], @"");

    _descLabel = [LMViewHelper createNormalLabel:16 fontColor:[NSColor colorWithHex:0x94979b]];
    [self.view addSubview:_descLabel];
    _descLabel.font = [NSFontHelper getLightSystemFont:16];
    _descLabel.stringValue = NSLocalizedStringFromTableInBundle(@"LMDuplicateSelectFoldersViewController_initView__descLabel_3", nil, [NSBundle bundleForClass:[self class]], @"");

    _startScanBtn = [LMViewHelper createNormalGreenButton:20 title:NSLocalizedStringFromTableInBundle(@"LMDuplicateSelectFoldersViewController_initView_1553072147_4", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.view addSubview:_startScanBtn];
    [_startScanBtn setEnabled:NO];
    _startScanBtn.target = self;
    _startScanBtn.action = @selector(startScan);


    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(87);
        make.left.equalTo(self.view.mas_left).offset(70);
    }];

    [_descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self->_titleLabel.mas_bottom).offset(8);
        make.left.equalTo(self->_titleLabel);
    }];
    
    [pathSelectViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@400);
        make.height.equalTo(@80);
        make.left.equalTo(self->_titleLabel.mas_left);
        make.top.equalTo(self->_descLabel.mas_bottom).offset(30);
    }];

    [_startScanBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@148);
        make.height.equalTo(@48);
        make.top.equalTo(self->pathSelectViewController.view.mas_bottom).offset(34);
        make.left.equalTo(self->_titleLabel);
    }];
    
    [self initShadowView];
   
}

-(void)initBgImageView{
    NSImageView *imageView = [[NSImageView alloc]init];
    NSImage *image = [NSImage imageNamed:@"duplicate_file_main_bg" withClass:self.class];
    [imageView setImage:image];
    [self.view addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view);
        make.right.equalTo(self.view);
    }];
}

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

// MARK: button action
//开始扫描文件
- (void)startScan {
    
    NSArray *choosePaths = [pathSelectViewController getChoosePaths];

    if (choosePaths == nil || choosePaths.count == 0) {
        return;
    }
    
    LMDuplicateScanViewController *scanController = [[LMDuplicateScanViewController alloc] init];
    scanController.windowController = self.view.window.windowController;
    scanController.pathArray = choosePaths;
    self.view.window.contentViewController = scanController;
}

- (void)duplicateChoosePathChanged:(NSString *)path isRemove:(BOOL)remove {
    [_startScanBtn setEnabled:[[pathSelectViewController getChoosePaths] count] > 0];
}

- (NSArray *)duplicateViewAllowFilePaths:(NSArray *)filePaths {
    //    infoTextField.stringValue = @"";
    NSMutableArray *retArray = [NSMutableArray array];
    NSArray *array = [QMDuplicateFileScanManager systemProtectPath];
    for (__strong NSString *path in filePaths) {
        
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
        
        // 允许 iCloud 目录 (iCloud目录是~/Library/Mobile Documents/com~apple~CloudDocs) 内部的文件夹并不在这个目录下
        if([LMiCloudPathHelper isICloudPath:path]){
            path = [LMiCloudPathHelper getICloudContainerPath];
        }

        
        
        for (NSString *protectPath in array) {
            if ([path hasPrefix:protectPath] && ![LMiCloudPathHelper isICloudSubPath:path]) {
                NSLog(@"你选择了系统保护文档");
                return nil;
            }
        }
        
        // 是否是 app
        NSURL *contentURL = [NSURL fileURLWithPath:path];
        NSNumber *isPackage = nil;
        [contentURL getResourceValue:&isPackage forKey:NSURLIsPackageKey error:NULL];
        
        if(isPackage && [isPackage boolValue] && [[path lastPathComponent] hasSuffix:@".app"]){
            continue;
        }else{
            // 是否是文件夹
            BOOL isDir = NO;
            if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir){
                [retArray addObject:path];
            }
        }

      
    }

    if ([retArray count] > 0) {
        //        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kFirstDragDropFiles];
        //        [dropTipsImageView removeFromSuperview];
    }
    return retArray;
}


- (void)removeAllChoosePath {
    [_startScanBtn setEnabled:NO];
}

- (void)addFolderAction {

}


- (void)cancelAddAction {

}

@end



//@im
