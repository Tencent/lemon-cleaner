//
//  FullDiskAccessPermissionViewController.m
//  Lemon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "FullDiskAccessPermissionViewController.h"
#import "LMAlertViewController.h"
#import "LemonSuiteUserDefaults.h"
#import "LMPermissionGuideWndController.h"
#import "GetFullAccessWndController.h"
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/LMAuthorizationManager.h>
#import <QMCoreFunction/QMFullDiskAccessManager.h>

@interface FullDiskAccessPermissionViewController ()

@property (strong,nonatomic) GetFullAccessWndController *getFullAccessWndController;
@property SourceType sourceType;
@end

@implementation FullDiskAccessPermissionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleLabel.stringValue = NSLocalizedStringFromTableInBundle(@"GetFullDiskPremission_Title_10_15", nil, [NSBundle bundleForClass:[self class]], @"");
    self.okButton.title = NSLocalizedStringFromTableInBundle(@"GetFullDiskPremission_Button_OK_10_15", nil, [NSBundle bundleForClass:[self class]], @"");
    self.cancelButton.title = NSLocalizedStringFromTableInBundle(@"GetFullDiskPremission_Button_Cancel_10_15", nil, [NSBundle bundleForClass:[self class]], @"");
    
    __weak __typeof(self) weakSelf = self;
    self.okButtonCallback = ^{
        [weakSelf openFullDiskAccessSettingGuidePage];
        
    };
    self.cancelButtonCallback = ^{
    };
    
    self.windowShowCallback = ^{
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:IS_SHOW_REQUEST_FULL_DISK_PERMISSION_AT_BEGIN];
    };
}

-(CGPoint)getCenterPoint
{
    CGPoint origin = self.view.window.frame.origin;
    CGSize size = self.view.window.frame.size;
    return CGPointMake(origin.x + size.width / 2, origin.y + size.height / 2);
}

-(void)openFullDiskAccessSettingGuidePage
{
    CGPoint centerPoint = [self getCenterPoint];
    if (!self.getFullAccessWndController) {
        self.getFullAccessWndController = [GetFullAccessWndController shareInstance];
        [self.getFullAccessWndController setParaentCenterPos:centerPoint suceessSeting:nil];
    }
    [self.getFullAccessWndController.window makeKeyAndOrderFront:nil];
}

/// 没有授权并且没有弹出过窗口，则返回true, 否则返回false
+ (BOOL)needShowRequestFullDiskAccessPermissionAlert{
    
    // 没有显示过 并且没有权限则  弹窗
    return  ([QMFullDiskAccessManager getFullDiskAuthorationStatus] != QMFullDiskAuthorationStatusAuthorized)
    && (![[NSUserDefaults standardUserDefaults] boolForKey:IS_SHOW_REQUEST_FULL_DISK_PERMISSION_AT_BEGIN]);
    
}

/// 如果没有授权Lemon，则弹出引导窗口，采用通用的title
/// @param parentController parentController
+(BOOL)showFullDiskAccessRequestIfNeededWithParentController:(NSViewController *)parentController{
    return [self showFullDiskAccessRequestIfNeededWithParentController:parentController title:NSLocalizedStringFromTableInBundle(@"GetFullDiskPremission_Title_10_15", nil, [NSBundle bundleForClass:[self class]], @"") sourceType:SMALL_TOOLS_VIEW];
}

+(BOOL)showFullDiskAccessRequestIfNeededWithParentController:(NSViewController *)parentController sourceType: (SourceType)type{
    
    return [self showFullDiskAccessRequestIfNeededWithParentController:parentController title:NSLocalizedStringFromTableInBundle(@"GetFullDiskPremission_Title_10_15", nil, [NSBundle bundleForClass:[self class]], @"") sourceType:type];
}

//+(BOOL)showFullDiskAccessRequestIfNeededWithParentController:(NSViewController *)parentController title:(NSString *)title{
//
//    if (@available(macOS 10.15, *))
//    {
//        if([QMFullDiskAccessManager getFullDiskAuthorationStatus] != QMFullDiskAuthorationStatusAuthorized){
//            FullDiskAccessPermissionViewController *fullDiskAccessRequstController = [[FullDiskAccessPermissionViewController alloc] init];
//            fullDiskAccessRequstController.windowHeigh = 133;
//            fullDiskAccessRequstController.windowCloseCallback = ^{
//            };
//            fullDiskAccessRequstController.parentViewController = parentController;
//            [fullDiskAccessRequstController showAlertViewAsModalStypeAt:parentController];
//            fullDiskAccessRequstController.titleLabel.stringValue = title;
//            return YES;
//        }
//    }
//    return NO;
//}

+(BOOL)showFullDiskAccessRequestIfNeededWithParentController:(NSViewController *)parentController title:(NSString *)title sourceType:(SourceType)type{

    if (@available(macOS 10.15, *))
    {
        if([QMFullDiskAccessManager getFullDiskAuthorationStatus] != QMFullDiskAuthorationStatusAuthorized){
            FullDiskAccessPermissionViewController *fullDiskAccessRequstController = [[FullDiskAccessPermissionViewController alloc] init];
            fullDiskAccessRequstController.sourceType = type;
            fullDiskAccessRequstController.windowHeigh = 133;
            fullDiskAccessRequstController.windowCloseCallback = ^{
            };
            fullDiskAccessRequstController.parentViewController = parentController;
            [fullDiskAccessRequstController showAlertViewAsModalStypeAt:parentController];
           
            fullDiskAccessRequstController.titleLabel.stringValue = title;
            return YES;
        }
    }
    return NO;
}

+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock{
    [self showFullDiskAccessRequestWithParentController:parentController title:title description:nil okBtnTitle:nil windowCloseBlock:windowCloseblock okButtonBlock:okBtnBlock];
}

+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock cancelBtnBlock:(SimpleCallback)cancelBtnBlock{
      [self showFullDiskAccessRequestWithParentController:parentController title:title description:nil okBtnTitle:nil windowHeight:133 windowCloseBlock:windowCloseblock okButtonBlock:okBtnBlock cancelButtonBlock:cancelBtnBlock];
}


+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title description: (NSString *)desc windowHeight: (CGFloat)height windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock{
    
    [self showFullDiskAccessRequestWithParentController:parentController title:title description:desc okBtnTitle:nil windowHeight:height windowCloseBlock:windowCloseblock okButtonBlock:okBtnBlock cancelButtonBlock:nil];
    
}

+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title description: (NSString *)desc windowHeight: (CGFloat)height windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock cancelButtonBlock: (SimpleCallback)cancelBtnBlock{
    
    [self showFullDiskAccessRequestWithParentController:parentController title:title description:desc okBtnTitle:nil windowHeight:height windowCloseBlock:windowCloseblock okButtonBlock:okBtnBlock cancelButtonBlock:cancelBtnBlock];
    
}

+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title okBtnTitle: (NSString *)okBtnTitle windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock{
    
        [self showFullDiskAccessRequestWithParentController:parentController title:title description:nil okBtnTitle:okBtnTitle windowCloseBlock:windowCloseblock okButtonBlock:okBtnBlock];
}

+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title description: (NSString *)desc okBtnTitle: (NSString *)okBtnTitle windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock{
    
    [self showFullDiskAccessRequestWithParentController:parentController title:title description:desc okBtnTitle:okBtnTitle windowCloseBlock:windowCloseblock okButtonBlock:okBtnBlock cancelButtonBlock:nil];
}

+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title description: (NSString *)desc okBtnTitle: (NSString *)okBtnTitle okButtonBlock: (SimpleCallback) okBtnBlock cancelButtonBlock:(SimpleCallback) cancelBtnBlock{
    ///
    [self showFullDiskAccessRequestWithParentController:parentController title:title description:desc okBtnTitle:okBtnTitle windowCloseBlock:nil okButtonBlock:okBtnBlock cancelButtonBlock:cancelBtnBlock];
}

+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title description: (NSString *)desc okBtnTitle: (NSString *)okBtnTitle windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock cancelButtonBlock:(SimpleCallback) cancelBtnBlock{
    [self showFullDiskAccessRequestWithParentController:parentController title:title description:desc okBtnTitle:okBtnTitle windowHeight:133 windowCloseBlock:windowCloseblock okButtonBlock:okBtnBlock cancelButtonBlock:cancelBtnBlock];
}

+(void)showFullDiskAccessRequestWithParentController:(NSViewController *)parentController title: (NSString *)title description: (NSString *)desc okBtnTitle: (NSString *)okBtnTitle windowHeight:(CGFloat)height windowCloseBlock: (SimpleCallback) windowCloseblock okButtonBlock: (SimpleCallback) okBtnBlock cancelButtonBlock:(SimpleCallback) cancelBtnBlock{
//    if (@available(macOS 10.15, *))
    {
         __weak __typeof(self) weakSelf = self;
        FullDiskAccessPermissionViewController *fullDiskAccessRequstController = [[FullDiskAccessPermissionViewController alloc] init];
        fullDiskAccessRequstController.windowHeigh = height;
        fullDiskAccessRequstController.parentViewController = parentController;
        [fullDiskAccessRequstController showAlertViewAsModalStypeAt:parentController];
        
        fullDiskAccessRequstController.titleLabel.stringValue = title ? title : NSLocalizedStringFromTableInBundle(@"GetFullDiskPremission_Title_10_15", nil, [NSBundle bundleForClass:[self class]], @"");;
        fullDiskAccessRequstController.descLabel.stringValue = desc ? desc : @"";
        fullDiskAccessRequstController.okButton.title = okBtnTitle ? okBtnTitle : NSLocalizedStringFromTableInBundle(@"GetFullDiskPremission_Button_OK_10_15", nil, [NSBundle bundleForClass:[self class]], @"");
        [fullDiskAccessRequstController updateViewConstraints];
        fullDiskAccessRequstController.windowCloseCallback = windowCloseblock;
        fullDiskAccessRequstController.okButtonCallback = okBtnBlock ? okBtnBlock : ^{
            [weakSelf openFullDiskAccessSettingGuidePage];
        };
        fullDiskAccessRequstController.cancelButtonCallback = cancelBtnBlock ? cancelBtnBlock :  ^{
        };
    }
}


@end
