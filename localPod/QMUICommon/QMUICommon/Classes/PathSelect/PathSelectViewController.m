//
//  PathSelectViewController.m
//  PathSelect
//
//  
//  Copyright © 2019 xuanqi. All rights reserved.
//

#import "PathSelectViewController.h"
#import "PathSelectCollectionViewItem.h"
#import <Masonry/Masonry.h>
#import "LMAppThemeHelper.h"
#import "NSView+APForwardDraggingDestination.h"
#import <QMCoreFunction/NSImage+Extension.h>
#import "LMViewHelper.h"
#import "LMImageButton.h"
#import <QMCoreFunction/LanguageHelper.h>
#import <Quartz/Quartz.h>
//#import "LMImageBu"

#define FolderSelectCollectionViewIdentifier  @"FolderSelectCollectionViewIdentifier"

@interface PathSelectViewController () <NSCollectionViewDelegate, NSCollectionViewDataSource, PathRemoveDelegate, NSOpenSavePanelDelegate> {
    NSMutableArray<NSString *> *_pathArray;
    NSCollectionView *_collectionView;
    NSScrollView *_scrollView;
    NSImageView *_addImage;
    //首次添加的控件
    NSView *_firstAddContainer; //首次添加的container
    LMImageButton *_firstAddButton;
    NSTextField *_firstAddTipsLabel;
    NSTextField *_firstAddSystemPhotoText;
    
    //继续添加的控件
    NSView *_continueAddContainer; //继续添加的container
    NSTextField *_continueAddSystemPhotoText;
    LMImageButton *_continueAddButton; //继续添加的button
    NSTextField *_continueAddTipsLabel;
    
}

@end


@implementation PathSelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
    [self setupData];
}


- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 400, 80)];
    view.wantsLayer = true;
    view.layer.backgroundColor = [NSColor clearColor].CGColor;
    self.view = view;
}
//
//- (void)viewWillLayout{
//
//}

- (void)setupData{
    _pathArray = [NSMutableArray array];
}

- (void)initView{
    
    [self initFirstAddContainer];
    [self initContinueAddContainer];
    [self initCollectionViews];
    //    [self hideCollectionView];
    [_firstAddContainer setHidden:NO];
    [_continueAddContainer setHidden:YES];
    
}

- (void)addFilePathToView:(NSString *)path
{
    [self addFilePath:path];
}

/**
 初始化首次添加的控件
 */
-(void)initFirstAddContainer{
    //init container
    _firstAddContainer = [[NSView alloc] init];
    [self.view addSubview:_firstAddContainer];
    
    //init add button
    _firstAddButton = [[LMImageButton alloc] init];
    [_firstAddButton setFocusRingType:NSFocusRingTypeNone];
    [_firstAddContainer addSubview:_firstAddButton];
    
    _firstAddButton.hoverImage = [NSImage imageNamed:@"icon_path_select_first_add_hover" withClass:self.class];
    _firstAddButton.downImage = [NSImage imageNamed:@"icon_path_select_first_add_down" withClass:self.class];
    _firstAddButton.defaultImage = [NSImage imageNamed:@"icon_path_select_first_add_normal" withClass:self.class];
    
    [_firstAddButton setBordered:NO];
    [_firstAddButton setUp];
    [_firstAddButton setTarget:self];
    [_firstAddButton setAction:@selector(beginOpenPanel)];
    //init tips
    NSTextField *addTipsLabel = [[NSTextField alloc] init];
    _firstAddTipsLabel = addTipsLabel;
    [_firstAddContainer addSubview:addTipsLabel];
    addTipsLabel.bordered = NO;
    addTipsLabel.editable = NO;
    addTipsLabel.drawsBackground = NO;
    NSFont *font = [NSFont systemFontOfSize:12];
    addTipsLabel.textColor = [LMAppThemeHelper getTipsTextColor];
    addTipsLabel.font = font;
    addTipsLabel.stringValue = NSLocalizedStringFromTableInBundle(@"PathSelectViewController_addFolder_button_tips", nil, [NSBundle bundleForClass:[self class]], @"");
    [self initConstraintForFirstAddContainer];
}

-(void)initConstraintForFirstAddContainer{
    //如果是相似照片清理页面,并且系统相册存在，需要显示“添加系统相册”
    if(self.sourceType == 1 && [self systemPhotoLibraryIsExist]){
        _firstAddSystemPhotoText = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x057CFF]];
        _firstAddSystemPhotoText.stringValue = NSLocalizedStringFromTableInBundle(@"PathSelectViewController_add_system_photo", nil, [NSBundle bundleForClass:self.class], @"");
        [_firstAddContainer addSubview:_firstAddSystemPhotoText];
        
        [_firstAddTipsLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self->_firstAddButton.mas_right).offset(15);
            make.top.equalTo(self.view).offset(20);
        }];
        [_firstAddSystemPhotoText mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view).offset(-20);
            make.left.equalTo(_firstAddTipsLabel);
        }];
        NSClickGestureRecognizer *recognizer = [[NSClickGestureRecognizer alloc]initWithTarget:self action:@selector(addSystemPhotoPath)];
        [_firstAddSystemPhotoText addGestureRecognizer:recognizer];
    }else{
        [_firstAddTipsLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self->_firstAddContainer);
            make.left.equalTo(self->_firstAddButton.mas_right).offset(15);
        }];
    }
    
    [_firstAddContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(_firstAddTipsLabel).offset(5);
        make.top.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    
    [_firstAddButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@80);
        make.left.equalTo(self.view);
        make.centerY.equalTo(self.view);
    }];
}


-(BOOL)systemPhotoLibraryIsExist{
    NSString *photoPath = [NSString stringWithFormat:@"%@/Pictures/Photos Library.photoslibrary", [NSString getUserHomePath]];
    BOOL isDirectory = YES;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:photoPath isDirectory:&isDirectory];
    if(!isExist){
        photoPath = [NSString stringWithFormat:@"%@/Pictures/照片图库.photoslibrary", [NSString getUserHomePath]];
        isExist = [fileManager fileExistsAtPath:photoPath isDirectory:&isDirectory];
    }
    return isExist;
}

-(void)addSystemPhotoPath{
    NSString *photoPath = [NSString stringWithFormat:@"%@/Pictures/Photos Library.photoslibrary", [NSString getUserHomePath]];
    
    BOOL isDirectory;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:photoPath isDirectory:&isDirectory];
    if(!isExist){
        photoPath = [NSString stringWithFormat:@"%@/Pictures/照片图库.photoslibrary", [NSString getUserHomePath]];
        isExist = [fileManager fileExistsAtPath:photoPath isDirectory:&isDirectory];
        if (!isExist) {
            //            [self.ok setEnabled:NO];
        }
    }
    
    [self addFilePath:photoPath];
    
}


-(void)initContinueAddContainer{
    //init container
    _continueAddContainer = [[NSView alloc] init];
    [self.view addSubview:_continueAddContainer];
    [_continueAddContainer setHidden:YES];
    
    //init add button
    LMImageButton *addButton = [[LMImageButton alloc] init];
    _continueAddButton = addButton;
    [addButton setFocusRingType:NSFocusRingTypeNone];
    [_continueAddContainer addSubview:addButton];
    if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
        addButton.hoverImage = [NSImage imageNamed:@"icon_path_select_continue_add_hover_en" withClass:self.class];
        addButton.defaultImage = [NSImage imageNamed:@"icon_path_select_continue_add_normal_en" withClass:self.class];
        addButton.downImage = [NSImage imageNamed:@"icon_path_select_continue_add_down_en" withClass:self.class];
    }else{
        addButton.hoverImage = [NSImage imageNamed:@"icon_path_select_continue_add_hover_ch" withClass:self.class];
        addButton.defaultImage = [NSImage imageNamed:@"icon_path_select_continue_add_normal_ch" withClass:self.class];
        addButton.downImage = [NSImage imageNamed:@"icon_path_select_continue_add_down_ch" withClass:self.class];
    }
    
    [addButton setBordered:NO];
    [addButton setUp];
    [addButton setTarget:self];
    [addButton setAction:@selector(beginOpenPanel)];
    //init tips
    NSTextField *addTipsLabel = [LMViewHelper createNormalLabel:12 fontColor:[LMAppThemeHelper getTipsTextColor]];
    _continueAddTipsLabel = addTipsLabel;
    addTipsLabel.stringValue = NSLocalizedStringFromTableInBundle(@"PathSelectViewController_addFolder_button_continue_tips", nil, [NSBundle bundleForClass:[self class]], @"");
    [_continueAddContainer addSubview:addTipsLabel];
    
    NSTextField *addSystemPhotoText = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x057CFF]];
    _continueAddSystemPhotoText = addSystemPhotoText;
    addSystemPhotoText.stringValue = NSLocalizedStringFromTableInBundle(@"PathSelectViewController_add_system_photo", nil, [NSBundle bundleForClass:self.class], @"");
    NSClickGestureRecognizer *recognizer = [[NSClickGestureRecognizer alloc]initWithTarget:self action:@selector(addSystemPhotoPath)];
    [addSystemPhotoText addGestureRecognizer:recognizer];
    [_continueAddContainer addSubview:addSystemPhotoText];
    [self initConstraintForContinueAddContainer];
}

-(void)initConstraintForContinueAddContainer{
    if(self.sourceType == 1 && [self systemPhotoLibraryIsExist]){
          if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
              [_continueAddSystemPhotoText mas_remakeConstraints:^(MASConstraintMaker *make) {
                  make.left.equalTo(_continueAddButton);
                  make.top.equalTo(_continueAddButton.mas_bottom).offset(8);
              }];
              
              [_continueAddButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                  make.width.equalTo(@74);
                  make.height.equalTo(@35);
                  make.left.equalTo(self.view);
                  make.centerY.equalTo(self.view).offset(-10);
              }];
              
              [_continueAddContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
                  make.left.equalTo(self.view);
                  make.width.equalTo(@120);
                  make.top.equalTo(self.view);
                  make.bottom.equalTo(self.view);
              }];
          }else{
              [_continueAddSystemPhotoText mas_remakeConstraints:^(MASConstraintMaker *make) {
                  make.centerX.equalTo(_continueAddButton);
                  make.top.equalTo(_continueAddButton.mas_bottom).offset(8);
              }];
              
              [_continueAddButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                  make.width.equalTo(@100);
                  make.height.equalTo(@35);
                  make.left.equalTo(self.view);
                  make.centerY.equalTo(self.view).offset(-10);
              }];
              
              [_continueAddContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
                  make.left.equalTo(self.view);
                  make.width.equalTo(@100);
                  make.top.equalTo(self.view);
                  make.bottom.equalTo(self.view);
              }];
          }
          
      }else{
          if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
              [_continueAddButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                  make.width.equalTo(@74);
                  make.height.equalTo(@35);
                  make.left.equalTo(self.view);
                  make.centerY.equalTo(self.view);
              }];
              
              [_continueAddContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
                  make.left.equalTo(self.view);
                  make.width.equalTo(@74);
                  make.top.equalTo(self.view);
                  make.bottom.equalTo(self.view);
              }];
          }else{
              [_continueAddButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                  make.width.equalTo(@100);
                  make.height.equalTo(@35);
                  make.left.equalTo(self.view);
                  make.centerY.equalTo(self.view);
              }];
              
              [_continueAddContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
                  make.left.equalTo(self.view);
                  make.width.equalTo(@100);
                  make.top.equalTo(self.view);
                  make.bottom.equalTo(self.view);
              }];
          }
          
      }
      
      [_continueAddTipsLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
          make.left.equalTo(_continueAddButton).offset(38);
          make.centerY.equalTo(_continueAddButton);
      }];
      
}

//
//-(NSTextField *)getLable{
//
//}


- (void)initCollectionViews {
    NSCollectionView *folderCollectionView = [[NSCollectionView alloc] init];
    _collectionView = folderCollectionView;
    [_collectionView setBackgroundColors:@[[NSColor clearColor]]];
    // flow layout
    NSCollectionViewFlowLayout *flowLayout = [[NSCollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(68, 100);
    flowLayout.sectionInset = NSEdgeInsetsMake(0, 0, 0, 0);
    flowLayout.minimumInteritemSpacing = 10; //minimumInteritemSpacing: The minimum spacing to use between items in the same row.
    flowLayout.minimumLineSpacing = 10;     // minimumLineSpacing: The minimum spacing to use between lines of items in the grid
    flowLayout.scrollDirection = NSCollectionViewScrollDirectionHorizontal;
    
    folderCollectionView.collectionViewLayout = flowLayout;
    
    
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    _scrollView = scrollView;
    [self.view addSubview:scrollView];
    [scrollView setDrawsBackground:NO];
    scrollView.hasVerticalScroller = NO;
    [scrollView setHasHorizontalScroller:YES];
    [[scrollView horizontalScroller] setAlphaValue:0];
    [scrollView setAutoresizesSubviews:YES];
    [scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    
    scrollView.documentView = folderCollectionView;
    
    folderCollectionView.delegate = self;
    folderCollectionView.dataSource = self;
    
    // CollectionView注册的 Item 为 ViewController,如果这个ViewController没有对应的 xib,则必须实现 loadView 方法
    [folderCollectionView registerClass:PathSelectCollectionViewItem.class forItemWithIdentifier:FolderSelectCollectionViewIdentifier];

}


// MARK: collectionView delegate/dataSource

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _pathArray.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    double startTime = [[NSDate date] timeIntervalSince1970];
    NSLog(@"AddSystemPath-NSCollectionViewItem--Time:%f",startTime);
    NSCollectionViewItem *item = [collectionView makeItemWithIdentifier:FolderSelectCollectionViewIdentifier forIndexPath:indexPath];
    if (!item || ![item isKindOfClass:PathSelectCollectionViewItem.class]) {
        return item;
    }
    
    PathSelectCollectionViewItem *viewItem = (PathSelectCollectionViewItem *) item;
    viewItem.pathRemoveDelegate = self;
    NSUInteger row = (NSUInteger) indexPath.item;  // item + section, ios 才有 row + section
    NSString *path = _pathArray[row];
    startTime = [[NSDate date] timeIntervalSince1970];
    NSLog(@"AddSystemPath-before updateViewWith--Time:%f",startTime);
    [viewItem updateViewWith:path];
    return item;
}


// MARK: item path remove delegate
- (void)removePath:(NSString *)path {
    [self removeFilePath:path];
}


// MARK: path Array change Action

// sender:NString or NSArray<NSString*>
- (BOOL)addFilePath:(id)sender {
    // 1. 创建等待添加的数组
    NSArray *waitForAddPathArray = nil;
    if ([sender isKindOfClass:[NSString class]]) {
        if ([_pathArray containsObject:sender])
            return NO;
        waitForAddPathArray = @[sender];
    } else if ([sender isKindOfClass:[NSArray class]]) {
        waitForAddPathArray = sender;
    }
    
    if (!waitForAddPathArray)
        return NO;
    
    
    // 2. 具体模块对paths进行过滤
    waitForAddPathArray = [_delegate duplicateViewAllowFilePaths:waitForAddPathArray];
    
    
    // 3.真正添加,包括数据源改动,和 UI 改动.
    if (waitForAddPathArray.count == 0) {
        if ([_pathArray count] == 0)
            return NO;
    }
    
    //    NSMutableSet<NSIndexPath *> *indexSet = [NSMutableSet set];
    
    NSUInteger startIndex = [_pathArray count];
    int count = [_pathArray count];
    for (NSString *path in waitForAddPathArray) {
        if (![_pathArray containsObject:path]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:startIndex inSection:0];
            //            [indexSet addObject:indexPath];
            //            [_pathArray addObject:path];
            [_pathArray insertObject:path atIndex:0];
            [_delegate duplicateChoosePathChanged:path isRemove:NO];
            
            startIndex++;
        }
    }
    
    //    for (int i = 0; i < _pathArray.count; i++) {
    //        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
    //        [indexSet addObject:indexPath];
    //    }
    
//    NSAnimationContext.currentContext.duration = 1;
    //TODO: 动画时阻塞式的吗
    //    _collectionView.animator ins
    //    [_collectionView.animator insertItemsAtIndexPaths:indexSet];
    
    [_collectionView reloadData];
    // TODO: UI 改动和数据源改动谁先谁后?
    if(count == 0){
        [self showCollectionView];  //如果之前数组为空，说明是首次添加，需要更新view
    }
    //
    
    //    if(indexSet.count >0 || indexSet.count == _pathArray.count){
    //        [self showCollectionView];
    //    }
    
    double endTime = [[NSDate date] timeIntervalSince1970];
    NSLog(@"AddSystemPath---endAddTime:%f",endTime);
    
    return YES;
    
}

- (void)removeFilePath:(NSString *)path {
    if ([_pathArray containsObject:path]) {
        NSUInteger removeIndex = [_pathArray indexOfObject:path];
        
        [_pathArray removeObject:path];
        [_delegate duplicateChoosePathChanged:path isRemove:YES];
        // UI动画效果
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:removeIndex inSection:0];
        NSAnimationContext.currentContext.duration = 0.5;
        [_collectionView.animator deleteItemsAtIndexPaths:[[NSSet alloc] initWithArray:@[indexPath]]];
        
        
        //数量变为 0
        if([_pathArray count] == 0){
            [self hideCollectionView];
        }
    }
    
    
}

// 当 collectionView 有无内容时,更改 addButton 提示的位置
- (void)showCollectionView {
    //    _addTipsLabel.stringValue = NSLocalizedStringFromTableInBundle(@"PathSelectViewController_addFolder_button_continue_tips", nil, [NSBundle bundleForClass:[self class]], @"");
    //LMDuplicateSelectFoldersViewController_addFolder_button_continue_tips
    [_scrollView setHidden:NO];
    
    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@263);
        make.height.equalTo(@100);
        make.left.equalTo(self->_continueAddContainer.mas_right).offset(22);
        make.centerY.equalTo(self.view);
    }];
    
    
    //    [_firstAddContainer setHidden:NO];
    [_continueAddContainer.layer removeAllAnimations];  //移除上次的动画
    [_continueAddContainer setHidden:NO];
    
    //    [NSAnimationContext beginGrouping];
    //    [[NSAnimationContext currentContext] setDuration:0.5];
    //    [[_continueAddContainer animator] setAlphaValue:1];
    //    [NSAnimationContext endGrouping];
    //
    [_firstAddContainer setHidden:YES];
    [_firstAddContainer setAlphaValue:0];
    
}

- (void)hideCollectionView {
    
    [_scrollView setHidden:YES];
    
    [self hideContinueAddContainerAnimation];
    //    [_continueAddContainer setAlphaValue:0];    //设置为0，下一次动画显示
    //淡入显示_firstAddContainer
    [_firstAddContainer setHidden:NO];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:1];
    [[_firstAddContainer animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];
    
}


/**
 隐藏_continueAddContainer的动画
 */
-(void)hideContinueAddContainerAnimation{
    /* 移动 */
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    
    // 动画选项的设定
    animation.duration = 0.3; // 持续时间
    animation.repeatCount = 1; // 重复次数
    
    // 起始帧和结束帧的设定
    animation.fromValue = [NSValue valueWithPoint:_continueAddContainer.layer.position];
    CGPoint point = CGPointMake(-200, 0);
    animation.toValue = [NSValue valueWithPoint:point]; // 终了帧
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    // 添加动画
    [_continueAddContainer.layer addAnimation:animation forKey:@"move-layer"];
    
}
// MARK: configure openPanel

- (void)beginOpenPanel {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:NO];
    openPanel.delegate = self;
    
    NSString *language = [NSLocale preferredLanguages][0];
    if (language && [language containsString:@"zh"]) {
        [openPanel setPrompt:@"添加"];
    } else {
        [openPanel setPrompt:@"Add"];
    }
    
    if ([_delegate respondsToSelector:@selector(addFolderAction)]) {
        [_delegate addFolderAction];
    }
    
    __weak __typeof(self) weakSelf = self;
    [openPanel beginSheetModalForWindow:[self.view window]
                      completionHandler:^(NSInteger result) {
                          __strong __typeof(weakSelf) strongSelf = weakSelf;
                          if (!strongSelf) {return;}
                          
                          if (result == NSModalResponseOK) {
                              NSString *filePath = [[openPanel URL] path];
                              [strongSelf addFilePath:filePath];
                          } else {
                              if ([strongSelf->_delegate respondsToSelector:@selector(cancelAddAction)]) {
                                  [strongSelf->_delegate cancelAddAction];
                              }
                          }
                      }];
}


// MARK: open panel delegate
- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url NS_AVAILABLE_MAC(10_6) {
    
    NSString *path = [url path];
    NSLog(@"user select shouldEnableURL = %@", path);
    if (!path) {
        return NO;
    }
    if ([path isEqualToString:@"/"]) {
        return NO;
    }
    
    NSArray *pathArray = @[path];
    if (self.delegate) {
        NSArray *allowPathArray = [self.delegate duplicateViewAllowFilePaths:pathArray];
        if (allowPathArray && allowPathArray.count > 0) {
            return YES;
        }
    }
    return NO;
}


- (NSArray *)getChoosePaths
{
    return _pathArray;
}

@end
