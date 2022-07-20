//
//  OwlLogViewController.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlLogViewController.h"
#import "OwlTableRowView.h"
#import "OwlManager.h"
#import "OwlConstant.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/MMScroller.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/LMAppThemeHelper.h>

@interface OwlCellView : NSView
@property (nonatomic, strong) NSTextField *labelTime;
@property (nonatomic, strong) NSTextField *labelEvent;

@end

@implementation OwlCellView

- (instancetype)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.labelTime = [[NSTextField alloc] init];
        self.labelTime.alignment = NSTextAlignmentLeft;
        self.labelTime.bordered = NO;
        self.labelTime.editable = NO;
        self.labelTime.backgroundColor = [NSColor clearColor];
        self.labelTime.font = [NSFontHelper getLightSystemFont:12];
        self.labelTime.textColor = [NSColor colorWithHex:0x94979B];
        [self addSubview:self.labelTime];
        
        self.labelEvent = [[NSTextField alloc] init];
        self.labelEvent.alignment = NSTextAlignmentLeft;
        self.labelEvent.bordered = NO;
        self.labelEvent.editable = NO;
        self.labelEvent.backgroundColor = [NSColor clearColor];
        self.labelEvent.font = [NSFontHelper getLightSystemFont:12];
        self.labelEvent.textColor = [NSColor colorWithHex:0x94979B];
        [self addSubview:self.labelEvent];
        
        
        [self.labelTime mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self.mas_left).offset(50);
            make.width.equalTo(@(170));
        }];
        [self.labelEvent mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self.labelTime.mas_right);
            make.width.equalTo(@(600-170));
        }];
    }
    return self;
}
- (void)drawRect:(NSRect)dirtyRect{
    
}
@end

@interface OwlLogViewController () <NSTableViewDelegate, NSTableViewDataSource> {
    NSTableView *tableView;
    NSString *timeIdentifier;
    NSString *eventIdentifier;
}
@property (weak)NSView *bLineview;
@end

@implementation OwlLogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (instancetype)initWithFrame:(NSRect)frame{
    self = [super init];
    if (self) {
        NSView *contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height - 0/*OwlWindowTitleHeight*/)];
        contentView.wantsLayer = YES;
        CALayer *layer = [[CALayer alloc] init];
        layer.backgroundColor = [NSColor whiteColor].CGColor;
        contentView.layer = layer;
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height - OwlWindowTitleHeight - 29)];
        
        tableView = [[NSTableView alloc] init];
        [tableView setDelegate:self];
        [tableView setDataSource:self];
        [tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
        [tableView setAutoresizesSubviews:YES];
        tableView.headerView = nil;
        if (@available(macOS 11.0, *)) {
            tableView.style = NSTableViewStyleFullWidth;
        }
        timeIdentifier = @"OwlLogCellTime";
        eventIdentifier = @"OwlLogCellEvent";
        //[tableView registerNib:nil forIdentifier:timeIdentifier];
        //[contentView.contentView addSubview:tableView];
        
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutohidesScrollers:YES];
        [scrollView setAutoresizesSubviews:YES];
        [scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [scrollView setDocumentView:tableView];
        
        MMScroller *scroller = [[MMScroller alloc] init];
        [scrollView setVerticalScroller:scroller];
        [tableView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
        
        //NSTableHeaderView *headerView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 300, 30)];
        //[tableView setHeaderView:headerView];
        NSTableColumn *timeColumn = [[NSTableColumn alloc] initWithIdentifier:timeIdentifier];
        timeColumn.width = frame.size.width;
        //[timeColumn.headerCell setStringValue:@"时间"];
        [timeColumn.headerCell setFont:[NSFontHelper getMediumSystemFont:12]];
        [timeColumn.headerCell setTextColor:[LMAppThemeHelper getSecondTextColor]];
        [timeColumn.headerCell setAlignment:NSTextAlignmentCenter];
        [tableView addTableColumn:timeColumn];
//
//        NSTableColumn *eventColumn = [[NSTableColumn alloc] initWithIdentifier:eventIdentifier];
//        eventColumn.width = frame.size.width - OwlLogCellWidth;
//        [eventColumn.headerCell setStringValue:@"事件"];
//        [eventColumn.headerCell setFont:[NSFontHelper getMediumSystemFont:18]];
//        [eventColumn.headerCell setTextColor:[NSColor colorWithHex:0x7E7E7E]];
//        [eventColumn.headerCell setAlignment:NSTextAlignmentCenter];
//        [tableView addTableColumn:eventColumn];
        
//        [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(scrollView.mas_top).offset(20);
//            make.height.equalTo(@(frame.size.height-20));
//            make.width.equalTo(scrollView);
//        }];
        tableView.frame = NSMakeRect(0, 0, scrollView.frame.size.width, scrollView.frame.size.height);
        [contentView addSubview:scrollView];
        self.view = contentView;
        
        NSTextField *tfTitle = [[NSTextField alloc] initWithFrame:NSZeroRect];
        tfTitle.alignment = NSTextAlignmentCenter;
        tfTitle.bordered = NO;
        tfTitle.editable = NO;
        tfTitle.backgroundColor = [NSColor clearColor];
        tfTitle.stringValue = NSLocalizedStringFromTableInBundle(@"OwlLogViewController_initWithFrame_tfTitle_1", nil, [NSBundle bundleForClass:[self class]], @"");
        tfTitle.font = [NSFontHelper getMediumSystemFont:16];
        tfTitle.textColor = [LMAppThemeHelper getTitleColor];
        [contentView addSubview:tfTitle];
        
        NSView *bLineview = [[NSView alloc] init];
        CALayer *lineLayer = [[CALayer alloc] init];
        lineLayer.backgroundColor = [NSColor colorWithWhite:0.90 alpha:1].CGColor;
        bLineview.layer = lineLayer;
        self.bLineview = bLineview;
        [contentView addSubview:bLineview];
        
        NSTextField *labelTime = [[NSTextField alloc] init];
        labelTime.alignment = NSTextAlignmentLeft;
        labelTime.bordered = NO;
        labelTime.editable = NO;
        labelTime.stringValue = NSLocalizedStringFromTableInBundle(@"OwlLogViewController_initWithFrame_labelTime_2", nil, [NSBundle bundleForClass:[self class]], @"");
        labelTime.backgroundColor = [NSColor clearColor];
        labelTime.font = [NSFontHelper getMediumSystemFont:12];
        labelTime.textColor = [LMAppThemeHelper getSecondTextColor];
        [contentView addSubview:labelTime];
        
        NSTextField *labelEvent = [[NSTextField alloc] init];
        labelEvent.alignment = NSTextAlignmentLeft;
        labelEvent.bordered = NO;
        labelEvent.editable = NO;
        labelEvent.stringValue = NSLocalizedStringFromTableInBundle(@"OwlLogViewController_initWithFrame_labelEvent_3", nil, [NSBundle bundleForClass:[self class]], @"");
        labelEvent.backgroundColor = [NSColor clearColor];
        labelEvent.font = [NSFontHelper getMediumSystemFont:12];
        labelEvent.textColor = [LMAppThemeHelper getSecondTextColor];
        [contentView addSubview:labelEvent];
        
        [tfTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@9);
            make.centerX.equalTo(contentView);
        }];
        [labelTime mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(52));
            if (@available(macOS 11.0, *)) {
                make.left.equalTo(contentView.mas_left).offset(55);
            } else {
                make.left.equalTo(contentView.mas_left).offset(50);
            }
            make.width.equalTo(@(170));
        }];
        [labelEvent mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(52));
            if (@available(macOS 11.0, *)) {
                make.left.equalTo(@(170+55));
            } else {
                make.left.equalTo(@(170+50));
            }
            make.width.equalTo(@(170));
        }];
        [bLineview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(OwlWindowTitleHeight));
            make.left.equalTo(contentView);
            make.height.equalTo(@1);
            make.width.equalTo(contentView);
        }];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(owlLogChange:) name:OwlLogChangeNotication object:nil];
    }
    return self;
}



- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:self.bLineview];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)owlLogChange:(NSNotification*)no{
    NSLog(@"owlLogChange");
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
    NSString *idenifier = @"";
    NSString *strValue = @"";
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] init];
    strValue = [[[OwlManager shareInstance].logArray objectAtIndex:row] objectForKey:@"time"];
    NSString *appName = [[[OwlManager shareInstance].logArray objectAtIndex:row] objectForKey:OwlAppName];
    appName = [appName stringByAppendingString:@"  "];
    NSString *event = [[[OwlManager shareInstance].logArray objectAtIndex:row] objectForKey:@"event"];
    NSString *strLanguageKey = nil;
    if ([event isEqualToString:@"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_1"]) {
        strLanguageKey = @"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_1";
    } else if ([event isEqualToString:@"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_2"]) {
        strLanguageKey = @"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_2";
    } else if ([event isEqualToString:@"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_3"]) {
        strLanguageKey = @"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_3";
    } else if ([event isEqualToString:@"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_4"]) {
        strLanguageKey = @"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_4";
    } else if ([event isEqualToString:@"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_5"]) {
        strLanguageKey = @"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_5";
    } else if ([event isEqualToString:@"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_6"]) {
        strLanguageKey = @"OwlManager_analyseDeviceInfoForNotificationWithArray_NSString_6";
    }
    if (strLanguageKey) {
        event = NSLocalizedStringFromTableInBundle(strLanguageKey, nil, [NSBundle bundleForClass:[self class]], @"");
    }
    
    [attributed appendAttributedString:[[NSAttributedString alloc] initWithString:appName attributes:@{NSFontAttributeName: [NSFontHelper getMediumSystemFont:12],
                                                                                                       NSForegroundColorAttributeName:[LMAppThemeHelper getTitleColor]}]];
    [attributed appendAttributedString:[[NSAttributedString alloc] initWithString:event attributes:@{NSFontAttributeName: [NSFontHelper getLightSystemFont:12],
                                                                                                     NSForegroundColorAttributeName:[NSColor colorWithHex:0x94979B]}]];
    OwlCellView *view = [tableView makeViewWithIdentifier:@"owlLogCellView" owner:self];
    if (view == nil) {
        view = [[OwlCellView alloc] initWithFrame:NSMakeRect(0, 0, tableColumn.width, 32)];
        view.identifier = idenifier;
        view.labelTime.stringValue = strValue;
        view.labelEvent.attributedStringValue = attributed;
    } else {
        view.labelTime.stringValue = strValue;
        view.labelEvent.attributedStringValue = attributed;
    }
    return view;
}

- (nullable NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row{
    return [[OwlTableRowView alloc] initWithFrame:NSZeroRect];
}

#pragma mark NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return [OwlManager shareInstance].logArray.count;
}

@end
