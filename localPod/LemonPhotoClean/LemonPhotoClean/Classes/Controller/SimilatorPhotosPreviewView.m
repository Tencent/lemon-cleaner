//
//  SimilatorPhotosPreviewView.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "SimilatorPhotosPreviewView.h"
#import "LMPhotoPreviewCollectionViewLayout.h"
#import "LMPhotoViewItem.h"
#import <QMUICommon/LMViewHelper.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMBackButton.h>
#import <QMUICommon/LMRectangleButton.h>
#import <QMUICommon/LMPathBarView.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/MMScroller.h>
#import <QMUICommon/LMAppThemeHelper.h>

@interface SimilatorPhotosPreviewView ()<NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout,NSCollectionViewDelegate>
@property (nonatomic) NSCollectionView *collectionView;
@property (nonatomic) LMSimilarPhotoGroup *localSimilarPhotoGroup;
@property (nonatomic) LMSimilarPhotoGroup *similarPhotoGroupsCopy;
@property (nonatomic) LMSimilarPhotoGroup *localSimilarPhotoGroupCopy;
@property (nonatomic) NSView *contentView;

@property (nonatomic) NSImageView *preView;

@property (nonatomic) NSTextField *descriptionTextField;
@property (nonatomic) NSTextField *dateTextField;
@property (nonatomic) LMPathBarView *pathBarView;
@property (nonatomic) NSButton *magnifyingGlassButton;
@property (nonatomic) NSButton *confirmButton;
@property (nonatomic) LMGradientTitleButton *cancelButton;
@property (nonatomic) NSProgressIndicator* indicator;

@property (nonatomic) NSInteger selectIndex;

@property (nonatomic) NSTextField *imageNotExistDescriptionTextField;

@end

@implementation SimilatorPhotosPreviewView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [self setWantsLayer:YES];
    [self.layer setBackgroundColor:[[LMAppThemeHelper getMainBgColor] CGColor]];
    self.contentView.layer.backgroundColor = [LMAppThemeHelper getMainBgColor].CGColor;
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.contentView];
    
    //    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(descriptionView) name:LM_NOTIFICATION_PREVIEWITEM_UPDATESELECT object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(descriptionView:) name:LM_NOTIFICATION_ITEM_UPDATESELECT object:nil];
}

- (void)drawContentviewWithBgimage:(NSImage*)image{
    NSImageView *imageView = [[NSImageView alloc]initWithFrame:self.bounds];
    imageView.image = image;
    [self addSubview:imageView];
    
    self.contentView = [[NSView alloc]initWithFrame:NSMakeRect(87, 54, 600, 371)];
    
    [self addSubview:self.contentView];
    CALayer *borderLayer = [[CALayer alloc] init];
    borderLayer.borderColor = [NSColor colorWithHex:0x000000 alpha:0.05].CGColor;
    borderLayer.borderWidth = 1;
    borderLayer.cornerRadius = 2;
    borderLayer.backgroundColor = [LMAppThemeHelper getMainBgColor].CGColor;
    self.contentView.layer = borderLayer;
    
    [self addCollectionView];
    [self addPreview];
    [self addIndicatorView];
    
    [self addDescriptionTextField];
    [self addDateTextField];
    [self addConfirmButton];
//    [self addCancelButton];
    [self addPathTextField];
    [self addRevertFinder];
    [self addImageNotExistDescriptionTextField];
}

- (void)showSimilatorPhotosGroup:(LMSimilarPhotoGroup *)similarPhotoGroups firstShow:(NSInteger)index{
    self.similarPhotoGroupsCopy = similarPhotoGroups;
    
    self.localSimilarPhotoGroup = [[LMSimilarPhotoGroup alloc] init];
    self.localSimilarPhotoGroup.groupName = similarPhotoGroups.groupName;
    for (NSInteger index = 0; index < similarPhotoGroups.items.count; index++) {
        LMPhotoItem *item = similarPhotoGroups.items[index];
        [self.localSimilarPhotoGroup.items addObject:[item mutableCopy]];
    }
    
    self.localSimilarPhotoGroupCopy = [[LMSimilarPhotoGroup alloc] init];
    self.localSimilarPhotoGroupCopy.groupName = similarPhotoGroups.groupName;
    //    self.localSimilarPhotoGroupCopy.items = [similarPhotoGroups.items mutableCopy];
    for (NSInteger index = 0; index < similarPhotoGroups.items.count; index++) {
        LMPhotoItem *item = similarPhotoGroups.items[index];
        [self.localSimilarPhotoGroupCopy.items addObject:[item mutableCopy]];
    }
    
    [self descriptionView];
    [self.dateTextField setStringValue:self.localSimilarPhotoGroup.groupName == nil ?@"":self.localSimilarPhotoGroup.groupName];
    
    LMPhotoItem *item = [self getUnDeleteSimilarPhotoItem: self.localSimilarPhotoGroup].items[index];
    self.selectIndex = index;
    [self showBigPrivew:item];
    
    if (@available(macOS 10.11, *)) {
        [self.collectionView reloadData];
        NSIndexPath *indexpath = [NSIndexPath indexPathForItem:0 inSection:index];
//        self.collectionView.selectionIndexPaths
        [self.collectionView selectItemsAtIndexPaths:[NSSet setWithObjects:indexpath, nil] scrollPosition:NSCollectionViewScrollPositionCenteredVertically];
    } else {
        
        // Fallback on earlier versions
    }
}

- (void)showBigPrivew:(LMPhotoItem*)item{
    BOOL isDirectory;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:item.path isDirectory:&isDirectory];
    
    if(isExist){
//        self.preView.image = [self swatchWithColor:[NSColor whiteColor] size:self.preView.frame.size];
        self.indicator.hidden = NO;
        [self.indicator startAnimation:self.indicator];
        __weak typeof(self) weakself = self;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            __block NSImage *imageCopy = [self changeImage:item.path];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.indicator stopAnimation:weakself.indicator];
                weakself.indicator.hidden = YES;
                weakself.preView.image = imageCopy;
            });
        });
        
        self.imageNotExistDescriptionTextField.hidden = YES;
        
        self.magnifyingGlassButton.hidden = NO;
        self.pathBarView.hidden = NO;
    } else {
        self.preView.image = [NSImage imageNamed:@"deletedTag" withClass:self.class];
        self.imageNotExistDescriptionTextField.hidden = NO;
        
        self.magnifyingGlassButton.hidden = YES;
        self.pathBarView.hidden = YES;
    }
    
    [self.pathBarView setPath:item.path];
}

- (void)addPreview{
    self.preView = [[NSImageView alloc]initWithFrame:NSMakeRect(20, 65, 450, 286)];
    [self.contentView addSubview:self.preView];
}

- (void)addIndicatorView{
    float width = self.preView.frame.size.width;
    float height = self.preView.frame.size.height;
    self.indicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect((width - 30)/2, (height - 30)/2, 30, 30)];
    [self addSubview:self.indicator];

    self.indicator.indeterminate = YES;
    self.indicator.bezeled = YES;
    self.indicator.controlSize = NSControlSizeRegular;
    self.indicator.style = NSProgressIndicatorSpinningStyle;
    self.indicator.displayedWhenStopped = YES;
    [self.indicator setUsesThreadedAnimation:YES];

    [self.indicator setHidden:YES];
}

- (void)addDescriptionTextField{
    self.descriptionTextField = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x7E7E7E]];
//    self.descriptionTextField.frame = NSMakeRect(20, 34, 200, 20);
    [self.contentView addSubview:self.descriptionTextField];
    [self.descriptionTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(20);
        make.bottom.equalTo(self.contentView).offset(-34);
    }];
}

- (void)addPathTextField{
    _pathBarView = [[LMPathBarView alloc] init];
    _pathBarView.rightAlignment = NO;
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc]initWithObjectsAndKeys: [NSColor colorWithHex:0x94979B],NSForegroundColorAttributeName, [NSFontHelper getLightSystemFont:12],NSFontAttributeName, nil];
    NSMutableDictionary *highMutableDic = [[NSMutableDictionary alloc]initWithObjectsAndKeys: [NSColor colorWithHex:0x94979B],NSForegroundColorAttributeName, [NSFontHelper getLightSystemFont:12],NSFontAttributeName, nil];
    
//    [self.pathBarView setNormalAttrs:mutableDic
//                       highlistAttrs:highMutableDic];
    [self.contentView addSubview:_pathBarView];
    _pathBarView.wantsLayer = YES;
    [self.pathBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.descriptionTextField.mas_right).offset(20);
        make.right.mas_equalTo(self.contentView.mas_right).offset(-170);
        make.bottom.mas_equalTo(self.descriptionTextField.mas_bottom).offset(0);
        make.height.mas_equalTo(self.descriptionTextField.mas_height);
    }];
}

- (void)addRevertFinder{
    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(190, 36, 16, 16)];
    button.imageScaling = NSImageScaleProportionallyUpOrDown;
    [button setBezelStyle:NSRegularSquareBezelStyle];
    [button setButtonType:NSButtonTypeMomentaryChange];
    button.imagePosition = NSImageOverlaps;
    button.state = NSControlStateValueOff;
    button.bordered = NO;
    button.image = [NSImage imageNamed:@"reveal_finder" withClass:self.class];
    button.action = @selector(revertFinderClick);
    button.target = self;
    button.stringValue = @"";
    button.title = @"";
    [self.contentView addSubview:button];
    self.magnifyingGlassButton = button;
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.pathBarView.mas_right).offset(10);
        make.centerY.equalTo(self.pathBarView);
        make.width.equalTo(@20);
        make.height.equalTo(@20);
    }];
}

- (void)addImageNotExistDescriptionTextField{
    self.imageNotExistDescriptionTextField = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x7E7E7E]];
    self.imageNotExistDescriptionTextField.alignment = NSTextAlignmentCenter;
    self.imageNotExistDescriptionTextField.frame = NSMakeRect(145, 155, 200, 17);
    [self.contentView addSubview:self.imageNotExistDescriptionTextField];
    [self.imageNotExistDescriptionTextField setStringValue:NSLocalizedStringFromTableInBundle(@"SimilatorPhotosPreviewView_addImageNotExistDescriptionTextField_imageNotExistDescriptionTextField_1", nil, [NSBundle bundleForClass:[self class]], @"")];
}

- (void)addDateTextField{
    self.dateTextField = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x7E7E7E]];
    self.dateTextField.frame = NSMakeRect(20, 13, 200, 20);
    [self.contentView addSubview:self.dateTextField];
}

- (void)addConfirmButton{
    self.confirmButton = [LMViewHelper createSmallGreenButton:14 title:NSLocalizedStringFromTableInBundle(@"SimilatorPhotosPreviewView_addConfirmButton_1553065843_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    self.confirmButton.frame = NSMakeRect(520, 10, 60, 24);
    [self.contentView addSubview:self.confirmButton];
    self.confirmButton.target = self;
    self.confirmButton.action = @selector(confirmButtonClicked);
}

- (void)addCancelButton{
    self.cancelButton = [[LMGradientTitleButton alloc] init];
    self.cancelButton.frame = NSMakeRect(450, 10, 60, 24);
    
    [self.contentView addSubview:self.cancelButton];
    self.cancelButton.title = NSLocalizedStringFromTableInBundle(@"SimilatorPhotosPreviewView_addCancelButton_cancelButton_1", nil, [NSBundle bundleForClass:[self class]], @"");
    self.cancelButton.target = self;
    self.cancelButton.action = @selector(cancelButtonClicked);
    self.cancelButton.isGradient = NO;
    self.cancelButton.radius = 3;
    self.cancelButton.font = [NSFont systemFontOfSize:12];
}

- (void)descriptionView{
    NSString *description = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"SimilatorPhotosPreviewView_descriptionView_description _1", nil, [NSBundle bundleForClass:[self class]], @""),(unsigned long)self.localSimilarPhotoGroup.items.count ,self.localSimilarPhotoGroup.selectedItemCount];
    NSString *selectedItemCountString = [NSString stringWithFormat:@"%d",self.localSimilarPhotoGroup.selectedItemCount];
    NSRange newRange = [description rangeOfString:selectedItemCountString options:NSBackwardsSearch];
    
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc]initWithString:description];
    [attrStr addAttributes:@{NSForegroundColorAttributeName: [NSColor colorWithHex:0xFFAA09]}
                     range:newRange];
    [attrStr addAttributes:@{NSFontAttributeName: [NSFontHelper getLightSystemFont:12]}
                     range:NSMakeRange(0, description.length)];
    
    [self.descriptionTextField setAttributedStringValue:attrStr];
}

- (void)addCollectionView{
    MMScroller *scroller = [[MMScroller alloc] init];
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(480, 65, 110, 286)];
    [scrollView setVerticalScroller:scroller];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setHasHorizontalScroller:YES];
    [scrollView setAutoresizesSubviews:YES];
    [scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    
    self.collectionView = [[NSCollectionView alloc]initWithFrame:NSMakeRect(0, 0, 100, 286)];
    self.collectionView.backgroundColors  = @[[LMAppThemeHelper getMainBgColor]];
    
    if (@available(macOS 10.11, *)) {
        self.collectionView.collectionViewLayout = [[LMPhotoPreviewCollectionViewLayout alloc] init];
    } else {
        // Fallback on earlier versions
    }
    if (@available(macOS 10.11, *)) {
//        [self.collectionView registerClass:LMPhotoViewItem.self forItemWithIdentifier:@"LMPhotoPreviewItem"];
        //       [self.collectionView registerClass:LMPhotoViewItem.self forItemWithIdentifier:@"LMPhotoPreviewItem"];
        //
//        NSNib *itemNib = [[NSNib alloc]initWithNibNamed:@"LMPhotoViewItem" bundle:[NSBundle bundleForClass:self.class]];
//        [self.collectionView registerNib:itemNib forItemWithIdentifier:@"LMPhotoPreviewItem"];
        
        
        NSNib *itemNib = [[NSNib alloc]initWithNibNamed:@"LMPhotoViewItem" bundle:[NSBundle bundleForClass:self.class]];
        [self.collectionView registerNib:itemNib forItemWithIdentifier:@"LMPhotoPreviewItem"];
        

    } else {
        // Fallback on earlier versions
    }
    self.collectionView.content = self.localSimilarPhotoGroup.items;
    self.collectionView.autoresizingMask =  scrollView.autoresizingMask;
    if (@available(macOS 10.11, *)) {
        self.collectionView.dataSource = self;
    } else {
//        LMPhotoViewItem *itemPrototype = [[LMPhotoViewItem alloc]initWithNibName:@"LMPhotoViewItem" bundle:nil];
        LMPhotoViewItem *itemPrototype = [[LMPhotoViewItem alloc]initWithNibName:@"LMPhotoViewItem" bundle:[NSBundle bundleForClass:self.class]];
        self.collectionView.itemPrototype = itemPrototype;
    }
    
    
    self.collectionView.delegate = self;
    self.collectionView.allowsMultipleSelection = YES;
    self.collectionView.selectable = YES;
    [scrollView setDocumentView:self.collectionView];
    
    [self.contentView addSubview:scrollView];
}

- (void)confirmButtonClicked{
    self.hidden = YES;
    [self reloadSuperViewContronller:self.localSimilarPhotoGroup];
}

- (void)revertFinderClick{
    LMPhotoItem *item = [self getUnDeleteSimilarPhotoItem: self.localSimilarPhotoGroup].items[ self.selectIndex];
    if(item.path != nil && item.path.length > 0){
        [[NSWorkspace sharedWorkspace] selectFile:item.path
                         inFileViewerRootedAtPath:[item.path stringByDeletingLastPathComponent]];
    }
}

- (void)cancelButtonClicked{
    self.hidden = YES;
    [self reloadSuperViewContronller:self.localSimilarPhotoGroupCopy];
}

- (void)reloadSuperViewContronller:(LMSimilarPhotoGroup*)group{
    for (NSInteger index = 0; index < self.similarPhotoGroupsCopy.items.count; index ++) {
        LMPhotoItem *copyItem = self.similarPhotoGroupsCopy.items[index];
        LMPhotoItem *localItem = group.items[index];
        copyItem.isSelected = localItem.isSelected;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:LM_NOTIFICATION_RELOAD object:nil];
    
}

#pragma mark NSCollectionViewDataSource Methods
- (nonnull NSCollectionViewItem *)collectionView:(nonnull NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSInteger sectionIndex = 0;
    LMPhotoViewItem *viewItem;
    
    if (@available(macOS 10.11, *)) {
        sectionIndex = indexPath.section;
        viewItem =  [collectionView makeItemWithIdentifier:@"LMPhotoPreviewItem" forIndexPath:indexPath];
        if (sectionIndex >= [self.localSimilarPhotoGroup.items count]) {
            return nil;
        }
        if(self.selectIndex == sectionIndex){
            viewItem.view.layer.borderWidth = 2;
            viewItem.view.layer.borderColor = [NSColor colorWithHex:0x338EF4].CGColor;
        } else {
            viewItem.view.layer.borderWidth = 0;
            //            viewItem.view.layer.borderColor = [NSColor colorWithHex:0x000000].CGColor;
        }
        
        viewItem.representedObject = [self getUnDeleteSimilarPhotoItem: self.localSimilarPhotoGroup].items[sectionIndex];
    } else {
        // Fallback on earlier versions
    }
    
    return viewItem;
}

-(BOOL)collectionView:(NSCollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths{
    if (@available(macOS 10.11, *)) {
        NSInteger sectionIndex = indexPaths.allObjects.firstObject.section;
        LMPhotoItem *item = [self getUnDeleteSimilarPhotoItem: self.localSimilarPhotoGroup].items[sectionIndex];
        [self showBigPrivew:item];
        self.selectIndex = sectionIndex;
    } else {
        // Fallback on earlier versions
    }
    if (@available(macOS 10.11, *)) {
        [self.collectionView reloadData];
    } else {
        // Fallback on earlier versions
    }
}


- (NSInteger)collectionView:(nonnull NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return 1;
}

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
    return [self.localSimilarPhotoGroup.items count];
}

- (NSView *)collectionView:(NSCollectionView *)collectionView viewForSupplementaryElementOfKind:(NSCollectionViewSupplementaryElementKind)kind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark NSCollectionViewDelegateFlowLayout Methods
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section  API_AVAILABLE(macos(10.11)){
    // width无所谓会被设成和collectionView一样宽
    return NSMakeSize(100, HEADER_HEIGHT) ;
}

- (LMSimilarPhotoGroup *)getUnDeleteSimilarPhotoItem:(LMSimilarPhotoGroup *)unDeleteSimilarPhotoGroup{
    LMSimilarPhotoGroup *viewItemGroup = [[LMSimilarPhotoGroup alloc]init];
    for (NSInteger index = 0; index < unDeleteSimilarPhotoGroup.items.count; index ++) {
        LMPhotoItem *Item = [unDeleteSimilarPhotoGroup.items objectAtIndex:index];
        if (Item.isDeleted == NO) {
            [viewItemGroup.items addObject:Item];
        }
    }
    return viewItemGroup;
}

- (void) descriptionView:(NSNotification *)notifly {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self updateDesCription:notifly];
    });
}

- (void)updateDesCription:(NSNotification *)notifly {
    
    
    //     NSInteger selectPhotoTotalNummber = 0;
    //
    //    for (LMPhotoItem *item in self.localSimilarPhotoGroup.items) {
    //        if(item.isSelected){
    //            selectPhotoTotalNummber++;
    //        }
    //    }
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self descriptionView];
    });
}

- (NSImage *)changeImage:(NSString *)path{
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)[self createUrl:path], NULL);
    
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], (NSString *)kCGImageSourceCreateThumbnailWithTransform,
                             [NSNumber numberWithBool:YES], (NSString *)kCGImageSourceCreateThumbnailFromImageAlways,
                             [NSNumber numberWithInt:900], (NSString *)kCGImageSourceThumbnailMaxPixelSize,
                             nil];
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (CFDictionaryRef)options);
    
    if (thumbnail) {
        NSSize size = NSZeroSize;
        NSInteger thumbnailWidth = CGImageGetWidth(thumbnail);
        NSInteger thumbnailHeigh = CGImageGetHeight(thumbnail);
        
        if (thumbnailWidth > thumbnailHeigh*(450/286.0)) {
            size = NSMakeSize((thumbnailWidth*1.0/thumbnailHeigh)*286*2, 286*2);
        } else {
            size = NSMakeSize(450*2, (thumbnailHeigh*1.0/thumbnailWidth)*450*2);
        }
        
        NSImage *image = [[NSImage alloc] initWithCGImage:thumbnail size:size];
        if (image) {
            return image;
        }
        CGImageRelease(thumbnail);
    }
    return [NSImage imageNamed:@"deletedTag" withClass:self.class];
}
- (NSURL *)createUrl:(NSString *)path {
    NSString *filePath = [@"file://" stringByAppendingString:path];
    filePath = [filePath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL* url = [NSURL URLWithString:filePath];
    return url;
}

-(NSImage *)swatchWithColor:(NSColor *)color size:(NSSize)size
{
    NSImage *image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    [color drawSwatchInRect:NSMakeRect(0, 0, size.width, size.height)];
    [image unlockFocus];
    return image;
}

@end
