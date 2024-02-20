//
//  LMFloderAddWindowController.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMPhotoCleanerWndController.h"
#import "LMFloderAddViewController.h"
#import "LMScanViewController.h"
#import "LMSimilarPhotoResultViewContoller.h"
#import "LMPhotoCleanViewController.h"
#import "LMPhotoCleanFinishedViewController.h"
#import "LMNoSimilarPhotoResultViewController.h"
#import "CheckDeleteSystemPhotoViewController.h"
#import "DefineHeader.h"
#import "LMSimilarPhotoGroup.h"

@interface LMPhotoCleanerWndController ()<NSWindowDelegate>
@property (nonatomic, strong)  LMFloderAddViewController *addViewController;
@property (nonatomic, strong)  LMScanViewController *scanViewController;
@property (nonatomic, strong)  LMSimilarPhotoResultViewContoller *resultViewController;
@property (nonatomic, strong)  LMPhotoCleanViewController *cleanViewController;
@property (nonatomic, strong)  LMPhotoCleanFinishedViewController *cleanFinishViewController;
@property (nonatomic, strong)  LMNoSimilarPhotoResultViewController *noSimilarPhotoViewController;
@property (nonatomic, strong)  CheckDeleteSystemPhotoViewController *checkDeleteSystemPhotoViewController;


@end

@implementation LMPhotoCleanerWndController


- (instancetype) init {
    self = [super initWithWindowNibName:NSStringFromClass(self.class)];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib {
    self.window.titlebarAppearsTransparent = YES;
    self.window.styleMask |= NSFullSizeContentViewWindowMask;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];

    self.window.movableByWindowBackground = YES;
    [self showAddView];
    
}

- (void)showAddView {
    
    self.addViewController= [[LMFloderAddViewController alloc] init];
    self.window.contentViewController = self.addViewController;
    if(nil != self.scanViewController ){
        self.scanViewController = nil;
    }
    
    if(nil != self.resultViewController ){
        self.resultViewController  = nil;
    }
}

- (void)showScanView:(NSArray<NSString *> *)scanPaths {
    self.scanViewController = [[LMScanViewController alloc] init];
    
    self.window.contentViewController = self.scanViewController;
    [self.scanViewController scan:scanPaths];
}

- (void)showResultView:(NSMutableArray <LMSimilarPhotoGroup *>*)result {
    self.resultViewController = [[LMSimilarPhotoResultViewContoller alloc] init];
    self.window.contentViewController = self.resultViewController;
    [self.resultViewController updateScanResult:result];
    
    if(nil != self.scanViewController ){
        self.scanViewController  = nil;
    }
}

- (void)showCleanView:(NSMutableArray <LMSimilarPhotoGroup *>*)result {
    self.cleanViewController = [[LMPhotoCleanViewController alloc] init];
    
    self.window.contentViewController = self.cleanViewController;
    [self.cleanViewController deleteSelectItem:result];
}

- (void)showCleanFinishView:(NSInteger)deleteCount {
    self.cleanFinishViewController = [[LMPhotoCleanFinishedViewController alloc] init];
    self.cleanFinishViewController.deleteCount = deleteCount;
    self.window.contentViewController = self.cleanFinishViewController;
    self.cleanViewController = nil;
}

- (void)showNoSimilarPhotoViewController:(NSString *)descriptionString {
    self.noSimilarPhotoViewController = [[LMNoSimilarPhotoResultViewController alloc] init];
    self.noSimilarPhotoViewController.descriptionString = descriptionString;
    self.window.contentViewController = self.noSimilarPhotoViewController;
}

- (void)showCheckDeleteSystemPhotoViewController :(NSMutableArray <LMSimilarPhotoGroup *>*)result  :(Boolean)authorizedForCreateAlbum :(NSMutableArray *)systemPhotoArray{
    self.checkDeleteSystemPhotoViewController = [[CheckDeleteSystemPhotoViewController alloc] init];
    self.checkDeleteSystemPhotoViewController.result = result;
    self.checkDeleteSystemPhotoViewController.authorizedForCreateAlbum = authorizedForCreateAlbum;
    self.checkDeleteSystemPhotoViewController.systemPhotoArray = systemPhotoArray;
    self.window.contentViewController = self.checkDeleteSystemPhotoViewController;
}

- (void)windowWillClose:(NSNotification *)notification{
    NSLog(@"windowWillClose: %@, className:%@", notification, [self className]);
    [[NSNotificationCenter defaultCenter] postNotificationName:SimilatorImageScanCancel object:nil];
    [self setPropotyNil];
    if ([self.delegate respondsToSelector:@selector(windowWillDismiss:)]) {
        [self.delegate windowWillDismiss:[self className]];
    }
}

- (void)setPropotyNil{
    self.window.contentViewController = nil;
    self.addViewController = nil;
    self.scanViewController = nil;
    if (self.resultViewController != nil) {
        [self.resultViewController removeNotification];
    }
    self.resultViewController = nil;
    self.cleanViewController = nil;
    self.cleanFinishViewController = nil;
    self.noSimilarPhotoViewController = nil;
    self.checkDeleteSystemPhotoViewController = nil;

}

-(void)dealloc{
    NSLog(@"Super Dealloc _______________________ ，%@",[self className]);
}

@synthesize description;

@synthesize hash;

@synthesize superclass;

@end
