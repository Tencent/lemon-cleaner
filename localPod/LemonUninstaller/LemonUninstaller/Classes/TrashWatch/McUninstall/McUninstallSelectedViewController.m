//
//  McUninstallSelectedViewController.m
//  LemonMonitor
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "McUninstallSelectedViewController.h"
#import <QMCoreFunction/QMStatusItem.h>
#import <QMCoreFunction/QMExtension.h>
#import <QMUICommon/QMTrackOutlineView.h>
#import <QMUICommon/QMTrackScrollView.h>
#import <QMUICommon/MMScroller.h>
#import "LMLocalApp.h"
#import <QMUICommon/LMAppThemeHelper.h>

@interface McUninstallSelectedCellView : NSTableCellView
@property (nonatomic, assign) NSInteger cellRow;
@property (nonatomic, assign) QMTrackOutlineView *outlineView;
@property (nonatomic, assign) IBOutlet NSButton *checkButton;
@property (nonatomic, assign) IBOutlet NSTextField *sizeField;


@end

#define SizeLabelNormalOriginX  215
#define SizeLabelTrackOriginX  230


@implementation McUninstallSelectedCellView
@synthesize cellRow;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setUp];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self)
    {
        [self setUp];
    }
    return self;
}

- (void)setUp
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(trackRowDidChanged:)
                                                 name:@"QMTrackRowDidChangedNotification"
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSInteger)cellRow
{
    return cellRow;
}

- (void)setCellRow:(NSInteger)value
{
    cellRow = value;
    
    NSRect frame = self.sizeField.frame;
    if (self.cellRow == self.outlineView.trackRow)
        frame.origin.x = SizeLabelNormalOriginX;
    else
        frame.origin.x = SizeLabelTrackOriginX;
    [self.sizeField setFrame:frame];
}

- (void)trackRowDidChanged:(NSNotification *)notify
{
    if (notify.object == self.outlineView)
    {
        NSRect frame = self.sizeField.frame;
        if (self.cellRow == self.outlineView.trackRow)
            frame.origin.x = SizeLabelNormalOriginX;
        else
            frame.origin.x = SizeLabelTrackOriginX;
        [[self.sizeField animator] setFrame:frame];
    }
}

@end

@interface McUninstallSelectedViewController ()
{
//    NSMutableArray *showItems_old;
    NSMutableArray *showItems;
}
@end

@implementation McUninstallSelectedViewController
@synthesize delegate;
@synthesize soft;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (id)init
{
    self = [super initWithNibName:@"McUninstallSelectedViewController" bundle:[NSBundle bundleForClass:self.class]];
    if (self)
    {
//        showItems_old = [[NSMutableArray alloc] init];
    }
    return self;
}


-(void)initI18n{

    [checkAllButton setTitle:NSLocalizedStringFromTableInBundle(@"ButtonSelectAll", nil, [NSBundle bundleForClass:[self class]], @"")];
    [uninstallButton setTitle:NSLocalizedStringFromTableInBundle(@"ButtonUninstall", nil, [NSBundle bundleForClass:[self class]], @"")];
    [cancelButton setTitle:NSLocalizedStringFromTableInBundle(@"ButtonCancel", nil, [NSBundle bundleForClass:[self class]], @"")];
}


- (void)awakeFromNib {
    MMScroller *scroller = [[MMScroller alloc] init];
    [_scrollView setVerticalScroller:scroller];
    [_scrollView setHasHorizontalScroller:NO];
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor whiteColor].CGColor;
    [self initI18n];
    if (@available(macOS 11, *)) {
        listView.style = NSTableViewStyleFullWidth;
    }
}

- (void)loadView
{
    [super loadView];
    [listView setFloatsGroupRows:NO];
    
    NSImage *showImg = [[NSBundle bundleForClass:self.class] imageForResource:@"btn_showInFinder"];
    NSButton *showButton = [[NSButton alloc] initWithFrame:NSMakeRect(NSWidth(listView.frame)-showImg.size.width - 15, 0, showImg.size.width, showImg.size.height)];
    [showButton setAutoresizingMask:NSViewMinXMargin];
    [showButton setBordered:NO];
    [showButton setButtonType:NSToggleButton];
    [showButton setImage:showImg];
    [showButton setTarget:self];
    [showButton setAction:@selector(showInFinder:)];
    listView.overView = showButton;
    listView.hideGroupMark = YES;
    
    [checkAllButton setFontColor:[NSColor intlTitleColor]];
    [LMAppThemeHelper setDivideLineColorFor:lineView];
    [self setUp];
}

- (LMLocalApp *)soft
{
    return soft;
}

- (void)setSoft:(LMLocalApp *)value
{
    soft = value;
    [self setUp];
}

- (void)setUp
{
//    [showItems_old removeAllObjects];
    [iconView setImage:nil];
    [titleView setStringValue:@""];
    [checkAllButton setState:NSOnState];
    if (!soft)
    {
        return;
    }
    
    showItems = [[NSMutableArray alloc] init];
    for (LMFileGroup *group in soft.fileItemGroup) {
        [showItems addObjectsFromArray:group.filePaths];
    }
    //配置列表的数据源
    for (LMFileItem *fileItem in showItems)
    {
//        QMStatusItem *showItem = [QMStatusItem itemWithObject:fileItem];

        //默认让Other类型的文件不勾选
        if (fileItem.type == LMFileTypeOther)
        {
            fileItem.isSelected = NO;
            [checkAllButton setState:NSOffState];
        }else
        {
            fileItem.isSelected = YES;
        }

//        [showItems_old addObject:showItem];
    }
    
   
    //刷新列表
    [listView reloadData];
    [listView expandItem:nil expandChildren:YES];
    
    //设置Icon和提示文字
    [self refreshText];
    [iconView setImage:soft.icon];
}


//刷新提示文字
- (void)refreshText
{
    BOOL selectedOne = NO;
    NSInteger count = 0;
    size_t size = 0;
//    for (QMStatusItem *showItem in showItems_old)
//    {
//        if (showItem.status == NSOnState)
//        {
//            count++;
//            selectedOne = YES;
//            size += [(McSoftwareFileItem*)showItem.object fileSize];
//        }
//    }
    
    for (LMFileGroup *group in soft.fileItemGroup) {
        if (group.selectedState != NSOffState) {
            selectedOne = YES;
            count += group.selectedCount;
            size += group.selectedSize;
        }
    
    }

    [uninstallButton setEnabled:selectedOne];
    
    NSString *countString = [NSString stringWithFormat:@"%lu", count];
    NSString *sizeString = [NSString stringFromDiskSize:size];
    NSString *appName = [soft.showName truncatesString:QMTruncatingTail length:16]; //防止 appName 过长
    

    NSString *titleString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"McUninstallSelectedViewController_refreshText_titleString_1",
                                                                                          nil,
                                                                                          [NSBundle bundleForClass:[self class]], @""),
                                                                                        appName, countString, sizeString];
    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:titleString
                                                                                      attributes:@{NSForegroundColorAttributeName: [LMAppThemeHelper getTitleColor],
                                                                                                   NSFontAttributeName: [NSFont systemFontOfSize:13.0]}];
    
    NSString *tempTitleString = [titleString stringByReplacingOccurrencesOfString:appName withString:@""]; //防止 countRange被appName匹配到 (appName可能正好匹配到count这个数字)
    NSRange tempCountRange = [tempTitleString rangeOfString:countString];
    NSRange countRange = NSMakeRange(tempCountRange.location + [appName length], tempCountRange.length);
    [attributedStr addAttribute:NSForegroundColorAttributeName value:[NSColor intlBlueColor] range:countRange];
    
    NSRange sizeRange = [titleString rangeOfString:sizeString];
    [attributedStr addAttribute:NSForegroundColorAttributeName value:[NSColor intlBlueColor] range:sizeRange];
    [titleView setAttributedStringValue:attributedStr];
}

//- (NSArray *)selectedItems
//{
//    NSMutableArray *selectedArray = [[NSMutableArray alloc] init];
//    for (QMStatusItem *showItem in showItems_old)
//    {
//        if (showItem.status == NSOnState)
//        {
//            [selectedArray addObject:showItem.object];
//        }
//    }
//    return selectedArray;
//}

- (void)showInFinder:(id)sender
{
    NSInteger idx = [listView trackRow];
    if (idx == -1)
    {
        return;
    }
//    QMStatusItem *showItem = [listView itemAtRow:idx];
//    McSoftwareFileItem *item = showItem.object;
    LMFileItem *item = [listView itemAtRow:idx];
    [[NSWorkspace sharedWorkspace] selectFile:item.path inFileViewerRootedAtPath:[item.path stringByDeletingLastPathComponent]];
}

- (void)checkCellClick:(id)sender
{
    NSInteger idx = [listView rowForView:sender];
//    QMStatusItem *showItem = [listView itemAtRow:idx];
//    showItem.status = !showItem.status;
    
    LMFileItem *showItem = [listView itemAtRow:idx];
    showItem.isSelected = !showItem.isSelected;
    
    [listView reloadItem:showItem];
    
    //遍历所有元素,判定当前是否全选
    BOOL checkAll = YES;
    BOOL okEnabled = NO;
#pragma unused(okEnabled)
//    for (QMStatusItem *showItem in showItems_old)
//    {
//        if (showItem.status == NSOnState)
//        {
//            okEnabled = YES;
//        }
//        else
//        {
//            checkAll = NO;
//        }
//    }
    for (LMFileItem *showItem in showItems) {
        if (showItem.isSelected) {
            okEnabled = YES;
        } else{
            checkAll = NO;
        }
    }
    [checkAllButton setState:checkAll?NSOnState:NSOffState];
    [self refreshText];
}

#pragma mark -
#pragma mark 用户交互

- (IBAction)checkAllClick:(id)sender
{
//    for (QMStatusItem *showItem in showItems_old)
//    {
//        showItem.status = checkAllButton.state;
//    }
    for (LMFileItem *showItem in showItems) {
        showItem.isSelected = checkAllButton.state;
    }
    
    [listView reloadData];
    [self refreshText];
}

- (IBAction)cancelClick:(id)sender
{
    if ([delegate respondsToSelector:@selector(selectedDidCancel:)])
    {
        [delegate selectedDidCancel:self];
    }
}

- (IBAction)uninstallClick:(id)sender
{
    if ([delegate respondsToSelector:@selector(selectedDidDone:withSoft:)])
    {
        [delegate selectedDidDone:self withSoft:soft];
    }
}

#pragma mark -
#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item)
    {
        return [showItems count];
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item)
    {
        return [showItems objectAtIndex:index];
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return nil;
}

#pragma mark -
#pragma mark NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    McUninstallSelectedCellView *cellView = [outlineView makeViewWithIdentifier:@"Cell" owner:nil];
    cellView.outlineView = listView;
    cellView.cellRow = [listView rowForItem:item];
    
//    QMStatusItem *showItem = (QMStatusItem *)item;
//    McSoftwareFileItem *fileItem = showItem.object;
    LMFileItem *fileItem = (LMFileItem *)item;
    
    //勾选按钮
    [cellView.checkButton setTarget:self];
    [cellView.checkButton setAction:@selector(checkCellClick:)];
    [cellView.checkButton setState:fileItem.isSelected];
    
    //文件图标
    [cellView.imageView setImage:fileItem.icon];
    
    //文件名字
    [cellView.textField setStringValue:fileItem.name];
    
    //文件大小
    [cellView.sizeField setStringValue:[NSString stringFromDiskSize:fileItem.size]];
    return cellView;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    return 30;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    return NO;
}

@end
