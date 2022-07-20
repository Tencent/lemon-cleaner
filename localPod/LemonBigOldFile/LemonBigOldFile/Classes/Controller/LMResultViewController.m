//
//  LMResultViewController.m
//  LemonBigOldFile
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMResultViewController.h"
#import "McBigFileWndController.h"
#import "LMBigResultTableRowView.h"
#import "LMRootCellView.h"
#import "LMSubItemCellView.h"
#import "QMLargeOldManager.h"
#import <Quartz/Quartz.h>
#import <Masonry/Masonry.h>
#import <QMCoreFunction/QMFileClassification.h>
#import "NSButton+Extension.h"
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/MMScroller.h>
#import <Masonry/Masonry.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import "NSColor+Extension.h"
#import "NSString+Extension.h"
#import "NSFont+Extension.h"

#define ROOT_CELLVIEW_INDENTIFIER @"LMRootCellView"
#define SUB_ITEM_CELLVIEW_INDENTIFIER @"LMSubItemCellView"

#define OUTLINE_VIEW_WIDTH_MIN 360
#define OUTLINE_VIEW_WIDTH_MAX 780

#define FILTER_BTN_COLOR_SEL    0x515151
#define FILTER_BTN_COLOR_NO_SEL 0x94979b

@interface LMResultViewController ()<NSOutlineViewDataSource, NSOutlineViewDelegate, QLPreviewItem, BigFileWndEvent, RowViewDelegate>
{
    NSArray* _resultAllArray;
    NSArray* _resultArray;
    
    QMLargeOldResultItem* selectedItem;
    NSButton *filterBtnSelected;
    
    BOOL _previewing;
    
    BOOL _loading;
}
@property(nonatomic) QLPreviewView *previewView;

@end

@implementation LMResultViewController

- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {

    }
    return self;
}

-(void)initViewText{
    [backBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMResultViewController_initViewText_backBtn_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [filterBtnAll setTitle:NSLocalizedStringFromTableInBundle(@"LMResultViewController_initViewText_filterBtnAll_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    [filterBtnMusic setTitle:NSLocalizedStringFromTableInBundle(@"LMResultViewController_initViewText_filterBtnMusic_3", nil, [NSBundle bundleForClass:[self class]], @"")];
    [filterBtnVideo setTitle:NSLocalizedStringFromTableInBundle(@"LMResultViewController_initViewText_filterBtnVideo_4", nil, [NSBundle bundleForClass:[self class]], @"")];
    [filterBtnDocument setTitle:NSLocalizedStringFromTableInBundle(@"LMResultViewController_initViewText_filterBtnDocument_5", nil, [NSBundle bundleForClass:[self class]], @"")];
    [filterBtnInstall setTitle:NSLocalizedStringFromTableInBundle(@"LMResultViewController_initViewText_filterBtnInstall_6", nil, [NSBundle bundleForClass:[self class]], @"")];
    [filterBtnOther setTitle:NSLocalizedStringFromTableInBundle(@"LMResultViewController_initViewText_filterBtnOther_7", nil, [NSBundle bundleForClass:[self class]], @"")];
    [previewDescText setStringValue:NSLocalizedStringFromTableInBundle(@"LMResultViewController_initViewText_previewDescText_8", nil, [NSBundle bundleForClass:[self class]], @"")];
    [noFileDescLabel setStringValue:NSLocalizedStringFromTableInBundle(@"LMResultViewController_initViewText_noFileDescLabel_9", nil, [NSBundle bundleForClass:[self class]], @"")];
    [cleanBtn setTitle:NSLocalizedStringFromTableInBundle(@"LMResultViewController_initViewText_cleanBtn_10", nil, [NSBundle bundleForClass:[self class]], @"")];
}

-(void)setupViews{
    
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->totalSizeText.mas_right).offset(20);
        make.centerY.equalTo(self->totalSizeText.mas_centerY);
        make.width.equalTo(@60);
        make.height.equalTo(@24);
    }];
    
    [filterBtnAll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(38);
        make.centerY.equalTo(self->titleView.mas_centerY);
    }];
    
    [filterBtnMusic mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->filterBtnAll.mas_right).offset(36);
        make.centerY.equalTo(self->titleView.mas_centerY);
    }];
    
    [filterBtnVideo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->filterBtnMusic.mas_right).offset(36);
        make.centerY.equalTo(self->titleView.mas_centerY);
    }];
    
    [filterBtnDocument mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->filterBtnVideo.mas_right).offset(36);
        make.centerY.equalTo(self->titleView.mas_centerY);
    }];
    
    [filterBtnInstall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->filterBtnDocument.mas_right).offset(36);
        make.centerY.equalTo(self->titleView.mas_centerY);
    }];
    
    [filterBtnOther mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->filterBtnInstall.mas_right).offset(36);
        make.centerY.equalTo(self->titleView.mas_centerY);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initViewText];
    [self setupViews];
    
    [outlineView setHeaderView:nil];
    outlineView.action = @selector(clickOutlineView);
    
    if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
        [totalSizeText mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self->selectedSizeText).offset(-35);
            make.left.equalTo(self->selectedSizeText);
        }];
    }else{
        [totalSizeText mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self->selectedSizeText).offset(-35);
            make.left.equalTo(self->selectedSizeText).offset(-4);
        }];
    }
    [self setTitleColorForTextField:totalSizeText];
    
    [self setupPreview];
    
    filterBtnAll.tag = QMFileTypeAll;
    filterBtnMusic.tag = QMFileTypeMusic;
    filterBtnVideo.tag = QMFileTypeVideo;
    filterBtnDocument.tag = QMFileTypeDocument;
    filterBtnInstall.tag = QMFileTypeInstall;
    filterBtnOther.tag = QMFileTypeOther | QMFileTypeArchive | QMFileTypeFolder | QMFileTypePicture;
    filterBtnSelected = filterBtnAll;
    
    __weak __typeof(self) weakSelf = self;
    [previewBtn setOnValueChanged:^(COSwitch *button) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf previewAction:strongSelf->previewBtn];
    }];
    
    topLineView.wantsLayer = YES;
    
    bottomLineView.wantsLayer = YES;
    bottomLineView.layer.backgroundColor = [NSColor colorWithHex:0xEDEDED].CGColor;
    previewLineView.wantsLayer = YES;
    previewLineView.layer.backgroundColor = [NSColor colorWithHex:0xEDEDED].CGColor;
//    previewLineView.hidden = YES;
    
    
    noFileView.hidden = YES;
    
    [backBtn setFocusRingType:NSFocusRingTypeNone];
    
    previewItemPath.rightAlignment = NO;
    
    [backBtn setFont:[NSFontHelper getLightSystemFont:12]];
    [selectedSizeText setFont:[NSFontHelper getLightSystemFont:14]];
//    [previewItemPath setFont:[NSFontHelper getLightSystemFont:12]];
    [noFileDescLabel setFont:[NSFontHelper getLightSystemFont:12]];
    [previewDescText setFont:[NSFontHelper getLightSystemFont:12]];
    
    [self filterBtnSetFont:filterBtnAll
                      font:[NSFontHelper getRegularSystemFont:14]
                     color:[self getColorWithSelect:YES]];
    [self filterBtnSetFont:filterBtnMusic
                      font:[NSFontHelper getLightSystemFont:14]
                     color:[self getColorWithSelect:NO]];
    [self filterBtnSetFont:filterBtnVideo
                      font:[NSFontHelper getLightSystemFont:14]
                     color:[self getColorWithSelect:NO]];
    [self filterBtnSetFont:filterBtnDocument
                      font:[NSFontHelper getLightSystemFont:14]
                     color:[self getColorWithSelect:NO]];
    [self filterBtnSetFont:filterBtnInstall
                      font:[NSFontHelper getLightSystemFont:14]
                     color:[self getColorWithSelect:NO]];
    [self filterBtnSetFont:filterBtnOther
                      font:[NSFontHelper getLightSystemFont:14]
                     color:[self getColorWithSelect:NO]];
    
    MMScroller *scroller = [[MMScroller alloc] init];
    [outlineScrollView setVerticalScroller:scroller];
    outlineScrollView.hasHorizontalScroller = NO;
    outlineScrollView.hasVerticalScroller = YES;
    [outlineView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:topLineView];
    [LMAppThemeHelper setDivideLineColorFor:bottomLineView];
    [LMAppThemeHelper setDivideLineColorFor:previewLineView];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:noFileView];
}

-(NSColor *)getColorWithSelect: (BOOL) isSelect{
    if(isSelect){
        if (@available(macOS 10.14, *)) {
           return [NSColor colorNamed:@"title_color" bundle:[NSBundle bundleForClass:[self class]]];
        } else {

            return [NSColor colorWithHex:FILTER_BTN_COLOR_SEL];
        }
    }else{
        return [NSColor colorWithHex:FILTER_BTN_COLOR_NO_SEL];
    }
    
}

- (int)getFileType:(int)category {
    int type = 5;
    switch (category) {
        case QMFileTypeAll:
            type = 0;
            break;
        case QMFileTypeMusic:
            type = 1;
            break;
        case QMFileTypeVideo:
            type = 2;
            break;
        case QMFileTypeDocument:
            type = 3;
            break;
        case QMFileTypeInstall:
            type = 4;
            break;
        case QMFileTypePicture:
            type = 5;
            break;
        case QMFileTypeOther:
            type = 5;
            break;
        case QMFileTypeArchive:
            type = 5;
            break;
        case QMFileTypeFolder:
            type = 5;
            break;
        default:
            break;
    }
    return type;
}

- (void)setupPreview {
    _previewView = [[QLPreviewView alloc] initWithFrame:previewContainer.bounds style:QLPreviewViewStyleCompact];
    [previewFrame setHidden:YES];
}

- (void)_privateReloadDataView:(QMFileTypeEnum)type orderType:(QMResultOrderEnum)order {
    _loading = YES;
    __weak typeof(self) weakSelf = self;
    [[QMLargeOldManager sharedManager] resultWithFilter:type order:order block:^(NSArray * array, NSArray* allArray) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof(self) strongSelf = weakSelf;
            if(strongSelf == nil) return;
            
            strongSelf->_resultArray = array;
            strongSelf->_resultAllArray = allArray;
            if ([strongSelf->_resultArray count] == 0) {
                strongSelf->selectedItem = nil;
                strongSelf->noFileView.hidden = NO;
            }
            else {
                strongSelf->noFileView.hidden = YES;
                if ([[strongSelf->_resultArray objectAtIndex:0] isKindOfClass:[QMLargeOldResultRoot class]]) {
                    QMLargeOldResultRoot * resultRootItem = [strongSelf->_resultArray objectAtIndex:0];
                    strongSelf->selectedItem = [resultRootItem.subItemArray objectAtIndex:0];
                }
                else {
                    strongSelf->selectedItem = [strongSelf->_resultArray objectAtIndex:0];
                }
            }
            
            [strongSelf showSelectedItemInfo:strongSelf->selectedItem];
            [strongSelf->outlineView reloadData];
            [strongSelf _refreshDeleteStatus];
            
            [strongSelf->outlineView expandItem:nil expandChildren:YES];
            
//            if(self->_previewing) {
//                //直接执行的话会跟outlineview delegate交叉执行导致获取失败，重新抛到主线程执行。
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    NSInteger row = [self->outlineView rowForItem:self->selectedDuplicateBatch];
//                    if(row >= 0) {
//                        NSTableRowView* view = [self->outlineView rowViewAtRow:row makeIfNecessary:NO];
//                        [view setSelected:YES];
//                    }
//                });
//            }
            strongSelf->_loading = NO;
        });
    }];
}

- (void)reloadDataView {
    _resultArray = nil;
    [outlineView reloadData];
    
    [self _privateReloadDataView:(int)filterBtnSelected.tag
                       orderType:QMResultOrderSize];
}

- (void)_refreshDeleteStatus
{
    NSInteger totalSize = 0;
    NSInteger count = 0;
    UInt64 removeSize = 0;
    for (id item in _resultAllArray)
    {
        if ([item isKindOfClass:[QMLargeOldResultItem class]])
        {
            totalSize += [item fileSize];
            if ([item isSelected])
            {
                count++;
                removeSize += [item fileSize];
            }
        }
        else if ([item isKindOfClass:[QMLargeOldResultRoot class]])
        {
            for (QMLargeOldResultItem * resultItem in [item subItemArray])
            {
                totalSize += [resultItem fileSize];
                if (!resultItem.isSelected)
                    continue;
                count++;
                removeSize += [resultItem fileSize];
            }
        }
    }
    if (count > 0)
    {
        NSString * countStr = [NSString stringWithFormat:@"%ld", count];
        NSString * sizeStr =  [NSString stringFromDiskSize:removeSize];
//        NSString * displayStr = [NSString stringWithFormat:@"已选择 %@ 个文件，共 %@", countStr, sizeStr];
//        [selectedSizeText setStringValue:displayStr];
        NSString* totalStr = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMResultViewController__refreshDeleteStatus_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""), countStr, sizeStr];
        NSFont *font = [NSFontHelper getLightSystemFont:14];
        NSMutableAttributedString * attributed = [[NSMutableAttributedString alloc] initWithString:totalStr attributes:@{NSFontAttributeName: font,NSForegroundColorAttributeName:[NSColor colorWithHex:0x94979B]}];
        
        NSRange sizeRange = [totalStr rangeOfString:sizeStr];
        NSRange countRange = [totalStr rangeOfString:countStr];
        [attributed addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0xffaa09] range:sizeRange];
        [attributed addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0xffaa09] range:countRange];

        
        selectedSizeText.attributedStringValue = attributed;
        [cleanBtn setEnabled:YES];
    }
    else
    {
        selectedSizeText.stringValue = NSLocalizedStringFromTableInBundle(@"LMResultViewController__refreshDeleteStatus_selectedSizeText_2", nil, [NSBundle bundleForClass:[self class]], @"");
        [cleanBtn setEnabled:NO];
    }
    NSString * totalSizeStr =  [NSString stringFromDiskSize:totalSize];
    NSString * totalDisplayStr = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMResultViewController__refreshDeleteStatus_NSString_3", nil, [NSBundle bundleForClass:[self class]], @""), totalSizeStr];
    [totalSizeText setStringValue:totalDisplayStr];
}



- (void)showSelectedItemInfo:(QMLargeOldResultItem *)item {
    if(!item || !_previewing) {
        [previewFrame setHidden:YES];
        return;
    }
    [previewFrame setHidden:NO];
    selectedItem = item;
    previewItemName.stringValue = [[NSFileManager defaultManager] displayNameAtPath:selectedItem.filePath];
    [self setTitleColorForTextField:previewItemName];
    previewItemPath.path = selectedItem.filePath;
    previewItemSize.stringValue = [NSString stringFromDiskSize:selectedItem.fileSize];
    [self setTitleColorForTextField:previewItemSize];
    
    if(_previewView && _previewView.superview)
        [_previewView removeFromSuperview];
    _previewView = [[QLPreviewView alloc] initWithFrame:previewContainer.bounds style:QLPreviewViewStyleCompact];
    
    [previewContainer addSubview:_previewView];
    _previewView.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
    [_previewView setPreviewItem:self];

    [_previewView refreshPreviewItem];
    NSLog(@"BigFile showSelectedItemInfo:%d", [self getFileType:selectedItem.fileType]);
    
}

#pragma mark-
#pragma mark preview delegate

- (NSURL *)previewItemURL {
    if (selectedItem == nil || selectedItem.filePath == nil) {
        return nil;
    }
    return [NSURL fileURLWithPath:selectedItem.filePath];
}

- (NSString *)previewItemTitle {
    if (selectedItem == nil || selectedItem.filePath == nil) {
        return nil;
    }
    return selectedItem.filePath;
}

#pragma mark-
#pragma mark outline Row View Delegate

-(BOOL) isPreviewing {
    return _previewing;
}

#pragma mark-
#pragma mark outline View Delegate

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    if ([item isKindOfClass:[QMLargeOldResultRoot class]])
        return 60;
    return 40;
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
    LMBigResultTableRowView *rowView = [[LMBigResultTableRowView alloc] initWithFrame:NSZeroRect];
    rowView.rowViewDelegate = self;
    return rowView;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item {
    if (!item)
        return _resultArray.count;
    return [item subItemArray].count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item {
    if (!item)
        return [_resultArray objectAtIndex:index];
    return [[item subItemArray] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if ([item isKindOfClass:[QMLargeOldResultRoot class]])
        return YES;
    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if(!_previewing)
        return NO;
    if ([item isKindOfClass:[QMLargeOldResultRoot class]])
        return NO;
    return YES;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    return item;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    NSTableCellView* cellView;
    if ([item isKindOfClass:[QMLargeOldResultRoot class]])
        cellView = [outlineView makeViewWithIdentifier:ROOT_CELLVIEW_INDENTIFIER owner:self];
    else
        cellView = [outlineView makeViewWithIdentifier:SUB_ITEM_CELLVIEW_INDENTIFIER owner:self];
    
    [self refreshOutlineViewResult:item cellView:cellView];
    return cellView;
}

- (void)refreshOutlineViewResult:(id)item cellView:(NSTableCellView *)cellView {
    if([item isKindOfClass:QMLargeOldResultRoot.class]) {
        LMRootCellView* rootCellView = (LMRootCellView*)cellView;
        QMLargeOldResultRoot* rootItem = item;
        [rootCellView setCellData:rootItem];
    } else {
        LMSubItemCellView* subItemCellView = (LMSubItemCellView*)cellView;
        QMLargeOldResultItem* resultItem = item;
        [subItemCellView setCellData:resultItem];
        
        if(resultItem == selectedItem && self->_previewing) {
            NSInteger row = [self->outlineView rowForItem:resultItem];
            if(row >= 0) {
                NSTableRowView* view = [self->outlineView rowViewAtRow:row makeIfNecessary:NO];
                [view setSelected:YES];
            }
        }
        
        subItemCellView.checkButton.target = self;
        [subItemCellView.checkButton setAction:@selector(chooseSubItemAction:)];
    }
}

- (void)clickOutlineView {
    int idx = (int) outlineView.clickedRow;
    if (idx < 0) {
        return;
    }
    id item = [outlineView itemAtRow:idx];
    if (item != nil && [item isKindOfClass:QMLargeOldResultRoot.class]) {
        if([outlineView isItemExpanded:item])
            [outlineView.animator collapseItem:item];
        else
            [outlineView.animator expandItem:item];
    } else if (item != nil && [item isKindOfClass:QMLargeOldResultItem.class]) {
        [self showSelectedItemInfo:item];
    }
}


#pragma mark-
#pragma mark user action

//返回响应
- (IBAction)backAction:(id)sender {
    
    [self.view.window.windowController showMainView];
}

//清理响应
- (IBAction)cleanAction:(id)sender {
    NSArray * needRemoveArray = [[QMLargeOldManager sharedManager] needRemoveItem];
    if ([needRemoveArray count] == 0 || _loading)
        return;
    
    [self.view.window.windowController showCleanView];
    
    int count[6] = {0};
    int size[6] = {0};
    for(QMLargeOldResultItem* item in needRemoveArray) {
        count[0]++;
        size[0] += item.fileSize / 1000;
        int type = [self getFileType:item.fileType];
        count[type]++;
        size[type] += item.fileSize / 1000;
    }
}

//排序筛选响应
- (IBAction)popUpButtonAction:(id)sender {
    [self _privateReloadDataView:(int)filterBtnSelected.tag
                       orderType:QMResultOrderSize];
}

//选中item响应
- (void)chooseSubItemAction:(id)sender
{
    NSInteger row = [outlineView rowForView:sender];
    QMLargeOldResultItem * item = [outlineView itemAtRow:row];
    if (!item || _loading)
        return;
    item.isSelected = !item.isSelected;

    [self _refreshDeleteStatus];
    
    QMLargeOldResultRoot *rootItem = [outlineView parentForItem:item];
    NSInteger rootRow = [outlineView rowForItem:rootItem];
    if(rootRow >= 0) {
        NSTableRowView * curTableRowView = [outlineView rowViewAtRow:rootRow makeIfNecessary:NO];
        LMRootCellView * rootCellView =  [curTableRowView viewAtColumn:0];
        [self refreshOutlineViewResult:rootItem cellView:rootCellView];
    }
}

//预览响应
- (void)previewAction:(COSwitch*)switchBtn {
//    NSButton* button = sender;
    if(switchBtn.isOn) {
//    if(button.state == NSOnState) {
        //_previewing的修改需要在setframe之前，frame resize的时候会获取_previewing来调整下拉箭头位置
        _previewing = YES;
        NSRect frame = outlineScrollView.frame;
        frame.size.width = OUTLINE_VIEW_WIDTH_MIN;
        [outlineScrollView setFrame:frame];
        //预览模式需要选中第一个可见子项，如果没有，将第一个父项展开再选中
        CGRect visibleRect = [outlineView visibleRect];
        NSRange range = [outlineView rowsInRect:visibleRect];
        BOOL isNoExpand = YES;
        for(NSUInteger i = 0; i < range.length; i++) {
            id item = [outlineView itemAtRow:i + range.location];
            if([item isKindOfClass:QMLargeOldResultItem.class]) {
                selectedItem = item;
                NSTableRowView* view = [outlineView rowViewAtRow:i + range.location makeIfNecessary:NO];
                [view setSelected:YES];
                isNoExpand = NO;
                break;
            }
        }
        if(isNoExpand && range.length > 0) {
            id item = [outlineView itemAtRow:range.location];
            [outlineView expandItem:item];
            NSTableRowView* view = [outlineView rowViewAtRow:range.location + 1 makeIfNecessary:NO];
            [view setSelected:YES];
            isNoExpand = NO;
        }
        [self showSelectedItemInfo:selectedItem];
    } else {
        _previewing = NO;
        NSRect frame = outlineScrollView.frame;
        frame.size.width = OUTLINE_VIEW_WIDTH_MAX;
        [outlineScrollView setFrame:frame];
        [previewFrame setHidden:YES];
        
        NSInteger row = [outlineView rowForItem:selectedItem];
        if(row >= 0) {
            NSTableRowView* view = [outlineView rowViewAtRow:row makeIfNecessary:NO];
            [view setSelected:NO];
        }
    }
}

//类型筛选响应
- (IBAction)filterAction:(id)sender {
    if(filterBtnSelected) {
        [self filterBtnSetFont:filterBtnSelected
                          font:[NSFontHelper getLightSystemFont:14]
                         color:[self getColorWithSelect:NO]];
    }
    filterBtnSelected = sender;
    [self filterBtnSetFont:filterBtnSelected
                      font:[NSFontHelper getRegularSystemFont:14]
                     color:[self getColorWithSelect:YES]];
    
    
    [self _privateReloadDataView:(int)filterBtnSelected.tag
                       orderType:QMResultOrderSize];
    NSLog(@"BigFile filterAction:%d", [self getFileType:(int)filterBtnSelected.tag]);
}

- (void)filterBtnSetFont:(NSButton*)btn font:(NSFont*)font color:(NSColor*)color {
    NSString *str = btn.attributedTitle.string;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]init];
    NSDictionary *dictAttr = @{NSFontAttributeName:font, NSForegroundColorAttributeName:color};
    NSAttributedString *attr = [[NSAttributedString alloc]initWithString:str attributes:dictAttr];
    [attributedString appendAttributedString:attr];
    btn.attributedTitle = attributedString;
}

////打开文件位置
//- (IBAction)showInFinderAction:(id)sender {
//    NSInteger row = [outlineView clickedRow];
//    if (row == -1)
//        row = [sender tag];
//    if (row == -1)
//        return;
//    id item = [outlineView itemAtRow:row];
//    if ([item isKindOfClass:[QMLargeOldResultItem class]])
//        [[NSWorkspace sharedWorkspace] selectFile:[item filePath]
//                         inFileViewerRootedAtPath:[[item filePath] stringByDeletingLastPathComponent]];
//}

//预览模式打开文件位置
- (IBAction)showInFinderPreviewAction:(id)sender {
    if(selectedItem == nil)
        return;
    [[NSWorkspace sharedWorkspace] selectFile:[selectedItem filePath]
                     inFileViewerRootedAtPath:[[selectedItem filePath] stringByDeletingLastPathComponent]];
}

#pragma mark-
#pragma mark window event

- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"windowWillClose result view controller");
}

@end
