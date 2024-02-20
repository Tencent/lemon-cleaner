//
//  LMScanViewController.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMScanViewController.h"
#import <QMUICommon/QMProgressView.h>
#import "ImageGroupCompare.h"
#import "LMPhotoCleanerWndController.h"
#import "LMSimilarPhotoGroup.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/LMBackButton.h>
#import <Masonry/Masonry.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/NSButton+Extension.h>
#import <QMCoreFunction/NSTimer+Extension.h>
#import <QMUICommon/LMAppThemeHelper.h>

static NSTimeInterval kCollectionPathsProgressTimeInterval = 0.3;

@interface LMScanViewController ()


@property (weak) IBOutlet NSImageView *picView;
@property (weak) IBOutlet NSTextField *scanningTitleTextField;
@property (weak) IBOutlet NSTextField *currentPath;
@property (weak) IBOutlet QMProgressView *progressIndicator;
@property (weak) IBOutlet LMBackButton *cancelBtn;
@property (nonnull,nonatomic) NSMutableArray<NSMutableArray<NSString *> *> *resultData;
@property (nonatomic) ImageGroupCompare *imageGroupCompare;

@property (nonatomic) NSTimer *collectionPathsProgressTimer;
@property (nonatomic) NSInteger timerCount;

@end

@implementation LMScanViewController



- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        //myBundle = [NSBundle bundleForClass:[self class]];
    }
    return self;
}

-(void)initViewText{
    [self.scanningTitleTextField setStringValue:NSLocalizedStringFromTableInBundle(@"LMScanViewController_initViewText_scanningTitleTextField_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [LMAppThemeHelper setTitleColorForTextField:self.scanningTitleTextField];
    
    [self.currentPath setStringValue:NSLocalizedStringFromTableInBundle(@"LMScanViewController_initViewText_currentPath_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.cancelBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMScanViewController_initViewText_cancelBtn_1", nil, [NSBundle bundleForClass:[self class]], @"") withColor:[NSColor colorWithHex:0x94979b]];
    [self.cancelBtn setFocusRingType:NSFocusRingTypeNone];
}

-(void)setupViews{
    [self.scanningTitleTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.picView.mas_bottom).offset(36);
        make.centerX.equalTo(self.view);
    }];
    
    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.scanningTitleTextField.mas_right).offset(20);
        make.centerY.equalTo(self.scanningTitleTextField).offset(3);
        make.width.equalTo(@50);
        make.height.equalTo(@23);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initViewText];
    [self setupViews];
    self.timerCount = 0;
    __weak typeof(self) weakSelf = self;
    self.collectionPathsProgressTimer = [NSTimer timerWithTimeInterval:kCollectionPathsProgressTimeInterval repeats:YES handler:^{
        [weakSelf timerAction];
    }];
    
    [[NSRunLoop currentRunLoop]addTimer:self.collectionPathsProgressTimer forMode:NSRunLoopCommonModes];
    [self.collectionPathsProgressTimer fire];
    
    [self.currentPath setLineBreakMode:NSLineBreakByTruncatingMiddle];
    
    self.progressIndicator.value = 0;
    self.progressIndicator.borderColor = [NSColor clearColor];
    // Do view setup here.
    //NSLog(@"viewDidLoad scanPaths %@", self.scanPaths);
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onScanResult:) name:ReloadSimilatorImageTableView object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateProgress:) name:SimilatorImageScanProgress object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateScanPath:) name:SimilatorImageScanPath object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(cancelAction) name:SimilatorImageScanCancel object:nil];

    NSLog(@"did load %@", [NSThread currentThread]);
}

- (void)timerAction {
    self.timerCount++;
    NSString *descriptionString = NSLocalizedStringFromTableInBundle(@"LMScanViewController_timerAction_descriptionString _1", nil, [NSBundle bundleForClass:[self class]], @"");
    NSInteger leftTimerCount =   3 - self.timerCount%3;
    for (NSInteger index = 0; index <= self.timerCount%3; index++) {
        descriptionString = [descriptionString stringByAppendingString:@"."];
    }
    
    for (NSInteger index = 0; index <= leftTimerCount; index++) {
        descriptionString = [descriptionString stringByAppendingString:@" "];
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.currentPath setStringValue:descriptionString];
    });
}


- (void)cancelAction {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.imageGroupCompare cancelScan];
}

- (void)updateProgress:(NSNotification*)notificer{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *resultStr = [notificer.object mutableCopy];
        if (self.progressIndicator.actionEnd || [resultStr floatValue] >= 1) {
            self.progressIndicator.value = [resultStr floatValue] > 1?1:[resultStr floatValue];
        }
        
    });
}

- (void)updateScanPath:(NSNotification*)notificer{
   
//    [self.currentPath setLineBreakMode:NSLineBreakByTruncatingHead];

    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.collectionPathsProgressTimer != nil){
            [self.collectionPathsProgressTimer invalidate];
            self.collectionPathsProgressTimer = nil;
            self.currentPath.frame = NSMakeRect(228, 99, 324, 17);
            [self.currentPath setAlignment:NSTextAlignmentCenter];
        }
        NSString *resultStr = [notificer.object mutableCopy];

        if(nil == resultStr)
            return ;
        
        [self.currentPath setStringValue:resultStr] ;
        [self.currentPath setNeedsDisplay:true];        
    });
}

-(void)setProgressViewStyle{
//    self.scanProgressView = [[QMProgressView alloc] initWithFrame:NSMakeRect(151, 80, 175, 4)];
//    [self.view addSubview:self.scanProgressView];
//    self.scanProgressView.backColor = [NSColor colorWithSRGBRed:230/255.0 green:236/255.0 blue:241/255.0 alpha:1.0];
//    self.scanProgressView.fillColor = [NSColor colorWithSRGBRed:123/255.0 green:207/255.0 blue:140/255.0 alpha:1.0];
//    self.scanProgressView.borderColor = [NSColor blackColor];
//    self.scanProgressView.minValue = 0.0;
//    self.scanProgressView.maxValue = 1.0;
//    self.scanProgressView.value = 0.0;
//    [self.scanProgressView setWantsLayer:YES];
}

- (void)scan:(NSArray<NSString *> *)scanPaths {
    self.resultData = [NSMutableArray array];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.resultData removeAllObjects];
        self.imageGroupCompare = [ImageGroupCompare new];
//        [self.imageGroupCompare stepCalater:scanPaths];
        [self.imageGroupCompare photoCompareWithPathArray:scanPaths];
    });
}

-(void) onScanResult:(NSNotification*)notificer {
    NSLog(@"LMPhotoCleaner--onScanResult:notificer");
    NSMutableArray *result = [notificer.object mutableCopy];
    [self showResultView:result withCancelAction:NO];
}

- (void)showResultView:(NSMutableArray*)result withCancelAction:(BOOL) isClickCancelAction{
    NSMutableArray<LMSimilarPhotoGroup *> *groupResult = [[NSMutableArray alloc] init];
    BOOL isDirectory;
    NSFileManager *fileManager = [NSFileManager defaultManager];
 
    for (NSMutableDictionary *dic in result) {
        LMSimilarPhotoGroup *group = [[LMSimilarPhotoGroup alloc] init];
        group.groupName = dic[SECTION_HEADER];
        
        NSString *preferPath = dic[PREFER_PATH];
        NSMutableArray *sumTempArray = [NSMutableArray new];
        if([dic.allKeys containsObject:SOURCE_PATH] ){
            NSString *sourcePath = [dic objectForKey:SOURCE_PATH];
            if (sourcePath != nil &&sourcePath.length > 0) {
                [sumTempArray addObject:dic[SOURCE_PATH]];
            }
        }
        NSArray *sectionArray = dic[CHILDREN];
        for (NSDictionary *dicTemp in sectionArray) {
            NSString *targetPath = [dicTemp objectForKey:TARGET_PATH];
            if(nil != targetPath){
                [sumTempArray addObject:[dicTemp objectForKey:TARGET_PATH]];
            }
        }
        
        for (NSString *path in sumTempArray) {
            LMPhotoItem *item = [[LMPhotoItem alloc] init];
            item.path = path;
            BOOL isExist = [fileManager fileExistsAtPath:item.path isDirectory:&isDirectory];
            if(!isExist) continue;
            item.imageSize = [self fileSizeAtPath:path];
            if ([path isEqualToString:preferPath]) {
                item.isPrefer = YES;
                item.isSelected = NO;
            } else {
                item.isPrefer = NO;
                item.isSelected = YES;
            }
            [group.items addObject:item];
        }
        if(group.items.count > 0){
            [groupResult addObject:group];
        }
    }
    NSLog(@"LMPhotoCleaner--->showResultView_groupResult.count:%lu",(unsigned long)[groupResult count]);
//    for(LMSimilarPhotoGroup *group in groupResult){
//        NSLog(@"LMPhotoCleaner--->groupResult_groupName:%@, groupCount:%d",group.groupName,group.items.count);
//    }
    if ([groupResult count] == 0) {
        NSLog(@"LMPhotoCleaner--->showResultView_groupResult_count_0");
        if (isClickCancelAction) {
            [self.view.window.windowController showNoSimilarPhotoViewController:NSLocalizedStringFromTableInBundle(@"LMScanViewController_showResultView_1553065843_1", nil, [NSBundle bundleForClass:[self class]], @"")];
        } else {
            [self.view.window.windowController showNoSimilarPhotoViewController:NSLocalizedStringFromTableInBundle(@"LMScanViewController_showResultView_1553065843_2", nil, [NSBundle bundleForClass:[self class]], @"")];
        }
    } else {
        NSMutableArray <LMSimilarPhotoGroup *>*resultDateForShowVC = (NSMutableArray <LMSimilarPhotoGroup *>*)[groupResult sortedArrayWithOptions:NSSortStable usingComparator:
                                                                                                  ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
           LMSimilarPhotoGroup *value1 =  (LMSimilarPhotoGroup*)obj1;
           LMSimilarPhotoGroup *value2 =  (LMSimilarPhotoGroup*)obj2;
           NSString *groupName1 = nil;
           NSString *groupName2 = nil;
           if ([LanguageHelper getCurrentSystemLanguageType] ==SystemLanguageTypeChinese) {
               groupName1 = [value1.groupName stringByReplacingOccurrencesOfString:@"年" withString:@""];
               groupName1 = [groupName1 stringByReplacingOccurrencesOfString:@"月" withString:@""];
               groupName1 = [groupName1 stringByReplacingOccurrencesOfString:@"日" withString:@""];
                                                                                                          
               groupName2 = [value2.groupName stringByReplacingOccurrencesOfString:@"年" withString:@""];
               groupName2 = [groupName2 stringByReplacingOccurrencesOfString:@"月" withString:@""];
               groupName2 = [groupName2 stringByReplacingOccurrencesOfString:@"日" withString:@""];
           }else{
               groupName1 = [value1.groupName stringByReplacingOccurrencesOfString:@"-" withString:@""];
               groupName2 = [value2.groupName stringByReplacingOccurrencesOfString:@"-" withString:@""];
           }
                                                                                                      
           if ([groupName1 intValue] < [groupName2 intValue]) {
               return NSOrderedDescending;
           }else if ([groupName1 intValue] == [groupName2 intValue]){
              return NSOrderedSame;
           }else{
              return NSOrderedAscending;
           }
           }];
        for(LMSimilarPhotoGroup *group in resultDateForShowVC){
            NSLog(@"LMPhotoCleaner--->resultDateForShowVC_groupName:%@",group.groupName);
        }
       
        [self.view.window.windowController showResultView: resultDateForShowVC];
        [self.imageGroupCompare cancelScan];
        self.imageGroupCompare = nil;
    }
}

- (double)fileSizeAtPath:(NSString*)filePath
{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

- (IBAction)actionCancel:(id)sender {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self showResultView:[self.imageGroupCompare.resultData mutableCopy] withCancelAction:YES];
    [self.imageGroupCompare cancelScan];
    self.imageGroupCompare = nil;
}

-(void)dealloc{
    NSLog(@"Super Dealloc _______________________ ，%@",[self className]);
}

@end
