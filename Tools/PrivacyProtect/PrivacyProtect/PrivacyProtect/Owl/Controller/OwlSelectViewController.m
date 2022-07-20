//
//  OwlSelectViewController.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlSelectViewController.h"
#import "OwlCollectionViewItem.h"
#import "QMStaticField.h"
#import "QMButton.h"
#import "OwlManager.h"
#import "OwlWhiteListViewController.h"
#import "OwlConstant.h"
#import "LMTitleButton.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import "LMGradientTitleButton.h"
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/MMScroller.h>
#import "LemonDaemonConst.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/LMBorderButton.h>

@interface OwlSelectViewController (){
    NSCollectionView *collectionView;
    OwlCollectionViewItem *collectionViewItem;
    QMStaticField *tfSelected;
    
}
@property(nonatomic, assign) int selectCount;
@property (nonatomic, strong) NSMutableArray *appArray;
@property(weak) NSView *bottomBgView;
@property(weak) MMScroller *scroller;
@property(weak) NSView *lineView;
@property(weak) NSView *bLineview;
@end

@implementation OwlSelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (instancetype)initWithFrame:(NSRect)frame{
    self = [super init];
    if (self) {
        NSView *contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height - 0/*OwlWindowTitleHeight*/)];
        contentView.wantsLayer = YES;
//        NSView *topBgView = [[NSView alloc] init];
//        CALayer *layer = [[CALayer alloc] init];
//        layer.backgroundColor = [NSColor colorWithWhite:0 alpha:0.1].CGColor;
//        topBgView.layer = layer;
//        [contentView addSubview:topBgView];
        NSView *bottomBgView = [[NSView alloc] init];
        self.bottomBgView = bottomBgView;
//        CALayer *layerBottom = [[CALayer alloc] init];
//        layerBottom.backgroundColor = [NSColor colorWithWhite:1 alpha:1].CGColor;
//        bottomBgView.layer = layerBottom;
//        bottomBgView.wantsLayer = YES;
        [contentView addSubview:bottomBgView];
        
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
        collectionView = [[NSCollectionView alloc] init];
        
        MMScroller *scroller = [[MMScroller alloc] init];
        self.scroller = scroller;
//        [scroller setWantsLayer:YES];
//        scroller.layer.backgroundColor = [NSColor redColor].CGColor;
        [scrollView setVerticalScroller:scroller];
        [collectionView setBackgroundColors:[NSArray arrayWithObject:[LMAppThemeHelper getMainBgColor]]];
        
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutohidesScrollers:YES];
//        [scrollView setAutoresizesSubviews:YES];
        [scrollView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
//        [scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [scrollView setDocumentView:collectionView];
        [bottomBgView addSubview:scrollView];
        
        NSView *lineView = [[NSView alloc] init];
//        CALayer *layerLine = [[CALayer alloc] init];
//        layerLine.backgroundColor = [NSColor colorWithWhite:0.9 alpha:1].CGColor;
//        lineView.layer = layerLine;
        [bottomBgView addSubview:lineView];
        
        tfSelected = [[QMStaticField alloc] initWithFrame:NSZeroRect];
        tfSelected.font = [NSFont systemFontOfSize:13];
        [bottomBgView addSubview:tfSelected];
        
        LMBorderButton *cancel = [[LMBorderButton alloc] init];
        cancel.title = NSLocalizedStringFromTableInBundle(@"OwlSelectViewController_initWithFrame_cancel_1", nil, [NSBundle bundleForClass:[self class]], @"");
        cancel.target = self;
        cancel.action = @selector(clickCancel);
//        cancel.isGradient = NO;
//        LMGradientTitleButton *ok = [[LMGradientTitleButton alloc] initWithFrame:NSZeroRect];
       LMGradientTitleButton *ok = [[LMGradientTitleButton alloc] initWithFrame:NSZeroRect];
        ok.title = NSLocalizedStringFromTableInBundle(@"OwlSelectViewController_initWithFrame_ok_2", nil, [NSBundle bundleForClass:[self class]], @"");
        ok.titleNormalColor = [NSColor whiteColor];
        ok.titleHoverColor = [NSColor whiteColor];
        ok.target = self;
        ok.action = @selector(clickOk);
        [bottomBgView addSubview:cancel];
        [bottomBgView addSubview:ok];
        
        NSTextField *tfTitle = [[NSTextField alloc] initWithFrame:NSZeroRect];
        tfTitle.alignment = NSTextAlignmentCenter;
        tfTitle.bordered = NO;
        tfTitle.editable = NO;
        tfTitle.backgroundColor = [NSColor clearColor];
        tfTitle.font = [NSFontHelper getMediumSystemFont:16];
        tfTitle.textColor = [LMAppThemeHelper getTitleColor];
        tfTitle.stringValue = NSLocalizedStringFromTableInBundle(@"OwlSelectViewController_initWithFrame_tfTitle_3", nil, [NSBundle bundleForClass:[self class]], @"");
        [bottomBgView addSubview:tfTitle];
        NSView *bLineview = [[NSView alloc] init];
        self.bLineview = bLineview;
//        CALayer *lineLayer = [[CALayer alloc] init];
//        lineLayer.backgroundColor = [NSColor colorWithWhite:0.90 alpha:1].CGColor;
//        bLineview.layer = lineLayer;
        [bottomBgView addSubview:bLineview];
        
        self.view = contentView;
        
//        [topBgView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(contentView.mas_top).offset(0);
//            make.width.equalTo(contentView);
//            make.height.equalTo(@(150));
//        }];
        CGFloat bottomHeight = 48;
        CGFloat btnHeight = 24;
        [bottomBgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(contentView);
            make.left.right.equalTo(contentView);
            make.width.height.equalTo(contentView);
        }];
        [tfTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@9);
            make.centerX.equalTo(contentView);
        }];
        [bLineview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(tfTitle.mas_bottom).offset(9);
            make.left.equalTo(contentView);
            make.height.equalTo(@1);
            make.width.equalTo(contentView);
        }];
        [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.equalTo(bLineview).offset(0);
            make.bottom.equalTo(bottomBgView.mas_bottom).offset(-bottomHeight);
            make.left.equalTo(bottomBgView).offset(10);
            make.right.equalTo(bottomBgView).offset(-10);
        }];
        [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(scrollView.mas_bottom).offset(0);
            make.left.equalTo(bottomBgView);
            make.height.equalTo(@(1));
            make.width.equalTo(contentView);
        }];
        [tfSelected mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(lineView.mas_bottom).offset((bottomHeight-13)/2);
            make.left.equalTo(contentView).offset(30);
        }];
        [ok mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(lineView.mas_bottom).offset((bottomHeight-btnHeight)/2);
            make.right.equalTo(bottomBgView).offset(-(bottomHeight-btnHeight)/2);
            make.height.equalTo(@(btnHeight));
            make.width.equalTo(@(60));
        }];
        [cancel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(lineView.mas_bottom).offset((bottomHeight-btnHeight)/2);
            make.right.equalTo(ok.mas_left).offset(-(bottomHeight-btnHeight)/2);
            make.height.equalTo(@(btnHeight));
            make.width.equalTo(@(60));
        }];
        
        collectionViewItem = [[OwlCollectionViewItem alloc] init];
        //collectionViewItem.action = ^(id sender) {
        //    NSLog(@"action row: %@", sender);
        //};
        [collectionView setItemPrototype:collectionViewItem];
        
        _wlModelArray = [[NSMutableArray alloc] init];
        _appArray = [[NSMutableArray alloc] init];
        
        _appArray = [[OwlManager shareInstance] getAllAppInfoWithIndexArray:_wlModelArray];
        NSLog(@"%s _wlModelArray: %lu", __FUNCTION__, (unsigned long)_wlModelArray.count);
        //[collectionViewItem bind:NSContentBinding toObject:self withKeyPath:@"content" options:NULL];
        [self reloadData];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectAction:) name:@"OwlSelectAction" object:nil];
    }
    return self;
}

//MARK: 设置控件layer背景颜色
- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.bottomBgView];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.scroller];
    [LMAppThemeHelper setDivideLineColorFor:self.lineView];
    [LMAppThemeHelper setDivideLineColorFor:self.bLineview];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)selectAction:(NSNotification*)no{
    OwlCollectionViewItem *item = [no object];
    if (self.wlModelArray.count < item.index) {
        return ;
    }
    NSMutableDictionary *appDic = [self.wlModelArray objectAtIndex:item.index];
    if ([item.selectBtn state]) {
        self.selectCount++;
    } else {
        self.selectCount--;
    }
    [appDic setObject:[NSNumber numberWithBool:[item.selectBtn state]] forKey:@"isSelected"];
    [self updateSelectLabel];
}
- (void)reloadData{
    self.selectCount = 0;
    [_wlModelArray removeAllObjects];
    for (NSMutableDictionary *appDic in self.appArray) {
        //NSLog(@"appName: %@", name);
        [appDic setObject:[NSNumber numberWithBool:NO] forKey:@"isSelected"];
        [appDic setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchCamera];
        [appDic setObject:[NSNumber numberWithBool:YES] forKey:OwlWatchAudio];
        NSString *identifier = [appDic objectForKey:OwlIdentifier];
        BOOL isExist = NO;
        for (NSDictionary *item in [OwlManager shareInstance].wlArray) {
            if ([[item objectForKey:OwlIdentifier] isEqualToString:identifier]) {
                isExist = YES;
                break;
            }
        }
        if (isExist) {
            continue;
        }
        
        [_wlModelArray addObject:appDic];
    }
    [self updateSelectLabel];
    [collectionView setContent:_wlModelArray];
    
    for (int i = 0; i < _wlModelArray.count; i++) {
        NSMutableDictionary *appDic = [_wlModelArray objectAtIndex:i];
        OwlCollectionViewItem *item = (OwlCollectionViewItem *)[collectionView itemAtIndex:i];
        [item updateUIWithDic:appDic];
    }
}

- (void)updateSelectLabel{
    
    NSString *strCount = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"OwlSelectViewController_updateSelectLabel_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""), self.selectCount];
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc]initWithString:strCount];
    NSRange range = [strCount rangeOfString:[NSString stringWithFormat:@" %d ", self.selectCount]];
    
    [attrStr addAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:12],
                             NSForegroundColorAttributeName: [NSColor colorWithHex:0x7E7E7E]}
                     range:NSMakeRange(0, strCount.length)];
    [attrStr addAttributes:@{NSFontAttributeName:[NSFont boldSystemFontOfSize:12],
                             NSForegroundColorAttributeName: [LMAppThemeHelper getTitleColor]}
                     range:NSMakeRange(range.location, range.length)];
    tfSelected.attributedStringValue = attrStr;
}

- (void)clickCancel{
    [self.view.window orderOut:nil];
}

- (void)clickOk{
//    [[OwlManager shareInstance].wlArray removeAllObjects];
    NSLog(@"%s _wlModelArray: %lu", __FUNCTION__, (unsigned long)_wlModelArray.count);
    NSString *strApps = @"";
    for (int i = 0; i < _wlModelArray.count; i++) {
        OwlCollectionViewItem *item = (OwlCollectionViewItem *)[collectionView itemAtIndex:i];
        //NSLog(@"clickOk state: %ld", (long)item.selectBtn.state);
        if (item.selectBtn.state) {
            NSMutableDictionary *appDic = [_wlModelArray objectAtIndex:i];
            [[OwlManager shareInstance] addAppWhiteItem:appDic];
            if ([strApps length] > 0) {
                strApps = [[strApps stringByAppendingString:@"|"] stringByAppendingString:[appDic objectForKey:OwlAppName]];
            } else {
                strApps = [strApps stringByAppendingString:[appDic objectForKey:OwlAppName]];
            }
        }
    }
    [self clickCancel];
}

@end
