//
//  McUninstallDetailViewController.m
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "McUninstallDetailViewController.h"
#import "QMSoftwareHelp.h"
#import "NSString+Extension.h"
#import "NSColor+Extension.h"
#import "McUninstallWindowController.h"
#import "McDetailOutlineItemCellView.h"
#import "McDetailOutlineGroupCellView.h"
#import "LMOutlineRowView.h"
#import "QMMoveOutlineView.h"
#import "NSFontHelper.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/MMScroller.h>
#import <QMUICommon/LMGradientTitleButton.h>
#import <QMUICommon/LMBorderButton.h>
#import <QMUICommon/LMRectangleButton.h>
#import "NSButton+Extension.h"
#import "NSFileManager+Extension.h"
#import <QMUICommon/LMAppThemeHelper.h>

@interface McUninstallDetailViewController () {
    LMLocalApp *_soft;
}

@property (weak) IBOutlet NSImageView *appIcon;
@property (weak) IBOutlet NSTextField *appName;
@property (weak) IBOutlet NSTextField *lastUsed;
@property (weak) IBOutlet NSTextField *totalSize;
@property (weak) IBOutlet NSTextField *selectAll;
@property (weak) IBOutlet NSView *topLine;
@property (weak) IBOutlet NSView *bottomLine;
@property (strong) IBOutlet NSButton *showFinderButton;
@property (weak) IBOutlet NSTextField *windowTitle;
@property (weak) IBOutlet LMCheckboxButton *checkAll;
@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet LMBorderButton *cancelBtn;
@property (weak) IBOutlet LMRectangleButton *okBtn;

@end

@interface McUninstallDetailViewController()<NSOutlineViewDataSource, NSOutlineViewDelegate>
@property (weak) IBOutlet QMMoveOutlineView *outlineView;

@end

@implementation McUninstallDetailViewController 


- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        
    }
    return self;
}
-(void)initViewText{
    [self.windowTitle setStringValue:@""];
    [self.lastUsed setStringValue:NSLocalizedStringFromTableInBundle(@"McUninstallDetailViewController_initViewText_lastUsed_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.selectAll setStringValue:NSLocalizedStringFromTableInBundle(@"McUninstallDetailViewController_initViewText_selectAll_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.cancelBtn setTitle:NSLocalizedStringFromTableInBundle(@"McUninstallDetailViewController_initViewText_cancelBtn_3", nil, [NSBundle bundleForClass:[self class]], @"")];
    [self.okBtn setTitle:NSLocalizedStringFromTableInBundle(@"McUninstallDetailViewController_initViewText_okBtn_4", nil, [NSBundle bundleForClass:[self class]], @"")];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initViewText];
    self.windowTitle.font = [NSFontHelper getMediumSystemFont:16];
    self.windowTitle.textColor = [LMAppThemeHelper getTitleColor];
    
    self.appName.textColor = [LMAppThemeHelper getTitleColor];
    self.lastUsed.textColor = [NSColor colorWithHex:0x94979B];
    self.totalSize.textColor = [LMAppThemeHelper getTitleColor];;
    self.selectAll.textColor = [NSColor colorWithHex:0x7e7e7e];
    self.appIcon.imageScaling = NSImageScaleProportionallyUpOrDown;
////    [self.cancelBtn setFontColor:[NSColor colorWithHex:0x7e7e7e]];
//    [self.okBtn setTitleNormalColor:[NSColor colorWithHex:0xffffff]];
//    [self.okBtn setTitleDownColor:[NSColor colorWithHex:0xffffff]];
//    [self.okBtn setTitleHoverColor:[NSColor colorWithHex:0xffffff]];
//    [self.okBtn setTitleDisableColor:[NSColor colorWithHex:0xffffff]];
//    self.view.wantsLayer = true;
//    self.view.layer.backgroundColor = [NSColor redColor].CGColor;
    self.outlineView.action = @selector(clickOutlineView);
    [self.outlineView hiddenMoveButton];
    [self.outlineView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
    if (@available(macOS 11.0, *)) {
        self.outlineView.style = NSTableViewStyleFullWidth;
    } else {
        // Fallback on earlier versions
    }
    
    MMScroller *scroller = [[MMScroller alloc] init];
    [self.scrollView setVerticalScroller:scroller];
    [self.scrollView setHasHorizontalScroller:NO];

}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:self.topLine];
    [LMAppThemeHelper setDivideLineColorFor:self.bottomLine];
}

-(void)setSoft:(LMLocalApp *)soft{
    NSLog(@"%s, soft:%@", __FUNCTION__, soft);
    _soft = soft;
   
    self.appIcon.image = _soft.icon;
    self.appName.stringValue = _soft.showName;
    self.lastUsed.stringValue = [QMSoftwareHelp dateDistance:_soft.lastUsedDate];
    self.totalSize.stringValue = [NSString stringFromDiskSize:_soft.totalSize];
    [self.outlineView reloadData];
    [self.outlineView expandItem:nil expandChildren:YES];
    [self updateCheckAllBtn];
    [self updateOkBtnState];
}

- (LMLocalApp *)soft {
    return _soft;
}

- (IBAction)cancelClicked:(id)sender {
    [self.view.window.windowController showUninstallListView];
}



#pragma mark -
#pragma mark outlineview

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    if ([item isKindOfClass:[LMFileGroup class]])
        return 46;
    return 36;
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
    LMOutlineRowView *rowView = [[LMOutlineRowView alloc] initWithFrame:NSZeroRect];
    return rowView;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        return self.soft.validFileItemGroup.count;
    } else if ([item isKindOfClass:[LMFileGroup class]]) {
        return ((LMFileGroup *)item).filePaths.count;
    } else {
        return 0;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        return (self.soft.validFileItemGroup)[index];
    } else if ([item isKindOfClass:[LMFileGroup class]]){
        return (((LMFileGroup *)item).filePaths)[index];
    } else {
        return nil;
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [item isKindOfClass:[LMFileGroup class]];
//    return false;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    // Every regular view uses bindings to the item. The "Date Cell" needs to have the date extracted from the fileURL
    return item;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
//    return [item isKindOfClass:[McUninstallItemTypeGroup class]];
    return false;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if ([item isKindOfClass:[LMFileGroup class]])
        return NO;
    return YES;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([item isKindOfClass:[LMFileGroup class]]) {
        // Everything is setup in bindings
        McDetailOutlineGroupCellView *groupView = (McDetailOutlineGroupCellView *)[outlineView makeViewWithIdentifier:@"groupCell" owner:self];
        NSInteger type = [(LMFileGroup *)item fileType];
        [groupView.groupName setTextColor:[NSColor colorWithHex:0x94979B]];
        [groupView.groupName setStringValue:(NSString *)[LMFileItem getLMFileTypeName:type]];
        [groupView.checkButton setState:[(LMFileGroup *)item selectedState]];
        groupView.checkButton.target = self;
        [groupView.checkButton setAction:@selector(checkClick:)];
        return groupView;
        
    } else {
        McDetailOutlineItemCellView *itemView =(McDetailOutlineItemCellView *)[outlineView makeViewWithIdentifier:@"itemCell" owner:self];
        
        LMFileItem *fileItem = (LMFileItem *) item;
        
        [itemView.textFileName setTextColor:[LMAppThemeHelper getTitleColor]];
        [itemView.textSize setTextColor:[LMAppThemeHelper getTitleColor]];
        [itemView.textVersion setTextColor:[NSColor colorWithHex:0x94979B]];
        [itemView.textFileName setStringValue:fileItem.name];
        NSInteger maxWidthOfFileName = 200;
        
        if (fileItem.type == LMFileTypeBundle) {
            maxWidthOfFileName = 160;
        }
        [itemView.textFileName mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(itemView.textFileName);
            make.height.equalTo(itemView.textFileName);
            make.left.equalTo(itemView.icon.mas_right).offset(14);
            make.centerY.equalTo(itemView.mas_centerY);
            make.width.lessThanOrEqualTo([NSNumber numberWithInteger:maxWidthOfFileName]);
        }];
        
        [itemView.textSize setStringValue:[NSString stringFromDiskSize:fileItem.size]];
        [itemView.icon setImage:fileItem.icon];
        
        [itemView.btnShowFinder setHidden:YES];
        [itemView.pathBarView setHidden:YES];
        
        if([LMFileItem needShowPath:fileItem] ){
            [itemView.pathBarView setPath:fileItem.path];
            itemView.needShowPath = YES;
        }else{
            [itemView.textSize setHidden:YES];
            itemView.needShowPath = NO;
        }
        [itemView.checkButton setState:fileItem.isSelected];
        itemView.path = fileItem.path;
        itemView.checkButton.target = self;
        [itemView.checkButton setAction:@selector(checkClick:)];
        
        
        if (fileItem.type == LMFileTypeBundle) {
            itemView.textVersion.hidden = NO;
            NSString *version = [QMSoftwareHelp getVersionOfBundlePath:fileItem.path];
            //TODO 很多程序比如说 python 使用现有方法不能获取版本号(没有 infoPlist 文件),是不是换种方式获取版本号.
            if (version) {
                [itemView.textVersion setStringValue:version];
            } else {
                NSString *unknownStr =  NSLocalizedStringFromTableInBundle(@"String_UnKnown", nil, [NSBundle bundleForClass:[self class]], @"");
                [itemView.textVersion setStringValue:unknownStr];
            }
            [itemView.textVersion setWantsLayer:YES];
            [itemView.textVersion setBordered:YES];
            itemView.textVersion.layer.borderColor = [NSColor colorWithHex:0xd8d8d8].CGColor;
            itemView.textVersion.layer.borderWidth = 1;
            itemView.textVersion.alignment = NSTextAlignmentCenter;
            
            
            NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:itemView.textVersion.font, NSFontAttributeName, nil];
            CGFloat versionWidth =  [[[NSAttributedString alloc] initWithString:itemView.textVersion.stringValue attributes:attributes] size].width;
            
            [itemView.textVersion mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.equalTo(@(versionWidth + 10));
                make.height.equalTo(@18);
                make.left.equalTo(itemView.textFileName.mas_right).offset(20);
                make.baseline.equalTo(itemView.textFileName.mas_baseline);
            }];
            
            [itemView.pathBarView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(itemView.textVersion.mas_right).offset(20);
                make.right.equalTo(itemView).offset(-120);
                make.height.equalTo(@20);
                make.centerY.equalTo(itemView.textFileName);
            }];
            
        }else{
            itemView.textVersion.hidden = YES;
            
            [itemView.pathBarView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(itemView).offset(310);
                make.right.equalTo(itemView).offset(-120);
                make.height.equalTo(@20);
                make.centerY.equalTo(itemView.textFileName);
            }];
        }

        
        return itemView;
    }
    return nil;
}


- (void)clickOutlineView {
    int idx = (int) self.outlineView.clickedRow;
    if (idx < 0) {
        return;
    }
    id item = [self.outlineView itemAtRow:idx];
    if (item != nil && [item isKindOfClass:LMFileGroup.class]) {
        if([self.outlineView isItemExpanded:item])
            [self.outlineView.animator collapseItem:item];
        else
            [self.outlineView.animator expandItem:item];
    }
//    } else if (item != nil && [item isKindOfClass:McSoftwareFileItem.class]) {
////        [self showSelectedItemInfo:item];
//    }
}


- (void)checkClick:(id)sender
{
    int idx = (int) [self.outlineView rowForView:sender];
    if (idx < 0) {
        return;
    }
    id item = [self.outlineView itemAtRow:idx];
    if (item != nil && [item isKindOfClass:LMFileItem.class]) {
        LMFileItem *fileItem = (LMFileItem *)item;
        fileItem.isSelected = !fileItem.isSelected;
        id parentItem = [self.outlineView parentForItem:item];
        
          if (@available(macOS 10.13, *)) {
              [self.outlineView reloadItem:fileItem];
              [self.outlineView reloadItem:parentItem];
          }else{
              [self.outlineView reloadData];
          }
   
    } else if ([item isKindOfClass:LMFileGroup.class]) {
        LMFileGroup *groupItem = (LMFileGroup *) item;
        NSControlStateValue state = NSOffState;
        if (groupItem.selectedState == NSOffState) {
            state = NSOnState;
        } 
        for (LMFileItem *fileItem in groupItem.filePaths) {
            fileItem.isSelected = state;
        }
        if (@available(macOS 10.13, *)) {
            [self.outlineView reloadData];
        }else{
            [self.outlineView reloadItem:item reloadChildren:YES];
        }
    }
    [self updateCheckAllBtn];
    [self updateOkBtnState];
}

- (BOOL)isAllItemCheck {
    for (LMFileGroup *group in self.soft.fileItemGroup) {
        if ([group.filePaths count] == 0)
            continue;
        
        if (group.selectedState != NSOnState){
            return NO;
        }
    }
    return YES;
}

- (BOOL)isAllItemUnCheck {
    for (LMFileGroup *group in self.soft.fileItemGroup) {
        if ([group.filePaths count] == 0)
            continue;
        
        if (group.selectedState != NSOffState){
            return NO;
        }
    }
    return YES;
}

- (void)updateOkBtnState {
    BOOL unCheckAll = [self isAllItemUnCheck];
    [self.okBtn setEnabled:!unCheckAll];
}


- (void)updateCheckAllBtn {
    BOOL checkAll = [self isAllItemCheck];
    [self.checkAll setState:checkAll];
}

- (IBAction)checkAllClicked:(id)sender {
    BOOL isCheckAll = self.checkAll.state;
    for (LMFileGroup *group in self.soft.fileItemGroup) {
        for (LMFileItem *fileItem in group.filePaths) {
            fileItem.isSelected = isCheckAll;
        }
    }
    [self.outlineView reloadData];
    [self updateOkBtnState];
}

- (IBAction)okClicked:(id)sender {
    [self.view.window.windowController uninstallSoft:_soft];
}
@end
