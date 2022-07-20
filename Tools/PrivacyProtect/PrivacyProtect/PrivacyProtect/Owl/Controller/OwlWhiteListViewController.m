//
//  OwlWhiteListViewController.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlWhiteListViewController.h"
#import "OwlTableRowView.h"
#import "OwlSelectViewController.h"
#import "OwlWindowController.h"
#import "OwlManager.h"
#import "OwlConstant.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import "LMGradientTitleButton.h"
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/MMScroller.h>
#import <QMUICommon/LMCheckboxButton.h>
#import <Masonry/Masonry.h>
#import "OwlCollectionViewItem.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSButton+Extension.h>

typedef void(^removeOwlWhiteListItem)(NSInteger);
typedef void(^checkOwlWhiteListItemCamera)(NSInteger, LMCheckboxButton *btn);
typedef void(^checkOwlWhiteListItemAudio)(NSInteger, LMCheckboxButton *btn);

@interface OwlWhiteListCell : NSTableCellView{
    
}
@property (nonatomic, strong) NSImageView *appIcon;
@property (nonatomic, strong) NSTextField *tfAppName;
@property (nonatomic, strong) NSTextField *tfKind;
@property (nonatomic, strong) LMCheckboxButton *cameraCheck;
@property (nonatomic, strong) LMCheckboxButton *audioCheck;
@property (nonatomic, assign) NSInteger indexRow;
@property (nonatomic, strong) removeOwlWhiteListItem action;
@property (nonatomic, strong) checkOwlWhiteListItemCamera cameraCheckAction;
@property (nonatomic, strong) checkOwlWhiteListItemAudio audioCheckAction;
@property (nonatomic, strong) NSTextField *checkLabelCamera;
@property (nonatomic, strong) NSTextField *checkLabelAudio;


@end

@implementation OwlWhiteListCell

- (instancetype)initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    if (self) {
        
        _appIcon = [[NSImageView alloc] init];
        [self addSubview:_appIcon];
        
        _tfAppName = [OwlWhiteListViewController buildLabel:@"" font:[NSFontHelper getRegularSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
        [_tfAppName setLineBreakMode:NSLineBreakByTruncatingTail];
        [self addSubview:_tfAppName];
        
        _tfKind = [OwlWhiteListViewController buildLabel:@"" font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x94979B]];
        [self addSubview:_tfKind];
        
        _cameraCheck = [[LMCheckboxButton alloc] init];
        _cameraCheck.imageScaling = NSImageScaleProportionallyDown;
        _cameraCheck.title = @"";
//        NSMutableAttributedString *attrTitleCamera = [[NSMutableAttributedString alloc] initWithString:@" 摄像头"];
//        NSUInteger len = [attrTitleCamera length];
//        NSRange range = NSMakeRange(0, len);
//        [attrTitleCamera addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x94979B] range:range];
//        [attrTitleCamera addAttribute:NSFontAttributeName value:[NSFontHelper getLightSystemFont:12] range:range];
//        [attrTitleCamera fixAttributesInRange:range];
//        [cameraCheck setAttributedTitle:attrTitleCamera];
        [_cameraCheck setButtonType:NSButtonTypeSwitch];
        _cameraCheck.allowsMixedState = NO;
        [_cameraCheck setTarget:self];
        [_cameraCheck setAction:@selector(checkCamera:)];
        [self addSubview:_cameraCheck];
        
        _checkLabelCamera = [OwlWhiteListViewController buildLabel:NSLocalizedStringFromTableInBundle(@"OwlWhiteListViewController_initWithFrame_1553136870_1", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x94979B]];
        [self addSubview:_checkLabelCamera];
        
        _audioCheck = [[LMCheckboxButton alloc] init];
        _audioCheck.imageScaling = NSImageScaleProportionallyDown;
        _audioCheck.title = @"";
//        NSMutableAttributedString *attrTitleAudio = [[NSMutableAttributedString alloc] initWithString:@" 麦克风"];
//        len = [attrTitleAudio length];
//        range = NSMakeRange(0, len);
//        [attrTitleAudio addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x94979B] range:range];
//        [attrTitleAudio addAttribute:NSFontAttributeName value:[NSFontHelper getLightSystemFont:12] range:range];
//        [attrTitleAudio fixAttributesInRange:range];
//        [audioCheck setAttributedTitle:attrTitleAudio];
        [_audioCheck setButtonType:NSButtonTypeSwitch];
        _audioCheck.allowsMixedState = YES;
        [_audioCheck setTarget:self];
        [_audioCheck setAction:@selector(checkAudio:)];
        [self addSubview:_audioCheck];
        
        _checkLabelAudio = [OwlWhiteListViewController buildLabel:NSLocalizedStringFromTableInBundle(@"OwlWhiteListViewController_initWithFrame_1553136870_2", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x94979B]];
        [self addSubview:_checkLabelAudio];
        
        LMGradientTitleButton *removeBtn = [[LMGradientTitleButton alloc] initWithFrame:NSZeroRect];
        removeBtn.title = NSLocalizedStringFromTableInBundle(@"OwlWhiteListViewController_initWithFrame_removeBtn_3", nil, [NSBundle bundleForClass:[self class]], @"");
        removeBtn.target = self;
        removeBtn.action = @selector(clickRemoveOwlItem:);
        removeBtn.isGradient = NO;
//        removeBtn.titleNormalColor = [LMAppThemeHelper getTitleColor];
        removeBtn.fillColor = [LMAppThemeHelper getMainBgColor];
//        removeBtn.normalColor = [NSColor redColor];
//        removeBtn.color
        [self addSubview:removeBtn];
        
        [_appIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(@0).offset(OwlElementLeft);
            make.height.equalTo(@22);
            make.width.equalTo(@(22));
        }];
        [_tfKind mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(@0).offset(158);
            make.width.equalTo(@(100));
        }];
        [_tfAppName mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self.appIcon.mas_right).offset(10);
            //make.right.equalTo(self.tfKind).offset(-10);
            make.width.equalTo(@(106));
        }];
        [_cameraCheck mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(@0).offset(294);
            make.height.width.equalTo(@(14));
        }];
        [_checkLabelCamera mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.cameraCheck.mas_right).offset(7);
            make.centerY.equalTo(self);
            make.width.equalTo(@160);
        }];
        [_audioCheck mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(@0).offset(382);
            make.height.width.equalTo(@(14));
        }];
        [_checkLabelAudio mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.audioCheck.mas_right).offset(7);
            make.centerY.equalTo(self);
            make.width.equalTo(@160);
        }];
        [removeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            if (@available(macOS 11, *)) {
                make.right.equalTo(self).offset(-OwlElementLeft - 6);
            } else {
                make.right.equalTo(self).offset(-OwlElementLeft);
            }
            make.width.equalTo(@(60));
            make.height.equalTo(@(24));
        }];
    }
    return self;
}
- (void)setWhiteListModel:(NSDictionary *)appDic{
    NSString *iconPath;
    
    iconPath = [appDic valueForKey:OwlAppIcon];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (iconPath && [iconPath length] > 0 && [fm fileExistsAtPath:iconPath]) {
        NSImage * iconImage = nil;
        iconImage = [[NSImage alloc] initWithContentsOfFile:iconPath];
        //iconImage = [[NSWorkspace sharedWorkspace] iconForFile:iconPath];
        if (iconImage != nil)
        {
            [iconImage setSize:NSMakeSize(64, 64)];
            [_appIcon setImage:iconImage];
        }
    } else {
        if ([iconPath isEqualToString:@"console"]) {
            NSBundle *bundle = [NSBundle bundleForClass:[self class]];
            [_appIcon setImage:[bundle imageForResource:@"defaultTeminate"]];
        } else {
            [_appIcon setImage:[OwlCollectionViewItem getDefaultAppIcon]];
        }
    }
    
    
    [_tfAppName setStringValue:[appDic valueForKey:OwlAppName]];
    if ([[appDic valueForKey:OwlAppleApp] boolValue]) {
        _tfKind.stringValue = NSLocalizedStringFromTableInBundle(@"OwlWhiteListViewController_setWhiteListModel__tfKind_1", nil, [NSBundle bundleForClass:[self class]], @"");
    } else {
        _tfKind.stringValue = NSLocalizedStringFromTableInBundle(@"OwlWhiteListViewController_setWhiteListModel__tfKind_2", nil, [NSBundle bundleForClass:[self class]], @"");
    }
    _cameraCheck.state = [[appDic objectForKey:OwlWatchCamera] boolValue];
    _audioCheck.state = [[appDic objectForKey:OwlWatchAudio] boolValue];
    
    [self updateCameraLabel];
    [self updateAudioLabel];
}
- (void)clickRemoveOwlItem:(id)sender{
    if (self.action) {
        self.action(self.indexRow);
    }
}
- (void)updateCameraLabel{
    if (self.cameraCheck.state) {
        self.checkLabelCamera.textColor = [LMAppThemeHelper getTitleColor];
    } else {
        self.checkLabelCamera.textColor = [NSColor colorWithHex:0x94979B];
    }
}
- (void)updateAudioLabel{
    if (self.audioCheck.state) {
        self.checkLabelAudio.textColor = [LMAppThemeHelper getTitleColor];
    } else {
        self.checkLabelAudio.textColor = [NSColor colorWithHex:0x94979B];
    }
}
- (BOOL)wantRemove{
    if (self.action) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"OwlWhiteListViewController_wantRemove_NSString_1", nil, [NSBundle bundleForClass:[self class]], @"")];
        alert.informativeText = @"";
        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"OwlWhiteListViewController_wantRemove_NSString_2", nil, [NSBundle bundleForClass:[self class]], @"")];
        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"OwlWhiteListViewController_wantRemove_NSString_3", nil, [NSBundle bundleForClass:[self class]], @"")];
        
        NSInteger responseTag = [alert runModal];
        if (responseTag == NSAlertFirstButtonReturn) {
            self.action(self.indexRow);
            return YES;
        } else {
            return NO;
        }
    }
    return NO;
}
- (void)checkCamera:(id)sender{
    if (self.cameraCheckAction) {
        if (!self.audioCheck.state && !self.cameraCheck.state) {
            if (![self wantRemove]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.cameraCheck.state = !self.cameraCheck.state;
                    [self updateCameraLabel];
                });
            }
        } else {
            self.cameraCheckAction(self.indexRow, self.cameraCheck);
            [self updateCameraLabel];
        }
    }
}
- (void)checkAudio:(id)sender{
    if (self.audioCheckAction) {
        if (!self.audioCheck.state && !self.cameraCheck.state) {
            if (![self wantRemove]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.audioCheck.state = !self.audioCheck.state;
                    [self updateAudioLabel];
                });
            }
        } else {
            self.audioCheckAction(self.indexRow, self.audioCheck);
            [self updateAudioLabel];
        }
    }
}
// fix 不同系统选中下，textfield的文字颜色不同，有些是黑有些是白的问题
- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle{
    [super setBackgroundStyle:NSBackgroundStyleLight];
}



@end

@interface OwlWhiteListViewController () <NSTableViewDelegate, NSTableViewDataSource>{
    NSTableView *tableView;
    NSScrollView *scrollView;
    NSButton *addBtn;
    NSString *identifier;
}
@property(weak) NSView *contentView;
@property(weak) NSView *bLineview;
@property(weak) MMScroller *scroller;

@end

@implementation OwlWhiteListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}
                      
-(void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.contentView];
    [LMAppThemeHelper setDivideLineColorFor:self.bLineview];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.scroller];
}


+ (NSTextField*)buildLabel:(NSString*)title font:(NSFont*)font color:(NSColor*)color{
    NSTextField *labelTitle = [[NSTextField alloc] init];
    labelTitle.stringValue = title;
    labelTitle.font = font;
    labelTitle.alignment = NSTextAlignmentLeft;
    labelTitle.bordered = NO;
    labelTitle.editable = NO;
    labelTitle.textColor = color;
    labelTitle.backgroundColor = [NSColor clearColor];
    return labelTitle;
}
- (instancetype)initWithFrame:(NSRect)frame{
    self = [super init];
    if (self) {
        NSView *contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height - 0/*OwlWindowTitleHeight*/)];
        contentView.wantsLayer = YES;
        CALayer *layer = [[CALayer alloc] init];
        layer.backgroundColor = [NSColor whiteColor].CGColor;
        contentView.layer = layer;
        self.contentView = contentView;
        scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height-OwlWindowTitleHeight*2)];
        
        tableView = [[NSTableView alloc] init];
        [tableView setDelegate:self];
        [tableView setDataSource:self];
        [tableView setBackgroundColor:[NSColor whiteColor]];
        //[tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
        [tableView setAutoresizesSubviews:YES];
        identifier = @"OwlWhiteListCell";
        //[tableView registerNib:nil forIdentifier:identifier];
        if (@available (macOS 11.0, *)) {
            tableView.style = NSTableViewStyleFullWidth;
        }
        
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutohidesScrollers:YES];
        [scrollView setAutoresizesSubviews:YES];
        [scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [scrollView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
        [scrollView setDocumentView:tableView];
        
        MMScroller *scroller = [[MMScroller alloc] init];
        self.scroller = scroller;
        [scroller setWantsLayer:YES];
        
//        scroller.layer.backgroundColor = [NSColor whiteColor].CGColor;
        [self->scrollView setVerticalScroller:scroller];
        [tableView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
        
        [tableView setHeaderView:nil];
        NSTableColumn *timeColumn = [[NSTableColumn alloc] initWithIdentifier:identifier];
        timeColumn.width = frame.size.width;
        [tableView addTableColumn:timeColumn];
        
        //        [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        //            make.top.equalTo(scrollView.mas_top).offset(20);
        //            make.height.equalTo(@(frame.size.height-20));
        //            make.width.equalTo(scrollView);
        //        }];
        tableView.frame = NSMakeRect(0, 0, scrollView.frame.size.width, scrollView.frame.size.height);
        
        addBtn = [[NSButton alloc] init];
        [addBtn setButtonType:NSButtonTypeMomentaryChange];
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        addBtn.image = [bundle imageForResource:@"owl_add"];
        //addBtn.image = [NSImage imageNamed:@"owl_add"];
        addBtn.imagePosition = NSImageLeft;
        //addBtn.alignment = NSTextAlignmentRight;
        addBtn.title = NSLocalizedStringFromTableInBundle(@"OwlWhiteListViewController_initWithFrame_addBtn_1", nil, [NSBundle bundleForClass:[self class]], @"");
        addBtn.target = self;
        addBtn.action = @selector(clickBtn:);
        addBtn.bordered = NO;
        addBtn.font = [NSFont systemFontOfSize:12];
        [addBtn setFontColor:[LMAppThemeHelper getTitleColor]];
        
        [contentView addSubview:scrollView];
        [contentView addSubview:addBtn];
        self.view = contentView;
        
        NSTextField *tfTitle = [[NSTextField alloc] initWithFrame:NSZeroRect];
        tfTitle.alignment = NSTextAlignmentCenter;
        tfTitle.bordered = NO;
        tfTitle.editable = NO;
        tfTitle.backgroundColor = [NSColor clearColor];
        
        tfTitle.font = [NSFontHelper getMediumSystemFont:16];
        tfTitle.textColor = [LMAppThemeHelper getTitleColor];
        tfTitle.stringValue = NSLocalizedStringFromTableInBundle(@"OwlWhiteListViewController_initWithFrame_tfTitle_2", nil, [NSBundle bundleForClass:[self class]], @"");
        [contentView addSubview:tfTitle];
        
        NSTextField *labelSpecApp = [OwlWhiteListViewController buildLabel:NSLocalizedStringFromTableInBundle(@"OwlWhiteListViewController_initWithFrame_labelSpecApp _3", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getRegularSystemFont:12]color:[LMAppThemeHelper getTitleColor]];
        [contentView addSubview:labelSpecApp];
        NSTextField *labelSpecType = [OwlWhiteListViewController buildLabel:NSLocalizedStringFromTableInBundle(@"OwlWhiteListViewController_initWithFrame_labelSpecType _4", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getRegularSystemFont:12]color:[LMAppThemeHelper getTitleColor]];
        [contentView addSubview:labelSpecType];
        NSTextField *labelSpecOp = [OwlWhiteListViewController buildLabel:NSLocalizedStringFromTableInBundle(@"OwlWhiteListViewController_initWithFrame_labelSpecOp _5", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getRegularSystemFont:12]color:[LMAppThemeHelper getTitleColor]];
        [contentView addSubview:labelSpecOp];
        
        NSView *bLineview = [[NSView alloc] init];
        bLineview.wantsLayer = YES;
        CALayer *lineLayer = [[CALayer alloc] init];
        lineLayer.backgroundColor = [NSColor colorWithWhite:0.96 alpha:1].CGColor;
        bLineview.layer = lineLayer;
        self.bLineview = bLineview;
        [contentView addSubview:bLineview];
        
        [tfTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@9);
            make.centerX.equalTo(contentView);
        }];
        [addBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@9);
            make.right.equalTo(contentView).offset(-30);
            make.height.equalTo(@20);
            make.width.equalTo(@50);
        }];
        [labelSpecApp mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@0).offset(OwlElementLeft);
            make.top.equalTo(@52);
            make.width.equalTo(@160);
        }];
        [labelSpecType mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@0).offset(158);
            make.top.equalTo(@52);
            make.width.equalTo(@160);
        }];
        [labelSpecOp mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@0).offset(294);
            make.top.equalTo(@52);
            make.width.equalTo(@160);
        }];
        [bLineview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(OwlWindowTitleHeight));
            make.left.equalTo(contentView);
            make.height.equalTo(@1);
            make.width.equalTo(contentView);
        }];
        
        [tableView reloadData];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(whiteListChange:) name:OwlWhiteListChangeNotication object:nil];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.selectWindowController) {
        [self.selectWindowController close];
        //[[self.selectWindowController.window parentWindow] removeChildWindow:self.selectWindowController.window];
        self.selectWindowController = nil;
    }
}
- (void)whiteListChange:(NSNotification*)no{
    [tableView reloadData];
}

- (void)clickBtn:(id)sender{
    if (!self.selectWindowController || !self.selectWindowController.window.contentViewController) {
        NSRect prect = self.view.window.frame;
        NSRect srect = NSMakeRect(prect.origin.x + (prect.size.width - self.view.frame.size.width) / 2, prect.origin.y + (prect.size.height - self.view.frame.size.height) / 2, self.view.frame.size.width, self.view.frame.size.height);
        NSLog(@"clickBtn: %@", NSStringFromRect(srect));
        NSViewController *viewController = [[OwlSelectViewController alloc] initWithFrame:srect];
        self.selectWindowController = [[OwlWindowController alloc] initViewController:viewController];
        [self.selectWindowController.window setReleasedWhenClosed:NO];
        [self.view.window addChildWindow:self.selectWindowController.window ordered:NSWindowAbove];
        [self.selectWindowController showWindow:nil];
        [self.selectWindowController.window setFrame:srect display:NO];
    } else {
        [(OwlSelectViewController*)(self.selectWindowController).window.contentViewController reloadData];
        [self.selectWindowController showWindow:nil];
    }
}

- (void)reloadWhiteList{
    [tableView reloadData];
}
#pragma mark NSTableViewDelegate
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    return 40;
}

//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//    return [NSString stringWithFormat:@"%ld", row];
//}

//- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//    NSTextField *textField = [[NSTextField alloc] initWithFrame:(NSRect){.size = {100, 15}}];
//    textField.stringValue = [NSString stringWithFormat:@"%ld", row];
//    return textField;
//}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    OwlWhiteListCell *view = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if (view == nil) {
        view = [[OwlWhiteListCell alloc] initWithFrame:NSMakeRect(0, 0, tableView.frame.size.width, 24)];
        view.identifier = tableColumn.identifier;
    }
    __weak typeof(self) weakSelf = self;
    view.action = ^(NSInteger indexRow) {
        NSLog(@"action row: %ld", (long)indexRow);
        [[OwlManager shareInstance] removeAppWhiteItemIndex:indexRow];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf->tableView reloadData];
    };
    view.cameraCheckAction = ^(NSInteger indexRow, LMCheckboxButton *btn) {
        if ([OwlManager shareInstance].wlArray.count < indexRow) {
            return;
        }
        NSMutableDictionary *dic = [[OwlManager shareInstance].wlArray objectAtIndex:indexRow];
        [dic setValue:[NSNumber numberWithBool:btn.state] forKey:OwlWatchCamera];
        [[OwlManager shareInstance] replaceAppWhiteItemIndex:indexRow];
    };
    view.audioCheckAction = ^(NSInteger indexRow, LMCheckboxButton *btn) {
        if ([OwlManager shareInstance].wlArray.count < indexRow) {
            return;
        }
        NSMutableDictionary *dic = [[OwlManager shareInstance].wlArray objectAtIndex:indexRow];
        [dic setValue:[NSNumber numberWithBool:btn.state] forKey:OwlWatchAudio];
        [[OwlManager shareInstance] replaceAppWhiteItemIndex:indexRow];
    };
    view.indexRow = row;
    [view setWhiteListModel:[[OwlManager shareInstance].wlArray objectAtIndex:row]];
    return view;
}

- (nullable NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row{
    return [[OwlTableRowView alloc] initWithFrame:NSZeroRect];
}

#pragma mark NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return [OwlManager shareInstance].wlArray.count;
}

@end
