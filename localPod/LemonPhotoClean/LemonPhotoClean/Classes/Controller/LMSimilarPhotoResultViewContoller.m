//
//  LMSimilarPhotoResultViewContoller.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMSimilarPhotoResultViewContoller.h"
#import "LMPhotoCollectionViewLayout.h"
#import "LMPhotoViewItem.h"
#import "LMPhotoItem.h"
#import "LMPhotoCollectionViewHeader.h"
#import "LMPhotoCleanerWndController.h"
#import "SimilatorPhotosPreviewView.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMViewHelper.h>
#import <CoreImage/CoreImage.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/MMScroller.h>
#import "PhotoCleanerBlurView.h"
#import <QMCoreFunction/NSString+Extension.h>
#import <QMCoreFunction/NSButton+Extension.h>
#import <QMUICommon/LMGradientTitleButton.h>
#import <QMCoreFunction/NSTextField+Extension.h>
#import <QMUICommon/COSwitch.h>
#import <QMUICommon/LMAppThemeHelper.h>

@interface LMSimilarPhotoResultViewContoller () <NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout,NSCollectionViewDelegate>
@property (weak) IBOutlet NSTextField *textTotalNumDescription;
@property (weak) IBOutlet NSTextField *textDesciption;
@property (weak) IBOutlet NSCollectionView *collectionView;
@property (nonatomic,nonnull) NSButton *operateButton;
@property (nonatomic,nonnull) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSScrollView *containerScrollView;
@property (weak) NSButton *intelligentSelectBtn;
@property (atomic) NSInteger  totalDeelteSizeFromSelfDefineFloder;
@property (atomic) NSInteger  totalDeelteSizeFromPhotos;
@property (atomic) SimilatorPhotosPreviewView *similatorPhotosPreviewView;
@property Boolean isIntelligentSelect;//是否选择“智能选择”

@property NSInteger selectPhotoTotalNummber;
@property NSInteger totalNumber;

@property (weak) LMGradientTitleButton *selectBtn;

@end


@implementation LMSimilarPhotoResultViewContoller

- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        //myBundle = [NSBundle bundleForClass:[self class]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_cancelButton setTitle:NSLocalizedStringFromTableInBundle(@"LMSimilarPhotoResultViewContoller_viewDidLoad_cancelButton_1", nil, [NSBundle bundleForClass:[self class]], @"") withColor:[NSColor colorWithHex:0x94979b]];
//    _cancelButton b
    self.operateButton = [LMViewHelper createNormalGreenButton:20 title:NSLocalizedStringFromTableInBundle(@"LMSimilarPhotoResultViewContoller_viewDidLoad_1553065843_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.view addSubview:self.operateButton];
    self.operateButton.target = self;
    self.operateButton.action = @selector(actionClean);
    __weak LMSimilarPhotoResultViewContoller *weakSelf = self;
    [self.operateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(148);
        make.height.mas_equalTo(48);
        make.bottom.equalTo(weakSelf.view).offset(-394);
        make.left.equalTo(weakSelf.view).offset(592);
    }];
    [self.operateButton setEnabled:YES];
    
    [self addIntelligentSelectView];
    self.isIntelligentSelect = true;
    
    MMScroller *scroller = [[MMScroller alloc] init];
    [self.containerScrollView  setVerticalScroller:scroller];
    [self.containerScrollView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
    
    if (@available(macOS 10.11, *)) {
        self.collectionView.collectionViewLayout = [[LMPhotoCollectionViewLayout alloc] init];
        self.collectionView.backgroundColors  = @[[LMAppThemeHelper getMainBgColor]];
        
        NSNib *itemNib = [[NSNib alloc]initWithNibNamed:@"LMPhotoViewItem" bundle:[NSBundle bundleForClass:self.class]];
        [self.collectionView registerNib:itemNib forItemWithIdentifier:@"LMPhotoViewItem"];
        
        NSNib *headerNib = [[NSNib alloc] initWithNibNamed:@"PhotoCollectionViewHeader" bundle:[NSBundle bundleForClass:[self class]]];
        [self.collectionView registerNib:headerNib forSupplementaryViewOfKind:NSCollectionElementKindSectionHeader withIdentifier:@"PhotoCollectionViewHeader"];
        
    } else {
        //       LMPhotoViewItem *itemPrototype = [[LMPhotoViewItem alloc]initWithNibName:@"LMPhotoViewItem" bundle:nil];
        LMPhotoViewItem *itemPrototype = [[LMPhotoViewItem alloc]initWithNibName:@"LMPhotoViewItem" bundle:[NSBundle bundleForClass:self.class]];
        self.collectionView.itemPrototype = itemPrototype;
        self.collectionView.content = [self getUnDeleteSimilarPhotoGroups];
    }
    
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onItemDeleted:) name:LM_NOTIFICATION_ITEM_DELECTED object:nil];//不知道这个通知拿了干啥？？？
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(descriptionView:) name:LM_NOTIFICATION_ITEM_UPDATESELECT object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadCollectionView) name:LM_NOTIFICATION_RELOAD object:nil];
    
    self.totalDeelteSizeFromSelfDefineFloder = 0;
    self.totalDeelteSizeFromPhotos = 0;
    
    [self addPreviewView];
    
    
    [self->_cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(weakSelf.textTotalNumDescription.mas_right).offset(20);
        make.centerY.equalTo(weakSelf.textTotalNumDescription);
        make.width.equalTo(@50);
        make.height.equalTo(@23);
    }];
    
    [self->_textTotalNumDescription mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(weakSelf.view).offset(142);
        make.bottom.equalTo(weakSelf.view).offset(-410);
    }];
    
    [self setTitleColorForTextField:self.textTotalNumDescription];
}

-(void)addIntelligentSelectView{
    COSwitch *intelligentSelectBtn = [[COSwitch alloc] init];
    [self.view addSubview:intelligentSelectBtn];
    intelligentSelectBtn.on = YES;
    __weak LMSimilarPhotoResultViewContoller *weakSelf = self;
    [intelligentSelectBtn setOnValueChanged:^(COSwitch *button) {
        [weakSelf intelligentSelect];
    }];
    [intelligentSelectBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@33);
        make.height.equalTo(@17);
        make.top.equalTo(self.operateButton.mas_bottom).offset(20);
        make.right.equalTo(self.operateButton.mas_right);
       
    }];
    
    NSTextField *textField = [NSTextField labelWithStringCompat:NSLocalizedStringFromTableInBundle(@"LMSimilarPhotoResultViewContoller_intelligentSelect_text", nil, [NSBundle bundleForClass:[self class]], @"")];
    [textField setFont:[NSFont systemFontOfSize:14]];
    [textField setTextColor:[NSColor colorWithHex:0x94979B]];
    [self.view addSubview:textField];
    [textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(intelligentSelectBtn.mas_centerY);
        make.right.equalTo(intelligentSelectBtn.mas_left).offset(-8);
    }];
}

//-(LMGradientTitleButton *)createSelectBtn{
//    LMGradientTitleButton *selectBtn = [[LMGradientTitleButton alloc] initWithFrame:NSMakeRect(580, 2, 100, 20)];
//    selectBtn.title = NSLocalizedStringFromTableInBundle(@"LMPhotoCollectionViewHeader_initWithCoder_ok_1", nil, [NSBundle bundleForClass:[self class]], @"");
//    selectBtn.titleNormalColor = [NSColor colorWithHex:0x057cff];
//    selectBtn.titleHoverColor = [NSColor colorWithHex:0x2998ff];
//    selectBtn.titleDownColor = [NSColor colorWithHex:0x0a6ad4];
//    selectBtn.isGradient = NO;
//    selectBtn.isBorder = NO;
//    selectBtn.font = [NSFont systemFontOfSize:12];
//    selectBtn.target = self;
//    selectBtn.lineWidth = 0;
//    selectBtn.action = @selector(intelligentSelect);
//    return selectBtn;
//}

-(void)intelligentSelect{
    _isIntelligentSelect = !_isIntelligentSelect;
    
    for (LMSimilarPhotoGroup *group in self.similarPhotoGroups) {
        for (LMPhotoItem *item in group.items) {
            if(!item.isPrefer){
                item.isSelected = _isIntelligentSelect;
            }else{
                item.isSelected = NO;
            }
            
        }
//        [self caculateImageSize:group];
    }
    [self updateTextDescription];
    if (@available(macOS 10.11, *)) {
        [self.collectionView reloadData];
    } else {
        // Fallback on earlier versions
    }
}

- (void)addPreviewView{
    __weak LMSimilarPhotoResultViewContoller *weakSelf = self;
    @autoreleasepool {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                //                [self.view lockFocus];
                //                NSImage *image = [[NSImage alloc]initWithData:[self.view dataWithPDFInsideRect:[self.view bounds]]];
                //                [self.view unlockFocus];
                
                NSImage *bgImage = [PhotoCleanerBlurView blur:weakSelf.view frame:CGRectMake(0, 0, 780, 478)];
                weakSelf.similatorPhotosPreviewView = [[SimilatorPhotosPreviewView alloc]initWithFrame:weakSelf.view.bounds];
                [weakSelf.similatorPhotosPreviewView drawContentviewWithBgimage:bgImage];
                [weakSelf.view addSubview:weakSelf.similatorPhotosPreviewView];
                weakSelf.similatorPhotosPreviewView.hidden = YES;
            });
        });
    }
}

- (void)viewDidAppear {
    [super viewDidAppear];
}

- (void)reloadCollectionView{
    [self changeRootViewStatus:!self.similatorPhotosPreviewView.hidden];
    if (@available(macOS 10.11, *)) {
        [self.collectionView reloadData];
    } else {
        // Fallback on earlier versions
    }
    [self descriptionView:nil];
}

- (void)updateScanResult:(NSMutableArray *)result {
    [self.similarPhotoGroups removeAllObjects];
    self.similarPhotoGroups = [result mutableCopy];
    if (@available(macOS 10.11, *)) {
        [self.collectionView reloadData];
    } else {
        // Fallback on earlier versions
    }
    [self descriptionView:nil];
}

- (NSMutableArray<LMSimilarPhotoGroup *> *)getUnDeleteSimilarPhotoGroups{
    NSMutableArray<LMSimilarPhotoGroup *> *unDeleteSimilarPhotoGroups = [[NSMutableArray alloc]init];
    for (NSInteger index = 0; index < self.similarPhotoGroups.count; index ++) {
        if ([self.similarPhotoGroups count] <= index) {
            break;
        }
        LMSimilarPhotoGroup *group = [self.similarPhotoGroups objectAtIndex:index];
        if (group.isDeleted == NO) {
            if (group != nil) {
                [unDeleteSimilarPhotoGroups addObject:group];
            }
        }
    }
    return unDeleteSimilarPhotoGroups;
}

- (LMSimilarPhotoGroup *)getUnDeleteSimilarPhotoItem:(LMSimilarPhotoGroup *)unDeleteSimilarPhotoGroup{
    LMSimilarPhotoGroup *viewItemGroup = [[LMSimilarPhotoGroup alloc]init];
    for (NSInteger index = 0; index < unDeleteSimilarPhotoGroup.items.count; index ++) {
        LMPhotoItem *Item = [unDeleteSimilarPhotoGroup.items objectAtIndex:index];
        if (Item.isDeleted == NO) {
            if (Item != nil) {
                [viewItemGroup.items addObject:Item];
            }
        }
    }
    return viewItemGroup;
}

- (void)changeRootViewStatus:(BOOL)isHidden{
    self.operateButton.hidden = isHidden;
    self.collectionView.hidden = isHidden;
    self.cancelButton.hidden = isHidden;
}

#pragma mark NSCollectionViewDataSource Methods
- (nonnull NSCollectionViewItem *)collectionView:(nonnull NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(nonnull NSIndexPath *)indexPath {
//    double t = [[NSDate date] timeIntervalSince1970];
//    NSLog(@"updateCollectionViewByPath collectionView itemForRepresentedObjectAtIndexPath start time:%f",t);
    LMSimilarPhotoGroup *group ;
    LMPhotoViewItem *viewItem;
    NSInteger itemIndex = 0;
    
    if (@available(macOS 10.11, *)) {
        NSInteger sectionIndex = indexPath.section;
        itemIndex = indexPath.item;
//        NSLog(@"indexPath---indexItem:%ld",(long)itemIndex);
//        NSLog(@"indexPath---sectionIndex:%ld",(long)sectionIndex);
        viewItem =  [collectionView makeItemWithIdentifier:@"LMPhotoViewItem" forIndexPath:indexPath];
        
        if (sectionIndex >= [self.similarPhotoGroups count]) {
            return nil;
        }
        
//        group = [self getUnDeleteSimilarPhotoGroups][sectionIndex];   //不明白为什么y这样操作？
        group = self.similarPhotoGroups[sectionIndex];
    } else {
        // Fallback on earlier versions
    }
    
    if (itemIndex >= [group.items count]) {
        return nil;
    }
    
//    viewItem.representedObject = [self getUnDeleteSimilarPhotoItem: group].items[itemIndex];//不明白为什么y这样操作？
    viewItem.representedObject = group.items[itemIndex];
//    double t2 = [[NSDate date] timeIntervalSince1970];
//    NSLog(@"updateCollectionViewByPath collectionView itemForRepresentedObjectAtIndexPath end time:%f",t2);
    return viewItem;
}

-(BOOL)collectionView:(NSCollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths{
    LMSimilarPhotoGroup *group;
    if (@available(macOS 10.11, *)) {
        NSInteger sectionIndex = indexPaths.allObjects.firstObject.section;
        group = [self getUnDeleteSimilarPhotoGroups][sectionIndex];
    } else {
        // Fallback on earlier versions
    }
    self.similatorPhotosPreviewView.hidden = NO;
    [self changeRootViewStatus:!self.similatorPhotosPreviewView.hidden];
    if (@available(macOS 10.11, *)) {
        [self.similatorPhotosPreviewView showSimilatorPhotosGroup:group firstShow:indexPaths.allObjects.firstObject.item];
    } else {
        // Fallback on earlier versions
    }
}

- (NSInteger)collectionView:(nonnull NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSArray *unDeleteSimilarPhotoGroups = [self getUnDeleteSimilarPhotoGroups];
    if ([unDeleteSimilarPhotoGroups count] <= section) {
        return 0;
    }
    
    NSInteger numberOfItemsInSection = 0;
    for (LMPhotoItem *item in self.similarPhotoGroups[section].items) {
        if (item.isDeleted == NO) {
            numberOfItemsInSection ++;
        }
    }
    return numberOfItemsInSection;
}

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
    return self.similarPhotoGroups.count;
}

- (NSView *)collectionView:(NSCollectionView *)collectionView viewForSupplementaryElementOfKind:(NSCollectionViewSupplementaryElementKind)kind atIndexPath:(NSIndexPath *)indexPath {
//    double ts = [[NSDate date] timeIntervalSince1970];
//    NSLog(@"updateCollectionViewByPath collectionView start update time:%f",ts);
    if (@available(macOS 10.11, *)) {
        if (![kind isEqual:NSCollectionElementKindSectionHeader]) {
            return nil;
        }
    } else {
        // Fallback on earlier versions
    }
    NSInteger sectionIndex = 0;
    LMPhotoCollectionViewHeader *supplementaryView;
    if (@available(macOS 10.11, *)) {
        supplementaryView = [collectionView makeSupplementaryViewOfKind:kind withIdentifier:@"PhotoCollectionViewHeader" forIndexPath:indexPath];
        sectionIndex = indexPath.section;
    }
//    __block LMSimilarPhotoGroup *group = [self getUnDeleteSimilarPhotoGroups][sectionIndex];
      LMSimilarPhotoGroup *group = self.similarPhotoGroups[sectionIndex];
    int selectCount = 0;//用于更新LMPhotoCollectionViewHeader中的全选框状态
//    for (LMPhotoItem *item in [self getUnDeleteSimilarPhotoItem:group].items) {
     for (LMPhotoItem *item in group.items) {
        if(item.isSelected){
            selectCount++;
        }
    }
//    if(selectCount == [self getUnDeleteSimilarPhotoItem:group].items.count){
    if(selectCount == group.items.count){
        supplementaryView.checkBtn.state = NSOnState;
    }else if(selectCount == 0){
        supplementaryView.checkBtn.state = NSOffState;
    }else{
        supplementaryView.checkBtn.state = NSMixedState;
    }
   
    if (supplementaryView) {
        NSTextField *textField = supplementaryView.textTitle;
        textField.stringValue = group.groupName == nil?@"":group.groupName;
        __weak typeof(supplementaryView)weakSupplementaryView = supplementaryView;
        __weak typeof(self)weakSelf = self;
        supplementaryView.checkButtonEvent = ^{
            if(weakSupplementaryView.checkBtn.state == NSOnState){
//                for(LMPhotoItem *item in [weakSelf getUnDeleteSimilarPhotoItem:group].items){
                for(LMPhotoItem *item in group.items){
                    item.isSelected = YES;
                }
            }else{
               for(LMPhotoItem *item in group.items){
                    item.isSelected = NO;
                }
            }
//            [weakSelf caculateImageSize:group];
            [weakSelf updateTextDescription];
        };
    }
//    double t = [[NSDate date] timeIntervalSince1970];
//    NSLog(@"updateCollectionViewByPath collectionView end update time:%f",t);
    return supplementaryView;
}

#pragma mark NSCollectionViewDelegateFlowLayout Methods
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section  API_AVAILABLE(macos(10.11)){
    // width无所谓会被设成和collectionView一样宽
    return NSMakeSize(100, HEADER_HEIGHT) ;
}

- (void) descriptionView:(NSNotification *)notifly {
    if(self.similatorPhotosPreviewView !=nil && self.similatorPhotosPreviewView.hidden == NO){
        return;
    }
    [self updateDescription:notifly];
//    __weak LMSimilarPhotoResultViewContoller *weakSelf = self;
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        [weakSelf updateDescription:notifly];
//    });
}

/**
 根据item的选项更新界面显示
 
 @param notify <#notify description#>
 */
- (void)updateDescription:(NSNotification *)notify {
    [self updateTextDescription];
    if(notify != nil){
        NSString *path = [notify.userInfo objectForKey:LM_NOTIFICATION_ITEM_UPDATESELECT_PATH];
        [self updateCollectionViewByPath: path];
    }
    
}

/**
 更新collectionView显示

 @param path 点击的item的路径
 */
-(void)updateCollectionViewByPath:(NSString *)path{
    __weak LMSimilarPhotoResultViewContoller *weakSelf = self;
    NSMutableSet *reloadSet = [NSMutableSet set];
    NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
//    NSMutableArray<LMSimilarPhotoGroup *> * unDeleteSimilarPhotoGroups = [self getUnDeleteSimilarPhotoGroups];
    for (NSInteger i = 0;i < self.similarPhotoGroups.count; i++) { // section
            LMSimilarPhotoGroup *group  = nil;
        @try {
            group  = self.similarPhotoGroups[i];
        } @catch (NSException *exception) {
            NSLog(@"exception updateDescription = %@", exception);//多线程可能会导致crash，临时采用捕获异常的方式
            continue;
        }
        
//        NSMutableArray *array = [self getUnDeleteSimilarPhotoItem:group].items;
        NSMutableArray *array = group.items;
//        double startTime = [[NSDate date] timeIntervalSince1970];
//        NSLog(@"updateCollectionViewByPath find start time:%f",startTime);
        for (NSInteger j = 0; j < [array count]; j++) {           // item
            LMPhotoItem *item = array[j];
            if([item.path isEqualToString:path]){
                if (@available(macOS 10.11, *)) {
                    [reloadSet addObject:[NSIndexPath indexPathForItem:j inSection:i]];
                    [indexSet addIndex:i];
//                    double t = [[NSDate date] timeIntervalSince1970];
//                    NSLog(@"updateCollectionViewByPath find out end time:%f",t);
                    dispatch_async(dispatch_get_main_queue(), ^{ //放在队列中会降低更新速度
                        // 在 10.11 系统上 reloadSection 可能会造成排序不对?(需要验证) 只能使用 reloadItemsAtIndexPaths
                        if (@available(macOS 10.11, *)) {
                            // 10.13 上使用reloadItemsAtIndexPaths 会造成 header 无法刷新,所以仍然需要使用reloadSections
                            if (@available(macOS 10.13, *)) {
//                                double tt = [[NSDate date] timeIntervalSince1970];
//                                NSLog(@"updateCollectionViewByPath reloadSection end time:%f",tt);
                                [weakSelf.collectionView reloadSections: indexSet];
                            }else{
                                //                     [self.collectionView reloadItemsAtIndexPaths:reloadSet];
                                [weakSelf.collectionView reloadData];
                            }
                        } else {
                            // Fallback on earlier versions
                        }
                    });
                    return;
                } else {
                }
                
            }
        }
    }
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        // 在 10.11 系统上 reloadSection 可能会造成排序不对?(需要验证) 只能使用 reloadItemsAtIndexPaths
//        if (@available(macOS 10.11, *)) {
//            // 10.13 上使用reloadItemsAtIndexPaths 会造成 header 无法刷新,所以仍然需要使用reloadSections
//            if (@available(macOS 10.13, *)) {
//                [weakSelf.collectionView reloadSections: indexSet];
//            }else{
//                //                     [self.collectionView reloadItemsAtIndexPaths:reloadSet];
//                [weakSelf.collectionView reloadData];
//            }
//        } else {
//            // Fallback on earlier versions
//        }
//    });
    
}

/**
 更新文字描述，包括选择的照片数量、大小
 */
-(void)updateTextDescription{
    double selectPhotoTotalSize = 0.0;
    NSInteger selectPhotoTotalNummber = 0;
    
    NSInteger totalNummber = 0;
    for (LMSimilarPhotoGroup *group in self.similarPhotoGroups) {
        for (LMPhotoItem *item in group.items) {
            totalNummber ++;
            if(item.isSelected){
                selectPhotoTotalSize = selectPhotoTotalSize + item.imageSize;
                selectPhotoTotalNummber++;
            }
        }
    }
    
    NSString *selectPhotoTotalSizeStr = [self getDeletePictureSizeDescription:selectPhotoTotalSize];
    __weak LMSimilarPhotoResultViewContoller *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.textTotalNumDescription.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMSimilarPhotoResultViewContoller_updateDescription_textTotalNumDescription_1", nil, [NSBundle bundleForClass:[weakSelf class]], @""), totalNummber];
        NSString *textDesciptionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMSimilarPhotoResultViewContoller_updateDescription_textDesciptionString _2", nil, [NSBundle bundleForClass:[weakSelf class]], @""), selectPhotoTotalNummber,selectPhotoTotalSizeStr];
        
        NSString *selectPhotoTotalNummberString = [NSString stringWithFormat:@"%ld",selectPhotoTotalNummber];
        NSRange rangeSelectNum = [textDesciptionString rangeOfString:selectPhotoTotalNummberString];
        
        NSRange rangeSelectSize = [textDesciptionString rangeOfString:selectPhotoTotalSizeStr];
        
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc]initWithString:textDesciptionString];
        [attrStr addAttributes:@{NSForegroundColorAttributeName: [NSColor colorWithHex:0xFFAA09]}
                         range:rangeSelectNum];
        [attrStr addAttributes:@{NSForegroundColorAttributeName: [NSColor colorWithHex:0xFFAA09]}
                         range:rangeSelectSize];
        weakSelf.textDesciption.attributedStringValue = attrStr;
        if(selectPhotoTotalNummber == 0){
            if(weakSelf.operateButton.enabled == YES){
                [weakSelf.operateButton setEnabled:NO];
            }
        } else {
            if(weakSelf.operateButton.enabled == NO){
                [weakSelf.operateButton setEnabled:YES];
            }
        }
        self.selectPhotoTotalNummber = selectPhotoTotalNummber;
        self.totalNumber = totalNummber;
    });
}

#pragma notification
- (void) onItemDeleted:(NSNotification *)notifly {
    __block LMSimilarPhotoGroup *group = [notifly object];
    //    __block NSInteger groupIndex = [self.similarPhotoGroups indexOfObject:[notifly object]];
    
    group.isDeleted = YES;
    for (LMPhotoItem *item in group.items) {
        if (!item.isDeleted) {
            group.isDeleted = NO;
        }
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf descriptionView:nil];
        //        if (group.isDeleted == YES){
        if (@available(macOS 10.11, *)) {
            [weakSelf.collectionView reloadData];
        } else {
            // Fallback on earlier versions
        }
        //        } else {
        //            [weakSelf.collectionView reloadSections: [NSIndexSet indexSetWithIndex:groupIndex]];
        //        }
    });
    
    if([self getUnDeleteSimilarPhotoGroups].count == 0){
        [self.view.window.windowController showCleanFinishView:0];
    }
}

- (NSArray*)caculateImageSize:(LMSimilarPhotoGroup *)group{
    NSString *photoPath = [NSString stringWithFormat:@"%@/Pictures", [NSString getUserHomePath]];
    NSString *photoslibraryPath = @"photoslibrary";
    for (LMPhotoItem *item in group.items) {
        if(!item.isSelected){
            continue;
        }
        if ([item.path containsString: photoPath]&&[item.path containsString: photoslibraryPath]) {
            self.totalDeelteSizeFromSelfDefineFloder += item.imageSize;
        } else {
            self.totalDeelteSizeFromPhotos += item.imageSize;
        }
    }
    
    return @[[self getDeletePictureSizeDescription:self.totalDeelteSizeFromSelfDefineFloder],[self getDeletePictureSizeDescription:self.totalDeelteSizeFromPhotos]];
}

- (NSString*)getDeletePictureSizeDescription:(NSInteger)fileSize{
    NSString *deletePictureSizeDescription = @"";
    fileSize /= 1000;
    if (fileSize > 1000*1000*1000) {
        deletePictureSizeDescription = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMSimilarPhotoResultViewContoller_getDeletePictureSizeDescription_1553065843_1", nil, [NSBundle bundleForClass:[self class]], @""),fileSize*1.0/(1000*1000*1000)];
    }else if (fileSize > 1000*1000) {
        deletePictureSizeDescription = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMSimilarPhotoResultViewContoller_getDeletePictureSizeDescription_1553065843_2", nil, [NSBundle bundleForClass:[self class]], @""),fileSize*1.0/(1000*1000)];
    } else {
        deletePictureSizeDescription = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMSimilarPhotoResultViewContoller_getDeletePictureSizeDescription_1553065843_3", nil, [NSBundle bundleForClass:[self class]], @""),fileSize*1.0/(1000)];
    }
    return deletePictureSizeDescription;
}

#pragma mark action
- (IBAction)actionReturn:(id)sender {
    [self.view.window.windowController showAddView];
    [self cancelAllOptionAndData];
}

-(void)cancelAllOptionAndData{
    self.similarPhotoGroups = nil;
    [self.similatorPhotosPreviewView removeFromSuperview];
    self.similatorPhotosPreviewView = nil;
    [LMPhotoItem cancelAllPreviewLoadingOperationQueue];
}

- (IBAction)actionClean {
//    [self test];
//    return;
    [self.view.window.windowController showCleanView:self.similarPhotoGroups];
    [self cancelAllOptionAndData];
}

-(void)test{
     _isIntelligentSelect = !_isIntelligentSelect;
    for (LMSimilarPhotoGroup *group in self.similarPhotoGroups) {
        for (LMPhotoItem *item in group.items) {
            item.isSelected = _isIntelligentSelect;
           
        }
        [self caculateImageSize:group];
    }
    
    [self updateDescription:nil];
}

-(void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)dealloc{
    [self cancelAllOptionAndData];
    NSLog(@"Super Dealloc _______________________ ，%@",[self className]);
}

@end
